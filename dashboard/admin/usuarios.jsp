<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    Usuario usuario = (Usuario) session.getAttribute("usuario");
    if (usuario == null || !usuario.isAdmin()) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }

    String DB_URL  = "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true";
    String DB_USER = "uf7uiezwq3tjedqa";
    String DB_PASS = "9vpBUmwZ8xqi4kP8FmXe";

    String action = request.getParameter("action");
    String userId = request.getParameter("id");

    /* ── ACCIONES GET: activar / desactivar / eliminar ── */
    if (action != null && userId != null && !"POST".equalsIgnoreCase(request.getMethod())) {
        if (!userId.equals(String.valueOf(usuario.getId()))) {  // nunca sobre tu propia cuenta
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
                PreparedStatement ps;
                if ("eliminar".equals(action)) {
                    ps = conn.prepareStatement("DELETE FROM usuarios WHERE id=?");
                    ps.setInt(1, Integer.parseInt(userId));
                    ps.executeUpdate(); ps.close(); conn.close();
                    response.sendRedirect("usuarios.jsp?msg=Usuario+eliminado+correctamente"); return;
                } else if ("activar".equals(action) || "desactivar".equals(action)) {
                    int nuevoActivo = "activar".equals(action) ? 1 : 0;
                    ps = conn.prepareStatement("UPDATE usuarios SET activo=? WHERE id=?");
                    ps.setInt(1, nuevoActivo); ps.setInt(2, Integer.parseInt(userId));
                    ps.executeUpdate(); ps.close(); conn.close();
                    response.sendRedirect("usuarios.jsp?msg=Usuario+actualizado"); return;
                } else {
                    conn.close();
                }
            } catch (Exception e) { /* ignorar */ }
        }
        response.sendRedirect("usuarios.jsp"); return;
    }

    /* ── ACCIÓN POST: editar ── */
    if ("POST".equalsIgnoreCase(request.getMethod()) && "editar".equals(action) && userId != null) {
        String nombre   = request.getParameter("nombre")   != null ? request.getParameter("nombre").trim()   : "";
        String apellido = request.getParameter("apellido") != null ? request.getParameter("apellido").trim() : "";
        String email    = request.getParameter("email")    != null ? request.getParameter("email").trim()    : "";
        String telefono = request.getParameter("telefono") != null ? request.getParameter("telefono").trim() : "";
        String rolIdStr = request.getParameter("rol_id");
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
            PreparedStatement ps = conn.prepareStatement(
                "UPDATE usuarios SET nombre=?, apellido=?, email=?, telefono=?, rol_id=? WHERE id=?");
            ps.setString(1, nombre);
            ps.setString(2, apellido);
            ps.setString(3, email);
            ps.setString(4, telefono.isEmpty() ? null : telefono);
            ps.setInt(5, Integer.parseInt(rolIdStr));
            ps.setInt(6, Integer.parseInt(userId));
            ps.executeUpdate(); ps.close(); conn.close();
        } catch (Exception e) { /* ignorar */ }
        response.sendRedirect("usuarios.jsp?msg=Usuario+editado+correctamente"); return;
    }

    /* ── CARGA DE DATOS ── */
    String filtroRol = request.getParameter("rol") != null ? request.getParameter("rol") : "";
    String msg       = request.getParameter("msg");

    List<String[]> usuarios = new ArrayList<>();
    List<String[]> roles    = new ArrayList<>();
    int cntAdmin = 0, cntAgente = 0, cntCliente = 0;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
        try {
            /* Contadores por rol */
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT r.nombre, COUNT(*) AS cnt FROM usuarios u JOIN roles r ON u.rol_id=r.id GROUP BY r.nombre")) {
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    String r = rs.getString("nombre"); int c = rs.getInt("cnt");
                    if      ("admin".equalsIgnoreCase(r))   cntAdmin  = c;
                    else if ("agente".equalsIgnoreCase(r))  cntAgente = c;
                    else if ("cliente".equalsIgnoreCase(r)) cntCliente = c;
                }
            }

            /* Lista de roles para el select del modal */
            try (PreparedStatement ps = conn.prepareStatement("SELECT id, nombre FROM roles ORDER BY id")) {
                ResultSet rs = ps.executeQuery();
                while (rs.next()) roles.add(new String[]{ String.valueOf(rs.getInt("id")), rs.getString("nombre") });
            }

            /* Lista de usuarios (con filtro opcional) */
            StringBuilder sql = new StringBuilder(
                "SELECT u.id, u.nombre, u.apellido, u.email, u.telefono, u.activo, r.nombre AS rol, r.id AS rol_id " +
                "FROM usuarios u JOIN roles r ON u.rol_id = r.id");
            if (!filtroRol.isEmpty()) sql.append(" WHERE r.nombre=?");
            sql.append(" ORDER BY u.id DESC");
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            if (!filtroRol.isEmpty()) ps.setString(1, filtroRol);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) usuarios.add(new String[]{
                String.valueOf(rs.getInt("id")),
                rs.getString("nombre"),
                rs.getString("apellido"),
                rs.getString("email"),
                rs.getString("telefono") != null ? rs.getString("telefono") : "",
                rs.getString("rol"),
                rs.getBoolean("activo") ? "1" : "0",
                String.valueOf(rs.getInt("rol_id"))
            });
            rs.close(); ps.close();
        } finally { conn.close(); }
    } catch (Exception e) { /* continuar */ }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Usuarios — Sereno Admin</title>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&family=Outfit:wght@300;400;500;600&display=swap" rel="stylesheet"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.0/font/bootstrap-icons.min.css" rel="stylesheet"/>
  <style>
    *,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
    :root{
      --navy:#0A1628; --navy-mid:#122040;
      --blue:#1455A4; --blue-bright:#1E6FD9;
      --sky:#4A9DE0;  --sky-lt:#A8D4F5;
      --ice:#EAF4FD;  --white:#FFFFFF;
      --slate:#4A5568; --slate-lt:#8A9BB0;
      --border:#D6E8F7; --bg:#F4F8FD;
    }
    body{font-family:'Outfit',sans-serif;background:var(--bg);color:var(--navy);min-height:100vh;}

    /* ── SIDEBAR ── */
    .sidebar{width:248px;min-height:100vh;background:var(--navy);position:fixed;top:0;left:0;z-index:100;overflow-y:auto;display:flex;flex-direction:column;border-right:1px solid rgba(255,255,255,0.04);}
    .sidebar-brand{padding:26px 24px 14px;border-bottom:1px solid rgba(255,255,255,0.06);}
    .brand-logo{font-family:'Playfair Display',serif;font-size:22px;font-weight:700;color:var(--white);text-decoration:none;display:block;}
    .brand-logo span{color:var(--sky);}
    .brand-sub{color:rgba(255,255,255,0.25);font-size:11px;letter-spacing:1px;text-transform:uppercase;margin-top:3px;}
    .brand-role{margin:14px 16px 4px;padding:8px 12px;background:rgba(248,113,113,0.12);border:1px solid rgba(248,113,113,0.2);border-radius:8px;font-size:11px;font-weight:600;letter-spacing:1.5px;text-transform:uppercase;color:#fca5a5;display:flex;align-items:center;gap:6px;}
    .nav-section{color:rgba(255,255,255,0.2);font-size:10px;font-weight:600;letter-spacing:2px;text-transform:uppercase;padding:18px 24px 6px;}
    .nav-link{color:rgba(255,255,255,0.45);padding:10px 24px;display:flex;align-items:center;gap:10px;font-size:14px;text-decoration:none;transition:all .2s;border-left:3px solid transparent;}
    .nav-link i{font-size:15px;flex-shrink:0;}
    .nav-link:hover{color:rgba(255,255,255,0.85);background:rgba(255,255,255,0.04);}
    .nav-link.active{color:var(--white);background:rgba(30,111,217,0.15);border-left-color:var(--blue-bright);}
    .sidebar-footer{margin-top:auto;padding:20px 24px;border-top:1px solid rgba(255,255,255,0.06);}
    .user-mini{display:flex;align-items:center;gap:10px;margin-bottom:4px;}
    .user-avatar{width:34px;height:34px;border-radius:50%;background:#e05555;color:var(--white);font-weight:700;font-size:13px;display:flex;align-items:center;justify-content:center;flex-shrink:0;}
    .user-name{color:rgba(255,255,255,0.8);font-size:13px;font-weight:500;}
    .user-role{color:rgba(255,255,255,0.3);font-size:11px;}

    /* ── MAIN ── */
    .main{margin-left:248px;min-height:100vh;display:flex;flex-direction:column;}

    /* ── HEADER BANNER ── */
    .header-banner{background:var(--navy);padding:28px 40px 32px;display:grid;grid-template-columns:1fr auto;align-items:center;gap:24px;position:relative;overflow:hidden;}
    .header-banner::after{content:'';position:absolute;right:-40px;top:-60px;width:260px;height:260px;border-radius:50%;background:radial-gradient(circle,rgba(248,113,113,0.08) 0%,transparent 70%);pointer-events:none;}
    .hb-eyebrow{font-size:11px;font-weight:600;letter-spacing:3px;text-transform:uppercase;color:rgba(255,255,255,0.35);margin-bottom:6px;}
    .hb-title{font-family:'Playfair Display',serif;font-size:28px;font-weight:900;color:var(--white);line-height:1.1;}
    .hb-title em{font-style:italic;color:#fca5a5;}
    .hb-sub{color:rgba(255,255,255,0.4);font-size:13px;margin-top:4px;font-weight:300;}

    /* ── STATS STRIP ── */
    .stats-strip{background:var(--navy-mid);display:grid;grid-template-columns:repeat(4,1fr);border-top:1px solid rgba(255,255,255,0.06);}
    .sstat{padding:16px 28px;display:flex;align-items:center;gap:14px;border-right:1px solid rgba(255,255,255,0.06);cursor:pointer;text-decoration:none;transition:background .2s;}
    .sstat:last-child{border-right:none;}
    .sstat:hover{background:rgba(255,255,255,0.03);}
    .sstat.active-filter{background:rgba(30,111,217,0.15);}
    .sstat-icon{width:36px;height:36px;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0;}
    .sstat-icon.all{background:rgba(255,255,255,0.08);color:rgba(255,255,255,0.6);}
    .sstat-icon.red{background:rgba(248,113,113,0.15);color:#fca5a5;}
    .sstat-icon.amber{background:rgba(245,158,11,0.15);color:#fcd34d;}
    .sstat-icon.blue{background:rgba(30,111,217,0.2);color:var(--sky-lt);}
    .sstat-num{font-family:'Playfair Display',serif;font-size:24px;font-weight:900;color:var(--white);line-height:1;}
    .sstat-lbl{font-size:11px;color:rgba(255,255,255,0.4);margin-top:1px;}

    /* ── CONTENT ── */
    .content{padding:28px 40px;flex:1;}

    /* ── ALERT ── */
    .alert-ok{display:flex;align-items:center;gap:10px;background:rgba(34,197,94,0.08);border:1.5px solid rgba(34,197,94,0.25);border-radius:10px;padding:12px 16px;color:#16a34a;font-size:14px;margin-bottom:20px;}
    .alert-close{margin-left:auto;background:none;border:none;color:#16a34a;cursor:pointer;font-size:16px;}

    /* ── TABLE PANEL ── */
    .panel{background:var(--white);border-radius:14px;border:1.5px solid var(--border);overflow:hidden;}
    .panel-head{display:flex;justify-content:space-between;align-items:center;padding:18px 24px;border-bottom:1.5px solid var(--border);}
    .panel-title{font-family:'Playfair Display',serif;font-size:17px;font-weight:700;color:var(--navy);}
    .panel-count{font-size:13px;color:var(--slate-lt);}

    /* Table */
    .users-table{width:100%;border-collapse:collapse;}
    .users-table th{padding:11px 20px;font-size:10px;font-weight:600;letter-spacing:1.5px;text-transform:uppercase;color:var(--slate-lt);text-align:left;background:var(--ice);border-bottom:1.5px solid var(--border);}
    .users-table td{padding:12px 20px;font-size:13px;border-bottom:1.5px solid var(--border);vertical-align:middle;}
    .users-table tr:last-child td{border-bottom:none;}
    .users-table tbody tr{transition:background .15s;}
    .users-table tbody tr:hover{background:var(--ice);}

    .td-id{font-size:11px;color:var(--slate-lt);font-weight:500;}
    .td-name{font-weight:600;color:var(--navy);font-size:14px;margin-bottom:1px;}
    .td-email{font-size:12px;color:var(--slate-lt);}
    .td-phone{font-size:13px;color:var(--slate);}

    /* Badges */
    .badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:600;white-space:nowrap;}
    .badge-green{background:rgba(34,197,94,0.1);color:#16a34a;}
    .badge-red{background:rgba(224,85,85,0.1);color:#e05555;}
    .badge-blue{background:rgba(30,111,217,0.1);color:var(--blue-bright);}
    .badge-amber{background:rgba(245,158,11,0.1);color:#d97706;}
    .badge-gray{background:rgba(0,0,0,0.06);color:var(--slate);}
    .badge-purple{background:rgba(139,92,246,0.1);color:#7c3aed;}

    /* Action buttons */
    .actions-cell{display:flex;align-items:center;gap:6px;flex-wrap:wrap;}
    .btn-action{display:inline-flex;align-items:center;gap:4px;padding:5px 12px;border-radius:20px;font-family:'Outfit',sans-serif;font-size:12px;font-weight:500;cursor:pointer;text-decoration:none;transition:all .2s;border:1.5px solid transparent;white-space:nowrap;}
    .btn-edit{border-color:rgba(30,111,217,0.25);color:var(--blue-bright);background:transparent;}
    .btn-edit:hover{background:var(--blue-bright);color:var(--white);border-color:var(--blue-bright);}
    .btn-deactivate{border-color:rgba(224,85,85,0.25);color:#e05555;background:transparent;}
    .btn-deactivate:hover{background:#e05555;color:var(--white);border-color:#e05555;}
    .btn-activate{border-color:rgba(34,197,94,0.3);color:#16a34a;background:transparent;}
    .btn-activate:hover{background:#22c55e;color:var(--white);border-color:#22c55e;}
    .btn-delete{border-color:rgba(153,27,27,0.2);color:#991b1b;background:transparent;}
    .btn-delete:hover{background:#dc2626;color:var(--white);border-color:#dc2626;}
    .own-tag{font-size:12px;color:var(--slate-lt);font-style:italic;}

    .empty-state{padding:48px;text-align:center;color:var(--slate-lt);font-size:14px;}
    .empty-state i{font-size:36px;color:var(--border);display:block;margin-bottom:10px;}

    /* ── MODAL ── */
    .modal-overlay{display:none;position:fixed;inset:0;background:rgba(10,22,40,0.65);z-index:500;align-items:center;justify-content:center;backdrop-filter:blur(3px);}
    .modal-overlay.open{display:flex;}
    .modal-box{background:var(--white);border-radius:18px;padding:36px;width:100%;max-width:500px;margin:0 20px;box-shadow:0 24px 80px rgba(10,22,40,0.25);animation:modalIn .25s ease;}
    @keyframes modalIn{from{opacity:0;transform:translateY(16px) scale(.97);}to{opacity:1;transform:none;}}
    .modal-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:24px;}
    .modal-title{font-family:'Playfair Display',serif;font-size:20px;font-weight:900;color:var(--navy);}
    .modal-close{width:32px;height:32px;border-radius:50%;border:1.5px solid var(--border);background:transparent;cursor:pointer;display:flex;align-items:center;justify-content:center;color:var(--slate-lt);font-size:16px;transition:all .2s;}
    .modal-close:hover{background:var(--bg);color:var(--navy);}
    .form-grid{display:grid;grid-template-columns:1fr 1fr;gap:14px;}
    .form-group{display:flex;flex-direction:column;gap:5px;}
    .form-group.full{grid-column:1/-1;}
    .form-label{font-size:11px;font-weight:600;letter-spacing:.8px;text-transform:uppercase;color:var(--slate);}
    .form-input{padding:10px 14px;border:1.5px solid var(--border);border-radius:9px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--navy);background:var(--bg);transition:border-color .2s;}
    .form-input:focus{outline:none;border-color:var(--blue-bright);background:var(--white);}
    .form-actions{display:flex;gap:10px;justify-content:flex-end;margin-top:24px;padding-top:20px;border-top:1.5px solid var(--border);}
    .btn-cancel{padding:10px 22px;border:1.5px solid var(--border);border-radius:22px;background:transparent;font-family:'Outfit',sans-serif;font-size:13px;font-weight:500;color:var(--slate);cursor:pointer;transition:all .2s;}
    .btn-cancel:hover{background:var(--bg);}
    .btn-save{padding:10px 24px;border:none;border-radius:22px;background:var(--blue-bright);color:var(--white);font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;cursor:pointer;transition:all .2s;display:flex;align-items:center;gap:6px;}
    .btn-save:hover{background:var(--blue);}

    /* ── CONFIRM MODAL ── */
    .confirm-box{background:var(--white);border-radius:18px;padding:32px;width:100%;max-width:400px;margin:0 20px;box-shadow:0 24px 80px rgba(10,22,40,0.25);animation:modalIn .25s ease;text-align:center;}
    .confirm-icon{width:56px;height:56px;border-radius:50%;background:rgba(220,38,38,0.1);display:flex;align-items:center;justify-content:center;margin:0 auto 16px;font-size:24px;color:#dc2626;}
    .confirm-title{font-family:'Playfair Display',serif;font-size:19px;font-weight:900;color:var(--navy);margin-bottom:8px;}
    .confirm-msg{font-size:13px;color:var(--slate-lt);line-height:1.6;margin-bottom:24px;}
    .confirm-actions{display:flex;gap:10px;justify-content:center;}
    .btn-confirm-del{padding:10px 24px;border:none;border-radius:22px;background:#dc2626;color:var(--white);font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;cursor:pointer;transition:background .2s;}
    .btn-confirm-del:hover{background:#b91c1c;}

    @media(max-width:1100px){.stats-strip{grid-template-columns:repeat(2,1fr);}}
    @media(max-width:900px){.form-grid{grid-template-columns:1fr;}.form-group.full{grid-column:1;}}
    @media(max-width:768px){.main{margin-left:0;}.content{padding:20px 16px;}.header-banner{padding:20px;}.actions-cell{flex-direction:column;align-items:flex-start;}}
  </style>
</head>
<body>

<!-- ══════════════════════ SIDEBAR ══════════════════════ -->
<aside class="sidebar">
  <div class="sidebar-brand">
    <a href="${pageContext.request.contextPath}/" class="brand-logo">Ser<span>eno</span></a>
    <div class="brand-sub">Panel de Control</div>
  </div>
  <div class="brand-role"><i class="bi bi-shield-fill"></i> Administrador</div>
  <nav>
    <div class="nav-section">Principal</div>
    <a href="index.jsp" class="nav-link"><i class="bi bi-grid-1x2"></i> Dashboard</a>
    <a href="<%= request.getContextPath() %>/propiedades" class="nav-link"><i class="bi bi-building"></i> Propiedades</a>
    <div class="nav-section">Gestión</div>
    <a href="usuarios.jsp" class="nav-link active"><i class="bi bi-people"></i> Usuarios</a>
    <a href="citas.jsp" class="nav-link"><i class="bi bi-calendar-check"></i> Citas</a>
    <a href="solicitudes.jsp" class="nav-link"><i class="bi bi-file-earmark-text"></i> Solicitudes</a>
    <a href="transacciones.jsp" class="nav-link"><i class="bi bi-cash-coin"></i> Transacciones</a>
  </nav>
  <div class="sidebar-footer">
    <div class="user-mini">
      <div class="user-avatar"><%= usuario.getNombre().charAt(0) %><%= usuario.getApellido().charAt(0) %></div>
      <div>
        <div class="user-name"><%= usuario.getNombreCompleto() %></div>
        <div class="user-role">Administrador</div>
      </div>
    </div>
    <a href="<%= request.getContextPath() %>/logout" class="nav-link" style="padding:10px 0 0;border-left:none;color:rgba(255,255,255,0.35);">
      <i class="bi bi-box-arrow-left"></i> Cerrar sesión
    </a>
  </div>
</aside>

<!-- ══════════════════════ MAIN ══════════════════════ -->
<div class="main">

  <!-- HEADER -->
  <div class="header-banner">
    <div>
      <div class="hb-eyebrow">Administración</div>
      <h1 class="hb-title">Gestión de <em>Usuarios</em></h1>
      <p class="hb-sub"><%= cntAdmin + cntAgente + cntCliente %> usuarios registrados en la plataforma</p>
    </div>
  </div>

  <!-- STATS / FILTROS -->
  <div class="stats-strip">
    <a href="usuarios.jsp" class="sstat <%= filtroRol.isEmpty() ? "active-filter" : "" %>">
      <div class="sstat-icon all"><i class="bi bi-people"></i></div>
      <div><div class="sstat-num"><%= cntAdmin + cntAgente + cntCliente %></div><div class="sstat-lbl">Todos</div></div>
    </a>
    <a href="usuarios.jsp?rol=admin" class="sstat <%= "admin".equals(filtroRol) ? "active-filter" : "" %>">
      <div class="sstat-icon red"><i class="bi bi-shield-fill"></i></div>
      <div><div class="sstat-num"><%= cntAdmin %></div><div class="sstat-lbl">Administradores</div></div>
    </a>
    <a href="usuarios.jsp?rol=agente" class="sstat <%= "agente".equals(filtroRol) ? "active-filter" : "" %>">
      <div class="sstat-icon amber"><i class="bi bi-building"></i></div>
      <div><div class="sstat-num"><%= cntAgente %></div><div class="sstat-lbl">Inmobiliarias</div></div>
    </a>
    <a href="usuarios.jsp?rol=cliente" class="sstat <%= "cliente".equals(filtroRol) ? "active-filter" : "" %>">
      <div class="sstat-icon blue"><i class="bi bi-person"></i></div>
      <div><div class="sstat-num"><%= cntCliente %></div><div class="sstat-lbl">Clientes</div></div>
    </a>
  </div>

  <!-- CONTENT -->
  <div class="content">

    <% if (msg != null) { %>
    <div class="alert-ok" id="alertMsg">
      <i class="bi bi-check-circle-fill"></i> <%= msg.replace("+"," ") %>
      <button class="alert-close" onclick="document.getElementById('alertMsg').remove()">×</button>
    </div>
    <% } %>

    <div class="panel">
      <div class="panel-head">
        <div class="panel-title">
          <% if (!filtroRol.isEmpty()) { %>
            Usuarios · <span style="font-style:italic;color:var(--blue-bright)"><%= filtroRol %></span>
          <% } else { %>
            Todos los usuarios
          <% } %>
        </div>
        <span class="panel-count"><%= usuarios.size() %> resultado<%= usuarios.size()!=1?"s":"" %></span>
      </div>

      <% if (usuarios.isEmpty()) { %>
        <div class="empty-state">
          <i class="bi bi-people"></i>
          No hay usuarios<%= !filtroRol.isEmpty() ? " con rol " + filtroRol : "" %>.
        </div>
      <% } else { %>
      <table class="users-table">
        <thead>
          <tr>
            <th>#</th>
            <th>Usuario</th>
            <th>Teléfono</th>
            <th>Rol</th>
            <th>Estado</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <% for (String[] u : usuarios) {
              String rol    = u[5];
              String rolId  = u[7];
              String rolCls = "admin".equalsIgnoreCase(rol)   ? "badge-purple"
                            : "agente".equalsIgnoreCase(rol)  ? "badge-amber"
                            : "cliente".equalsIgnoreCase(rol) ? "badge-blue" : "badge-gray";
              String rolIco = "admin".equalsIgnoreCase(rol)   ? "bi-shield-fill"
                            : "agente".equalsIgnoreCase(rol)  ? "bi-building" : "bi-person";
              boolean activo      = "1".equals(u[6]);
              boolean esMiCuenta  = u[0].equals(String.valueOf(usuario.getId()));
              // Escapar para JS
              String jNombre   = u[1].replace("'", "\\'").replace("\"","&quot;");
              String jApellido = u[2].replace("'", "\\'").replace("\"","&quot;");
              String jEmail    = u[3].replace("'", "\\'").replace("\"","&quot;");
              String jTelefono = u[4].replace("'", "\\'");
          %>
          <tr>
            <td><span class="td-id">#<%= u[0] %></span></td>
            <td>
              <div class="td-name"><%= u[1] %> <%= u[2] %></div>
              <div class="td-email"><%= u[3] %></div>
            </td>
            <td><span class="td-phone"><%= u[4].isEmpty() ? "—" : u[4] %></span></td>
            <td>
              <span class="badge <%= rolCls %>">
                <i class="bi <%= rolIco %>"></i> <%= rol %>
              </span>
            </td>
            <td>
              <span class="badge <%= activo ? "badge-green" : "badge-red" %>">
                <i class="bi bi-<%= activo ? "check-circle" : "x-circle" %>"></i>
                <%= activo ? "Activo" : "Inactivo" %>
              </span>
            </td>
            <td>
              <% if (!esMiCuenta) { %>
                <div class="actions-cell">
                  <!-- Editar -->
                  <button class="btn-action btn-edit"
                    onclick="abrirEditar('<%= u[0] %>','<%= jNombre %>','<%= jApellido %>','<%= jEmail %>','<%= jTelefono %>','<%= rolId %>')">
                    <i class="bi bi-pencil"></i> Editar
                  </button>
                  <!-- Activar / Desactivar -->
                  <% if (activo) { %>
                    <a href="usuarios.jsp?action=desactivar&id=<%= u[0] %>" class="btn-action btn-deactivate">
                      <i class="bi bi-person-x"></i> Desactivar
                    </a>
                  <% } else { %>
                    <a href="usuarios.jsp?action=activar&id=<%= u[0] %>" class="btn-action btn-activate">
                      <i class="bi bi-person-check"></i> Activar
                    </a>
                  <% } %>
                  <!-- Eliminar -->
                  <button class="btn-action btn-delete"
                    onclick="confirmarEliminar('<%= u[0] %>','<%= jNombre %> <%= jApellido %>')">
                    <i class="bi bi-trash"></i> Eliminar
                  </button>
                </div>
              <% } else { %>
                <span class="own-tag"><i class="bi bi-star-fill" style="font-size:10px;color:var(--border)"></i> Tu cuenta</span>
              <% } %>
            </td>
          </tr>
          <% } %>
        </tbody>
      </table>
      <% } %>
    </div>

  </div>
</div>

<!-- ══════════════════════ MODAL EDITAR ══════════════════════ -->
<div class="modal-overlay" id="modalEditar">
  <div class="modal-box">
    <div class="modal-header">
      <span class="modal-title">Editar Usuario</span>
      <button class="modal-close" onclick="cerrarEditar()"><i class="bi bi-x"></i></button>
    </div>
    <form method="POST" action="usuarios.jsp">
      <input type="hidden" name="action" value="editar"/>
      <input type="hidden" name="id"     id="edit-id"/>
      <div class="form-grid">
        <div class="form-group">
          <label class="form-label">Nombre</label>
          <input class="form-input" type="text" name="nombre" id="edit-nombre" required/>
        </div>
        <div class="form-group">
          <label class="form-label">Apellido</label>
          <input class="form-input" type="text" name="apellido" id="edit-apellido" required/>
        </div>
        <div class="form-group full">
          <label class="form-label">Correo electrónico</label>
          <input class="form-input" type="email" name="email" id="edit-email" required/>
        </div>
        <div class="form-group">
          <label class="form-label">Teléfono</label>
          <input class="form-input" type="text" name="telefono" id="edit-telefono"/>
        </div>
        <div class="form-group">
          <label class="form-label">Rol</label>
          <select class="form-input" name="rol_id" id="edit-rol">
            <% for (String[] r : roles) { %>
              <option value="<%= r[0] %>"><%= r[1] %></option>
            <% } %>
          </select>
        </div>
      </div>
      <div class="form-actions">
        <button type="button" class="btn-cancel" onclick="cerrarEditar()">Cancelar</button>
        <button type="submit" class="btn-save"><i class="bi bi-check-lg"></i> Guardar cambios</button>
      </div>
    </form>
  </div>
</div>

<!-- ══════════════════════ MODAL CONFIRMAR ELIMINAR ══════════════════════ -->
<div class="modal-overlay" id="modalEliminar">
  <div class="confirm-box">
    <div class="confirm-icon"><i class="bi bi-trash3"></i></div>
    <div class="confirm-title">¿Eliminar usuario?</div>
    <p class="confirm-msg" id="confirm-msg">Esta acción es permanente y no se puede deshacer.</p>
    <div class="confirm-actions">
      <button class="btn-cancel" onclick="cerrarEliminar()">Cancelar</button>
      <a id="confirm-del-btn" href="#" class="btn-confirm-del">
        <i class="bi bi-trash"></i> Sí, eliminar
      </a>
    </div>
  </div>
</div>

<!-- ══════════════════════ SCRIPTS ══════════════════════ -->
<script>
  /* ── Modal Editar ── */
  function abrirEditar(id, nombre, apellido, email, telefono, rolId) {
    document.getElementById('edit-id').value       = id;
    document.getElementById('edit-nombre').value   = nombre;
    document.getElementById('edit-apellido').value = apellido;
    document.getElementById('edit-email').value    = email;
    document.getElementById('edit-telefono').value = telefono;
    document.getElementById('edit-rol').value      = rolId;
    document.getElementById('modalEditar').classList.add('open');
  }
  function cerrarEditar() {
    document.getElementById('modalEditar').classList.remove('open');
  }
  document.getElementById('modalEditar').addEventListener('click', function(e){
    if (e.target === this) cerrarEditar();
  });

  /* ── Modal Confirmar Eliminar ── */
  function confirmarEliminar(id, nombreCompleto) {
    document.getElementById('confirm-msg').textContent =
      'Vas a eliminar permanentemente a "' + nombreCompleto + '". Esta acción no se puede deshacer.';
    document.getElementById('confirm-del-btn').href =
      'usuarios.jsp?action=eliminar&id=' + id;
    document.getElementById('modalEliminar').classList.add('open');
  }
  function cerrarEliminar() {
    document.getElementById('modalEliminar').classList.remove('open');
  }
  document.getElementById('modalEliminar').addEventListener('click', function(e){
    if (e.target === this) cerrarEliminar();
  });

  /* Cerrar modales con Escape */
  document.addEventListener('keydown', function(e){
    if (e.key === 'Escape') { cerrarEditar(); cerrarEliminar(); }
  });

  /* Auto-ocultar alerta de éxito */
  var alertEl = document.getElementById('alertMsg');
  if (alertEl) setTimeout(function(){ alertEl.style.opacity='0'; alertEl.style.transition='opacity .5s'; setTimeout(function(){ alertEl.remove(); }, 500); }, 4000);
</script>

</body>
</html>
