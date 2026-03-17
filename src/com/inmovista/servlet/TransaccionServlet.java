package com.inmovista.servlet;

import com.inmovista.model.Usuario;

import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;

public class TransaccionServlet extends HttpServlet {

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

        if (usuario == null || (!usuario.isInmobiliaria() && !usuario.isAdmin())) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        String propiedadIdStr = req.getParameter("propiedadId");
        String clienteIdStr   = req.getParameter("clienteId");
        String tipo           = req.getParameter("tipo");
        String valorStr       = req.getParameter("valor");
        String comisionStr    = req.getParameter("comision");
        String fechaCierre    = req.getParameter("fechaCierre");
        String notas          = req.getParameter("notas");

        if (propiedadIdStr == null || clienteIdStr == null || tipo == null || valorStr == null || fechaCierre == null) {
            resp.sendRedirect(req.getContextPath() + "/dashboard/inmobiliaria/mis-propiedades.jsp?msg=Error:+datos+incompletos");
            return;
        }

        Connection conn = null;
        try {
            conn = DriverManager.getConnection(URL, USER, PASS);

            // Insertar transacción
            PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO transacciones (propiedad_id, cliente_id, inmobiliaria_id, tipo, valor, comision, fecha_cierre, notas) " +
                "VALUES (?,?,?,?,?,?,?,?)");
            ps.setInt(1, Integer.parseInt(propiedadIdStr));
            ps.setInt(2, Integer.parseInt(clienteIdStr));
            ps.setInt(3, usuario.getId());
            ps.setString(4, tipo);
            ps.setDouble(5, Double.parseDouble(valorStr.replace(",","").replace(".","").replace("$","")));
            ps.setDouble(6, comisionStr != null && !comisionStr.isEmpty() ? Double.parseDouble(comisionStr) : 0);
            ps.setString(7, fechaCierre);
            ps.setString(8, notas != null && !notas.trim().isEmpty() ? notas.trim() : null);
            ps.executeUpdate();
            ps.close();

            // Actualizar estado de la propiedad
            String nuevoEstado = "VENTA".equals(tipo) ? "VENDIDO" : "ARRENDADO";
            ps = conn.prepareStatement("UPDATE propiedades SET estado=? WHERE id=?");
            ps.setString(1, nuevoEstado);
            ps.setInt(2, Integer.parseInt(propiedadIdStr));
            ps.executeUpdate();
            ps.close();

            resp.sendRedirect(req.getContextPath() + "/dashboard/inmobiliaria/mis-propiedades.jsp?msg=Negocio+cerrado+exitosamente");
        } catch (Exception e) {
            resp.sendRedirect(req.getContextPath() + "/dashboard/inmobiliaria/mis-propiedades.jsp?msg=Error:+" +
                java.net.URLEncoder.encode(e.getMessage() != null ? e.getMessage() : "Error", "UTF-8"));
        } finally {
            if (conn != null) try { conn.close(); } catch (Exception ignored) {}
        }
    }
}
