package com.inmovista.filter;

import com.inmovista.model.Usuario;

import javax.servlet.*;
import javax.servlet.http.*;
import java.io.IOException;

public class SessionFilter implements Filter {

    @Override
    public void init(FilterConfig config) throws ServletException {}

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  req  = (HttpServletRequest)  request;
        HttpServletResponse resp = (HttpServletResponse) response;

        HttpSession session = req.getSession(false);
        Usuario usuario = session != null ? (Usuario) session.getAttribute("usuario") : null;

        if (usuario == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        // Verificar acceso por rol
        String uri = req.getRequestURI();
        String ctx = req.getContextPath();

        if (uri.startsWith(ctx + "/dashboard/admin") && !usuario.isAdmin()) {
            resp.sendRedirect(ctx + "/acceso-denegado.jsp");
            return;
        }
        if (uri.startsWith(ctx + "/dashboard/inmobiliaria") && !usuario.isInmobiliaria() && !usuario.isAdmin()) {
            resp.sendRedirect(ctx + "/acceso-denegado.jsp");
            return;
        }
        if (uri.startsWith(ctx + "/dashboard/cliente") && !usuario.isCliente() && !usuario.isAdmin()) {
            resp.sendRedirect(ctx + "/acceso-denegado.jsp");
            return;
        }

        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {}
}
