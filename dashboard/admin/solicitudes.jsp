<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    Usuario usuario = (Usuario) session.getAttribute("usuario");
    if (usuario == null || !usuario.isAdmin()) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }

    String filtro = request.getParameter("estado") != null ? request.getParameter("estado") : "";
    String msg    = request.getParameter("msg");

    List<String[]> solicitudes = new ArrayList<>();
    int cntPend=0, cntRev=0, cntAprov=0, cntRech=0;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
        try {
            try (PreparedStatement ps = conn.prepareStatement("SELECT estado, COUNT(*) as cnt FROM solicitudes_documentos GROUP BY estado")) {
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    String e = rs.getString("estado"); int c = rs.getInt("cnt");
                    if ("PENDIENTE".equals(e)) cntPend = c;
                    else if ("EN_REVISION".equals(e)) cntRev = c;
                    else if ("APROBADO".equals(e)) cntAprov = c;
                    else if ("RECHAZADO".equals(e)) cntRech = c;
                }
            }
            StringBuilder sql = new StringBuilder(
                "SELECT s.id, s.tipo_operacion, s.estado, s.observaciones, s.created_at, " +
                "p.titulo, p.id AS pid, " +
                "uc.nombre AS cnombre, uc.apellido AS capellido, " +
                "ui.nombre AS inombre, ui.apellido AS iapellido " +
                "FROM solicitudes_documentos s " +
                "JOIN propiedades p ON s.propiedad_id=p.id " +
                "JOIN usuarios uc ON s.cliente_id=uc.id " +
                "JOIN usuarios ui ON p.inmobiliaria_id=ui.id");
            if (!filtro.isEmpty()) sql.append(" WHERE s.estado=?");
            sql.append(" ORDER BY s.id DESC");
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            if (!filtro.isEmpty()) ps.setString(1, filtro);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                String fecha = rs.getString("created_at") != null ? rs.getString("created_at").substring(0,10) : "";
                solicitudes.add(new String[]{
                    String.valueOf(rs.getInt("id")), rs.getString("tipo_operacion"),
                    rs.getString("estado"),
                    rs.getString("observaciones") != null ? rs.getString("observaciones") : "",
                    fecha, rs.getString("titulo"), String.valueOf(rs.getInt("pid")),
                    rs.getString("cnombre") + " " + rs.getString("capellido"),
                    rs.getString("inombre") + " " + rs.getString("iapellido")
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
  <title>Solicitudes — Sereno Admin</title>
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

    /* ── STATS STRIP como filtros ── */
    .stats-strip{background:var(--navy-mid);display:grid;grid-template-columns:repeat(5,1fr);border-top:1px solid rgba(255,255,255,0.06);}
    .sstat{padding:16px 20px;display:flex;align-items:center;gap:12px;border-right:1px solid rgba(255,255,255,0.06);cursor:pointer;text-decoration:none;transition:background .2s;}
    .sstat:last-child{border-right:none;}
    .sstat:hover{background:rgba(255,255,255,0.03);}
    .sstat.active-filter{background:rgba(30,111,217,0.15);}
    .sstat-icon{width:34px;height:34px;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:14px;flex-shrink:0;}
    .sstat-icon.all{background:rgba(255,255,255,0.08);color:rgba(255,255,255,0.6);}
    .sstat-icon.amber{background:rgba(245,158,11,0.15);color:#fcd34d;}
    .sstat-icon.blue{background:rgba(74,157,224,0.15);color:var(--sky-lt);}
    .sstat-icon.green{background:rgba(34,197,94,0.15);color:#86efac;}
    .sstat-icon.red{background:rgba(248,113,113,0.15);color:#fca5a5;}
    .sstat-num{font-family:'Playfair Display',serif;font-size:22px;font-weight:900;color:var(--white);line-height:1;}
    .sstat-lbl{font-size:10px;color:rgba(255,255,255,0.4);margin-top:1px;}

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

    table{width:100%;border-collapse:collapse;}
    th{padding:11px 18px;font-size:10px;font-weight:600;letter-spacing:1.5px;text-transform:uppercase;color:var(--slate-lt);text-align:left;background:var(--ice);border-bottom:1.5px solid var(--border);}
    td{padding:14px 18px;font-size:13px;border-bottom:1.5px solid var(--border);vertical-align:middle;}
    tr:last-child td{border-bottom:none;}
    tbody tr{transition:background .15s;}
    tbody tr:hover{background:var(--ice);}

    .td-id{font-size:11px;color:var(--slate-lt);font-weight:600;letter-spacing:.5px;}
    .td-name{font-weight:600;color:var(--navy);font-size:14px;}
    .td-prop{color:var(--blue-bright);text-decoration:none;font-weight:500;font-size:13px;transition:color .2s;}
    .td-prop:hover{color:var(--sky);}
    .td-inmo{font-size:13px;color:var(--slate);}
    .td-date{font-size:12px;color:var(--slate);white-space:nowrap;}
    .td-notes{font-size:12px;color:var(--slate-lt);max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;}
    .td-tipo{display:inline-flex;align-items:center;gap:5px;font-size:12px;font-weight:500;color:var(--slate);background:var(--ice);padding:3px 10px;border-radius:20px;border:1.5px solid var(--border);}

    /* Badges */
    .badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:600;white-space:nowrap;}
    .badge-pending{background:rgba(245,158,11,0.1);color:#d97706;}
    .badge-review{background:rgba(74,157,224,0.1);color:var(--sky);}
    .badge-approved{background:rgba(34,197,94,0.1);color:#16a34a;}
    .badge-rejected{background:rgba(224,85,85,0.1);color:#e05555;}

    .empty-state{padding:48px;text-align:center;color:var(--slate-lt);font-size:14px;}
    .empty-state i{font-size:36px;color:var(--border);display:block;margin-bottom:10px;}

    @media(max-width:1200px){.stats-strip{grid-template-columns:repeat(3,1fr);}}
    @media(max-width:768px){.sidebar{transform:translateX(-100);}  .main{margin-left:0;}.content{padding:20px 16px;}.header-banner{padding:20px;}}
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
    <a href="index.jsp" class="nav-link"><i class="bi bi-grid-1x2"></i> Dashboard</a>
    <a href="<%= request.getContextPath() %>/propiedades" class="nav-link"><i class="bi bi-building"></i> Propiedades</a>
    <div class="nav-section">Gestión</div>
    <a href="usuarios.jsp" class="nav-link"><i class="bi bi-people"></i> Usuarios</a>
    <a href="citas.jsp" class="nav-link"><i class="bi bi-calendar-check"></i> Citas</a>
    <a href="solicitudes.jsp" class="nav-link active"><i class="bi bi-file-earmark-text"></i> Solicitudes</a>
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
      <div class="hb-eyebrow">Administración</div>
      <h1 class="hb-title">Gestión de <em>Solicitudes</em></h1>
      <p class="hb-sub"><%= cntPend + cntRev + cntAprov + cntRech %> solicitudes de documentos en total</p>
    </div>
  </div>

  <!-- STATS STRIP como filtros -->
  <div class="stats-strip">
    <a href="solicitudes.jsp" class="sstat <%= filtro.isEmpty() ? "active-filter" : "" %>">
      <div class="sstat-icon all"><i class="bi bi-folder2-open"></i></div>
      <div><div class="sstat-num"><%= cntPend+cntRev+cntAprov+cntRech %></div><div class="sstat-lbl">Todas</div></div>
    </a>
    <a href="solicitudes.jsp?estado=PENDIENTE" class="sstat <%= "PENDIENTE".equals(filtro) ? "active-filter" : "" %>">
      <div class="sstat-icon amber"><i class="bi bi-hourglass-split"></i></div>
      <div><div class="sstat-num"><%= cntPend %></div><div class="sstat-lbl">Pendientes</div></div>
    </a>
    <a href="solicitudes.jsp?estado=EN_REVISION" class="sstat <%= "EN_REVISION".equals(filtro) ? "active-filter" : "" %>">
      <div class="sstat-icon blue"><i class="bi bi-search"></i></div>
      <div><div class="sstat-num"><%= cntRev %></div><div class="sstat-lbl">En revisión</div></div>
    </a>
    <a href="solicitudes.jsp?estado=APROBADO" class="sstat <%= "APROBADO".equals(filtro) ? "active-filter" : "" %>">
      <div class="sstat-icon green"><i class="bi bi-patch-check"></i></div>
      <div><div class="sstat-num"><%= cntAprov %></div><div class="sstat-lbl">Aprobadas</div></div>
    </a>
    <a href="solicitudes.jsp?estado=RECHAZADO" class="sstat <%= "RECHAZADO".equals(filtro) ? "active-filter" : "" %>">
      <div class="sstat-icon red"><i class="bi bi-x-octagon"></i></div>
      <div><div class="sstat-num"><%= cntRech %></div><div class="sstat-lbl">Rechazadas</div></div>
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
          <% if (!filtro.isEmpty()) { %>
            Solicitudes · <span style="font-style:italic;color:var(--blue-bright)"><%= filtro.replace("_"," ").toLowerCase() %></span>
          <% } else { %>
            Todas las solicitudes
          <% } %>
        </div>
        <span class="panel-count"><%= solicitudes.size() %> resultado<%= solicitudes.size()!=1?"s":"" %></span>
      </div>

      <% if (solicitudes.isEmpty()) { %>
        <div class="empty-state">
          <i class="bi bi-file-earmark-x"></i>
          No hay solicitudes<%= !filtro.isEmpty() ? " con estado " + filtro.replace("_"," ").toLowerCase() : "" %>.
        </div>
      <% } else { %>
      <table>
        <thead>
          <tr>
            <th>#</th>
            <th>Cliente</th>
            <th>Propiedad</th>
            <th>Inmobiliaria</th>
            <th>Tipo</th>
            <th>Fecha</th>
            <th>Observaciones</th>
            <th>Estado</th>
          </tr>
        </thead>
        <tbody>
          <% for (String[] s : solicitudes) {
              String est = s[2];
              String bc  = "APROBADO".equals(est)    ? "badge-approved"
                         : "RECHAZADO".equals(est)   ? "badge-rejected"
                         : "EN_REVISION".equals(est) ? "badge-review" : "badge-pending";
              String bIco = "APROBADO".equals(est)    ? "bi-patch-check"
                          : "RECHAZADO".equals(est)   ? "bi-x-octagon"
                          : "EN_REVISION".equals(est) ? "bi-search" : "bi-hourglass-split";
          %>
          <tr>
            <td><span class="td-id">SOL-<%= s[0] %></span></td>
            <td><div class="td-name"><%= s[7] %></div></td>
            <td>
              <a href="<%= request.getContextPath() %>/propiedades?id=<%= s[6] %>" class="td-prop">
                <i class="bi bi-building" style="font-size:11px;margin-right:3px"></i><%= s[5] %>
              </a>
            </td>
            <td><span class="td-inmo"><%= s[8] %></span></td>
            <td><span class="td-tipo"><i class="bi bi-arrow-left-right"></i> <%= s[1] %></span></td>
            <td><span class="td-date"><i class="bi bi-calendar3" style="font-size:10px;margin-right:3px"></i><%= s[4] %></span></td>
            <td>
              <span class="td-notes" title="<%= s[3] %>">
                <%= s[3].isEmpty() ? "—" : s[3].length()>45 ? s[3].substring(0,45)+"…" : s[3] %>
              </span>
            </td>
            <td>
              <span class="badge <%= bc %>">
                <i class="bi <%= bIco %>"></i> <%= est.replace("_"," ") %>
              </span>
            </td>
          </tr>
          <% } %>
        </tbody>
      </table>
      <% } %>
    </div>

  </div>
</div>

</body>
</html>
