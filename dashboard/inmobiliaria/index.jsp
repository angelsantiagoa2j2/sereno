<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%@ page import="com.inmovista.db.DBManager" %>
<%@ page import="java.sql.*" %>
<%
    Usuario usuario = (Usuario) session.getAttribute("usuario");
    if (usuario == null || (!usuario.isInmobiliaria() && !usuario.isAdmin())) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }
    int uid = usuario.getId();
    int totalPropiedades = 0, propDisponibles = 0, propArrendadas = 0, propVendidas = 0;
    int citasPendientes = 0, citasHoy = 0, docsPendientes = 0;
    java.util.List<String[]> propsRecientes = new java.util.ArrayList<>();
    java.util.List<String[]> citasRecientes = new java.util.ArrayList<>();

    try (Connection conn = DBManager.getConnection("cloud")) {
        try (PreparedStatement ps = conn.prepareStatement(
            "SELECT estado, COUNT(*) as cnt FROM propiedades WHERE inmobiliaria_id=? GROUP BY estado")) {
            ps.setInt(1, uid); ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                int cnt = rs.getInt("cnt"); totalPropiedades += cnt;
                String est = rs.getString("estado");
                if ("DISPONIBLE".equals(est)) propDisponibles += cnt;
                else if ("ARRENDADO".equals(est)) propArrendadas += cnt;
                else if ("VENDIDO".equals(est)) propVendidas += cnt;
            }
        }
        try (PreparedStatement ps = conn.prepareStatement(
            "SELECT COUNT(*) FROM citas c JOIN propiedades p ON c.propiedad_id=p.id WHERE p.inmobiliaria_id=? AND c.estado='PENDIENTE'")) {
            ps.setInt(1, uid); ResultSet rs = ps.executeQuery();
            if (rs.next()) citasPendientes = rs.getInt(1);
        }
        try (PreparedStatement ps = conn.prepareStatement(
            "SELECT COUNT(*) FROM citas c JOIN propiedades p ON c.propiedad_id=p.id WHERE p.inmobiliaria_id=? AND DATE(c.fecha_hora)=CURDATE()")) {
            ps.setInt(1, uid); ResultSet rs = ps.executeQuery();
            if (rs.next()) citasHoy = rs.getInt(1);
        }
        try (PreparedStatement ps = conn.prepareStatement(
            "SELECT COUNT(*) FROM solicitudes_documentos sd JOIN propiedades p ON sd.propiedad_id=p.id WHERE p.inmobiliaria_id=? AND sd.estado='PENDIENTE'")) {
            ps.setInt(1, uid); ResultSet rs = ps.executeQuery();
            if (rs.next()) docsPendientes = rs.getInt(1);
        }
        try (PreparedStatement ps = conn.prepareStatement(
            "SELECT id, titulo, tipo, operacion, precio, estado FROM propiedades WHERE inmobiliaria_id=? ORDER BY fecha_creacion DESC LIMIT 5")) {
            ps.setInt(1, uid); ResultSet rs = ps.executeQuery();
            while (rs.next()) propsRecientes.add(new String[]{
                String.valueOf(rs.getInt("id")), rs.getString("titulo"), rs.getString("tipo"),
                rs.getString("operacion"), String.format("%,.0f", rs.getDouble("precio")), rs.getString("estado")
            });
        }
        try (PreparedStatement ps = conn.prepareStatement(
            "SELECT c.id, c.fecha_hora, c.estado, p.titulo, u.nombre, u.apellido FROM citas c " +
            "JOIN propiedades p ON c.propiedad_id=p.id JOIN usuarios u ON c.cliente_id=u.id " +
            "WHERE p.inmobiliaria_id=? ORDER BY c.fecha_hora DESC LIMIT 5")) {
            ps.setInt(1, uid); ResultSet rs = ps.executeQuery();
            while (rs.next()) citasRecientes.add(new String[]{
                String.valueOf(rs.getInt("id")),
                rs.getTimestamp("fecha_hora") != null ? rs.getTimestamp("fecha_hora").toString().substring(0,16) : "Sin fecha",
                rs.getString("estado"), rs.getString("titulo"),
                rs.getString("nombre") + " " + rs.getString("apellido")
            });
        }
    } catch (Exception e) { /* continuar */ }

    int pctDisp = totalPropiedades > 0 ? (propDisponibles * 100) / totalPropiedades : 0;
    int pctArr  = totalPropiedades > 0 ? (propArrendadas * 100) / totalPropiedades : 0;
    int pctVend = totalPropiedades > 0 ? (propVendidas * 100) / totalPropiedades : 0;
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Dashboard — Sereno</title>
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
    .sidebar-brand{padding:26px 24px 22px;border-bottom:1px solid rgba(255,255,255,0.06);}
    .brand-logo{font-family:'Playfair Display',serif;font-size:22px;font-weight:700;color:var(--white);text-decoration:none;display:block;}
    .brand-logo span{color:var(--sky);}
    .brand-sub{color:rgba(255,255,255,0.25);font-size:11px;letter-spacing:1px;text-transform:uppercase;margin-top:3px;}
    .nav-section{color:rgba(255,255,255,0.2);font-size:10px;font-weight:600;letter-spacing:2px;text-transform:uppercase;padding:20px 24px 6px;}
    .nav-link{color:rgba(255,255,255,0.45);padding:10px 24px;display:flex;align-items:center;gap:10px;font-size:14px;text-decoration:none;transition:all .2s;border-left:3px solid transparent;}
    .nav-link i{font-size:15px;flex-shrink:0;}
    .nav-link:hover{color:rgba(255,255,255,0.85);background:rgba(255,255,255,0.04);}
    .nav-link.active{color:var(--white);background:rgba(30,111,217,0.15);border-left-color:var(--blue-bright);}
    .nav-badge{margin-left:auto;background:var(--blue-bright);color:var(--white);font-size:10px;font-weight:600;padding:2px 7px;border-radius:20px;}
    .nav-badge.red{background:#e05555;}
    .sidebar-footer{margin-top:auto;padding:20px 24px;border-top:1px solid rgba(255,255,255,0.06);}
    .user-mini{display:flex;align-items:center;gap:10px;}
    .user-avatar{width:34px;height:34px;border-radius:50%;background:var(--blue-bright);color:var(--white);font-weight:700;font-size:14px;display:flex;align-items:center;justify-content:center;flex-shrink:0;}
    .user-name{color:rgba(255,255,255,0.8);font-size:13px;font-weight:500;line-height:1.2;}
    .user-role{color:rgba(255,255,255,0.3);font-size:11px;}

    /* ── MAIN ── */
    .main{margin-left:248px;min-height:100vh;display:flex;flex-direction:column;}

    /* ── HEADER BANNER (reemplaza topbar) ── */
    .header-banner{
      background:var(--navy);
      padding:28px 40px 32px;
      display:grid;
      grid-template-columns:1fr auto;
      align-items:center;
      gap:24px;
      position:relative;
      overflow:hidden;
    }
    .header-banner::after{
      content:'';position:absolute;
      right:-40px;top:-60px;
      width:260px;height:260px;border-radius:50%;
      background:radial-gradient(circle,rgba(74,157,224,0.12) 0%,transparent 70%);
      pointer-events:none;
    }
    .hb-eyebrow{font-size:11px;font-weight:600;letter-spacing:3px;text-transform:uppercase;color:rgba(255,255,255,0.35);margin-bottom:6px;}
    .hb-title{font-family:'Playfair Display',serif;font-size:28px;font-weight:900;color:var(--white);line-height:1.1;}
    .hb-title em{font-style:italic;color:var(--sky-lt);}
    .hb-right{display:flex;gap:10px;align-items:center;position:relative;z-index:1;}
    .btn-primary{display:inline-flex;align-items:center;gap:7px;padding:10px 22px;background:var(--blue-bright);border:none;border-radius:40px;color:var(--white);font-family:'Outfit',sans-serif;font-size:14px;font-weight:500;cursor:pointer;text-decoration:none;transition:background .2s;}
    .btn-primary:hover{background:var(--sky);color:var(--white);}

    /* ── STATS STRIP (horizontal dentro del banner) ── */
    .stats-strip{
      background:var(--navy-mid);
      display:grid;grid-template-columns:repeat(4,1fr);
      border-top:1px solid rgba(255,255,255,0.06);
    }
    .sstat{
      padding:18px 28px;
      display:flex;align-items:center;gap:14px;
      border-right:1px solid rgba(255,255,255,0.06);
      transition:background .2s;cursor:default;
    }
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

    /* ── MAIN GRID: 3 cols ── */
    /* Row 1: wide props panel + narrow summary */
    .row-1{display:grid;grid-template-columns:1fr 260px;gap:20px;}
    /* Row 2: citas full width */

    /* ── PANELS ── */
    .panel{background:var(--white);border-radius:14px;border:1.5px solid var(--border);}

    /* Props panel — table style */
    .panel-head{display:flex;justify-content:space-between;align-items:center;padding:18px 24px;border-bottom:1.5px solid var(--border);}
    .panel-title{font-family:'Playfair Display',serif;font-size:17px;font-weight:700;color:var(--navy);}
    .btn-outline-sm{padding:6px 14px;border:1.5px solid var(--border);border-radius:20px;background:transparent;color:var(--slate);font-family:'Outfit',sans-serif;font-size:12px;font-weight:500;cursor:pointer;text-decoration:none;transition:all .2s;}
    .btn-outline-sm:hover{border-color:var(--blue-bright);color:var(--blue-bright);}

    .props-table{width:100%;border-collapse:collapse;}
    .props-table th{padding:10px 20px;font-size:10px;font-weight:600;letter-spacing:1.5px;text-transform:uppercase;color:var(--slate-lt);text-align:left;background:var(--ice);border-bottom:1.5px solid var(--border);}
    .props-table td{padding:13px 20px;font-size:13px;border-bottom:1.5px solid var(--border);vertical-align:middle;}
    .props-table tr:last-child td{border-bottom:none;}
    .props-table tbody tr{transition:background .15s;}
    .props-table tbody tr:hover{background:var(--ice);}
    .td-name{font-weight:600;color:var(--navy);font-size:14px;}
    .td-meta{color:var(--slate-lt);font-size:12px;margin-top:1px;}
    .td-price{font-family:'Playfair Display',serif;font-size:16px;font-weight:700;color:var(--blue);white-space:nowrap;}
    .td-actions{display:flex;justify-content:flex-end;}
    .btn-icon{width:30px;height:30px;border-radius:8px;border:1.5px solid var(--border);background:transparent;display:flex;align-items:center;justify-content:center;color:var(--slate-lt);font-size:13px;cursor:pointer;text-decoration:none;transition:all .2s;}
    .btn-icon:hover{border-color:var(--blue-bright);color:var(--blue-bright);}

    /* Badges */
    .badge{display:inline-flex;align-items:center;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:600;white-space:nowrap;}
    .badge-green{background:rgba(34,197,94,0.1);color:#16a34a;}
    .badge-blue{background:rgba(30,111,217,0.1);color:var(--blue-bright);}
    .badge-gray{background:rgba(0,0,0,0.06);color:var(--slate);}
    .badge-yellow{background:rgba(234,179,8,0.1);color:#ca8a04;}
    .badge-red{background:rgba(224,85,85,0.1);color:#e05555;}

    /* ── SUMMARY CARD (right of row 1) ── */
    .summary-card{display:flex;flex-direction:column;}
    .summary-top{
      background:linear-gradient(150deg,var(--navy-mid) 0%,var(--blue) 100%);
      border-radius:12px 12px 0 0;
      padding:22px 22px 18px;
      position:relative;overflow:hidden;
      border:1.5px solid rgba(255,255,255,0.05);
      border-bottom:none;
    }
    .summary-top::before{content:'';position:absolute;top:-30px;right:-30px;width:120px;height:120px;border-radius:50%;background:rgba(255,255,255,0.05);}
    .st-label{font-size:10px;font-weight:600;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,0.4);margin-bottom:8px;}
    .st-today{display:flex;justify-content:space-between;align-items:flex-end;position:relative;z-index:1;}
    .st-today-text{color:rgba(255,255,255,0.6);font-size:13px;font-weight:300;}
    .st-today-num{font-family:'Playfair Display',serif;font-size:42px;font-weight:900;color:var(--sky-lt);line-height:1;}
    .summary-body{
      background:var(--white);border-radius:0 0 12px 12px;
      border:1.5px solid var(--border);border-top:none;
      flex:1;
    }
    .bk-row{display:flex;align-items:center;gap:12px;padding:13px 18px;border-bottom:1.5px solid var(--border);}
    .bk-row:last-of-type{border-bottom:none;}
    .bk-label{font-size:13px;color:var(--slate);width:80px;flex-shrink:0;}
    .bk-track{flex:1;height:4px;background:var(--border);border-radius:2px;overflow:hidden;}
    .bk-fill{height:100%;border-radius:2px;}
    .bk-fill.disp{background:#22c55e;}
    .bk-fill.arr{background:var(--blue-bright);}
    .bk-fill.vend{background:var(--slate-lt);}
    .bk-val{font-family:'Playfair Display',serif;font-size:17px;font-weight:700;color:var(--navy);width:22px;text-align:right;flex-shrink:0;}
    .summary-cta{display:block;text-align:center;padding:13px;background:var(--blue-bright);border:none;border-radius:0 0 10px 10px;color:var(--white);font-family:'Outfit',sans-serif;font-size:13px;font-weight:500;cursor:pointer;text-decoration:none;transition:background .2s;}
    .summary-cta:hover{background:var(--sky);color:var(--white);}

    /* ── CITAS ROW ── */
    .citas-grid{display:grid;grid-template-columns:repeat(5,1fr);gap:0;}
    .cita-cell{
      padding:16px 20px;border-right:1.5px solid var(--border);
      transition:background .15s;
    }
    .cita-cell:last-child{border-right:none;}
    .cita-cell:hover{background:var(--ice);}
    .cc-client{font-size:14px;font-weight:600;color:var(--navy);margin-bottom:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
    .cc-prop{font-size:11px;color:var(--slate-lt);margin-bottom:8px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
    .cc-time{font-size:11px;color:var(--slate-lt);display:flex;align-items:center;gap:4px;margin-bottom:8px;}
    .cc-footer{display:flex;justify-content:space-between;align-items:center;gap:6px;}
    .btn-confirm{padding:4px 10px;border-radius:20px;background:rgba(34,197,94,0.1);border:1.5px solid rgba(34,197,94,0.3);color:#16a34a;font-family:'Outfit',sans-serif;font-size:11px;font-weight:600;cursor:pointer;text-decoration:none;transition:all .2s;}
    .btn-confirm:hover{background:#22c55e;color:var(--white);border-color:#22c55e;}

    .empty-state{padding:32px;text-align:center;color:var(--slate-lt);font-size:14px;}
    .empty-state a{color:var(--blue-bright);text-decoration:none;}

    @media(max-width:1200px){
      .row-1{grid-template-columns:1fr;}
      .summary-card{display:none;}
      .citas-grid{grid-template-columns:repeat(3,1fr);}
    }
    @media(max-width:900px){
      .stats-strip{grid-template-columns:repeat(2,1fr);}
      .citas-grid{grid-template-columns:repeat(2,1fr);}
    }
    @media(max-width:768px){
      .sidebar{transform:translateX(-100%);}
      .main{margin-left:0;}
      .content{padding:16px;}
      .header-banner{padding:20px 20px 24px;}
    }
  </style>
</head>
<body>

<!-- SIDEBAR -->
<aside class="sidebar">
  <div class="sidebar-brand">
    <a href="${pageContext.request.contextPath}/" class="brand-logo">Ser<span>eno</span></a>
    <div class="brand-sub">Panel Inmobiliaria</div>
  </div>
  <nav>
    <div class="nav-section">Principal</div>
    <a href="index.jsp" class="nav-link active"><i class="bi bi-grid-1x2"></i> Inicio</a>
    <a href="mis-propiedades.jsp" class="nav-link">
      <i class="bi bi-building"></i> Mis Propiedades
      <span class="nav-badge"><%= totalPropiedades %></span>
    </a>
    <div class="nav-section">Gestión</div>
    <a href="solicitudes.jsp" class="nav-link">
      <i class="bi bi-calendar-check"></i> Citas / Visitas
      <% if (citasPendientes > 0) { %><span class="nav-badge red"><%= citasPendientes %></span><% } %>
    </a>
    <a href="documentos.jsp" class="nav-link">
      <i class="bi bi-file-earmark-check"></i> Documentos
      <% if (docsPendientes > 0) { %><span class="nav-badge red"><%= docsPendientes %></span><% } %>
    </a>
    <div class="nav-section">Reportes</div>
    <a href="reportes.jsp" class="nav-link"><i class="bi bi-bar-chart-line"></i> Reportes</a>
  </nav>
  <div class="sidebar-footer">
    <div class="user-mini">
      <div class="user-avatar"><%= usuario.getNombre().substring(0,1).toUpperCase() %></div>
      <div>
        <div class="user-name"><%= usuario.getNombreCompleto() %></div>
        <div class="user-role">Inmobiliaria</div>
      </div>
    </div>
    <a href="<%= request.getContextPath() %>/logout" class="nav-link" style="padding:12px 0 0;border-left:none;">
      <i class="bi bi-box-arrow-left"></i> Cerrar sesión
    </a>
  </div>
</aside>

<!-- MAIN -->
<div class="main">

  <!-- HEADER BANNER (reemplaza topbar plano) -->
  <div class="header-banner">
    <div>
      <div class="hb-eyebrow">Panel de control</div>
      <h1 class="hb-title">Bienvenido, <em><%= usuario.getNombre() %></em></h1>
    </div>
    <div class="hb-right">
      <a href="<%= request.getContextPath() %>/propiedades?action=form" class="btn-primary">
        <i class="bi bi-plus-lg"></i> Nueva Propiedad
      </a>
    </div>
  </div>

  <!-- STATS STRIP (dentro del área oscura, debajo del banner) -->
  <div class="stats-strip">
    <div class="sstat">
      <div class="sstat-icon blue"><i class="bi bi-building"></i></div>
      <div>
        <div class="sstat-num"><%= totalPropiedades %></div>
        <div class="sstat-lbl">Total Propiedades</div>
      </div>
    </div>
    <div class="sstat">
      <div class="sstat-icon green"><i class="bi bi-check-circle"></i></div>
      <div>
        <div class="sstat-num"><%= propDisponibles %></div>
        <div class="sstat-lbl">Disponibles</div>
      </div>
    </div>
    <div class="sstat">
      <div class="sstat-icon amber"><i class="bi bi-calendar-event"></i></div>
      <div>
        <div class="sstat-num"><%= citasPendientes %></div>
        <div class="sstat-lbl">Citas Pendientes</div>
      </div>
    </div>
    <div class="sstat">
      <div class="sstat-icon red"><i class="bi bi-file-earmark-text"></i></div>
      <div>
        <div class="sstat-num"><%= docsPendientes %></div>
        <div class="sstat-lbl">Docs. Pendientes</div>
      </div>
    </div>
  </div>

  <!-- CONTENT -->
  <div class="content">

    <!-- ROW 1: tabla propiedades + resumen lateral -->
    <div class="row-1">

      <!-- Propiedades como tabla -->
      <div class="panel">
        <div class="panel-head">
          <div class="panel-title">Propiedades Recientes</div>
          <a href="mis-propiedades.jsp" class="btn-outline-sm">Ver todas</a>
        </div>
        <% if (propsRecientes.isEmpty()) { %>
          <div class="empty-state">Sin propiedades. <a href="<%= request.getContextPath() %>/propiedades?action=form">Agregar una →</a></div>
        <% } else { %>
        <table class="props-table">
          <thead>
            <tr>
              <th>Propiedad</th>
              <th>Estado</th>
              <th>Precio</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <% for (String[] p : propsRecientes) {
                String est = p[5];
                String bc = "DISPONIBLE".equals(est)?"badge-green":"ARRENDADO".equals(est)?"badge-blue":"VENDIDO".equals(est)?"badge-gray":"badge-yellow"; %>
            <tr>
              <td>
                <div class="td-name"><%= p[1] %></div>
                <div class="td-meta"><%= p[2] %> · <%= p[3] %></div>
              </td>
              <td><span class="badge <%= bc %>"><%= est %></span></td>
              <td><span class="td-price">$<%= p[4] %></span></td>
              <td class="td-actions">
                <a href="<%= request.getContextPath() %>/propiedades?action=form&id=<%= p[0] %>" class="btn-icon">
                  <i class="bi bi-pencil"></i>
                </a>
              </td>
            </tr>
            <% } %>
          </tbody>
        </table>
        <% } %>
      </div>

      <!-- Resumen / summary card -->
      <div class="summary-card">
        <div class="summary-top">
          <div class="st-label">Actividad hoy</div>
          <div class="st-today">
            <div class="st-today-text">Citas<br>programadas</div>
            <div class="st-today-num"><%= citasHoy %></div>
          </div>
        </div>
        <div class="summary-body">
          <div class="bk-row">
            <span class="bk-label">Disponibles</span>
            <div class="bk-track"><div class="bk-fill disp" style="width:<%= pctDisp %>%"></div></div>
            <span class="bk-val"><%= propDisponibles %></span>
          </div>
          <div class="bk-row">
            <span class="bk-label">Arrendadas</span>
            <div class="bk-track"><div class="bk-fill arr" style="width:<%= pctArr %>%"></div></div>
            <span class="bk-val"><%= propArrendadas %></span>
          </div>
          <div class="bk-row">
            <span class="bk-label">Vendidas</span>
            <div class="bk-track"><div class="bk-fill vend" style="width:<%= pctVend %>%"></div></div>
            <span class="bk-val"><%= propVendidas %></span>
          </div>
        </div>
        <a href="reportes.jsp" class="summary-cta">
          <i class="bi bi-bar-chart-line" style="margin-right:6px"></i> Ver Reportes
        </a>
      </div>

    </div><!-- /row-1 -->

    <!-- ROW 2: citas como grid horizontal de cards -->
    <div class="panel">
      <div class="panel-head">
        <div class="panel-title">Citas / Visitas Recientes</div>
        <a href="solicitudes.jsp" class="btn-outline-sm">Ver todas</a>
      </div>
      <% if (citasRecientes.isEmpty()) { %>
        <div class="empty-state">No hay citas registradas aún.</div>
      <% } else { %>
      <div class="citas-grid">
        <% for (String[] c : citasRecientes) {
            String est = c[2];
            String bc = "PENDIENTE".equals(est)?"badge-yellow":"CONFIRMADA".equals(est)?"badge-green":"CANCELADA".equals(est)?"badge-red":"badge-gray"; %>
        <div class="cita-cell">
          <div class="cc-client"><%= c[4] %></div>
          <div class="cc-prop"><%= c[3] %></div>
          <div class="cc-time"><i class="bi bi-clock" style="font-size:10px"></i> <%= c[1] %></div>
          <div class="cc-footer">
            <span class="badge <%= bc %>"><%= est %></span>
            <% if ("PENDIENTE".equals(est)) { %>
              <a href="solicitudes.jsp?action=confirmar&id=<%= c[0] %>" class="btn-confirm">Confirmar</a>
            <% } %>
          </div>
        </div>
        <% } %>
      </div>
      <% } %>
    </div>

  </div><!-- /content -->
</div><!-- /main -->

</body>
</html>
