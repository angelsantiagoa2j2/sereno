package com.inmovista.servlet;

import com.inmovista.dao.PropiedadDAO;
import com.inmovista.model.Propiedad;
import com.inmovista.model.Propiedad.*;
import com.inmovista.model.Usuario;

import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.List;

public class PropiedadServlet extends HttpServlet {

    private final PropiedadDAO dao = new PropiedadDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String action  = req.getParameter("action");
        String idParam = req.getParameter("id");

        // Detalle
        if (idParam != null && action == null) {
            req.getRequestDispatcher("/propiedades/detalle.jsp").forward(req, resp);
            return;
        }

        // Formulario
        if ("form".equals(action)) {
            requireAuth(req, resp);
            if (resp.isCommitted()) return;
            if (idParam != null) {
                try {
                    Propiedad p = dao.findById(Integer.parseInt(idParam));
                    req.setAttribute("propiedad", p);
                } catch (Exception ignored) {}
            }
            req.getRequestDispatcher("/propiedades/form.jsp").forward(req, resp);
            return;
        }

        // Lista
        String keyword   = req.getParameter("buscar");
        String tipo      = req.getParameter("tipo");
        String operacion = req.getParameter("operacion");

        List<Propiedad> propiedades;
        if ((keyword != null && !keyword.isEmpty()) || (tipo != null && !tipo.isEmpty()) || (operacion != null && !operacion.isEmpty())) {
            propiedades = dao.search(keyword, tipo, operacion, null, null, null);
        } else {
            propiedades = dao.findDisponibles();
        }

        req.setAttribute("propiedades", propiedades);
        req.getRequestDispatcher("/propiedades/lista.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        requireAuth(req, resp);
        if (resp.isCommitted()) return;

        String action = req.getParameter("action");

        if ("delete".equals(action)) {
            dao.delete(Integer.parseInt(req.getParameter("id")));
            resp.sendRedirect(req.getContextPath() + getDashboardUrl(req) + "?msg=Propiedad+eliminada");
            return;
        }

        String idParam    = req.getParameter("id");
        boolean esEdicion = idParam != null && !idParam.isEmpty();

        try {
            Propiedad p = esEdicion ? dao.findById(Integer.parseInt(idParam)) : new Propiedad();
            if (p == null) p = new Propiedad();

            p.setTitulo(req.getParameter("titulo"));
            p.setDescripcion(req.getParameter("descripcion"));
            p.setTipo(Tipo.valueOf(req.getParameter("tipo").toUpperCase()));
            p.setOperacion(Operacion.valueOf(req.getParameter("operacion").toUpperCase()));
            p.setPrecio(new BigDecimal(req.getParameter("precio").replace(".", "").replace(",", ".")));
            String area = req.getParameter("areaM2");
            if (area != null && !area.isEmpty()) p.setAreaM2(new BigDecimal(area));
            p.setHabitaciones(safeInt(req.getParameter("habitaciones"), 0));
            p.setBanos(safeInt(req.getParameter("banos"), 0));
            p.setParqueaderos(safeInt(req.getParameter("parqueaderos"), 0));
            p.setEstrato(safeInteger(req.getParameter("estrato")));
            p.setDireccion(req.getParameter("direccion"));
            p.setBarrio(req.getParameter("barrio"));
            p.setCiudadId(Integer.parseInt(req.getParameter("ciudadId")));
            String est = req.getParameter("estado");
            p.setEstado(Estado.valueOf(est != null && !est.isEmpty() ? est.toUpperCase() : "DISPONIBLE"));

            Usuario usuario = (Usuario) req.getSession().getAttribute("usuario");
            if (!esEdicion) p.setInmobiliariaId(usuario.getId());

            boolean ok = esEdicion ? dao.update(p) : dao.insert(p) > 0;
            resp.sendRedirect(req.getContextPath() + getDashboardUrl(req) + "?msg=" + (ok ? "Propiedad+guardada" : "Error+al+guardar"));

        } catch (Exception e) {
            req.setAttribute("error", "Error: " + e.getMessage());
            req.getRequestDispatcher("/propiedades/form.jsp").forward(req, resp);
        }
    }

    private void requireAuth(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession s = req.getSession(false);
        Usuario u = s != null ? (Usuario) s.getAttribute("usuario") : null;
        if (u == null || (!u.isInmobiliaria() && !u.isAdmin()))
            resp.sendRedirect(req.getContextPath() + "/login");
    }

    private String getDashboardUrl(HttpServletRequest req) {
        Usuario u = (Usuario) req.getSession().getAttribute("usuario");
        return (u != null && u.isAdmin()) ? "/dashboard/admin/index.jsp" : "/dashboard/inmobiliaria/index.jsp";
    }

    private int safeInt(String s, int def) {
        try { return (s != null && !s.isEmpty()) ? Integer.parseInt(s) : def; } catch (Exception e) { return def; }
    }

    private Integer safeInteger(String s) {
        try { return (s != null && !s.isEmpty()) ? Integer.parseInt(s) : null; } catch (Exception e) { return null; }
    }
}
