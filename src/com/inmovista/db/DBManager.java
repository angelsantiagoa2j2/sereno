package com.inmovista.db;
 
import java.sql.*;
import java.util.logging.Level;
import java.util.logging.Logger;
 
public class DBManager {
 
    private static final Logger LOGGER = Logger.getLogger(DBManager.class.getName());
 
    private static final String URL  = "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true&useUnicode=true&characterEncoding=UTF-8";
    private static final String USER = "uf7uiezwq3tjedqa";
    private static final String PASS = "9vpBUmwZ8xqi4kP8FmXe";
 
    static {
        try { Class.forName("com.mysql.cj.jdbc.Driver"); }
        catch (ClassNotFoundException e) { LOGGER.severe("Driver MySQL no encontrado"); }
    }
 
    private DBManager() {}
 
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASS);
    }
 
    public static Connection getConnection(String env) throws SQLException {
        return getConnection(); // siempre cloud
    }
 
    public static void release(Connection conn) {
        if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
    }
 
    public static void release(Connection conn, String env) {
        release(conn);
    }
 
    public static void closeResources(PreparedStatement ps, Connection conn) {
        if (ps != null) try { ps.close(); } catch (SQLException ignored) {}
        release(conn);
    }
 
    public static void closeResources(ResultSet rs, PreparedStatement ps, Connection conn) {
        if (rs != null) try { rs.close(); } catch (SQLException ignored) {}
        closeResources(ps, conn);
    }
 
    public static boolean testConnection() {
        try (Connection conn = getConnection()) {
            return conn.isValid(5);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Test FALLIDO: " + e.getMessage());
            return false;
        }
    }
 
    public static String getActiveEnvironment() { return "cloud"; }
    public static String getPoolStatus() { return "Conexiones directas (sin pool)"; }
}