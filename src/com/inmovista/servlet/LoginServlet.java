package com.inmovista.servlet;

import com.inmovista.dao.UsuarioDAO;
import com.inmovista.model.Usuario;
import com.inmovista.util.BCryptUtil;

import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;

/**
 * LoginServlet — Maneja autenticacion de usuarios.
 * GET  /login  → muestra login.jsp
 * POST /login  → valida credenciales y crea sesion
 */

public class LoginServlet extends HttpServlet {

    private final UsuarioDAO usuarioDAO = new UsuarioDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        // Si ya hay sesion activa, redirigir al dashboard
        HttpSession session = req.getSession(false);
        if (session != null && session.getAttribute("usuario") != null) {
            Usuario u = (Usuario) session.getAttribute("usuario");
            resp.sendRedirect(req.getContextPath() + u.getDashboardUrl());
            return;
        }
        req.getRequestDispatcher("/login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String email    = req.getParameter("email");
        String password = req.getParameter("password");
        String remember = req.getParameter("remember");

        // Validacion basica
        if (email == null || email.trim().isEmpty()
                || password == null || password.trim().isEmpty()) {
            req.setAttribute("error", "Por favor ingresa tu correo y contraseña.");
            req.getRequestDispatcher("/login.jsp").forward(req, resp);
            return;
        }

        // Buscar usuario por email
        Usuario usuario = usuarioDAO.findByEmail(email.trim().toLowerCase());

        if (usuario == null) {
            req.setAttribute("error", "Correo o contraseña incorrectos.");
            req.setAttribute("emailValue", email);
            req.getRequestDispatcher("/login.jsp").forward(req, resp);
            return;
        }

        // Verificar contraseña con BCrypt
        if (!BCryptUtil.checkPassword(password, usuario.getPasswordHash())) {
            req.setAttribute("error", "Correo o contraseña incorrectos.");
            req.setAttribute("emailValue", email);
            req.getRequestDispatcher("/login.jsp").forward(req, resp);
            return;
        }

        // Verificar que el usuario este activo
        if (!usuario.isActivo()) {
            req.setAttribute("error", "Tu cuenta ha sido desactivada. Contacta al administrador.");
            req.getRequestDispatcher("/login.jsp").forward(req, resp);
            return;
        }

        // Crear sesion
        HttpSession session = req.getSession(true);
        session.setAttribute("usuario", usuario);
        session.setAttribute("usuarioId", usuario.getId());
        session.setAttribute("usuarioNombre", usuario.getNombreCompleto());
        session.setAttribute("usuarioRol", usuario.getRol().getNombre());

        // Recordar sesion 7 dias si lo pidio
        if ("on".equals(remember)) {
            session.setMaxInactiveInterval(7 * 24 * 60 * 60);
        } else {
            session.setMaxInactiveInterval(30 * 60); // 30 minutos
        }

        // Registrar ultimo login
        usuarioDAO.registerLogin(usuario.getId());

        // Redirigir segun rol
        resp.sendRedirect(req.getContextPath() + usuario.getDashboardUrl());
    }
}
