package com.inmovista.servlet;


import javax.servlet.http.*;
import java.io.IOException;

/** LogoutServlet — Invalida la sesion y redirige al login. */

public class LogoutServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        HttpSession session = req.getSession(false);
        if (session != null) session.invalidate();
        resp.sendRedirect(req.getContextPath() + "/login?logout=true");
    }
}
