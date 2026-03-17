package com.inmovista.listener;

import com.inmovista.db.ConnectionPool;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;
import java.util.logging.Logger;

/**
 * AppContextListener
 *
 * Se ejecuta al iniciar y apagar Tomcat.
 * - Inicio: pre-calienta el pool de conexiones.
 * - Apagado: cierra todas las conexiones ordenadamente
 *   para no acumular conexiones abiertas en Clever Cloud.
 *
 * Registrado automáticamente con @WebListener.
 */
@WebListener
public class AppContextListener implements ServletContextListener {

    private static final Logger LOGGER = Logger.getLogger(AppContextListener.class.getName());

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        LOGGER.info("╔══════════════════════════════════════╗");
        LOGGER.info("║  InmoVista — Iniciando aplicación    ║");
        LOGGER.info("╚══════════════════════════════════════╝");
        try {
            // Pre-inicializa el pool cloud para detectar errores al arrancar
            ConnectionPool pool = ConnectionPool.getCloudPool();
            LOGGER.info("[AppContextListener] Pool Cloud listo. " + pool.getStatus());
        } catch (Exception e) {
            LOGGER.severe("[AppContextListener] ❌ No se pudo conectar a la BD: " + e.getMessage());
        }
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        LOGGER.info("[AppContextListener] Cerrando pools de conexiones...");
        try { ConnectionPool.getCloudPool().shutdown(); } catch (Exception ignored) {}
        try { ConnectionPool.getLocalPool().shutdown(); } catch (Exception ignored) {}
        LOGGER.info("[AppContextListener] ✅ Pools cerrados. Tomcat detenido.");
    }
}
