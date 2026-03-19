<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    Usuario usuario = (Usuario) session.getAttribute("usuario");
    if (usuario == null || !usuario.isAdmin()) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }

    int totalPropiedades=0, totalUsuarios=0, totalCitas=0, totalSolicitudes=0;
    List<String[]> usuariosRecientes = new ArrayList<>();
    List<String[]> citasRecientes = new ArrayList<>();

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
        try {
            PreparedStatement ps; ResultSet rs;

            ps = conn.prepareStatement("SELECT COUNT(*) FROM propiedades WHERE estado != 'INACTIVO'");
            rs = ps.executeQuery(); if (rs.next()) totalPropiedades = rs.getInt(1); rs.close(); ps.close();

            ps = conn.prepareStatement("SELECT COUNT(*) FROM usuarios WHERE activo=1");
            rs = ps.executeQuery(); if (rs.next()) totalUsuarios = rs.getInt(1); rs.close(); ps.close();

            ps = conn.prepareStatement("SELECT COUNT(*) FROM citas WHERE estado='PENDIENTE'");
            rs = ps.executeQuery(); if (rs.next()) totalCitas = rs.getInt(1); rs.close(); ps.close();

            ps = conn.prepareStatement("SELECT COUNT(*) FROM solicitudes_documentos WHERE estado='PENDIENTE'");
            rs = ps.executeQuery(); if (rs.next()) totalSolicitudes = rs.getInt(1); rs.close(); ps.close();

            ps = conn.prepareStatement(
                "SELECT u.id, u.nombre, u.apellido, u.email, u.activo, r.nombre AS rol " +
                "FROM usuarios u JOIN roles r ON u.rol_id=r.id ORDER BY u.id DESC LIMIT 6");
            rs = ps.executeQuery();
            while (rs.next()) usuariosRecientes.add(new String[]{
                String.valueOf(rs.getInt("id")),
                rs.getString("nombre") + " " + rs.getString("apellido"),
                rs.getString("email"), rs.getString("rol"),
                rs.getBoolean("activo") ? "Activo" : "Inactivo"
            });
            rs.close(); ps.close();

            ps = conn.prepareStatement(
                "SELECT c.id, c.fecha_solicitada, c.estado, p.titulo, u.nombre, u.apellido " +
                "FROM citas c JOIN propiedades p ON c.propiedad_id=p.id JOIN usuarios u ON c.cliente_id=u.id " +
                "ORDER BY c.id DESC LIMIT 5");
            rs = ps.executeQuery();
            while (rs.next()) {
                String fecha = rs.getString("fecha_solicitada") != null ? rs.getString("fecha_solicitada").substring(0,10) : "";
                citasRecientes.add(new String[]{
                    String.valueOf(rs.getInt("id")),
                    rs.getString("nombre") + " " + rs.getString("apellido"),
                    rs.getString("titulo"), fecha, rs.getString("estado")
                });
            }
            rs.close(); ps.close();
        } finally { conn.close(); }
    } catch (Exception e) { /* continuar */ }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Sereno — Panel Admin</title>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&family=Outfit:wght@300;400;500;600&display=swap" rel="stylesheet"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.0/font/bootstrap-icons.min.css" rel="stylesheet"/>
  <style>
    *,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
    :root{
      --navy:#0A1628; --navy-mid:#122040;
      --blue:#1455A4; --blue-bright:#1E6FD9;
      --sky:#4A9DE0; --sky-lt:#A8D4F5;
      --ice:#EAF4FD; --white:#FFFFFF;
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
    .brand-role{
      margin:0 16px 0;
      padding:8px 12px;
      background:rgba(248,113,113,0.12);
      border:1px solid rgba(248,113,113,0.2);
      border-radius:8px;
      font-size:11px;font-weight:600;letter-spacing:1.5px;text-transform:uppercase;
      color:#fca5a5;display:flex;align-items:center;gap:6px;
      margin-top:14px;margin-bottom:4px;
    }
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
    .header-banner{
      background:var(--navy);padding:28px 40px 32px;
      display:grid;grid-template-columns:1fr auto;align-items:center;gap:24px;
      position:relative;overflow:hidden;
    }
    .header-banner::after{content:'';position:absolute;right:-40px;top:-60px;width:260px;height:260px;border-radius:50%;background:radial-gradient(circle,rgba(248,113,113,0.1) 0%,transparent 70%);pointer-events:none;}
    .hb-eyebrow{font-size:11px;font-weight:600;letter-spacing:3px;text-transform:uppercase;color:rgba(255,255,255,0.35);margin-bottom:6px;}
    .hb-title{font-family:'Playfair Display',serif;font-size:28px;font-weight:900;color:var(--white);line-height:1.1;}
    .hb-title em{font-style:italic;color:#fca5a5;}
    .hb-right{display:flex;gap:10px;align-items:center;position:relative;z-index:1;}
    .btn-primary{display:inline-flex;align-items:center;gap:7px;padding:10px 22px;background:var(--blue-bright);border:none;border-radius:40px;color:var(--white);font-family:'Outfit',sans-serif;font-size:14px;font-weight:500;cursor:pointer;text-decoration:none;transition:background .2s;}
    .btn-primary:hover{background:var(--sky);color:var(--white);}

    /* ── STATS STRIP (4 métricas en franja oscura) ── */
    .stats-strip{background:var(--navy-mid);display:grid;grid-template-columns:repeat(4,1fr);border-top:1px solid rgba(255,255,255,0.06);}
    .sstat{padding:18px 28px;display:flex;align-items:center;gap:14px;border-right:1px solid rgba(255,255,255,0.06);transition:background .2s;}
    .sstat:last-child{border-right:none;}
    .sstat:hover{background:rgba(255,255,255,0.03);}
    .sstat-icon{width:38px;height:38px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;}
    .sstat-icon.blue{background:rgba(30,111,217,0.2);color:var(--sky-lt);}
    .sstat-icon.green{background:rgba(34,197,94,0.15);color:#86efac;}
    .sstat-icon.amber{background:rgba(245,158,11,0.15);color:#fcd34d;}
    .sstat-icon.red{background:rgba(248,113,113,0.15);color:#fca5a5;}
    .sstat-num{font-family:'Playfair Display',serif;font-size:28px;font-weight:900;color:var(--white);line-height:1;}
    .sstat-lbl{font-size:11px;color:rgba(255,255,255,0.4);margin-top:2px;}

    /* ── CONTENT ── */
    .content{padding:28px 40px;flex:1;display:flex;flex-direction:column;gap:20px;}

    /* ── ROW 1: acciones rápidas (izq) + usuarios recientes (der) ── */
    .row-1{display:grid;grid-template-columns:280px 1fr;gap:20px;}

    /* ── PANELS ── */
    .panel{background:var(--white);border-radius:14px;border:1.5px solid var(--border);overflow:hidden;}
    .panel-head{display:flex;justify-content:space-between;align-items:center;padding:18px 24px;border-bottom:1.5px solid var(--border);}
    .panel-title{font-family:'Playfair Display',serif;font-size:17px;font-weight:700;color:var(--navy);}
    .btn-outline-sm{padding:6px 14px;border:1.5px solid var(--border);border-radius:20px;background:transparent;color:var(--slate);font-family:'Outfit',sans-serif;font-size:12px;font-weight:500;cursor:pointer;text-decoration:none;transition:all .2s;}
    .btn-outline-sm:hover{border-color:var(--blue-bright);color:var(--blue-bright);}

    /* Acciones rápidas — columna izquierda en row-1 */
    .quick-actions{display:flex;flex-direction:column;gap:0;}
    .qa{display:flex;align-items:center;gap:14px;padding:14px 20px;border-bottom:1.5px solid var(--border);text-decoration:none;transition:all .2s;}
    .qa:last-child{border-bottom:none;}
    .qa:hover{background:var(--ice);padding-left:26px;}
    .qa-icon{width:36px;height:36px;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0;}
    .qa.q1 .qa-icon{background:rgba(30,111,217,0.1);color:var(--blue-bright);}
    .qa.q2 .qa-icon{background:rgba(34,197,94,0.1);color:#22c55e;}
    .qa.q3 .qa-icon{background:rgba(245,158,11,0.1);color:#f59e0b;}
    .qa.q4 .qa-icon{background:rgba(139,92,246,0.1);color:#8b5cf6;}
    .qa.q5 .qa-icon{background:rgba(248,113,113,0.1);color:#e05555;}
    .qa-label{font-size:13px;font-weight:500;color:var(--navy);flex:1;}
    .qa-sub{font-size:11px;color:var(--slate-lt);}
    .qa-arrow{color:var(--slate-lt);font-size:13px;transition:transform .2s;}
    .qa:hover .qa-arrow{transform:translateX(3px);color:var(--blue-bright);}

    /* Usuarios table */
    .users-table{width:100%;border-collapse:collapse;}
    .users-table th{padding:10px 20px;font-size:10px;font-weight:600;letter-spacing:1.5px;text-transform:uppercase;color:var(--slate-lt);text-align:left;background:var(--ice);border-bottom:1.5px solid var(--border);}
    .users-table td{padding:12px 20px;font-size:13px;border-bottom:1.5px solid var(--border);vertical-align:middle;}
    .users-table tr:last-child td{border-bottom:none;}
    .users-table tbody tr{transition:background .15s;}
    .users-table tbody tr:hover{background:var(--ice);}
    .td-name{font-weight:600;color:var(--navy);font-size:14px;}
    .td-email{color:var(--slate-lt);font-size:12px;}

    /* Badges */
    .badge{display:inline-flex;align-items:center;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:600;white-space:nowrap;}
    .badge-green{background:rgba(34,197,94,0.1);color:#16a34a;}
    .badge-blue{background:rgba(30,111,217,0.1);color:var(--blue-bright);}
    .badge-red{background:rgba(224,85,85,0.1);color:#e05555;}
    .badge-amber{background:rgba(245,158,11,0.1);color:#d97706;}
    .badge-gray{background:rgba(0,0,0,0.06);color:var(--slate);}
    .badge-purple{background:rgba(139,92,246,0.1);color:#7c3aed;}

    /* ── ROW 2: citas como grid horizontal ── */
    .citas-grid{display:grid;grid-template-columns:repeat(5,1fr);gap:0;}
    .cita-cell{padding:16px 20px;border-right:1.5px solid var(--border);transition:background .15s;}
    .cita-cell:last-child{border-right:none;}
    .cita-cell:hover{background:var(--ice);}
    .cc-id{font-size:10px;color:var(--slate-lt);font-weight:600;letter-spacing:1px;margin-bottom:6px;}
    .cc-client{font-size:13px;font-weight:600;color:var(--navy);margin-bottom:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
    .cc-prop{font-size:11px;color:var(--slate-lt);margin-bottom:8px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
    .cc-date{font-size:11px;color:var(--slate-lt);display:flex;align-items:center;gap:4px;margin-bottom:8px;}

    .empty-state{padding:32px;text-align:center;color:var(--slate-lt);font-size:14px;}

    @media(max-width:1200px){
      .stats-strip{grid-template-columns:repeat(2,1fr);}
      .row-1{grid-template-columns:1fr;}
      .citas-grid{grid-template-columns:repeat(3,1fr);}
    }
    @media(max-width:768px){
      .sidebar{transform:translateX(-100%);}
      .main{margin-left:0;}
      .content{padding:20px 16px;}
      .header-banner{padding:20px;}
    }
  </style>
</head>
<body>

<!-- SIDEBAR -->
<aside class="sidebar">
  <div class="sidebar-brand">
    <a href="${pageContext.request.contextPath}/" class="brand-logo">Ser<span>eno</span></a>
    <div class="brand-sub">Panel de Control</div>
  </div>
  <div class="brand-role"><i class="bi bi-shield-fill"></i> Administrador</div>
  <nav>
    <div class="nav-section">Principal</div>
    <a href="index.jsp" class="nav-link active"><i class="bi bi-grid-1x2"></i> Dashboard</a>
    <a href="<%= request.getContextPath() %>/propiedades" class="nav-link"><i class="bi bi-building"></i> Propiedades</a>
    <div class="nav-section">Gestión</div>
    <a href="usuarios.jsp" class="nav-link"><i class="bi bi-people"></i> Usuarios</a>
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

<!-- MAIN -->
<div class="main">

  <!-- HEADER BANNER -->
  <div class="header-banner">
    <div>
      <div class="hb-eyebrow">Panel de administración</div>
      <h1 class="hb-title">Bienvenido, <em><%= usuario.getNombre() %></em></h1>
    </div>
    <div class="hb-right">
      <a href="<%= request.getContextPath() %>/propiedades?action=form" class="btn-primary">
        <i class="bi bi-plus-lg"></i> Nueva Propiedad
      </a>
    </div>
  </div>

  <!-- STATS STRIP -->
  <div class="stats-strip">
    <div class="sstat">
      <div class="sstat-icon blue"><i class="bi bi-building"></i></div>
      <div><div class="sstat-num"><%= totalPropiedades %></div><div class="sstat-lbl">Propiedades activas</div></div>
    </div>
    <div class="sstat">
      <div class="sstat-icon green"><i class="bi bi-people"></i></div>
      <div><div class="sstat-num"><%= totalUsuarios %></div><div class="sstat-lbl">Usuarios registrados</div></div>
    </div>
    <div class="sstat">
      <div class="sstat-icon amber"><i class="bi bi-calendar-event"></i></div>
      <div><div class="sstat-num"><%= totalCitas %></div><div class="sstat-lbl">Citas pendientes</div></div>
    </div>
    <div class="sstat">
      <div class="sstat-icon red"><i class="bi bi-file-earmark-text"></i></div>
      <div><div class="sstat-num"><%= totalSolicitudes %></div><div class="sstat-lbl">Solicitudes pendientes</div></div>
    </div>
  </div>

  <!-- CONTENT -->
  <div class="content">

    <!-- ROW 1: acciones rápidas (izq) + tabla usuarios (der) -->
    <div class="row-1">

      <!-- Acciones rápidas — columna izquierda -->
      <div class="panel">
        <div class="panel-head">
          <div class="panel-title">Acciones rápidas</div>
        </div>
        <div class="quick-actions">
          <a href="<%= request.getContextPath() %>/propiedades?action=form" class="qa q1">
            <div class="qa-icon"><i class="bi bi-plus-circle"></i></div>
            <div><div class="qa-label">Nueva propiedad</div><div class="qa-sub">Publicar en el catálogo</div></div>
            <i class="bi bi-chevron-right qa-arrow"></i>
          </a>
          <a href="usuarios.jsp" class="qa q2">
            <div class="qa-icon"><i class="bi bi-people"></i></div>
            <div><div class="qa-label">Gestionar usuarios</div><div class="qa-sub">Ver todos los usuarios</div></div>
            <i class="bi bi-chevron-right qa-arrow"></i>
          </a>
          <a href="citas.jsp" class="qa q3">
            <div class="qa-icon"><i class="bi bi-calendar-check"></i></div>
            <div><div class="qa-label">Ver citas</div><div class="qa-sub">Gestionar visitas</div></div>
            <i class="bi bi-chevron-right qa-arrow"></i>
          </a>
          <a href="transacciones.jsp" class="qa q4">
            <div class="qa-icon"><i class="bi bi-cash-coin"></i></div>
            <div><div class="qa-label">Transacciones</div><div class="qa-sub">Historial de negocios</div></div>
            <i class="bi bi-chevron-right qa-arrow"></i>
          </a>
          <a href="solicitudes.jsp" class="qa q5">
            <div class="qa-icon"><i class="bi bi-file-earmark-check"></i></div>
            <div><div class="qa-label">Solicitudes</div><div class="qa-sub">Documentos pendientes</div></div>
            <i class="bi bi-chevron-right qa-arrow"></i>
          </a>
        </div>
      </div>

      <!-- Usuarios recientes — columna derecha (tabla) -->
      <div class="panel">
        <div class="panel-head">
          <div class="panel-title">Usuarios recientes</div>
          <a href="usuarios.jsp" class="btn-outline-sm">Ver todos</a>
        </div>
        <% if (usuariosRecientes.isEmpty()) { %>
          <div class="empty-state">No hay usuarios aún.</div>
        <% } else { %>
        <table class="users-table">
          <thead>
            <tr>
              <th>Nombre</th>
              <th>Email</th>
              <th>Rol</th>
              <th>Estado</th>
            </tr>
          </thead>
          <tbody>
            <% for (String[] u : usuariosRecientes) {
                String rol = u[3];
                String rolCls = "admin".equalsIgnoreCase(rol) ? "badge-red"
                              : "agente".equalsIgnoreCase(rol) ? "badge-amber"
                              : "cliente".equalsIgnoreCase(rol) ? "badge-blue" : "badge-gray";
                String estCls = "Activo".equals(u[4]) ? "badge-green" : "badge-red";
            %>
            <tr>
              <td>
                <div class="td-name"><%= u[1] %></div>
              </td>
              <td><span class="td-email"><%= u[2] %></span></td>
              <td><span class="badge <%= rolCls %>"><%= rol %></span></td>
              <td><span class="badge <%= estCls %>"><%= u[4] %></span></td>
            </tr>
            <% } %>
          </tbody>
        </table>
        <% } %>
      </div>

    </div><!-- /row-1 -->

    <!-- ROW 2: citas como grid horizontal de cards -->
    <div class="panel">
      <div class="panel-head">
        <div class="panel-title">Citas recientes</div>
        <a href="citas.jsp" class="btn-outline-sm">Ver todas</a>
      </div>
      <% if (citasRecientes.isEmpty()) { %>
        <div class="empty-state">No hay citas registradas aún.</div>
      <% } else { %>
      <div class="citas-grid">
        <% for (String[] c : citasRecientes) {
            String est = c[4];
            String bc = "CONFIRMADA".equals(est) ? "badge-green"
                      : "CANCELADA".equals(est)||"RECHAZADA".equals(est) ? "badge-red"
                      : "REALIZADA".equals(est) ? "badge-blue" : "badge-amber";
            String bIco = "CONFIRMADA".equals(est) ? "bi-check-circle"
                        : "CANCELADA".equals(est)||"RECHAZADA".equals(est) ? "bi-x-circle"
                        : "REALIZADA".equals(est) ? "bi-calendar2-check" : "bi-clock";
        %>
        <div class="cita-cell">
          <div class="cc-id">CIT-<%= c[0] %></div>
          <div class="cc-client"><%= c[1] %></div>
          <div class="cc-prop"><i class="bi bi-building" style="font-size:10px;margin-right:3px"></i><%= c[2] %></div>
          <div class="cc-date"><i class="bi bi-calendar3" style="font-size:10px"></i> <%= c[3] %></div>
          <span class="badge <%= bc %>"><i class="bi <%= bIco %>"></i> <%= est %></span>
        </div>
        <% } %>
      </div>
      <% } %>
    </div>

  </div><!-- /content -->
</div><!-- /main -->

</body>
</html>
