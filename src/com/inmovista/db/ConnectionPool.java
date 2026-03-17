package com.inmovista.db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

/**
 * ConnectionPool — Pool de conexiones thread-safe para InmoVista.
 *
 * Clever Cloud Free Tier = máx 5 conexiones simultáneas.
 * Este pool mantiene máx 4 (dejamos 1 libre para admin/CLI).
 *
 * Patrón Singleton: una sola instancia por entorno (local / cloud).
 */
public class ConnectionPool {

    private static final Logger LOGGER = Logger.getLogger(ConnectionPool.class.getName());

    // ── Límites ────────────────────────────────────────────────────────────
    private static final int CLOUD_MAX_POOL = 4;   // ≤ 5 límite Clever Cloud
    private static final int LOCAL_MAX_POOL = 10;
    private static final int WAIT_TIMEOUT_MS = 8000; // espera máx por conexión libre

    // ── Instancias Singleton ───────────────────────────────────────────────
    private static ConnectionPool cloudInstance = null;
    private static ConnectionPool localInstance = null;
    private static final Object LOCK = new Object();

    // ── Estado interno del pool ────────────────────────────────────────────
    private final String url;
    private final String user;
    private final String password;
    private final int maxSize;
    private final String envName;

    private final List<Connection> pool      = new ArrayList<>(); // conexiones disponibles
    private final List<Connection> inUse     = new ArrayList<>(); // conexiones ocupadas
    private boolean closed = false;

    // ─────────────────────────────────────────────────────────────────────
    //  Constructor privado
    // ─────────────────────────────────────────────────────────────────────
    private ConnectionPool(String envName, String url, String user,
                           String password, int maxSize) throws SQLException {
        this.envName  = envName;
        this.url      = url;
        this.user     = user;
        this.password = password;
        this.maxSize  = maxSize;

        // Carga el driver
        try { Class.forName("com.mysql.cj.jdbc.Driver"); }
        catch (ClassNotFoundException e) {
            throw new SQLException("Driver MySQL no encontrado", e);
        }

        // Pre-crea 1 conexión inicial para validar credenciales
        pool.add(createConnection());
        LOGGER.info("[Pool:" + envName + "] Inicializado. Max=" + maxSize
                    + " | Pre-conectado: 1");
    }

    // ─────────────────────────────────────────────────────────────────────
    //  Singleton getters
    // ─────────────────────────────────────────────────────────────────────

    public static ConnectionPool getCloudPool() throws SQLException {
        if (cloudInstance == null) {
            synchronized (LOCK) {
                if (cloudInstance == null) {
                    cloudInstance = new ConnectionPool(
                        "CLOUD",
                        "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/" +
                        "by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC" +
                        "&allowPublicKeyRetrieval=true&useUnicode=true" +
                        "&characterEncoding=UTF-8&autoReconnect=true",
                        "uf7uiezwq3tjedqa",
                        "9vpBUmwZ8xqi4kP8FmXe",
                        CLOUD_MAX_POOL
                    );
                }
            }
        }
        return cloudInstance;
    }

    public static ConnectionPool getLocalPool() throws SQLException {
        if (localInstance == null) {
            synchronized (LOCK) {
                if (localInstance == null) {
                    // Lee credenciales del properties (delegado a DBManager)
                    localInstance = new ConnectionPool(
                        "LOCAL",
                        "jdbc:mysql://localhost:3306/inmovista_db?useSSL=false" +
                        "&serverTimezone=America/Bogota&allowPublicKeyRetrieval=true" +
                        "&useUnicode=true&characterEncoding=UTF-8&autoReconnect=true",
                        "root",
                        "",          // ← cambia si tu root tiene contraseña
                        LOCAL_MAX_POOL
                    );
                }
            }
        }
        return localInstance;
    }

    // ─────────────────────────────────────────────────────────────────────
    //  Obtener conexión del pool
    // ─────────────────────────────────────────────────────────────────────

