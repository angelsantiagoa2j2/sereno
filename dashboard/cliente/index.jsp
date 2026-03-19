<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    Usuario usuario = (Usuario) session.getAttribute("usuario");
    if (usuario == null || !usuario.isCliente()) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }
    int uid = usuario.getId();

    int numCitas = 0, numSolicitudes = 0;
    List<String[]> citasProximas = new ArrayList<>();
    List<String[]> propsRecientes = new ArrayList<>();

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
        try {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM citas WHERE cliente_id=? AND estado IN ('PENDIENTE','CONFIRMADA') AND fecha_solicitada >= NOW()");
            ps.setInt(1, uid); ResultSet rs = ps.executeQuery();
            if (rs.next()) numCitas = rs.getInt(1); rs.close(); ps.close();

            ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM solicitudes_documentos WHERE cliente_id=? AND estado='PENDIENTE'");
            ps.setInt(1, uid); rs = ps.executeQuery();
            if (rs.next()) numSolicitudes = rs.getInt(1); rs.close(); ps.close();

            ps = conn.prepareStatement(
                "SELECT c.id, c.fecha_solicitada, c.estado, p.id as pid, p.titulo FROM citas c " +
                "JOIN propiedades p ON c.propiedad_id=p.id " +
                "WHERE c.cliente_id=? AND c.fecha_solicitada >= NOW() ORDER BY c.fecha_solicitada ASC LIMIT 5");
            ps.setInt(1, uid); rs = ps.executeQuery();
            while (rs.next()) {
                String fecha = rs.getString("fecha_solicitada") != null ? rs.getString("fecha_solicitada").substring(0,16) : "Sin fecha";
                citasProximas.add(new String[]{
                    String.valueOf(rs.getInt("id")), fecha, rs.getString("estado"),
                    String.valueOf(rs.getInt("pid")), rs.getString("titulo")
                });
            } rs.close(); ps.close();

            ps = conn.prepareStatement(
                "SELECT p.id, p.titulo, p.tipo, p.operacion, p.precio, " +
                "(SELECT url FROM propiedad_fotos WHERE propiedad_id=p.id AND es_portada=1 LIMIT 1) as foto " +
                "FROM propiedades p WHERE p.estado='DISPONIBLE' ORDER BY p.fecha_creacion DESC LIMIT 5");
            rs = ps.executeQuery();
            while (rs.next()) propsRecientes.add(new String[]{
                String.valueOf(rs.getInt("id")), rs.getString("titulo"), rs.getString("tipo"),
                rs.getString("operacion"), String.format("%,.0f", rs.getDouble("precio")),
                rs.getString("foto") != null ? rs.getString("foto") : ""
            }); rs.close(); ps.close();
        } finally { conn.close(); }
    } catch (Exception e) { /* continuar */ }

    String[] MESES = {"","Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dic"};
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Sereno — Mi Panel</title>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,700;0,900;1,700&family=Outfit:wght@300;400;500;600&display=swap" rel="stylesheet"/>
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
    .nav-badge.amber{background:#f59e0b;}
    .sidebar-footer{margin-top:auto;padding:20px 24px;border-top:1px solid rgba(255,255,255,0.06);}
    .user-mini{display:flex;align-items:center;gap:10px;}
    .user-avatar{width:34px;height:34px;border-radius:50%;background:var(--blue-bright);color:var(--white);font-weight:700;font-size:14px;display:flex;align-items:center;justify-content:center;flex-shrink:0;}
    .user-name{color:rgba(255,255,255,0.8);font-size:13px;font-weight:500;line-height:1.2;}
    .user-role{color:rgba(255,255,255,0.3);font-size:11px;}

    /* ── MAIN ── */
    .main{margin-left:248px;min-height:100vh;display:flex;flex-direction:column;}

    /* ── HEADER BANNER ── */
    .header-banner{
      background:var(--navy);
      padding:28px 40px 32px;
      display:grid;grid-template-columns:1fr auto;
      align-items:center;gap:24px;
      position:relative;overflow:hidden;
    }
    .header-banner::after{
      content:'';position:absolute;right:-40px;top:-60px;
      width:260px;height:260px;border-radius:50%;
      background:radial-gradient(circle,rgba(74,157,224,0.12) 0%,transparent 70%);
      pointer-events:none;
    }
    .hb-eyebrow{font-size:11px;font-weight:600;letter-spacing:3px;text-transform:uppercase;color:rgba(255,255,255,0.35);margin-bottom:6px;}
    .hb-title{font-family:'Playfair Display',serif;font-size:28px;font-weight:900;color:var(--white);line-height:1.1;}
    .hb-title em{font-style:italic;color:var(--sky-lt);}
    .hb-sub{color:rgba(255,255,255,0.4);font-size:13px;margin-top:6px;font-weight:300;}
    .hb-sub strong{color:var(--sky-lt);font-weight:500;}
    .hb-right{display:flex;gap:10px;align-items:center;position:relative;z-index:1;}
    .btn-primary{display:inline-flex;align-items:center;gap:7px;padding:10px 22px;background:var(--blue-bright);border:none;border-radius:40px;color:var(--white);font-family:'Outfit',sans-serif;font-size:14px;font-weight:500;cursor:pointer;text-decoration:none;transition:background .2s;}
    .btn-primary:hover{background:var(--sky);color:var(--white);}
    .btn-ghost-hb{display:inline-flex;align-items:center;gap:7px;padding:9px 20px;background:transparent;border:1.5px solid rgba(255,255,255,0.2);border-radius:40px;color:rgba(255,255,255,0.65);font-family:'Outfit',sans-serif;font-size:14px;cursor:pointer;text-decoration:none;transition:all .2s;}
    .btn-ghost-hb:hover{border-color:rgba(255,255,255,0.45);color:var(--white);}

    /* ── STATS STRIP ── */
    .stats-strip{
      background:var(--navy-mid);
      display:grid;grid-template-columns:repeat(3,1fr);
      border-top:1px solid rgba(255,255,255,0.06);
    }
    .sstat{padding:18px 28px;display:flex;align-items:center;gap:14px;border-right:1px solid rgba(255,255,255,0.06);transition:background .2s;}
    .sstat:last-child{border-right:none;}
    .sstat:hover{background:rgba(255,255,255,0.03);}
    .sstat-icon{width:38px;height:38px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;}
    .sstat-icon.blue{background:rgba(30,111,217,0.2);color:var(--sky-lt);}
    .sstat-icon.amber{background:rgba(245,158,11,0.15);color:#fcd34d;}
    .sstat-icon.green{background:rgba(34,197,94,0.15);color:#86efac;}
    .sstat-num{font-family:'Playfair Display',serif;font-size:28px;font-weight:900;color:var(--white);line-height:1;}
    .sstat-lbl{font-size:11px;color:rgba(255,255,255,0.4);margin-top:2px;}

    /* ── CONTENT ── */
    .content{padding:28px 40px;flex:1;display:flex;flex-direction:column;gap:20px;}

    /* ── ROW 1: props table + summary card ── */
    .row-1{display:grid;grid-template-columns:1fr 260px;gap:20px;}

    /* ── PANELS ── */
    .panel{background:var(--white);border-radius:14px;border:1.5px solid var(--border);overflow:hidden;}
    .panel-head{display:flex;justify-content:space-between;align-items:center;padding:18px 24px;border-bottom:1.5px solid var(--border);}
    .panel-title{font-family:'Playfair Display',serif;font-size:17px;font-weight:700;color:var(--navy);}
    .btn-outline-sm{padding:6px 14px;border:1.5px solid var(--border);border-radius:20px;background:transparent;color:var(--slate);font-family:'Outfit',sans-serif;font-size:12px;font-weight:500;cursor:pointer;text-decoration:none;transition:all .2s;}
    .btn-outline-sm:hover{border-color:var(--blue-bright);color:var(--blue-bright);}

    /* Props table */
    .props-table{width:100%;border-collapse:collapse;}
    .props-table th{padding:10px 20px;font-size:10px;font-weight:600;letter-spacing:1.5px;text-transform:uppercase;color:var(--slate-lt);text-align:left;background:var(--ice);border-bottom:1.5px solid var(--border);}
    .props-table td{padding:13px 20px;font-size:13px;border-bottom:1.5px solid var(--border);vertical-align:middle;}
    .props-table tr:last-child td{border-bottom:none;}
    .props-table tbody tr{transition:background .15s;}
    .props-table tbody tr:hover{background:var(--ice);}
    .td-thumb{width:44px;height:44px;border-radius:8px;object-fit:cover;flex-shrink:0;background:linear-gradient(135deg,var(--ice),#cce3f5);display:flex;align-items:center;justify-content:center;font-size:18px;color:var(--sky-lt);overflow:hidden;}
    .td-thumb img{width:44px;height:44px;object-fit:cover;display:block;}
    .td-name{font-weight:600;color:var(--navy);font-size:14px;}
    .td-meta{color:var(--slate-lt);font-size:12px;margin-top:1px;}
    .td-price{font-family:'Playfair Display',serif;font-size:16px;font-weight:700;color:var(--blue);white-space:nowrap;}
    .td-actions{display:flex;gap:6px;justify-content:flex-end;}
    .btn-td{padding:5px 12px;border-radius:20px;font-size:11px;font-weight:500;cursor:pointer;text-decoration:none;font-family:'Outfit',sans-serif;transition:all .2s;white-space:nowrap;}
    .btn-td-primary{background:var(--blue-bright);color:var(--white);border:none;}
    .btn-td-primary:hover{background:var(--sky);color:var(--white);}
    .btn-td-ghost{background:transparent;border:1.5px solid var(--border);color:var(--slate);}
    .btn-td-ghost:hover{border-color:var(--blue-bright);color:var(--blue-bright);}

    /* ── SUMMARY CARD ── */
    .summary-card{display:flex;flex-direction:column;}
    .summary-top{
      background:linear-gradient(150deg,var(--navy-mid) 0%,var(--blue) 100%);
      border-radius:12px 12px 0 0;padding:22px 22px 18px;
      position:relative;overflow:hidden;
      border:1.5px solid rgba(255,255,255,0.05);border-bottom:none;
    }
    .summary-top::before{content:'';position:absolute;top:-30px;right:-30px;width:120px;height:120px;border-radius:50%;background:rgba(255,255,255,0.05);}
    .st-label{font-size:10px;font-weight:600;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,0.4);margin-bottom:8px;}
    .st-row{display:flex;justify-content:space-between;align-items:flex-end;position:relative;z-index:1;}
    .st-text{color:rgba(255,255,255,0.6);font-size:13px;font-weight:300;line-height:1.4;}
    .st-num{font-family:'Playfair Display',serif;font-size:42px;font-weight:900;color:var(--sky-lt);line-height:1;}
    .summary-body{background:var(--white);border-radius:0 0 12px 12px;border:1.5px solid var(--border);border-top:none;flex:1;}
    .qa{display:flex;align-items:center;gap:12px;padding:13px 18px;border-bottom:1.5px solid var(--border);text-decoration:none;transition:all .2s;}
    .qa:last-of-type{border-bottom:none;}
    .qa:hover{background:var(--ice);padding-left:22px;}
    .qa-icon{width:32px;height:32px;border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:14px;flex-shrink:0;}
    .qa.qa1 .qa-icon{background:rgba(30,111,217,0.1);color:var(--blue-bright);}
    .qa.qa2 .qa-icon{background:rgba(245,158,11,0.1);color:#f59e0b;}
    .qa.qa3 .qa-icon{background:rgba(34,197,94,0.1);color:#22c55e;}
    .qa-label{font-size:13px;font-weight:500;color:var(--navy);flex:1;}
    .qa-arrow{color:var(--slate-lt);font-size:13px;transition:transform .2s;}
    .qa:hover .qa-arrow{transform:translateX(3px);color:var(--blue-bright);}
    .summary-cta{display:block;text-align:center;padding:13px;background:var(--blue-bright);color:var(--white);font-family:'Outfit',sans-serif;font-size:13px;font-weight:500;cursor:pointer;text-decoration:none;transition:background .2s;border-radius:0 0 10px 10px;}
    .summary-cta:hover{background:var(--sky);color:var(--white);}

    /* ── CITAS GRID (row 2) ── */
    .citas-grid{display:grid;grid-template-columns:repeat(5,1fr);gap:0;}
    .cita-cell{padding:16px 20px;border-right:1.5px solid var(--border);transition:background .15s;}
    .cita-cell:last-child{border-right:none;}
    .cita-cell:hover{background:var(--ice);}
    .cc-datebox{
      width:40px;height:40px;border-radius:10px;
      background:linear-gradient(135deg,var(--blue-bright),var(--sky));
      display:flex;flex-direction:column;align-items:center;justify-content:center;
      margin-bottom:10px;
    }
    .cc-day{font-family:'Playfair Display',serif;font-size:17px;font-weight:900;color:var(--white);line-height:1;}
    .cc-mon{font-size:8px;font-weight:600;text-transform:uppercase;color:rgba(255,255,255,0.7);letter-spacing:.8px;}
    .cc-client{font-size:13px;font-weight:600;color:var(--navy);margin-bottom:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
    .cc-prop{font-size:11px;color:var(--slate-lt);margin-bottom:8px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
    .cc-footer{display:flex;align-items:center;justify-content:space-between;gap:4px;flex-wrap:wrap;}

    /* Badges */
    .badge{display:inline-flex;align-items:center;gap:3px;padding:3px 9px;border-radius:20px;font-size:10px;font-weight:600;white-space:nowrap;}
    .badge-confirmed{background:rgba(34,197,94,0.1);color:#16a34a;}
    .badge-pending{background:rgba(245,158,11,0.1);color:#d97706;}
    .badge-cancelled{background:rgba(224,85,85,0.1);color:#e05555;}

    .empty-state{padding:32px;text-align:center;color:var(--slate-lt);font-size:14px;}
    .empty-state i{font-size:32px;color:var(--border);display:block;margin-bottom:10px;}
    .empty-state a{color:var(--blue-bright);text-decoration:none;}

    @media(max-width:1200px){
      .row-1{grid-template-columns:1fr;}
      .summary-card{display:none;}
      .citas-grid{grid-template-columns:repeat(3,1fr);}
    }
    @media(max-width:900px){
      .stats-strip{grid-template-columns:repeat(3,1fr);}
      .citas-grid{grid-template-columns:repeat(2,1fr);}
    }
    @media(max-width:768px){
      .sidebar{transform:translateX(-100%);}
      .main{margin-left:0;}
      .content{padding:16px;}
      .header-banner{padding:20px 20px 24px;}
      .hb-right{display:none;}
      .stats-strip{grid-template-columns:1fr 1fr;}
    }
  </style>
</head>
<body>

<!-- SIDEBAR -->
<aside class="sidebar">
  <div class="sidebar-brand">
    <a href="<%= request.getContextPath() %>/" class="brand-logo">Ser<span>eno</span></a>
    <div class="brand-sub">Portal Cliente</div>
  </div>
  <nav>
    <div class="nav-section">Principal</div>
    <a href="index.jsp" class="nav-link active"><i class="bi bi-grid-1x2"></i> Inicio</a>
    <a href="<%= request.getContextPath() %>/propiedades" class="nav-link"><i class="bi bi-search"></i> Buscar propiedades</a>
    <div class="nav-section">Mi cuenta</div>
    <a href="mis-citas.jsp" class="nav-link">
      <i class="bi bi-calendar-check"></i> Mis citas
      <% if (numCitas > 0) { %><span class="nav-badge"><%= numCitas %></span><% } %>
    </a>
    <a href="mis-solicitudes.jsp" class="nav-link">
      <i class="bi bi-file-earmark-text"></i> Mis solicitudes
      <% if (numSolicitudes > 0) { %><span class="nav-badge amber"><%= numSolicitudes %></span><% } %>
    </a>
  </nav>
  <div class="sidebar-footer">
    <div class="user-mini">
      <div class="user-avatar"><%= usuario.getNombre().charAt(0) %><%= usuario.getApellido().charAt(0) %></div>
      <div>
        <div class="user-name"><%= usuario.getNombreCompleto() %></div>
        <div class="user-role">Cliente</div>
      </div>
    </div>
    <a href="<%= request.getContextPath() %>/logout" class="nav-link" style="padding:12px 0 0;border-left:none;">
      <i class="bi bi-box-arrow-left"></i> Cerrar sesión
    </a>
  </div>
</aside>

<!-- MAIN -->
<div class="main">

  <!-- HEADER BANNER -->
  <div class="header-banner">
    <div>
      <div class="hb-eyebrow">Portal cliente</div>
      <h1 class="hb-title">Bienvenido, <em><%= usuario.getNombre() %></em></h1>
      <p class="hb-sub">
        Tienes <strong><%= numCitas %> cita<%= numCitas!=1?"s":"" %></strong> próxima<%= numCitas!=1?"s":"" %>
        y <strong><%= numSolicitudes %> solicitud<%= numSolicitudes!=1?"es":"" %></strong> pendiente<%= numSolicitudes!=1?"s":"" %>.
      </p>
    </div>
    <div class="hb-right">
      <a href="<%= request.getContextPath() %>/propiedades" class="btn-primary">
        <i class="bi bi-search"></i> Buscar propiedades
      </a>
      <a href="mis-citas.jsp" class="btn-ghost-hb">
        <i class="bi bi-calendar-check"></i> Mis citas
      </a>
    </div>
  </div>

  <!-- STATS STRIP -->
  <div class="stats-strip">
    <div class="sstat">
      <div class="sstat-icon blue"><i class="bi bi-calendar-event"></i></div>
      <div>
        <div class="sstat-num"><%= numCitas %></div>
        <div class="sstat-lbl">Citas próximas</div>
      </div>
    </div>
    <div class="sstat">
      <div class="sstat-icon amber"><i class="bi bi-file-earmark-text"></i></div>
      <div>
        <div class="sstat-num"><%= numSolicitudes %></div>
        <div class="sstat-lbl">Solicitudes pendientes</div>
      </div>
    </div>
    <div class="sstat">
      <div class="sstat-icon green"><i class="bi bi-house-door"></i></div>
      <div>
        <div class="sstat-num"><%= propsRecientes.size() %>+</div>
        <div class="sstat-lbl">Propiedades disponibles</div>
      </div>
    </div>
  </div>

  <!-- CONTENT -->
  <div class="content">

    <!-- ROW 1: tabla de propiedades + accesos rápidos -->
    <div class="row-1">

      <!-- Propiedades como tabla -->
      <div class="panel">
        <div class="panel-head">
          <div class="panel-title">Propiedades disponibles</div>
          <a href="<%= request.getContextPath() %>/propiedades" class="btn-outline-sm">Ver todas</a>
        </div>
        <% if (propsRecientes.isEmpty()) { %>
          <div class="empty-state"><i class="bi bi-building"></i>No hay propiedades disponibles.</div>
        <% } else { %>
        <table class="props-table">
          <thead>
            <tr>
              <th></th>
              <th>Propiedad</th>
              <th>Precio</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <% for (String[] p : propsRecientes) {
                boolean esA = "ARRIENDO".equals(p[3]); %>
            <tr>
              <td style="width:56px;padding-right:0">
                <div class="td-thumb">
                  <% if (!p[5].isEmpty()) { %><img src="<%= p[5] %>" alt="<%= p[1] %>"/><% } else { %><i class="bi bi-house"></i><% } %>
                </div>
              </td>
              <td>
                <div class="td-name"><%= p[1] %></div>
                <div class="td-meta"><%= p[2] %> · <%= p[3] %></div>
              </td>
              <td>
                <span class="td-price">$<%= p[4] %><% if(esA){%><span style="font-size:12px;font-weight:400;color:var(--slate-lt);font-family:'Outfit',sans-serif"> /mes</span><%}%></span>
              </td>
              <td>
                <div class="td-actions">
                  <a href="<%= request.getContextPath() %>/propiedades?id=<%= p[0] %>" class="btn-td btn-td-primary">Ver</a>
                  <a href="<%= request.getContextPath() %>/propiedades?id=<%= p[0] %>#cita" class="btn-td btn-td-ghost">Agendar</a>
                </div>
              </td>
            </tr>
            <% } %>
          </tbody>
        </table>
        <% } %>
      </div>

      <!-- Summary / accesos card -->
      <div class="summary-card">
        <div class="summary-top">
          <div class="st-label">Mi actividad</div>
          <div class="st-row">
            <div class="st-text">Citas<br>próximas</div>
            <div class="st-num"><%= numCitas %></div>
          </div>
        </div>
        <div class="summary-body">
          <a href="<%= request.getContextPath() %>/propiedades" class="qa qa1">
            <div class="qa-icon"><i class="bi bi-search"></i></div>
            <span class="qa-label">Buscar propiedades</span>
            <i class="bi bi-chevron-right qa-arrow"></i>
          </a>
          <a href="mis-citas.jsp" class="qa qa2">
            <div class="qa-icon"><i class="bi bi-calendar-check"></i></div>
            <span class="qa-label">Mis citas</span>
            <i class="bi bi-chevron-right qa-arrow"></i>
          </a>
          <a href="mis-solicitudes.jsp" class="qa qa3">
            <div class="qa-icon"><i class="bi bi-file-earmark-check"></i></div>
            <span class="qa-label">Mis solicitudes</span>
            <i class="bi bi-chevron-right qa-arrow"></i>
          </a>
        </div>
        <a href="<%= request.getContextPath() %>/propiedades" class="summary-cta">
          <i class="bi bi-search" style="margin-right:6px"></i> Explorar catálogo
        </a>
      </div>

    </div><!-- /row-1 -->

    <!-- ROW 2: citas próximas como grid horizontal -->
    <div class="panel">
      <div class="panel-head">
        <div class="panel-title">Mis citas próximas</div>
        <a href="mis-citas.jsp" class="btn-outline-sm">Ver todas</a>
      </div>
      <% if (citasProximas.isEmpty()) { %>
        <div class="empty-state">
          <i class="bi bi-calendar-x"></i>
          No tienes citas próximas. <a href="<%= request.getContextPath() %>/propiedades">Buscar propiedades →</a>
        </div>
      <% } else { %>
      <div class="citas-grid">
        <% for (String[] c : citasProximas) {
            String est = c[2];
            String bCls = "CONFIRMADA".equals(est)?"badge-confirmed":"CANCELADA".equals(est)?"badge-cancelled":"badge-pending";
            String bIco = "CONFIRMADA".equals(est)?"bi-check-circle":"CANCELADA".equals(est)?"bi-x-circle":"bi-clock";
            String fecha = c[1];
            String dia = fecha.length()>=10?fecha.substring(8,10):"--";
            String mesNum = fecha.length()>=7?fecha.substring(5,7):"0";
            String hora = fecha.length()>=16?fecha.substring(11,16):"";
            String mesNom="";
            try{mesNom=MESES[Integer.parseInt(mesNum)];}catch(Exception ex){mesNom=mesNum;}
        %>
        <div class="cita-cell">
          <div class="cc-datebox">
            <div class="cc-day"><%= dia %></div>
            <div class="cc-mon"><%= mesNom %></div>
          </div>
          <div class="cc-client"><%= c[4] %></div>
          <div class="cc-prop"><i class="bi bi-clock" style="font-size:10px;margin-right:3px"></i><%= hora.isEmpty()?"Hora por confirmar":hora %></div>
          <div class="cc-footer">
            <span class="badge <%= bCls %>"><i class="bi <%= bIco %>"></i> <%= est %></span>
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
