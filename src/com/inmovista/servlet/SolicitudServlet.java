package com.inmovista.servlet;

import com.inmovista.model.Usuario;

import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;

public class SolicitudServlet extends HttpServlet {

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

        String propiedadIdStr  = req.getParameter("propiedadId");
        String tipoOperacion   = req.getParameter("tipoOperacion");
        String observaciones   = req.getParameter("observaciones");

        if (propiedadIdStr == null || tipoOperacion == null || tipoOperacion.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/dashboard/cliente/mis-solicitudes.jsp?msg=Error:+datos+incompletos");
            return;
        }

        Connection conn = null;
        try {
            conn = DriverManager.getConnection(URL, USER, PASS);
            PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO solicitudes_documentos (propiedad_id, cliente_id, tipo_operacion, estado, observaciones) " +
                "VALUES (?,?,?,'PENDIENTE',?)");
            ps.setInt(1, Integer.parseInt(propiedadIdStr));
            ps.setInt(2, usuario.getId());
            ps.setString(3, tipoOperacion);
            ps.setString(4, observaciones != null && !observaciones.trim().isEmpty() ? observaciones.trim() : null);
            ps.executeUpdate();
            ps.close();
            resp.sendRedirect(req.getContextPath() + "/dashboard/cliente/mis-solicitudes.jsp?msg=Solicitud+enviada+exitosamente");
        } catch (Exception e) {
            resp.sendRedirect(req.getContextPath() + "/dashboard/cliente/mis-solicitudes.jsp?msg=Error+al+enviar+solicitud");
        } finally {
            if (conn != null) try { conn.close(); } catch (Exception ignored) {}
        }
    }
}
