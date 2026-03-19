<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    Usuario usuario = (Usuario) session.getAttribute("usuario");
    if (usuario == null || !usuario.isCliente()) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }

    List<String[]> solicitudes = new ArrayList<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
        try {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT s.id, s.tipo_operacion, s.estado, s.observaciones, s.created_at, " +
                "p.id AS pid, p.titulo, p.tipo, p.direccion, " +
                "(SELECT url FROM propiedad_fotos WHERE propiedad_id=p.id AND es_portada=1 LIMIT 1) AS foto " +
                "FROM solicitudes_documentos s JOIN propiedades p ON s.propiedad_id=p.id " +
                "WHERE s.cliente_id=? ORDER BY s.created_at DESC");
            ps.setInt(1, usuario.getId());
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                solicitudes.add(new String[]{
                    String.valueOf(rs.getInt("id")),
                    rs.getString("tipo_operacion"),
                    rs.getString("estado"),
                    rs.getString("observaciones") != null ? rs.getString("observaciones") : "",
                    rs.getString("created_at") != null ? rs.getString("created_at").substring(0,10) : "",
                    String.valueOf(rs.getInt("pid")),
                    rs.getString("titulo"),
                    rs.getString("tipo"),
                    rs.getString("direccion") != null ? rs.getString("direccion") : "",
                    rs.getString("foto") != null ? rs.getString("foto") : ""
                });
            }
            rs.close(); ps.close();
        } finally { conn.close(); }
    } catch (Exception e) { /* continuar */ }

    String msg = request.getParameter("msg");

    // Contadores
    int cntPend=0, cntRev=0, cntAprov=0, cntRech=0;
    for (String[] s : solicitudes) {
        String e = s[2];
        if ("PENDIENTE".equals(e)) cntPend++;
        else if ("EN_REVISION".equals(e)) cntRev++;
        else if ("APROBADO".equals(e)) cntAprov++;
        else if ("RECHAZADO".equals(e)) cntRech++;
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Mis Solicitudes — Sereno</title>
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
    .topbar{background:var(--white);padding:14px 36px;display:flex;justify-content:space-between;align-items:center;border-bottom:1.5px solid var(--border);position:sticky;top:0;z-index:40;}
    .topbar-left{font-family:'Playfair Display',serif;font-size:20px;font-weight:700;color:var(--navy);}
    .topbar-right{display:flex;align-items:center;gap:14px;}
    .topbar-av{width:36px;height:36px;border-radius:50%;background:var(--blue-bright);color:var(--white);font-weight:700;font-size:13px;display:flex;align-items:center;justify-content:center;}

    /* ── CONTENT: two-column ── */
    .content{padding:28px 32px;flex:1;display:flex;flex-direction:column;gap:22px;}

    /* ── PAGE HEADER ── */
    .page-header{display:flex;justify-content:space-between;align-items:flex-end;gap:20px;flex-wrap:wrap;}
    .page-eyebrow{font-size:11px;font-weight:600;letter-spacing:3px;text-transform:uppercase;color:var(--blue-bright);margin-bottom:8px;display:flex;align-items:center;gap:8px;}
    .page-eyebrow::before{content:'';width:18px;height:1.5px;background:var(--blue-bright);}
    .page-title{font-family:'Playfair Display',serif;font-size:clamp(26px,3vw,38px);font-weight:900;color:var(--navy);line-height:1.05;}
    .page-sub{color:var(--slate-lt);font-size:13px;margin-top:5px;}

    /* ── ALERT ── */
    .alert-ok{display:flex;align-items:center;gap:10px;background:rgba(34,197,94,0.08);border:1.5px solid rgba(34,197,94,0.25);border-radius:10px;padding:12px 16px;color:#16a34a;font-size:14px;}
    .alert-close{margin-left:auto;background:none;border:none;color:#16a34a;cursor:pointer;font-size:16px;}

    /* ── STATUS ROW ── */
    .status-row{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;}
    .scard{background:var(--white);border-radius:12px;border:1.5px solid var(--border);padding:16px 18px;display:flex;align-items:center;gap:12px;transition:box-shadow .2s;}
    .scard:hover{box-shadow:0 4px 20px rgba(20,85,164,0.07);}
    .sdot{width:10px;height:10px;border-radius:50%;flex-shrink:0;}
    .sdot-pend{background:#f59e0b;}
    .sdot-rev{background:var(--sky);}
    .sdot-aprov{background:#22c55e;}
    .sdot-rech{background:#e05555;}
    .snum{font-family:'Playfair Display',serif;font-size:24px;font-weight:900;color:var(--navy);line-height:1;}
    .slbl{font-size:12px;color:var(--slate-lt);margin-top:1px;}

    /* ── TWO-COL ── */
    .two-col{display:grid;grid-template-columns:1fr 360px;gap:20px;align-items:start;}

    /* ── SOLICITUDES LIST ── */
    .sol-list{display:flex;flex-direction:column;gap:14px;}
    .sol-card{
      background:var(--white);border-radius:14px;
      border:1.5px solid var(--border);overflow:hidden;
      display:grid;grid-template-columns:140px 1fr;
      transition:all .25s;
    }
    .sol-card:hover{box-shadow:0 10px 36px rgba(20,85,164,0.09);border-color:var(--sky-lt);transform:translateY(-2px);}

    /* status accent */
    .sol-card.s-pend{border-left:4px solid #f59e0b;}
    .sol-card.s-rev{border-left:4px solid var(--sky);}
    .sol-card.s-aprov{border-left:4px solid #22c55e;}
    .sol-card.s-rech{border-left:4px solid #e05555;opacity:.7;}
    .sol-card.s-rech:hover{opacity:.9;}

    .sol-img-col{position:relative;overflow:hidden;}
    .sol-img{width:140px;height:100%;object-fit:cover;display:block;}
    .sol-placeholder{width:140px;min-height:130px;background:linear-gradient(135deg,var(--ice),#cce3f5);display:flex;align-items:center;justify-content:center;font-size:2.5rem;color:var(--sky-lt);}
    .sol-op-chip{position:absolute;bottom:10px;left:10px;background:rgba(10,22,40,0.75);backdrop-filter:blur(4px);color:var(--white);font-size:10px;font-weight:600;padding:3px 10px;border-radius:20px;letter-spacing:.8px;text-transform:uppercase;}

    .sol-body{padding:18px 20px;display:flex;flex-direction:column;justify-content:space-between;gap:10px;}
    .sol-top{display:flex;justify-content:space-between;align-items:flex-start;gap:10px;}
    .sol-prop-name{font-family:'Playfair Display',serif;font-size:16px;font-weight:700;color:var(--navy);line-height:1.25;}
    .sol-prop-type{font-size:11px;font-weight:600;letter-spacing:1.5px;text-transform:uppercase;color:var(--blue-bright);margin-top:2px;}
    .sol-loc{display:flex;align-items:center;gap:5px;font-size:12px;color:var(--slate-lt);}
    .sol-meta{display:flex;gap:10px;flex-wrap:wrap;align-items:center;}
    .meta-chip{display:inline-flex;align-items:center;gap:5px;font-size:12px;color:var(--slate);background:var(--ice);padding:4px 10px;border-radius:20px;border:1.5px solid var(--border);}
    .sol-notes{font-size:12px;color:var(--slate-lt);font-style:italic;background:var(--ice);border-radius:8px;padding:8px 12px;border-left:3px solid var(--border);line-height:1.5;}
    .sol-footer{display:flex;justify-content:flex-end;}
    .btn-ver{display:inline-flex;align-items:center;gap:5px;padding:7px 16px;background:var(--blue-bright);border:none;border-radius:20px;color:var(--white);font-family:'Outfit',sans-serif;font-size:12px;font-weight:500;cursor:pointer;text-decoration:none;transition:background .2s;}
    .btn-ver:hover{background:var(--sky);color:var(--white);}

    /* Badges */
    .badge{display:inline-flex;align-items:center;gap:4px;padding:4px 12px;border-radius:20px;font-size:11px;font-weight:600;white-space:nowrap;flex-shrink:0;}
    .badge-pend{background:rgba(245,158,11,0.12);color:#d97706;}
    .badge-rev{background:rgba(74,157,224,0.1);color:var(--sky);}
    .badge-aprov{background:rgba(34,197,94,0.1);color:#16a34a;}
    .badge-rech{background:rgba(224,85,85,0.1);color:#e05555;}

    /* ── RIGHT COL — FORM ── */
    .form-panel{background:var(--white);border-radius:14px;border:1.5px solid var(--border);overflow:hidden;position:sticky;top:80px;}
    .form-panel-head{
      padding:18px 22px;
      background:linear-gradient(130deg,var(--navy) 0%,var(--blue) 100%);
      position:relative;overflow:hidden;
    }
    .form-panel-head::before{content:'';position:absolute;top:-30px;right:-30px;width:110px;height:110px;border-radius:50%;background:rgba(255,255,255,0.06);}
    .form-panel-title{font-family:'Playfair Display',serif;font-size:17px;font-weight:700;color:var(--white);margin-bottom:3px;position:relative;z-index:1;}
    .form-panel-sub{font-size:12px;color:rgba(255,255,255,0.5);position:relative;z-index:1;}
    .form-body{padding:22px;}
    .field{margin-bottom:16px;}
    .field:last-of-type{margin-bottom:0;}
    .field label{display:block;font-size:11px;font-weight:600;letter-spacing:1px;text-transform:uppercase;color:var(--slate);margin-bottom:6px;}
    .field input,.field select,.field textarea{width:100%;padding:11px 14px;border:1.5px solid var(--border);border-radius:8px;background:var(--ice);font-family:'Outfit',sans-serif;font-size:14px;color:var(--navy);outline:none;transition:border-color .2s,background .2s;}
    .field input:focus,.field select:focus,.field textarea:focus{border-color:var(--blue-bright);background:var(--white);}
    .field input::placeholder,.field textarea::placeholder{color:rgba(0,0,0,0.25);}
    .field textarea{resize:vertical;min-height:72px;}
    .btn-submit{width:100%;padding:13px;background:var(--blue-bright);border:none;border-radius:40px;color:var(--white);font-family:'Outfit',sans-serif;font-size:14px;font-weight:600;cursor:pointer;transition:background .2s;margin-top:18px;display:flex;align-items:center;justify-content:center;gap:8px;}
    .btn-submit:hover{background:var(--sky);}

    /* ── EMPTY ── */
    .empty-wrap{background:var(--white);border-radius:14px;border:1.5px solid var(--border);padding:60px 32px;text-align:center;}
    .empty-ill{width:80px;height:80px;border-radius:50%;background:var(--ice);border:2px dashed var(--border);display:flex;align-items:center;justify-content:center;font-size:2rem;margin:0 auto 18px;color:var(--slate-lt);}
    .empty-title{font-family:'Playfair Display',serif;font-size:20px;font-weight:700;color:var(--navy);margin-bottom:8px;}
    .empty-sub{color:var(--slate-lt);font-size:13px;line-height:1.6;}

    @media(max-width:1100px){.two-col{grid-template-columns:1fr;}.form-panel{position:static;}}
    @media(max-width:900px){.status-row{grid-template-columns:repeat(2,1fr);}}
    @media(max-width:768px){.sidebar{transform:translateX(-100);}  .main{margin-left:0;}.content{padding:16px;}.topbar{padding:14px 20px;}.sol-card{grid-template-columns:1fr;}.sol-img,.sol-placeholder{width:100%;height:160px;}}
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
    <a href="mis-citas.jsp" class="nav-item"><i class="bi bi-calendar-check"></i> Mis citas</a>
    <a href="mis-solicitudes.jsp" class="nav-item active"><i class="bi bi-file-earmark-text"></i> Mis solicitudes</a>
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
    <div class="topbar-left">Mis Solicitudes</div>
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
    <div class="alert-ok" id="alertMsg">
      <i class="bi bi-check-circle-fill"></i> <%= msg.replace("+"," ") %>
      <button class="alert-close" onclick="document.getElementById('alertMsg').remove()">×</button>
    </div>
    <% } %>

    <!-- PAGE HEADER -->
    <div class="page-header">
      <div>
        <div class="page-eyebrow">Documentación</div>
        <h1 class="page-title">Mis solicitudes</h1>
        <p class="page-sub"><%= solicitudes.size() %> solicitud<%= solicitudes.size()!=1?"es":"" %> en total</p>
      </div>
    </div>

    <!-- STATUS ROW -->
    <% if (!solicitudes.isEmpty()) { %>
    <div class="status-row">
      <div class="scard"><span class="sdot sdot-pend"></span><div><div class="snum"><%= cntPend %></div><div class="slbl">Pendientes</div></div></div>
      <div class="scard"><span class="sdot sdot-rev"></span><div><div class="snum"><%= cntRev %></div><div class="slbl">En revisión</div></div></div>
      <div class="scard"><span class="sdot sdot-aprov"></span><div><div class="snum"><%= cntAprov %></div><div class="slbl">Aprobadas</div></div></div>
      <div class="scard"><span class="sdot sdot-rech"></span><div><div class="snum"><%= cntRech %></div><div class="slbl">Rechazadas</div></div></div>
    </div>
    <% } %>

    <!-- TWO-COL: list + form -->
    <div class="two-col">

      <!-- LEFT: lista -->
      <div>
        <% if (solicitudes.isEmpty()) { %>
        <div class="empty-wrap">
          <div class="empty-ill"><i class="bi bi-file-earmark-x"></i></div>
          <div class="empty-title">Aún no tienes solicitudes</div>
          <div class="empty-sub">Usa el formulario para enviar tu primera solicitud<br>de documentos sobre una propiedad.</div>
        </div>
        <% } else { %>
        <div class="sol-list">
          <% for (String[] s : solicitudes) {
              String est = s[2];
              String cardCls = "PENDIENTE".equals(est) ? "s-pend"
                             : "EN_REVISION".equals(est) ? "s-rev"
                             : "APROBADO".equals(est) ? "s-aprov" : "s-rech";
              String badgeCls = "PENDIENTE".equals(est) ? "badge-pend"
                              : "EN_REVISION".equals(est) ? "badge-rev"
                              : "APROBADO".equals(est) ? "badge-aprov" : "badge-rech";
              String badgeIco = "PENDIENTE".equals(est) ? "bi-hourglass-split"
                              : "EN_REVISION".equals(est) ? "bi-search"
                              : "APROBADO".equals(est) ? "bi-patch-check" : "bi-x-octagon";
          %>
          <div class="sol-card <%= cardCls %>">
            <div class="sol-img-col">
              <% if (!s[9].isEmpty()) { %>
                <img src="<%= s[9] %>" class="sol-img" alt="<%= s[6] %>"/>
              <% } else { %>
                <div class="sol-placeholder"><i class="bi bi-building"></i></div>
              <% } %>
              <span class="sol-op-chip"><%= s[1] %></span>
            </div>
            <div class="sol-body">
              <div>
                <div class="sol-top">
                  <div>
                    <div class="sol-prop-name"><%= s[6] %></div>
                    <div class="sol-prop-type"><%= s[7] %></div>
                  </div>
                  <span class="badge <%= badgeCls %>"><i class="bi <%= badgeIco %>"></i> <%= est.replace("_"," ") %></span>
                </div>
                <% if (!s[8].isEmpty()) { %>
                <div class="sol-loc" style="margin-top:5px"><i class="bi bi-geo-alt-fill" style="color:var(--blue-bright);font-size:11px"></i><%= s[8] %></div>
                <% } %>
              </div>
              <div class="sol-meta">
                <span class="meta-chip"><i class="bi bi-calendar3"></i> <%= s[4] %></span>
                <span class="meta-chip"><i class="bi bi-hash"></i> SOL-<%= s[0] %></span>
              </div>
              <% if (!s[3].isEmpty()) { %>
              <div class="sol-notes"><i class="bi bi-chat-quote" style="margin-right:5px;opacity:.5"></i><%= s[3].length()>100?s[3].substring(0,100)+"…":s[3] %></div>
              <% } %>
              <div class="sol-footer">
                <a href="<%= request.getContextPath() %>/propiedades?id=<%= s[5] %>" class="btn-ver">
                  <i class="bi bi-eye"></i> Ver propiedad
                </a>
              </div>
            </div>
          </div>
          <% } %>
        </div>
        <% } %>
      </div>

      <!-- RIGHT: form nueva solicitud -->
      <div class="form-panel">
        <div class="form-panel-head">
          <div class="form-panel-title">Nueva solicitud</div>
          <div class="form-panel-sub">Solicita documentación de una propiedad</div>
        </div>
        <div class="form-body">
          <form method="post" action="<%= request.getContextPath() %>/solicitudes">
            <div class="field">
              <label>ID de la propiedad</label>
              <input type="number" name="propiedadId" placeholder="Ej: 25" required/>
            </div>
            <div class="field">
              <label>Tipo de operación</label>
              <select name="tipoOperacion" required>
                <option value="">Seleccionar…</option>
                <option value="COMPRA">Compra</option>
                <option value="ARRIENDO">Arriendo</option>
              </select>
            </div>
            <div class="field">
              <label>Observaciones (opcional)</label>
              <textarea name="observaciones" placeholder="Cuéntanos más sobre lo que necesitas…"></textarea>
            </div>
            <button type="submit" class="btn-submit">
              <i class="bi bi-send"></i> Enviar solicitud
            </button>
          </form>

          <div style="margin-top:20px;padding-top:18px;border-top:1.5px solid var(--border)">
            <p style="font-size:12px;color:var(--slate-lt);line-height:1.6;">
              <i class="bi bi-info-circle" style="color:var(--blue-bright);margin-right:4px"></i>
              Una vez enviada, la inmobiliaria revisará tu solicitud y te notificará el resultado. El proceso toma entre 1 y 3 días hábiles.
            </p>
          </div>
        </div>
      </div>

    </div><!-- /two-col -->

  </div>
</div>
</body>
</html>