    /**
     * Obtiene una conexión disponible del pool.
     * Si no hay disponibles y no se alcanzó el máximo, crea una nueva.
     * Si se alcanzó el máximo, espera hasta WAIT_TIMEOUT_MS ms.
     *
     * @throws SQLException si no se obtiene conexión en el tiempo límite
     */
    public synchronized Connection getConnection() throws SQLException {
        if (closed) throw new SQLException("[Pool:" + envName + "] Pool cerrado.");

        long start = System.currentTimeMillis();

        while (true) {
            // 1) ¿Hay conexión disponible y válida en el pool?
            for (int i = pool.size() - 1; i >= 0; i--) {
                Connection c = pool.get(i);
                if (isValid(c)) {
                    pool.remove(i);
                    inUse.add(c);
                    LOGGER.fine("[Pool:" + envName + "] Conexión entregada. "
                                + "En uso=" + inUse.size() + "/" + maxSize);
                    return c;
                } else {
                    pool.remove(i); // descarta conexión muerta
                    LOGGER.fine("[Pool:" + envName + "] Conexión muerta descartada.");
                }
            }

            // 2) ¿Podemos crear una nueva?
            int total = pool.size() + inUse.size();
            if (total < maxSize) {
                Connection c = createConnection();
                inUse.add(c);
                LOGGER.fine("[Pool:" + envName + "] Nueva conexión creada. "
                            + "En uso=" + inUse.size() + "/" + maxSize);
                return c;
            }

            // 3) Pool lleno → esperar
            long elapsed = System.currentTimeMillis() - start;
            if (elapsed >= WAIT_TIMEOUT_MS) {
                throw new SQLException(
                    "[Pool:" + envName + "] Timeout: no hay conexiones disponibles. " +
                    "En uso=" + inUse.size() + "/" + maxSize +
                    ". Verifica que usas releaseConnection() tras cada operación."
                );
            }

            LOGGER.warning("[Pool:" + envName + "] Pool lleno (" + inUse.size() +
                           "/" + maxSize + "). Esperando...");
            try { wait(500); }
            catch (InterruptedException e) { Thread.currentThread().interrupt(); }
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  Devolver conexión al pool
    // ─────────────────────────────────────────────────────────────────────

    /**
     * Devuelve una conexión al pool para que pueda ser reutilizada.
     * SIEMPRE llamar esto en el bloque finally.
     */
    public synchronized void releaseConnection(Connection conn) {
        if (conn == null) return;
        if (inUse.remove(conn)) {
            if (isValid(conn)) {
                try { if (!conn.getAutoCommit()) conn.setAutoCommit(true); }
                catch (SQLException ignored) {}
                pool.add(conn);
                LOGGER.fine("[Pool:" + envName + "] Conexión devuelta al pool. "
                            + "Disponibles=" + pool.size());
            } else {
                LOGGER.fine("[Pool:" + envName + "] Conexión inválida descartada al devolver.");
            }
        } else {
            // No pertenece al pool → cerrar directo
            try { conn.close(); } catch (SQLException ignored) {}
        }
        notifyAll(); // despierta hilos esperando
    }

    // ─────────────────────────────────────────────────────────────────────
    //  Utilidades
    // ─────────────────────────────────────────────────────────────────────

    private Connection createConnection() throws SQLException {
        return DriverManager.getConnection(url, user, password);
    }

    private boolean isValid(Connection c) {
        try { return c != null && !c.isClosed() && c.isValid(2); }
        catch (SQLException e) { return false; }
    }

    /** Cierra todas las conexiones del pool. Llamar al destruir la app. */
    public synchronized void shutdown() {
        closed = true;
        for (Connection c : pool)  { try { c.close(); } catch (SQLException ignored) {} }
        for (Connection c : inUse) { try { c.close(); } catch (SQLException ignored) {} }
        pool.clear();
        inUse.clear();
        LOGGER.info("[Pool:" + envName + "] Pool cerrado.");
    }

    /** Info de estado del pool (útil para debug). */
    public synchronized String getStatus() {
        return "[Pool:" + envName + "] Disponibles=" + pool.size()
               + " | En uso=" + inUse.size()
               + " | Máximo=" + maxSize;
    }

    public synchronized int getAvailable() { return pool.size(); }
    public synchronized int getInUse()     { return inUse.size(); }
    public String getEnvName()             { return envName; }
}
