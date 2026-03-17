package com.inmovista.servlet;

import com.inmovista.dao.UsuarioDAO;
import com.inmovista.model.Usuario;
import com.inmovista.model.Usuario.Rol;
import com.inmovista.util.BCryptUtil;

import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;

/**
 * RegisterServlet — Registro de nuevos usuarios.
 * GET  /register → muestra register.jsp
 * POST /register → crea la cuenta y redirige al login
 */

public class RegisterServlet extends HttpServlet {

    private final UsuarioDAO usuarioDAO = new UsuarioDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session != null && session.getAttribute("usuario") != null) {
            Usuario u = (Usuario) session.getAttribute("usuario");
            resp.sendRedirect(req.getContextPath() + u.getDashboardUrl());
            return;
        }
        req.getRequestDispatcher("/register.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String nombre    = req.getParameter("nombre");
        String apellido  = req.getParameter("apellido");
        String email     = req.getParameter("email");
        String password  = req.getParameter("password");
        String password2 = req.getParameter("password2");
        String telefono  = req.getParameter("telefono");
        String rolParam  = req.getParameter("rol"); // CLIENTE o INMOBILIARIA

        // ── Validaciones ─────────────────────────────────────────────────────
        if (isEmpty(nombre) || isEmpty(apellido) || isEmpty(email)
                || isEmpty(password) || isEmpty(password2)) {
            req.setAttribute("error", "Todos los campos obligatorios deben estar completos.");
            preserveFormData(req, nombre, apellido, email, telefono, rolParam);
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
            return;
        }

        if (!password.equals(password2)) {
            req.setAttribute("error", "Las contraseñas no coinciden.");
            preserveFormData(req, nombre, apellido, email, telefono, rolParam);
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
            return;
        }

        if (password.length() < 8) {
            req.setAttribute("error", "La contraseña debe tener al menos 8 caracteres.");
            preserveFormData(req, nombre, apellido, email, telefono, rolParam);
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
            return;
        }

        if (!email.matches("^[\\w.-]+@[\\w.-]+\\.[a-zA-Z]{2,}$")) {
            req.setAttribute("error", "El formato del correo no es válido.");
            preserveFormData(req, nombre, apellido, email, telefono, rolParam);
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
            return;
        }

        if (usuarioDAO.emailExists(email.trim().toLowerCase())) {
            req.setAttribute("error", "Ya existe una cuenta con este correo electrónico.");
            preserveFormData(req, nombre, apellido, email, telefono, rolParam);
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
            return;
        }

        // ── Determinar rol (solo CLIENTE o INMOBILIARIA pueden registrarse) ──
        Rol rol;
        try {
            rol = Rol.fromNombre(rolParam != null ? rolParam.toUpperCase() : "CLIENTE");
            if (rol == Rol.ADMIN) rol = Rol.CLIENTE; // seguridad: no se puede auto-asignar ADMIN
        } catch (Exception e) {
            rol = Rol.CLIENTE;
        }

        // ── Crear usuario ────────────────────────────────────────────────────
        Usuario nuevo = new Usuario();
        nuevo.setNombre(capitalize(nombre.trim()));
        nuevo.setApellido(capitalize(apellido.trim()));
        nuevo.setEmail(email.trim().toLowerCase());
        nuevo.setPasswordHash(BCryptUtil.hashPassword(password));
        nuevo.setTelefono(telefono != null ? telefono.trim() : null);
        nuevo.setRol(rol);
        nuevo.setActivo(true);
        nuevo.setEmailVerificado(false);

        int nuevoId = -1;
try { nuevoId = usuarioDAO.insert(nuevo); }
catch (Exception e) {
    req.setAttribute("error", "Error: " + e.getMessage());
    req.getRequestDispatcher("/register.jsp").forward(req, resp);
    return;
}

        if (nuevoId <= 0) {
            req.setAttribute("error", "Error al crear la cuenta. Por favor intenta de nuevo.");
            preserveFormData(req, nombre, apellido, email, telefono, rolParam);
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
            return;
        }

        // ── Redirigir al login con mensaje de exito ──────────────────────────
        resp.sendRedirect(req.getContextPath()
                + "/login?success=Cuenta+creada+exitosamente.+Inicia+sesion.");
    }

    private void preserveFormData(HttpServletRequest req, String nombre,
            String apellido, String email, String telefono, String rol) {
        req.setAttribute("fNombre",   nombre);
        req.setAttribute("fApellido", apellido);
        req.setAttribute("fEmail",    email);
        req.setAttribute("fTelefono", telefono);
        req.setAttribute("fRol",      rol);
    }

    private boolean isEmpty(String s) {
        return s == null || s.trim().isEmpty();
    }

    private String capitalize(String s) {
        if (s == null || s.isEmpty()) return s;
        return Character.toUpperCase(s.charAt(0)) + s.substring(1).toLowerCase();
    }
}
