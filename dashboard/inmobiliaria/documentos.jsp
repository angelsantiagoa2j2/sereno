<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    Usuario usuario = (Usuario) session.getAttribute("usuario");
    if (usuario == null || (!usuario.isInmobiliaria() && !usuario.isAdmin())) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }
    int uid = usuario.getId();

    String action = request.getParameter("action");
    String solId  = request.getParameter("id");
    if (action != null && solId != null) {
        String nuevoEstado = "aprobar".equals(action) ? "APROBADO" : "rechazar".equals(action) ? "RECHAZADO" : null;
        if (nuevoEstado != null) {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection conn = java.sql.DriverManager.getConnection(
                    "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
                    "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
                PreparedStatement ps = conn.prepareStatement(
                    "UPDATE solicitudes_documentos SET estado=?, revisado_por=? WHERE id=?");
                ps.setString(1, nuevoEstado); ps.setInt(2, uid); ps.setInt(3, Integer.parseInt(solId));
                ps.executeUpdate(); ps.close(); conn.close();
            } catch (Exception e) { /* ignorar */ }
        }
        response.sendRedirect("documentos.jsp?msg=Solicitud+actualizada"); return;
    }

    String filtro = request.getParameter("estado") != null ? request.getParameter("estado") : "";
    String msg    = request.getParameter("msg");

    List<String[]> solicitudes = new ArrayList<>();
    int cntPendiente = 0, cntRevision = 0, cntAprobado = 0, cntRechazado = 0;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
        try {
            // Contadores
            try (PreparedStatement ps = conn.prepareStatement(
                "SELECT sd.estado, COUNT(*) as cnt FROM solicitudes_documentos sd " +
                "JOIN propiedades p ON sd.propiedad_id=p.id WHERE p.inmobiliaria_id=? GROUP BY sd.estado")) {
                ps.setInt(1, uid); ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    String e = rs.getString("estado"); int c = rs.getInt("cnt");
                    if ("PENDIENTE".equals(e)) cntPendiente = c;
                    else if ("EN_REVISION".equals(e)) cntRevision = c;
                    else if ("APROBADO".equals(e)) cntAprobado = c;
                    else if ("RECHAZADO".equals(e)) cntRechazado = c;
                }
            }
            StringBuilder sql = new StringBuilder(
                "SELECT sd.id, sd.tipo_operacion, sd.estado, sd.observaciones, sd.created_at, " +
                "p.titulo, u.nombre, u.apellido " +
                "FROM solicitudes_documentos sd JOIN propiedades p ON sd.propiedad_id=p.id " +
                "JOIN usuarios u ON sd.cliente_id=u.id WHERE p.inmobiliaria_id=?");
            if (!filtro.isEmpty()) sql.append(" AND sd.estado=?");
            sql.append(" ORDER BY sd.created_at DESC");
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            ps.setInt(1, uid);
            if (!filtro.isEmpty()) ps.setString(2, filtro);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                solicitudes.add(new String[]{
                    String.valueOf(rs.getInt("id")),
                    rs.getString("tipo_operacion"),
                    rs.getString("estado"),
                    rs.getString("observaciones") != null ? rs.getString("observaciones") : "",
                    rs.getString("created_at") != null ? rs.getString("created_at").substring(0,10) : "",
                    rs.getString("titulo"),
                    rs.getString("nombre") + " " + rs.getString("apellido")
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
  <title>Documentos — Sereno</title>
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
    .sidebar-footer{margin-top:auto;padding:20px 24px;border-top:1px solid rgba(255,255,255,0.06);}
    .user-mini{display:flex;align-items:center;gap:10px;margin-bottom:4px;}
    .user-avatar{width:34px;height:34px;border-radius:50%;background:var(--blue-bright);color:var(--white);font-weight:700;font-size:14px;display:flex;align-items:center;justify-content:center;flex-shrink:0;}
    .user-name{color:rgba(255,255,255,0.8);font-size:13px;font-weight:500;line-height:1.2;}
    .user-role{color:rgba(255,255,255,0.3);font-size:11px;}

    /* ── MAIN ── */
    .main{margin-left:248px;padding:32px 36px;min-height:100vh;}

    /* ── TOPBAR ── */
    .topbar{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:28px;}
    .topbar-left h1{font-family:'Playfair Display',serif;font-size:26px;font-weight:900;color:var(--navy);}
    .topbar-left p{color:var(--slate-lt);font-size:14px;margin-top:2px;}

    /* ── ALERT ── */
    .alert-ok{display:flex;align-items:center;gap:10px;background:rgba(34,197,94,0.08);border:1.5px solid rgba(34,197,94,0.25);border-radius:10px;padding:12px 16px;color:#16a34a;font-size:14px;margin-bottom:22px;}
    .alert-close{margin-left:auto;background:none;border:none;color:#16a34a;cursor:pointer;font-size:16px;}

    /* ── SUMMARY CARDS ── */
    .summary-row{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:26px;}
    .sum-card{background:var(--white);border-radius:12px;border:1.5px solid var(--border);padding:18px 20px;display:flex;align-items:center;gap:14px;transition:box-shadow .2s;cursor:pointer;text-decoration:none;}
    .sum-card:hover{box-shadow:0 6px 24px rgba(20,85,164,0.09);}
    .sum-card.active-filter{border-color:var(--blue-bright);box-shadow:0 0 0 3px rgba(30,111,217,0.1);}
    .sum-icon{width:40px;height:40px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:17px;flex-shrink:0;}
    .sum-icon.all{background:rgba(10,22,40,0.07);color:var(--navy);}
    .sum-icon.pend{background:rgba(234,179,8,0.1);color:#ca8a04;}
    .sum-icon.rev{background:rgba(74,157,224,0.1);color:var(--sky);}
    .sum-icon.aprov{background:rgba(34,197,94,0.1);color:#16a34a;}
    .sum-icon.rech{background:rgba(224,85,85,0.1);color:#e05555;}
    .sum-num{font-family:'Playfair Display',serif;font-size:26px;font-weight:900;color:var(--navy);line-height:1;}
    .sum-lbl{font-size:12px;color:var(--slate-lt);margin-top:2px;}

    /* ── CARDS GRID ── */
    .docs-grid{display:grid;grid-template-columns:repeat(2,1fr);gap:16px;}
    @media(max-width:1100px){.docs-grid{grid-template-columns:1fr;}}

    .doc-card{
      background:var(--white);border-radius:14px;
      border:1.5px solid var(--border);
      padding:0;overflow:hidden;
      transition:all .25s;
    }
    .doc-card:hover{box-shadow:0 8px 32px rgba(20,85,164,0.08);border-color:var(--sky-lt);}

    /* Colored left accent per status */
    .doc-card.pend{border-left:4px solid #eab308;}
    .doc-card.rev{border-left:4px solid var(--sky);}
    .doc-card.aprov{border-left:4px solid #22c55e;}
    .doc-card.rech{border-left:4px solid #e05555;}

    .doc-card-inner{padding:20px 22px;}
    .doc-card-top{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:14px;}
    .doc-id{font-size:11px;color:var(--slate-lt);font-weight:500;letter-spacing:1px;}
    .doc-date{font-size:12px;color:var(--slate-lt);display:flex;align-items:center;gap:4px;}

    .doc-prop{font-family:'Playfair Display',serif;font-size:16px;font-weight:700;color:var(--navy);margin-bottom:4px;line-height:1.3;}
    .doc-client{display:flex;align-items:center;gap:6px;font-size:13px;color:var(--slate);margin-bottom:14px;}
    .doc-client-avatar{width:24px;height:24px;border-radius:50%;background:var(--ice);border:1.5px solid var(--border);display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:700;color:var(--blue-bright);flex-shrink:0;}

    .doc-meta{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:14px;}
    .meta-chip{display:inline-flex;align-items:center;gap:5px;padding:4px 12px;border-radius:20px;font-size:12px;font-weight:500;background:var(--ice);color:var(--slate);border:1.5px solid var(--border);}

    .doc-notes{font-size:13px;color:var(--slate-lt);line-height:1.6;padding:10px 12px;background:var(--ice);border-radius:8px;margin-bottom:16px;}

    .doc-card-footer{display:flex;justify-content:flex-end;align-items:center;gap:8px;padding:14px 22px;border-top:1.5px solid var(--border);background:rgba(244,248,253,0.5);}

    /* Badges */
    .badge{display:inline-flex;align-items:center;gap:5px;padding:4px 12px;border-radius:20px;font-size:11px;font-weight:600;white-space:nowrap;}
    .badge-pend{background:rgba(234,179,8,0.12);color:#ca8a04;}
    .badge-rev{background:rgba(74,157,224,0.1);color:var(--sky);}
    .badge-aprov{background:rgba(34,197,94,0.1);color:#16a34a;}
    .badge-rech{background:rgba(224,85,85,0.1);color:#e05555;}

    /* Buttons */
    .btn-approve{display:inline-flex;align-items:center;gap:5px;padding:7px 16px;border:none;border-radius:20px;background:rgba(34,197,94,0.1);color:#16a34a;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;cursor:pointer;text-decoration:none;transition:all .2s;}
    .btn-approve:hover{background:#22c55e;color:var(--white);}
    .btn-reject{display:inline-flex;align-items:center;gap:5px;padding:7px 16px;border:1.5px solid rgba(224,85,85,0.25);border-radius:20px;background:transparent;color:#e05555;font-family:'Outfit',sans-serif;font-size:13px;font-weight:500;cursor:pointer;text-decoration:none;transition:all .2s;}
    .btn-reject:hover{background:#e05555;color:var(--white);border-color:#e05555;}

    /* Empty state */
    .empty-state{grid-column:1/-1;text-align:center;padding:72px 24px;}
    .empty-icon{font-size:48px;color:var(--border);margin-bottom:16px;}
    .empty-title{font-family:'Playfair Display',serif;font-size:22px;font-weight:700;color:var(--navy);margin-bottom:8px;}
    .empty-sub{color:var(--slate-lt);font-size:14px;}

    @media(max-width:1200px){.summary-row{grid-template-columns:repeat(2,1fr);}}
    @media(max-width:768px){.sidebar{transform:translateX(-100);}.main{margin-left:0;padding:20px 16px;}}
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
    <a href="index.jsp" class="nav-link"><i class="bi bi-grid-1x2"></i> Inicio</a>
    <a href="mis-propiedades.jsp" class="nav-link"><i class="bi bi-building"></i> Mis Propiedades</a>
    <div class="nav-section">Gestión</div>
    <a href="solicitudes.jsp" class="nav-link"><i class="bi bi-calendar-check"></i> Citas / Visitas</a>
    <a href="documentos.jsp" class="nav-link active"><i class="bi bi-file-earmark-check"></i> Documentos</a>
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

  <div class="topbar">
    <div class="topbar-left">
      <h1>Documentos</h1>
      <p>Aprueba o rechaza solicitudes de documentación de tus clientes</p>
    </div>
  </div>

  <% if (msg != null) { %>
  <div class="alert-ok" id="alertMsg">
    <i class="bi bi-check-circle-fill"></i> <%= msg.replace("+"," ") %>
    <button class="alert-close" onclick="document.getElementById('alertMsg').remove()">×</button>
  </div>
  <% } %>

  <!-- SUMMARY CARDS / FILTROS -->
  <div class="summary-row">
    <a href="documentos.jsp" class="sum-card <%= filtro.isEmpty() ? "active-filter" : "" %>">
      <div class="sum-icon all"><i class="bi bi-folder2-open"></i></div>
      <div>
        <div class="sum-num"><%= cntPendiente + cntRevision + cntAprobado + cntRechazado %></div>
        <div class="sum-lbl">Total</div>
      </div>
    </a>
    <a href="documentos.jsp?estado=PENDIENTE" class="sum-card <%= "PENDIENTE".equals(filtro) ? "active-filter" : "" %>">
      <div class="sum-icon pend"><i class="bi bi-hourglass-split"></i></div>
      <div>
        <div class="sum-num"><%= cntPendiente %></div>
        <div class="sum-lbl">Pendientes</div>
      </div>
    </a>
    <a href="documentos.jsp?estado=APROBADO" class="sum-card <%= "APROBADO".equals(filtro) ? "active-filter" : "" %>">
      <div class="sum-icon aprov"><i class="bi bi-patch-check"></i></div>
      <div>
        <div class="sum-num"><%= cntAprobado %></div>
        <div class="sum-lbl">Aprobados</div>
      </div>
    </a>
    <a href="documentos.jsp?estado=RECHAZADO" class="sum-card <%= "RECHAZADO".equals(filtro) ? "active-filter" : "" %>">
      <div class="sum-icon rech"><i class="bi bi-x-octagon"></i></div>
      <div>
        <div class="sum-num"><%= cntRechazado %></div>
        <div class="sum-lbl">Rechazados</div>
      </div>
    </a>
  </div>

  <!-- DOCS GRID -->
  <div class="docs-grid">
    <% if (solicitudes.isEmpty()) { %>
    <div class="empty-state">
      <div class="empty-icon"><i class="bi bi-file-earmark-x"></i></div>
      <div class="empty-title">No hay solicitudes<%= !filtro.isEmpty() ? " con estado " + filtro.replace("_"," ").toLowerCase() : "" %></div>
      <div class="empty-sub">Las solicitudes de documentos de tus clientes aparecerán aquí.</div>
    </div>
    <% } else { for (String[] s : solicitudes) {
        String est = s[2];
        String cardCls = "PENDIENTE".equals(est)  ? "pend"
                       : "EN_REVISION".equals(est) ? "rev"
                       : "APROBADO".equals(est)    ? "aprov" : "rech";
        String badgeCls = "PENDIENTE".equals(est)  ? "badge-pend"
                        : "EN_REVISION".equals(est) ? "badge-rev"
                        : "APROBADO".equals(est)    ? "badge-aprov" : "badge-rech";
        String badgeIcon = "PENDIENTE".equals(est)  ? "bi-hourglass-split"
                         : "EN_REVISION".equals(est) ? "bi-search"
                         : "APROBADO".equals(est)    ? "bi-patch-check" : "bi-x-octagon";
        String initial = s[6].length() > 0 ? String.valueOf(s[6].charAt(0)).toUpperCase() : "?";
    %>
    <div class="doc-card <%= cardCls %>">
      <div class="doc-card-inner">
        <div class="doc-card-top">
          <span class="doc-id">SOL #<%= s[0] %></span>
          <span class="doc-date"><i class="bi bi-calendar3"></i> <%= s[4] %></span>
        </div>
        <div class="doc-prop"><%= s[5] %></div>
        <div class="doc-client">
          <div class="doc-client-avatar"><%= initial %></div>
          <span><%= s[6] %></span>
        </div>
        <div class="doc-meta">
          <span class="meta-chip"><i class="bi bi-arrow-left-right"></i> <%= s[1] %></span>
          <span class="badge <%= badgeCls %>"><i class="bi <%= badgeIcon %>"></i> <%= est.replace("_"," ") %></span>
        </div>
        <% if (!s[3].isEmpty()) { %>
        <div class="doc-notes"><i class="bi bi-chat-square-quote" style="margin-right:6px;opacity:.5"></i><%= s[3].length() > 120 ? s[3].substring(0,120)+"…" : s[3] %></div>
        <% } %>
      </div>
      <% if ("PENDIENTE".equals(est) || "EN_REVISION".equals(est)) { %>
      <div class="doc-card-footer">
        <a href="documentos.jsp?action=aprobar&id=<%= s[0] %>" class="btn-approve">
          <i class="bi bi-check-lg"></i> Aprobar
        </a>
        <a href="documentos.jsp?action=rechazar&id=<%= s[0] %>" class="btn-reject">
          <i class="bi bi-x-lg"></i> Rechazar
        </a>
      </div>
      <% } %>
    </div>
    <% }} %>
  </div>
</div>
</body>
</html>
