<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    Usuario usuario = (Usuario) session.getAttribute("usuario");
    if (usuario == null || !usuario.isCliente()) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }

    List<String[]> citas = new ArrayList<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
        try {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT c.id, c.fecha_solicitada, c.fecha_confirmada, c.estado, c.notas_cliente, " +
                "p.id AS pid, p.titulo, p.tipo, p.direccion, p.barrio, " +
                "(SELECT url FROM propiedad_fotos WHERE propiedad_id=p.id AND es_portada=1 LIMIT 1) AS foto " +
                "FROM citas c JOIN propiedades p ON c.propiedad_id=p.id " +
                "WHERE c.cliente_id=? ORDER BY c.fecha_solicitada DESC");
            ps.setInt(1, usuario.getId());
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                citas.add(new String[]{
                    String.valueOf(rs.getInt("id")),
                    rs.getString("fecha_solicitada") != null ? rs.getString("fecha_solicitada") : "",
                    rs.getString("fecha_confirmada") != null ? rs.getString("fecha_confirmada") : "",
                    rs.getString("estado"),
                    rs.getString("notas_cliente") != null ? rs.getString("notas_cliente") : "",
                    String.valueOf(rs.getInt("pid")),
                    rs.getString("titulo"),
                    rs.getString("tipo"),
                    rs.getString("direccion") != null ? rs.getString("direccion") : "",
                    rs.getString("barrio") != null ? rs.getString("barrio") : "",
                    rs.getString("foto") != null ? rs.getString("foto") : ""
                });
            }
            rs.close(); ps.close();
        } finally { conn.close(); }
    } catch (Exception e) { /* continuar */ }

    String msg = request.getParameter("msg");
    String[] MESES = {"","Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dic"};

    // Count by status
    int cntPend = 0, cntConf = 0, cntReal = 0, cntCanc = 0;
    for (String[] c : citas) {
        String e = c[3];
        if ("PENDIENTE".equals(e)) cntPend++;
        else if ("CONFIRMADA".equals(e)) cntConf++;
        else if ("REALIZADA".equals(e)) cntReal++;
        else cntCanc++;
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Mis Citas — Sereno</title>
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
    body{font-family:'Outfit',sans-serif;background:var(--bg);color:var(--navy);min-height:100vh;display:flex;}

    /* ── SIDEBAR ── */
    .sidebar{width:240px;min-height:100vh;background:var(--navy);position:fixed;top:0;left:0;bottom:0;z-index:50;display:flex;flex-direction:column;border-right:1px solid rgba(255,255,255,0.04);}
    .sidebar-brand{padding:26px 24px 22px;border-bottom:1px solid rgba(255,255,255,0.06);}
    .brand-logo{font-family:'Playfair Display',serif;font-size:22px;font-weight:700;color:var(--white);text-decoration:none;display:block;}
    .brand-logo span{color:var(--sky);}
    .brand-sub{color:rgba(255,255,255,0.22);font-size:11px;letter-spacing:1px;text-transform:uppercase;margin-top:3px;}
    .sidebar-nav{flex:1;padding:10px 0;}
    .nav-section{padding:18px 24px 6px;font-size:10px;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,0.2);font-weight:600;}
    .nav-item{display:flex;align-items:center;gap:11px;padding:10px 24px;color:rgba(255,255,255,0.45);text-decoration:none;font-size:14px;transition:all .2s;border-left:3px solid transparent;}
    .nav-item i{font-size:15px;flex-shrink:0;}
    .nav-item:hover{color:rgba(255,255,255,0.85);background:rgba(255,255,255,0.04);}
    .nav-item.active{color:var(--white);background:rgba(30,111,217,0.15);border-left-color:var(--blue-bright);}
    .sidebar-footer{padding:20px 24px;border-top:1px solid rgba(255,255,255,0.06);}
    .user-chip{display:flex;align-items:center;gap:10px;margin-bottom:14px;}
    .user-av{width:34px;height:34px;border-radius:50%;background:var(--blue-bright);color:var(--white);font-weight:700;font-size:13px;display:flex;align-items:center;justify-content:center;flex-shrink:0;}
    .user-nm{color:rgba(255,255,255,0.75);font-size:13px;font-weight:500;line-height:1.2;}
    .user-rl{color:rgba(255,255,255,0.3);font-size:11px;}
    .logout-btn{display:flex;align-items:center;gap:9px;color:rgba(255,255,255,0.35);text-decoration:none;font-size:13px;transition:color .2s;}
    .logout-btn:hover{color:#e05555;}

    /* ── MAIN ── */
    .main{margin-left:240px;flex:1;display:flex;flex-direction:column;min-height:100vh;}

    /* ── TOPBAR ── */
    .topbar{background:var(--white);padding:14px 36px;display:flex;justify-content:space-between;align-items:center;border-bottom:1.5px solid var(--border);position:sticky;top:0;z-index:40;}
    .topbar-left{font-family:'Playfair Display',serif;font-size:20px;font-weight:700;color:var(--navy);}
    .topbar-right{display:flex;align-items:center;gap:14px;}
    .topbar-av{width:36px;height:36px;border-radius:50%;background:var(--blue-bright);color:var(--white);font-weight:700;font-size:13px;display:flex;align-items:center;justify-content:center;}

    /* ── CONTENT ── */
    .content{padding:36px 40px;flex:1;}

    /* ── PAGE HEADER ── */
    .page-header{display:grid;grid-template-columns:1fr auto;gap:24px;align-items:start;margin-bottom:32px;}
    .page-eyebrow{font-size:11px;font-weight:600;letter-spacing:3px;text-transform:uppercase;color:var(--blue-bright);margin-bottom:8px;display:flex;align-items:center;gap:8px;}
    .page-eyebrow::before{content:'';width:18px;height:1.5px;background:var(--blue-bright);}
    .page-title{font-family:'Playfair Display',serif;font-size:clamp(28px,3vw,42px);font-weight:900;color:var(--navy);line-height:1.05;}
    .page-sub{color:var(--slate-lt);font-size:14px;margin-top:6px;}
    .btn-new-cita{display:inline-flex;align-items:center;gap:8px;padding:12px 26px;background:var(--blue-bright);border:none;border-radius:40px;color:var(--white);font-family:'Outfit',sans-serif;font-size:14px;font-weight:500;cursor:pointer;text-decoration:none;transition:background .2s;white-space:nowrap;}
    .btn-new-cita:hover{background:var(--sky);color:var(--white);}

    /* ── ALERT ── */
    .alert-ok{display:flex;align-items:center;gap:10px;background:rgba(34,197,94,0.08);border:1.5px solid rgba(34,197,94,0.25);border-radius:10px;padding:12px 16px;color:#16a34a;font-size:14px;margin-bottom:24px;}

    /* ── STATUS STRIP ── */
    .status-strip{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-bottom:32px;}
    .status-cell{background:var(--white);border-radius:12px;border:1.5px solid var(--border);padding:16px 18px;display:flex;align-items:center;gap:12px;transition:box-shadow .2s;cursor:pointer;text-decoration:none;}
    .status-cell:hover{box-shadow:0 4px 20px rgba(20,85,164,0.08);}
    .status-dot{width:10px;height:10px;border-radius:50%;flex-shrink:0;}
    .dot-pend{background:#f59e0b;}
    .dot-conf{background:#22c55e;}
    .dot-real{background:var(--sky);}
    .dot-canc{background:#e05555;}
    .status-num{font-family:'Playfair Display',serif;font-size:24px;font-weight:900;color:var(--navy);line-height:1;}
    .status-lbl{font-size:12px;color:var(--slate-lt);margin-top:1px;}

    /* ── FILTER TABS ── */
    .filter-row{display:flex;gap:8px;margin-bottom:28px;flex-wrap:wrap;}
    .ftab{padding:7px 18px;border-radius:20px;font-size:13px;font-weight:500;text-decoration:none;border:1.5px solid var(--border);background:var(--white);color:var(--slate);cursor:pointer;transition:all .2s;font-family:'Outfit',sans-serif;}
    .ftab:hover,.ftab.on{border-color:var(--blue-bright);color:var(--blue-bright);background:rgba(30,111,217,0.05);}
    .ftab.on{font-weight:600;}

    /* ── TIMELINE ── */
    .timeline{display:flex;flex-direction:column;gap:0;position:relative;}
    .timeline::before{content:'';position:absolute;left:27px;top:0;bottom:0;width:2px;background:var(--border);z-index:0;}

    .tl-item{display:flex;gap:20px;position:relative;padding-bottom:24px;}
    .tl-item:last-child{padding-bottom:0;}
    .tl-item:last-child .tl-line{display:none;}

    /* Timeline node */
    .tl-node{flex-shrink:0;width:56px;display:flex;flex-direction:column;align-items:center;position:relative;z-index:1;}
    .tl-dot{
      width:24px;height:24px;border-radius:50%;
      border:3px solid var(--white);
      box-shadow:0 0 0 2px var(--border);
      display:flex;align-items:center;justify-content:center;
      font-size:10px;font-weight:700;
      flex-shrink:0;margin-top:16px;
    }
    .tl-dot.pend{background:#f59e0b;box-shadow:0 0 0 2px rgba(245,158,11,0.3);}
    .tl-dot.conf{background:#22c55e;box-shadow:0 0 0 2px rgba(34,197,94,0.3);}
    .tl-dot.real{background:var(--sky);box-shadow:0 0 0 2px rgba(74,157,224,0.3);}
    .tl-dot.canc{background:#e05555;box-shadow:0 0 0 2px rgba(224,85,85,0.3);}

    /* Timeline card */
    .tl-card{
      flex:1;background:var(--white);
      border-radius:16px;border:1.5px solid var(--border);
      overflow:hidden;transition:all .25s;
      display:grid;grid-template-columns:160px 1fr;
      margin-bottom:0;
    }
    .tl-card:hover{box-shadow:0 12px 40px rgba(20,85,164,0.1);border-color:var(--sky-lt);transform:translateX(3px);}
    .tl-card.cancelled{opacity:0.6;}
    .tl-card.cancelled:hover{opacity:0.8;}

    /* Card image */
    .card-img-col{position:relative;overflow:hidden;}
    .card-img{width:160px;height:100%;object-fit:cover;display:block;}
    .card-img-placeholder{
      width:160px;height:100%;min-height:140px;
      background:linear-gradient(135deg,var(--ice),#cce3f5);
      display:flex;align-items:center;justify-content:center;
      font-size:3rem;color:var(--sky-lt);
    }
    .card-tipo-chip{
      position:absolute;bottom:10px;left:10px;
      background:rgba(10,22,40,0.75);backdrop-filter:blur(6px);
      color:var(--white);font-size:10px;font-weight:600;
      padding:3px 10px;border-radius:20px;letter-spacing:.8px;text-transform:uppercase;
    }

    /* Card body */
    .card-body{padding:20px 22px;display:flex;flex-direction:column;justify-content:space-between;gap:10px;}
    .card-top{display:flex;justify-content:space-between;align-items:flex-start;gap:10px;}
    .card-prop-name{font-family:'Playfair Display',serif;font-size:17px;font-weight:700;color:var(--navy);line-height:1.2;}
    .card-loc{display:flex;align-items:center;gap:5px;font-size:12px;color:var(--slate-lt);margin-top:3px;}
    .card-date-row{display:flex;align-items:center;gap:16px;flex-wrap:wrap;}
    .date-chip{display:flex;align-items:center;gap:6px;font-size:13px;color:var(--slate);}
    .date-chip i{color:var(--blue-bright);font-size:13px;}
    .date-chip strong{color:var(--navy);}
    .card-notes{font-size:12px;color:var(--slate-lt);font-style:italic;background:var(--ice);border-radius:8px;padding:8px 12px;border-left:3px solid var(--border);}
    .card-footer{display:flex;justify-content:space-between;align-items:center;gap:10px;}

    /* Badges */
    .badge{display:inline-flex;align-items:center;gap:5px;padding:5px 14px;border-radius:20px;font-size:11px;font-weight:600;white-space:nowrap;}
    .badge-pend{background:rgba(245,158,11,0.12);color:#d97706;}
    .badge-conf{background:rgba(34,197,94,0.1);color:#16a34a;}
    .badge-real{background:rgba(74,157,224,0.1);color:var(--sky);}
    .badge-canc{background:rgba(224,85,85,0.1);color:#e05555;}

    /* Action buttons */
    .btn-view{display:inline-flex;align-items:center;gap:5px;padding:7px 16px;background:var(--blue-bright);border:none;border-radius:20px;color:var(--white);font-family:'Outfit',sans-serif;font-size:12px;font-weight:500;cursor:pointer;text-decoration:none;transition:background .2s;}
    .btn-view:hover{background:var(--sky);color:var(--white);}
    .btn-cancel-cita{display:inline-flex;align-items:center;gap:5px;padding:6px 14px;background:transparent;border:1.5px solid rgba(224,85,85,0.25);border-radius:20px;color:#e05555;font-family:'Outfit',sans-serif;font-size:12px;font-weight:500;cursor:pointer;transition:all .2s;}
    .btn-cancel-cita:hover{background:#e05555;color:var(--white);border-color:#e05555;}

    /* Empty */
    .empty-wrap{text-align:center;padding:80px 40px;}
    .empty-illustration{width:120px;height:120px;border-radius:50%;background:var(--ice);border:2px dashed var(--border);display:flex;align-items:center;justify-content:center;font-size:3rem;margin:0 auto 24px;}
    .empty-title{font-family:'Playfair Display',serif;font-size:24px;font-weight:700;color:var(--navy);margin-bottom:8px;}
    .empty-sub{color:var(--slate-lt);font-size:14px;margin-bottom:28px;line-height:1.6;}
    .btn-empty{display:inline-flex;align-items:center;gap:8px;padding:12px 28px;background:var(--blue-bright);border:none;border-radius:40px;color:var(--white);font-family:'Outfit',sans-serif;font-size:14px;font-weight:500;cursor:pointer;text-decoration:none;transition:background .2s;}
    .btn-empty:hover{background:var(--sky);color:var(--white);}

    @media(max-width:900px){
      .tl-card{grid-template-columns:1fr;}
      .card-img,.card-img-placeholder{width:100%;height:160px;}
      .tl-card.cancelled{grid-template-columns:1fr;}
    }
    @media(max-width:768px){
      .sidebar{transform:translateX(-100%);}
      .main{margin-left:0;}
      .content{padding:20px 16px;}
      .topbar{padding:14px 20px;}
      .status-strip{grid-template-columns:repeat(2,1fr);}
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
  <nav class="sidebar-nav">
    <div class="nav-section">Principal</div>
    <a href="index.jsp" class="nav-item"><i class="bi bi-grid-1x2"></i> Inicio</a>
    <a href="<%= request.getContextPath() %>/propiedades" class="nav-item"><i class="bi bi-search"></i> Buscar propiedades</a>
    <div class="nav-section">Mi cuenta</div>
    <a href="mis-citas.jsp" class="nav-item active"><i class="bi bi-calendar-check"></i> Mis citas</a>
    <a href="mis-solicitudes.jsp" class="nav-item"><i class="bi bi-file-earmark-text"></i> Mis solicitudes</a>
  </nav>
  <div class="sidebar-footer">
    <div class="user-chip">
      <div class="user-av"><%= usuario.getNombre().charAt(0) %><%= usuario.getApellido().charAt(0) %></div>
      <div>
        <div class="user-nm"><%= usuario.getNombreCompleto() %></div>
        <div class="user-rl">Cliente</div>
      </div>
    </div>
    <a href="<%= request.getContextPath() %>/logout" class="logout-btn">
      <i class="bi bi-box-arrow-left"></i> Cerrar sesión
    </a>
  </div>
</aside>

<!-- MAIN -->
<div class="main">
  <div class="topbar">
    <div class="topbar-left">Mis Citas</div>
    <div class="topbar-right">
      <div style="text-align:right">
        <div style="font-size:14px;font-weight:500;color:var(--navy)"><%= usuario.getNombreCompleto() %></div>
        <div style="font-size:11px;color:var(--slate-lt)">Cliente</div>
      </div>
      <div class="topbar-av"><%= usuario.getNombre().charAt(0) %><%= usuario.getApellido().charAt(0) %></div>
    </div>
  </div>

  <div class="content">

    <% if (msg != null) { %>
    <div class="alert-ok"><i class="bi bi-check-circle-fill"></i> <%= msg.replace("+"," ") %></div>
    <% } %>

    <!-- PAGE HEADER -->
    <div class="page-header">
      <div>
        <div class="page-eyebrow">Mi agenda</div>
        <h1 class="page-title">Mis visitas<br>agendadas</h1>
        <p class="page-sub"><%= citas.size() %> cita<%= citas.size() != 1 ? "s" : "" %> en total</p>
      </div>
      <a href="<%= request.getContextPath() %>/propiedades" class="btn-new-cita">
        <i class="bi bi-plus-lg"></i> Agendar nueva visita
      </a>
    </div>

    <% if (!citas.isEmpty()) { %>

    <!-- STATUS STRIP -->
    <div class="status-strip">
      <div class="status-cell">
        <span class="status-dot dot-pend"></span>
        <div><div class="status-num"><%= cntPend %></div><div class="status-lbl">Pendientes</div></div>
      </div>
      <div class="status-cell">
        <span class="status-dot dot-conf"></span>
        <div><div class="status-num"><%= cntConf %></div><div class="status-lbl">Confirmadas</div></div>
      </div>
      <div class="status-cell">
        <span class="status-dot dot-real"></span>
        <div><div class="status-num"><%= cntReal %></div><div class="status-lbl">Realizadas</div></div>
      </div>
      <div class="status-cell">
        <span class="status-dot dot-canc"></span>
        <div><div class="status-num"><%= cntCanc %></div><div class="status-lbl">Canceladas</div></div>
      </div>
    </div>

    <!-- TIMELINE -->
    <div class="timeline">
      <% for (String[] c : citas) {
          String estado = c[3];
          boolean cancelable = "PENDIENTE".equals(estado) || "CONFIRMADA".equals(estado);
          String dotCls = "CONFIRMADA".equals(estado) ? "conf"
                        : "CANCELADA".equals(estado)||"RECHAZADA".equals(estado) ? "canc"
                        : "REALIZADA".equals(estado) ? "real" : "pend";
          String badgeCls = "CONFIRMADA".equals(estado) ? "badge-conf"
                          : "CANCELADA".equals(estado)||"RECHAZADA".equals(estado) ? "badge-canc"
                          : "REALIZADA".equals(estado) ? "badge-real" : "badge-pend";
          String badgeIco = "CONFIRMADA".equals(estado) ? "bi-check-circle"
                          : "CANCELADA".equals(estado)||"RECHAZADA".equals(estado) ? "bi-x-circle"
                          : "REALIZADA".equals(estado) ? "bi-calendar2-check" : "bi-clock";
          String fecha = c[1].length() >= 16 ? c[1].substring(0,16) : c[1];
          String dia = fecha.length() >= 10 ? fecha.substring(8,10) : "--";
          String mesNum = fecha.length() >= 7 ? fecha.substring(5,7) : "0";
          String hora = fecha.length() >= 16 ? fecha.substring(11,16) : "";
          String mesNom = "";
          try { mesNom = MESES[Integer.parseInt(mesNum)]; } catch(Exception ex){ mesNom = mesNum; }
          boolean isCancelled = "CANCELADA".equals(estado) || "RECHAZADA".equals(estado);
      %>
      <div class="tl-item">
        <div class="tl-node">
          <div class="tl-dot <%= dotCls %>"></div>
        </div>
        <div class="tl-card<%= isCancelled ? " cancelled" : "" %>">
          <!-- IMAGE -->
          <div class="card-img-col">
            <% if (!c[10].isEmpty()) { %>
              <img src="<%= c[10] %>" class="card-img" alt="<%= c[6] %>"/>
            <% } else { %>
              <div class="card-img-placeholder"><i class="bi bi-building"></i></div>
            <% } %>
            <span class="card-tipo-chip"><%= c[7] %></span>
          </div>
          <!-- BODY -->
          <div class="card-body">
            <div>
              <div class="card-top">
                <div>
                  <div class="card-prop-name"><%= c[6] %></div>
                  <% if (!c[8].isEmpty()) { %>
                  <div class="card-loc"><i class="bi bi-geo-alt-fill" style="color:var(--blue-bright);font-size:11px"></i><%= c[8] %><%= !c[9].isEmpty() ? ", "+c[9] : "" %></div>
                  <% } %>
                </div>
                <span class="badge <%= badgeCls %>"><i class="bi <%= badgeIco %>"></i> <%= estado %></span>
              </div>
            </div>

            <div class="card-date-row">
              <div class="date-chip">
                <i class="bi bi-calendar3"></i>
                <span><strong><%= dia %> <%= mesNom %></strong><%= !hora.isEmpty() ? " · " + hora : "" %></span>
              </div>
              <% if (!c[2].isEmpty()) { %>
              <div class="date-chip" style="color:#16a34a">
                <i class="bi bi-patch-check" style="color:#16a34a"></i>
                <span>Confirmada el <%= c[2].length() >= 10 ? c[2].substring(0,10) : c[2] %></span>
              </div>
              <% } %>
            </div>

            <% if (!c[4].isEmpty()) { %>
            <div class="card-notes">
              <i class="bi bi-chat-quote" style="margin-right:5px;opacity:.5"></i><%= c[4].length() > 100 ? c[4].substring(0,100)+"…" : c[4] %>
            </div>
            <% } %>

            <div class="card-footer">
              <a href="<%= request.getContextPath() %>/propiedades?id=<%= c[5] %>" class="btn-view">
                <i class="bi bi-eye"></i> Ver propiedad
              </a>
              <% if (cancelable) { %>
              <form method="post" action="<%= request.getContextPath() %>/citas" style="margin:0">
                <input type="hidden" name="action" value="cancelar"/>
                <input type="hidden" name="citaId" value="<%= c[0] %>"/>
                <button type="submit" class="btn-cancel-cita">
                  <i class="bi bi-x-lg"></i> Cancelar
                </button>
              </form>
              <% } %>
            </div>
          </div>
        </div>
      </div>
      <% } %>
    </div>

    <% } else { %>
    <!-- EMPTY STATE -->
    <div class="empty-wrap">
      <div class="empty-illustration"><i class="bi bi-calendar-x"></i></div>
      <div class="empty-title">Todavía no tienes citas</div>
      <div class="empty-sub">Explora nuestro catálogo, encuentra la propiedad de tus sueños<br>y agenda una visita sin compromiso.</div>
      <a href="<%= request.getContextPath() %>/propiedades" class="btn-empty">
        <i class="bi bi-search"></i> Explorar propiedades
      </a>
    </div>
    <% } %>

  </div>
</div>
</body>
</html>
