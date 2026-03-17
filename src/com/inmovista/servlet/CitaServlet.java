package com.inmovista.servlet;

import com.inmovista.model.Usuario;

import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;

public class CitaServlet extends HttpServlet {

    private static final String URL  = "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true";
    private static final String USER = "uf7uiezwq3tjedqa";
    private static final String PASS = "9vpBUmwZ8xqi4kP8FmXe";

    static {
        try { Class.forName("com.mysql.cj.jdbc.Driver"); } catch (Exception ignored) {}
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        HttpSession session = req.getSession(false);
        Usuario usuario = session != null ? (Usuario) session.getAttribute("usuario") : null;

        if (usuario == null || !usuario.isCliente()) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        String action = req.getParameter("action");

        // ── Cancelar cita ─────────────────────────────────────────────────────
        if ("cancelar".equals(action)) {
            String citaId = req.getParameter("citaId");
            Connection conn = null;
            try {
                conn = DriverManager.getConnection(URL, USER, PASS);
                PreparedStatement ps = conn.prepareStatement(
                    "UPDATE citas SET estado='CANCELADA' WHERE id=? AND cliente_id=?");
                ps.setInt(1, Integer.parseInt(citaId));
                ps.setInt(2, usuario.getId());
                ps.executeUpdate();
                ps.close();
                resp.sendRedirect(req.getContextPath() + "/dashboard/cliente/mis-citas.jsp");
            } catch (Exception e) {
                resp.sendRedirect(req.getContextPath() + "/dashboard/cliente/mis-citas.jsp");
            } finally {
                if (conn != null) try { conn.close(); } catch (Exception ignored) {}
            }
            return;
        }

        // ── Agendar cita ──────────────────────────────────────────────────────
        String propiedadIdStr = req.getParameter("propiedadId");
        String fechaHora      = req.getParameter("fechaHora");
        String mensaje        = req.getParameter("mensaje");

        if (propiedadIdStr == null || fechaHora == null || fechaHora.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/propiedades?id=" + propiedadIdStr + "&err=Debes+seleccionar+fecha+y+hora");
            return;
        }

        String fechaFormateada = fechaHora.replace("T", " ") + ":00";

        Connection conn = null;
        try {
            conn = DriverManager.getConnection(URL, USER, PASS);
            PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO citas (propiedad_id, cliente_id, fecha_solicitada, notas_cliente, estado) VALUES (?,?,?,?,'PENDIENTE')");
            ps.setInt(1, Integer.parseInt(propiedadIdStr));
            ps.setInt(2, usuario.getId());
            ps.setString(3, fechaFormateada);
            ps.setString(4, mensaje != null && !mensaje.trim().isEmpty() ? mensaje.trim() : null);
            ps.executeUpdate();
            ps.close();
            resp.sendRedirect(req.getContextPath() + "/propiedades?id=" + propiedadIdStr + "&msg=Cita+agendada+exitosamente");
        } catch (Exception e) {
            resp.sendRedirect(req.getContextPath() + "/propiedades?id=" + propiedadIdStr
                + "&err=" + java.net.URLEncoder.encode(e.getMessage() != null ? e.getMessage() : "Error", "UTF-8"));
        } finally {
            if (conn != null) try { conn.close(); } catch (Exception ignored) {}
        }
    }
}
