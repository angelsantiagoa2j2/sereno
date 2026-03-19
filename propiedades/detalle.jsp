<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%@ page import="com.inmovista.db.DBManager" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    String idParam = request.getParameter("id");
    if (idParam == null || idParam.isEmpty()) {
        response.sendRedirect(request.getContextPath() + "/propiedades");
        return;
    }

    String titulo="", tipo="", operacion="", precio="", descripcion="",
           direccion="", barrio="", estado="DISPONIBLE", ciudadNombre="",
           area="", estrato="", destacado="false";
    int habitaciones=0, banos=0, parqueaderos=0, propId=0;
    List<String[]> fotos = new ArrayList<>();
    boolean encontrado = false;
    String errorMsg = null;

    String msgCita = request.getParameter("msg");
    String errCita = request.getParameter("err");

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
        try {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT p.*, c.nombre AS ciudad FROM propiedades p LEFT JOIN ciudades c ON p.ciudad_id=c.id WHERE p.id=?");
            ps.setInt(1, Integer.parseInt(idParam));
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                encontrado   = true;
                propId       = rs.getInt("id");
                titulo       = rs.getString("titulo")      != null ? rs.getString("titulo")      : "";
                tipo         = rs.getString("tipo")        != null ? rs.getString("tipo")        : "";
                operacion    = rs.getString("operacion")   != null ? rs.getString("operacion")   : "";
                precio       = String.format("%,.0f", rs.getDouble("precio"));
                descripcion  = rs.getString("descripcion") != null ? rs.getString("descripcion") : "";
                direccion    = rs.getString("direccion")   != null ? rs.getString("direccion")   : "";
                barrio       = rs.getString("barrio")      != null ? rs.getString("barrio")      : "";
                estado       = rs.getString("estado")      != null ? rs.getString("estado")      : "DISPONIBLE";
                ciudadNombre = rs.getString("ciudad")      != null ? rs.getString("ciudad")      : "";
                habitaciones = rs.getInt("habitaciones");
                banos        = rs.getInt("banos");
                parqueaderos = rs.getInt("parqueaderos");
                area         = rs.getObject("area_m2")  != null ? rs.getString("area_m2")  : "";
                estrato      = rs.getObject("estrato")  != null ? String.valueOf(rs.getInt("estrato")) : "";
                destacado    = String.valueOf(rs.getBoolean("destacado"));
            }
            rs.close(); ps.close();
            if (encontrado) {
                PreparedStatement ps2 = conn.prepareStatement(
                    "SELECT url, descripcion FROM propiedad_fotos WHERE propiedad_id=? ORDER BY es_portada DESC");
                ps2.setInt(1, propId);
                ResultSet rs2 = ps2.executeQuery();
                while (rs2.next()) fotos.add(new String[]{
                    rs2.getString("url") != null ? rs2.getString("url") : "",
                    rs2.getString("descripcion") != null ? rs2.getString("descripcion") : ""
                });
                rs2.close(); ps2.close();
            }
        } finally { conn.close(); }
    } catch (Exception e) { errorMsg = e.getMessage(); }

    if (!encontrado) {
        response.sendRedirect(request.getContextPath() + "/propiedades");
        return;
    }

    Usuario usuario  = (Usuario) session.getAttribute("usuario");
    boolean logueado  = usuario != null;
    boolean esCliente = logueado && usuario.isCliente();
    String fotoPortada = fotos.isEmpty() ? "" : fotos.get(0)[0];
    String sufijoPrecio = "ARRIENDO".equals(operacion) ? "/mes" : "";
    boolean disponible = "DISPONIBLE".equals(estado);
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title><%= titulo %> — Sereno</title>
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

    /* ── NAVBAR ── */
    .navbar{
      background:var(--navy);
      padding:14px 48px;
      display:flex;justify-content:space-between;align-items:center;
      position:sticky;top:0;z-index:100;
      border-bottom:1px solid rgba(255,255,255,0.06);
    }
    .nav-logo{font-family:'Playfair Display',serif;font-size:22px;font-weight:700;color:var(--white);text-decoration:none;}
    .nav-logo span{color:var(--sky);}
    .nav-right{display:flex;align-items:center;gap:10px;}
    .btn-nav-ghost{display:inline-flex;align-items:center;gap:6px;padding:7px 16px;border:1.5px solid rgba(255,255,255,0.2);border-radius:20px;color:rgba(255,255,255,0.7);font-family:'Outfit',sans-serif;font-size:13px;text-decoration:none;transition:all .2s;}
    .btn-nav-ghost:hover{border-color:rgba(255,255,255,0.5);color:var(--white);}
    .btn-nav-solid{display:inline-flex;align-items:center;gap:6px;padding:8px 18px;background:var(--blue-bright);border:none;border-radius:20px;color:var(--white);font-family:'Outfit',sans-serif;font-size:13px;font-weight:500;text-decoration:none;cursor:pointer;transition:background .2s;}
    .btn-nav-solid:hover{background:var(--sky);color:var(--white);}

    /* ── PAGE WRAPPER ── */
    .page{max-width:1200px;margin:0 auto;padding:36px 32px 60px;}

    /* ── BREADCRUMB ── */
    .breadcrumb{display:flex;align-items:center;gap:8px;font-size:13px;color:var(--slate-lt);margin-bottom:24px;}
    .breadcrumb a{color:var(--blue-bright);text-decoration:none;}
    .breadcrumb a:hover{text-decoration:underline;}
    .breadcrumb i{font-size:11px;}

    /* ── ALERTS ── */
    .alert{display:flex;align-items:center;gap:10px;padding:12px 16px;border-radius:10px;font-size:14px;margin-bottom:20px;}
    .alert-ok{background:rgba(34,197,94,0.08);border:1.5px solid rgba(34,197,94,0.25);color:#16a34a;}
    .alert-err{background:rgba(224,85,85,0.08);border:1.5px solid rgba(224,85,85,0.25);color:#e05555;}
    .alert-close{margin-left:auto;background:none;border:none;cursor:pointer;font-size:16px;color:inherit;}

    /* ── MAIN GRID ── */
    .main-grid{display:grid;grid-template-columns:1fr 360px;gap:28px;align-items:start;}

    /* ── LEFT: MEDIA ── */
    .media-col{}
    .hero-img-wrap{
      width:100%;height:460px;border-radius:16px;overflow:hidden;
      background:linear-gradient(135deg,var(--ice),#cce3f5);
      display:flex;align-items:center;justify-content:center;
      position:relative;margin-bottom:12px;
    }
    .hero-img{width:100%;height:460px;object-fit:cover;display:block;}
    .hero-placeholder{font-size:5rem;color:var(--sky-lt);}
    .hero-badges{position:absolute;top:16px;left:16px;display:flex;gap:8px;z-index:1;}
    .hbadge{padding:5px 14px;border-radius:20px;font-size:11px;font-weight:600;letter-spacing:.8px;text-transform:uppercase;}
    .hbadge-op{background:var(--blue-bright);color:var(--white);}
    .hbadge-tipo{background:rgba(10,22,40,0.75);backdrop-filter:blur(6px);color:var(--white);}
    .hbadge-dest{background:rgba(245,158,11,0.9);color:var(--white);}

    .thumbs-row{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;}
    .thumb-item{height:80px;border-radius:10px;overflow:hidden;cursor:pointer;border:2px solid transparent;transition:all .2s;}
    .thumb-item img{width:100%;height:80px;object-fit:cover;display:block;}
    .thumb-item:hover,.thumb-item.active{border-color:var(--blue-bright);box-shadow:0 0 0 2px rgba(30,111,217,0.2);}

    /* ── INFO SECTION ── */
    .info-section{margin-top:24px;}
    .info-panel{background:var(--white);border-radius:14px;border:1.5px solid var(--border);padding:28px;margin-bottom:20px;}

    .prop-eyebrow{font-size:11px;font-weight:600;letter-spacing:3px;text-transform:uppercase;color:var(--blue-bright);margin-bottom:10px;display:flex;align-items:center;gap:8px;}
    .prop-eyebrow::before{content:'';width:16px;height:1.5px;background:var(--blue-bright);}
    .prop-title{font-family:'Playfair Display',serif;font-size:clamp(24px,3vw,34px);font-weight:900;color:var(--navy);line-height:1.1;margin-bottom:8px;}
    .prop-loc{display:flex;align-items:center;gap:6px;font-size:14px;color:var(--slate-lt);margin-bottom:20px;}
    .prop-loc i{color:var(--blue-bright);font-size:13px;}
    .prop-price{font-family:'Playfair Display',serif;font-size:36px;font-weight:900;color:var(--blue);line-height:1;margin-bottom:4px;}
    .prop-price-suffix{font-size:14px;font-weight:400;color:var(--slate-lt);font-family:'Outfit',sans-serif;margin-left:4px;}
    .prop-ref{font-size:12px;color:var(--slate-lt);margin-top:4px;}

    .divider{height:1.5px;background:var(--border);margin:20px 0;}

    .prop-desc{font-size:15px;color:var(--slate);line-height:1.75;font-weight:300;}

    /* Features grid */
    .features-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;}
    .feat-item{background:var(--ice);border-radius:10px;padding:14px 16px;display:flex;align-items:center;gap:10px;border:1.5px solid var(--border);}
    .feat-icon{width:36px;height:36px;border-radius:8px;background:rgba(30,111,217,0.1);color:var(--blue-bright);display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0;}
    .feat-val{font-family:'Playfair Display',serif;font-size:18px;font-weight:700;color:var(--navy);line-height:1;}
    .feat-lbl{font-size:11px;color:var(--slate-lt);}

    /* Status pill */
    .status-pill{display:inline-flex;align-items:center;gap:6px;padding:5px 14px;border-radius:20px;font-size:12px;font-weight:600;}
    .status-disp{background:rgba(34,197,94,0.1);color:#16a34a;border:1.5px solid rgba(34,197,94,0.25);}
    .status-no{background:rgba(224,85,85,0.1);color:#e05555;border:1.5px solid rgba(224,85,85,0.2);}

    /* ── RIGHT: CITA CARD ── */
    .cita-col{position:sticky;top:80px;}
    .cita-card{background:var(--white);border-radius:16px;border:1.5px solid var(--border);overflow:hidden;}
    .cita-card-head{
      background:linear-gradient(130deg,var(--navy) 0%,var(--blue) 100%);
      padding:24px 24px 20px;position:relative;overflow:hidden;
    }
    .cita-card-head::before{content:'';position:absolute;top:-30px;right:-30px;width:120px;height:120px;border-radius:50%;background:rgba(255,255,255,0.06);}
    .cita-card-title{font-family:'Playfair Display',serif;font-size:19px;font-weight:700;color:var(--white);margin-bottom:4px;position:relative;z-index:1;}
    .cita-card-sub{font-size:13px;color:rgba(255,255,255,0.5);position:relative;z-index:1;font-weight:300;}
    .cita-card-price{font-family:'Playfair Display',serif;font-size:28px;font-weight:900;color:var(--sky-lt);margin-top:12px;position:relative;z-index:1;line-height:1;}
    .cita-card-price span{font-size:13px;font-weight:400;color:rgba(255,255,255,0.4);font-family:'Outfit',sans-serif;}
    .cita-body{padding:22px;}

    .field{margin-bottom:16px;}
    .field label{display:block;font-size:11px;font-weight:600;letter-spacing:1px;text-transform:uppercase;color:var(--slate);margin-bottom:6px;}
    .field input,.field textarea{width:100%;padding:11px 14px;border:1.5px solid var(--border);border-radius:8px;background:var(--ice);font-family:'Outfit',sans-serif;font-size:14px;color:var(--navy);outline:none;transition:border-color .2s,background .2s;}
    .field input:focus,.field textarea:focus{border-color:var(--blue-bright);background:var(--white);}
    .field textarea{resize:vertical;min-height:80px;}

    .btn-submit{width:100%;padding:13px;background:var(--blue-bright);border:none;border-radius:40px;color:var(--white);font-family:'Outfit',sans-serif;font-size:15px;font-weight:600;cursor:pointer;transition:background .2s;display:flex;align-items:center;justify-content:center;gap:8px;}
    .btn-submit:hover{background:var(--sky);}

    .login-cta{text-align:center;padding:8px 0 4px;}
    .btn-login{display:block;width:100%;padding:12px;background:var(--blue-bright);border:none;border-radius:40px;color:var(--white);font-family:'Outfit',sans-serif;font-size:14px;font-weight:500;cursor:pointer;text-decoration:none;margin-bottom:10px;transition:background .2s;text-align:center;}
    .btn-login:hover{background:var(--sky);color:var(--white);}
    .btn-register{display:block;width:100%;padding:11px;background:transparent;border:1.5px solid var(--border);border-radius:40px;color:var(--slate);font-family:'Outfit',sans-serif;font-size:14px;font-weight:400;cursor:pointer;text-decoration:none;text-align:center;transition:all .2s;}
    .btn-register:hover{border-color:var(--blue-bright);color:var(--blue-bright);}

    .not-available{background:rgba(0,0,0,0.04);border:1.5px solid var(--border);border-radius:10px;padding:20px;text-align:center;color:var(--slate-lt);}
    .not-available i{font-size:28px;display:block;margin-bottom:8px;color:var(--border);}

    .cita-footer{padding:14px 22px;border-top:1.5px solid var(--border);background:var(--ice);display:flex;justify-content:center;}
    .ref-tag{font-size:12px;color:var(--slate-lt);}

    .info-row{display:flex;align-items:center;gap:8px;padding:10px 0;border-bottom:1.5px solid var(--border);font-size:14px;}
    .info-row:last-child{border-bottom:none;}
    .info-row i{color:var(--blue-bright);font-size:14px;width:20px;flex-shrink:0;}
    .info-row-label{color:var(--slate-lt);min-width:100px;}
    .info-row-val{color:var(--navy);font-weight:500;}

    @media(max-width:1000px){
      .main-grid{grid-template-columns:1fr;}
      .cita-col{position:static;}
      .features-grid{grid-template-columns:repeat(2,1fr);}
    }
    @media(max-width:600px){
      .page{padding:20px 16px 48px;}
      .navbar{padding:14px 20px;}
      .hero-img-wrap,.hero-img{height:260px;}
      .thumbs-row{grid-template-columns:repeat(3,1fr);}
      .features-grid{grid-template-columns:1fr 1fr;}
    }
  </style>
</head>
<body>

<!-- NAVBAR -->
<nav class="navbar">
  <a href="<%= request.getContextPath() %>/" class="nav-logo">Ser<span>eno</span></a>
  <div class="nav-right">
    <a href="<%= request.getContextPath() %>/propiedades" class="btn-nav-ghost">
      <i class="bi bi-arrow-left"></i> Volver
    </a>
    <% if (logueado) { %>
    <a href="<%= request.getContextPath() + usuario.getDashboardUrl() %>" class="btn-nav-solid">
      <i class="bi bi-grid-1x2"></i> Mi Panel
    </a>
    <% } else { %>
    <a href="<%= request.getContextPath() %>/login" class="btn-nav-solid">
      <i class="bi bi-box-arrow-in-right"></i> Iniciar Sesión
    </a>
    <% } %>
  </div>
</nav>

<div class="page">

  <!-- BREADCRUMB -->
  <div class="breadcrumb">
    <a href="<%= request.getContextPath() %>/">Inicio</a>
    <i class="bi bi-chevron-right"></i>
    <a href="<%= request.getContextPath() %>/propiedades">Propiedades</a>
    <i class="bi bi-chevron-right"></i>
    <span style="color:var(--slate)"><%= titulo %></span>
  </div>

  <!-- ALERTS -->
  <% if (msgCita != null) { %>
  <div class="alert alert-ok" id="alertOk">
    <i class="bi bi-check-circle-fill"></i> <%= msgCita.replace("+"," ") %>
    <button class="alert-close" onclick="document.getElementById('alertOk').remove()">×</button>
  </div>
  <% } %>
  <% if (errCita != null) { %>
  <div class="alert alert-err" id="alertErr">
    <i class="bi bi-exclamation-circle-fill"></i> <%= errCita.replace("+"," ") %>
    <button class="alert-close" onclick="document.getElementById('alertErr').remove()">×</button>
  </div>
  <% } %>

  <div class="main-grid">

    <!-- ── LEFT COLUMN ── -->
    <div>

      <!-- MEDIA -->
      <div class="hero-img-wrap">
        <div class="hero-badges">
          <span class="hbadge hbadge-op"><%= operacion %></span>
          <span class="hbadge hbadge-tipo"><%= tipo %></span>
          <% if ("true".equals(destacado)) { %><span class="hbadge hbadge-dest">⭐ Destacado</span><% } %>
        </div>
        <% if (!fotoPortada.isEmpty()) { %>
          <img id="fotoMain" src="<%= fotoPortada %>" class="hero-img" alt="<%= titulo %>"/>
        <% } else { %>
          <div class="hero-placeholder"><i class="bi bi-building"></i></div>
        <% } %>
      </div>

      <% if (fotos.size() > 1) { %>
      <div class="thumbs-row" style="margin-bottom:24px">
        <% for (int fi=0; fi<Math.min(fotos.size(),8); fi++) { String[] f = fotos.get(fi); %>
        <div class="thumb-item <%= fi==0?"active":"" %>" onclick="cambiarFoto(this,'<%= f[0] %>')">
          <img src="<%= f[0] %>" alt="<%= f[1] %>"/>
        </div>
        <% } %>
      </div>
      <% } %>

      <!-- INFO PANELS -->
      <div class="info-section">

        <!-- Título + precio -->
        <div class="info-panel">
          <div class="prop-eyebrow"><%= tipo %> en <%= operacion.toLowerCase() %></div>
          <h1 class="prop-title"><%= titulo %></h1>
          <div class="prop-loc">
            <i class="bi bi-geo-alt-fill"></i>
            <%= direccion %><% if (!barrio.isEmpty()) { %>, <%= barrio %><% } %><% if (!ciudadNombre.isEmpty()) { %> — <%= ciudadNombre %><% } %>
          </div>

          <div class="prop-price">$<%= precio %><span class="prop-price-suffix"><%= sufijoPrecio %></span></div>
          <div class="prop-ref">Ref. #<%= propId %></div>

          <div class="divider"></div>

          <div style="display:flex;align-items:center;gap:10px;margin-bottom:16px;">
            <% if (disponible) { %>
              <span class="status-pill status-disp"><i class="bi bi-check-circle-fill"></i> Disponible</span>
            <% } else { %>
              <span class="status-pill status-no"><i class="bi bi-x-circle-fill"></i> No disponible</span>
            <% } %>
          </div>

          <% if (!descripcion.isEmpty()) { %>
          <p class="prop-desc"><%= descripcion %></p>
          <% } %>
        </div>

        <!-- Características -->
        <% boolean hasFeats = habitaciones>0||banos>0||parqueaderos>0||!area.isEmpty()||!estrato.isEmpty(); %>
        <% if (hasFeats) { %>
        <div class="info-panel">
          <h3 style="font-family:'Playfair Display',serif;font-size:19px;font-weight:700;color:var(--navy);margin-bottom:18px;">Características</h3>
          <div class="features-grid">
            <% if (habitaciones > 0) { %>
            <div class="feat-item">
              <div class="feat-icon"><i class="bi bi-door-open"></i></div>
              <div><div class="feat-val"><%= habitaciones %></div><div class="feat-lbl">Habitaciones</div></div>
            </div>
            <% } %>
            <% if (banos > 0) { %>
            <div class="feat-item">
              <div class="feat-icon"><i class="bi bi-droplet"></i></div>
              <div><div class="feat-val"><%= banos %></div><div class="feat-lbl">Baños</div></div>
            </div>
            <% } %>
            <% if (parqueaderos > 0) { %>
            <div class="feat-item">
              <div class="feat-icon"><i class="bi bi-car-front"></i></div>
              <div><div class="feat-val"><%= parqueaderos %></div><div class="feat-lbl">Parqueaderos</div></div>
            </div>
            <% } %>
            <% if (!area.isEmpty()) { %>
            <div class="feat-item">
              <div class="feat-icon"><i class="bi bi-rulers"></i></div>
              <div><div class="feat-val"><%= area %></div><div class="feat-lbl">m² área</div></div>
            </div>
            <% } %>
            <% if (!estrato.isEmpty()) { %>
            <div class="feat-item">
              <div class="feat-icon"><i class="bi bi-layers"></i></div>
              <div><div class="feat-val"><%= estrato %></div><div class="feat-lbl">Estrato</div></div>
            </div>
            <% } %>
          </div>
        </div>
        <% } %>

        <!-- Detalles adicionales -->
        <div class="info-panel">
          <h3 style="font-family:'Playfair Display',serif;font-size:19px;font-weight:700;color:var(--navy);margin-bottom:18px;">Detalles</h3>
          <% if (!tipo.isEmpty()) { %>
          <div class="info-row"><i class="bi bi-building"></i><span class="info-row-label">Tipo</span><span class="info-row-val"><%= tipo %></span></div>
          <% } %>
          <% if (!operacion.isEmpty()) { %>
          <div class="info-row"><i class="bi bi-arrow-left-right"></i><span class="info-row-label">Operación</span><span class="info-row-val"><%= operacion %></span></div>
          <% } %>
          <% if (!estado.isEmpty()) { %>
          <div class="info-row"><i class="bi bi-info-circle"></i><span class="info-row-label">Estado</span><span class="info-row-val"><%= estado %></span></div>
          <% } %>
          <% if (!ciudadNombre.isEmpty()) { %>
          <div class="info-row"><i class="bi bi-geo-alt"></i><span class="info-row-label">Ciudad</span><span class="info-row-val"><%= ciudadNombre %></span></div>
          <% } %>
          <% if (!barrio.isEmpty()) { %>
          <div class="info-row"><i class="bi bi-map"></i><span class="info-row-label">Barrio</span><span class="info-row-val"><%= barrio %></span></div>
          <% } %>
        </div>

      </div>
    </div>

    <!-- ── RIGHT COLUMN: CITA CARD ── -->
    <div class="cita-col" id="cita">
      <div class="cita-card">
        <div class="cita-card-head">
          <div class="cita-card-title">¿Te interesa?</div>
          <div class="cita-card-sub">Agenda una visita con el agente</div>
          <div class="cita-card-price">$<%= precio %><span> <%= sufijoPrecio %></span></div>
        </div>
        <div class="cita-body">
          <% if (disponible) { %>
            <% if (esCliente) { %>
            <form method="post" action="<%= request.getContextPath() %>/citas">
              <input type="hidden" name="propiedadId" value="<%= propId %>"/>
              <div class="field">
                <label>Fecha y hora</label>
                <input type="datetime-local" name="fechaHora" required
                       min="<%= new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm").format(new java.util.Date()) %>"/>
              </div>
              <div class="field">
                <label>Mensaje (opcional)</label>
                <textarea name="mensaje" placeholder="Alguna pregunta o comentario…"></textarea>
              </div>
              <button type="submit" class="btn-submit">
                <i class="bi bi-calendar-check"></i> Agendar visita
              </button>
            </form>
            <% } else if (logueado) { %>
            <div class="not-available">
              <i class="bi bi-person-x"></i>
              Solo los clientes pueden agendar visitas.
            </div>
            <% } else { %>
            <div class="login-cta">
              <p style="font-size:13px;color:var(--slate-lt);margin-bottom:16px;line-height:1.6;">Inicia sesión o crea una cuenta gratuita para agendar tu visita.</p>
              <a href="<%= request.getContextPath() %>/login" class="btn-login">
                <i class="bi bi-box-arrow-in-right"></i> Iniciar Sesión
              </a>
              <a href="<%= request.getContextPath() %>/register" class="btn-register">
                Crear cuenta gratis
              </a>
            </div>
            <% } %>
          <% } else { %>
          <div class="not-available">
            <i class="bi bi-building-x"></i>
            Esta propiedad no está disponible actualmente.
          </div>
          <% } %>
        </div>
        <div class="cita-footer">
          <span class="ref-tag"><i class="bi bi-hash" style="font-size:11px"></i> Referencia <%= propId %></span>
        </div>
      </div>
    </div>

  </div><!-- /main-grid -->
</div><!-- /page -->

<script>
function cambiarFoto(el, url) {
  const main = document.getElementById('fotoMain');
  if (main) main.src = url;
  document.querySelectorAll('.thumb-item').forEach(t => t.classList.remove('active'));
  el.classList.add('active');
}
</script>
</body>
</html>
