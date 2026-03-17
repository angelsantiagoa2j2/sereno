package com.inmovista.servlet;

import com.inmovista.db.DBManager;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;

/**
 * DBTestServlet — Endpoint para verificar conexión a la BD.
 * Acceder desde: http://localhost:8080/inmovista/db-test
 *
 * ⚠️ ELIMINAR o proteger en producción.
 */

public class DBTestServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        resp.setContentType("text/html;charset=UTF-8");
        PrintWriter out = resp.getWriter();

        out.println("<!DOCTYPE html><html><head>");
        out.println("<meta charset='UTF-8'>");
        out.println("<title>InmoVista — DB Test</title>");
        out.println("<style>");
        out.println("body{font-family:monospace;background:#1a1a18;color:#f5f0e8;padding:40px;}");
        out.println(".ok{color:#4caf50;} .err{color:#f44336;} .info{color:#c9a84c;}");
        out.println("pre{background:#2a2820;padding:20px;border-radius:8px;border-left:4px solid #c9a84c;}");
        out.println("</style></head><body>");
        out.println("<h2 class='info'>🏠 InmoVista — Test de Conexión a Base de Datos</h2>");
        out.println("<pre>");

        // Test entorno activo
        String env = DBManager.getActiveEnvironment();
        String db  = DBManager.getDatabaseName();
        out.println("Entorno activo : <span class='info'>" + env + "</span>");
        out.println("Base de datos  : <span class='info'>" + db + "</span>");
        out.println();

        // Test Cloud
        testEnv(out, "cloud");
        out.println();

        // Test Local
        testEnv(out, "local");

        out.println("</pre>");
        out.println("</body></html>");
    }

    private void testEnv(PrintWriter out, String env) {
        out.print("Probando [" + env.toUpperCase() + "] ... ");
        try (Connection conn = DBManager.getConnection(env)) {
            if (conn != null && conn.isValid(5)) {
                String version = conn.getMetaData().getDatabaseProductVersion();
                out.println("<span class='ok'>✅ CONECTADO</span>  →  MySQL " + version);
            } else {
                out.println("<span class='err'>❌ Conexión inválida</span>");
            }
        } catch (Exception e) {
            out.println("<span class='err'>❌ ERROR: " + escapeHtml(e.getMessage()) + "</span>");
        }
    }

    private String escapeHtml(String s) {
        if (s == null) return "null";
        return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;");
    }
}
