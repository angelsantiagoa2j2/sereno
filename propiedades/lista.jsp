<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%@ page import="com.inmovista.db.DBManager" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    Usuario usuarioNav = (Usuario) session.getAttribute("usuario");

    String buscar    = request.getParameter("buscar")    != null ? request.getParameter("buscar").trim()    : "";
    String tipoParam = request.getParameter("tipo")      != null ? request.getParameter("tipo").trim()      : "";
    String opParam   = request.getParameter("operacion") != null ? request.getParameter("operacion").trim() : "";

    List<String[]> propiedades = new ArrayList<>();

    StringBuilder sql = new StringBuilder(
        "SELECT p.id, p.titulo, p.tipo, p.operacion, p.precio, p.habitaciones, p.banos, " +
        "p.area_m2, p.direccion, p.barrio, p.estado, p.destacado, c.nombre AS ciudad, " +
        "(SELECT url FROM propiedad_fotos WHERE propiedad_id=p.id AND es_portada=1 LIMIT 1) AS foto " +
        "FROM propiedades p LEFT JOIN ciudades c ON p.ciudad_id=c.id " +
        "WHERE p.estado != 'INACTIVO' ");

    List<Object> params = new ArrayList<>();
    if (!buscar.isEmpty())    { sql.append("AND (p.titulo LIKE ? OR p.barrio LIKE ? OR c.nombre LIKE ?) "); params.add("%"+buscar+"%"); params.add("%"+buscar+"%"); params.add("%"+buscar+"%"); }
    if (!tipoParam.isEmpty()) { sql.append("AND p.tipo=? "); params.add(tipoParam); }
    if (!opParam.isEmpty())   { sql.append("AND p.operacion=? "); params.add(opParam); }
    sql.append("ORDER BY p.destacado DESC, p.id DESC");

    try (Connection conn = DBManager.getConnection("cloud");
         PreparedStatement ps = conn.prepareStatement(sql.toString())) {
        for (int i = 0; i < params.size(); i++) ps.setObject(i+1, params.get(i));
        ResultSet rs = ps.executeQuery();
        while (rs.next()) {
            propiedades.add(new String[]{
                String.valueOf(rs.getInt("id")),
                rs.getString("titulo"),
                rs.getString("tipo"),
                rs.getString("operacion"),
                String.format("%,.0f", rs.getDouble("precio")),
                String.valueOf(rs.getInt("habitaciones")),
                String.valueOf(rs.getInt("banos")),
                rs.getString("area_m2") != null ? rs.getString("area_m2") : "",
                rs.getString("direccion") != null ? rs.getString("direccion") : "",
                rs.getString("barrio")    != null ? rs.getString("barrio")    : "",
                rs.getString("ciudad")    != null ? rs.getString("ciudad")    : "",
                rs.getString("estado"),
                rs.getString("foto")      != null ? rs.getString("foto")      : "",
                rs.getString("destacado"),
                rs.getString("operacion").equals("ARRIENDO") ? "/mes" : ""
            });
        }
    } catch (Exception e) { /* continuar */ }

    boolean hasFilters = !buscar.isEmpty() || !tipoParam.isEmpty() || !opParam.isEmpty();
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Propiedades — Sereno</title>
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
      background:var(--navy);padding:14px 56px;
      display:flex;justify-content:space-between;align-items:center;
      position:sticky;top:0;z-index:100;
      border-bottom:1px solid rgba(255,255,255,0.06);
    }
    .nav-logo{font-family:'Playfair Display',serif;font-size:22px;font-weight:700;color:var(--white);text-decoration:none;}
    .nav-logo span{color:var(--sky);}
    .nav-right{display:flex;align-items:center;gap:10px;}
    .nav-user{font-size:13px;color:rgba(255,255,255,0.45);margin-right:4px;}
    .btn-nav-ghost{display:inline-flex;align-items:center;gap:6px;padding:7px 16px;border:1.5px solid rgba(255,255,255,0.2);border-radius:20px;color:rgba(255,255,255,0.7);font-family:'Outfit',sans-serif;font-size:13px;text-decoration:none;transition:all .2s;}
    .btn-nav-ghost:hover{border-color:rgba(255,255,255,0.45);color:var(--white);}
    .btn-nav-solid{display:inline-flex;align-items:center;gap:6px;padding:8px 18px;background:var(--blue-bright);border:none;border-radius:20px;color:var(--white);font-family:'Outfit',sans-serif;font-size:13px;font-weight:500;text-decoration:none;cursor:pointer;transition:background .2s;}
    .btn-nav-solid:hover{background:var(--sky);color:var(--white);}

    /* ── HERO ── */
    .hero{
      background:var(--navy);
      padding:56px 56px 0;
      position:relative;overflow:hidden;
    }
    .hero::before{
      content:'';position:absolute;right:-60px;top:-80px;
      width:380px;height:380px;border-radius:50%;
      background:radial-gradient(circle,rgba(74,157,224,0.12) 0%,transparent 70%);
    }
    .hero::after{
      content:'';position:absolute;left:30%;bottom:-40px;
      width:280px;height:280px;border-radius:50%;
      border:1px solid rgba(255,255,255,0.04);
    }
    .hero-inner{position:relative;z-index:1;max-width:660px;margin-bottom:36px;}
    .hero-eyebrow{font-size:11px;font-weight:600;letter-spacing:3px;text-transform:uppercase;color:rgba(255,255,255,0.35);margin-bottom:10px;}
    .hero-title{font-family:'Playfair Display',serif;font-size:clamp(30px,4vw,48px);font-weight:900;color:var(--white);line-height:1.05;margin-bottom:10px;}
    .hero-title em{font-style:italic;color:var(--sky-lt);}
    .hero-sub{color:rgba(255,255,255,0.4);font-size:15px;font-weight:300;line-height:1.6;}

    /* ── SEARCH BAR (inside hero, bottom) ── */
    .search-wrap{
      position:relative;z-index:1;
      background:rgba(255,255,255,0.06);
      backdrop-filter:blur(14px);
      border:1px solid rgba(255,255,255,0.1);
      border-radius:14px 14px 0 0;
      padding:18px 20px;
      display:flex;gap:10px;align-items:center;
      flex-wrap:wrap;
    }
    .search-input{
      flex:1;min-width:200px;
      background:rgba(255,255,255,0.08);border:1.5px solid rgba(255,255,255,0.1);
      border-radius:8px;padding:11px 16px;
      color:var(--white);font-family:'Outfit',sans-serif;font-size:14px;outline:none;
      transition:border-color .2s;
    }
    .search-input::placeholder{color:rgba(255,255,255,0.3);}
    .search-input:focus{border-color:var(--sky);}
    .search-select{
      background:rgba(255,255,255,0.08);border:1.5px solid rgba(255,255,255,0.1);
      border-radius:8px;padding:11px 14px;
      color:rgba(255,255,255,0.7);font-family:'Outfit',sans-serif;font-size:13px;
      cursor:pointer;outline:none;transition:border-color .2s;
    }
    .search-select option{background:#0d1e38;}
    .search-select:focus{border-color:var(--sky);}
    .btn-search{
      display:inline-flex;align-items:center;gap:7px;
      padding:11px 26px;background:var(--blue-bright);border:none;border-radius:8px;
      color:var(--white);font-family:'Outfit',sans-serif;font-size:14px;font-weight:500;
      cursor:pointer;transition:background .2s;white-space:nowrap;
    }
    .btn-search:hover{background:var(--sky);}

    /* ── CONTENT AREA ── */
    .content{max-width:1280px;margin:0 auto;padding:32px 40px 72px;}

    /* ── RESULTS BAR ── */
    .results-bar{display:flex;justify-content:space-between;align-items:center;margin-bottom:24px;flex-wrap:wrap;gap:12px;}
    .results-count{font-size:14px;color:var(--slate);}
    .results-count strong{color:var(--navy);font-weight:600;}
    .filter-tags{display:flex;gap:8px;flex-wrap:wrap;}
    .filter-tag{display:inline-flex;align-items:center;gap:6px;padding:4px 12px;background:rgba(30,111,217,0.08);border:1.5px solid rgba(30,111,217,0.2);border-radius:20px;font-size:12px;color:var(--blue-bright);font-weight:500;}
    .filter-tag a{color:var(--blue-bright);text-decoration:none;font-size:13px;line-height:1;}
    .btn-clear-filters{font-size:12px;color:var(--slate-lt);text-decoration:none;padding:4px 10px;border:1.5px solid var(--border);border-radius:20px;transition:all .2s;}
    .btn-clear-filters:hover{border-color:var(--blue-bright);color:var(--blue-bright);}

    /* ── GRID ── */
    .props-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:22px;}
    @media(max-width:1100px){.props-grid{grid-template-columns:repeat(2,1fr);}}
    @media(max-width:640px){.props-grid{grid-template-columns:1fr;}}

    /* ── PROP CARD ── */
    .prop-card{
      background:var(--white);border-radius:14px;
      border:1.5px solid var(--border);overflow:hidden;
      transition:all .25s;text-decoration:none;color:inherit;display:block;
    }
    .prop-card:hover{transform:translateY(-5px);box-shadow:0 16px 48px rgba(20,85,164,0.11);border-color:var(--sky-lt);}

    .card-img-wrap{position:relative;height:210px;overflow:hidden;background:linear-gradient(135deg,var(--ice),#cce3f5);display:flex;align-items:center;justify-content:center;}
    .card-img{width:100%;height:210px;object-fit:cover;display:block;transition:transform .4s;}
    .prop-card:hover .card-img{transform:scale(1.04);}
    .card-placeholder{font-size:3.5rem;color:var(--sky-lt);}
    .card-img-wrap::after{content:'';position:absolute;inset:0;background:linear-gradient(0deg,rgba(10,22,40,0.18) 0%,transparent 50%);pointer-events:none;}

    /* Badges over image */
    .img-badges{position:absolute;top:12px;left:12px;display:flex;gap:7px;z-index:1;}
    .ibadge{padding:4px 12px;border-radius:20px;font-size:10px;font-weight:600;letter-spacing:.8px;text-transform:uppercase;}
    .ibadge-op{background:var(--blue-bright);color:var(--white);}
    .ibadge-tipo{background:rgba(10,22,40,0.75);backdrop-filter:blur(4px);color:var(--white);}
    .ibadge-dest{background:rgba(245,158,11,0.9);color:var(--white);}

    /* Card body */
    .card-body{padding:18px 20px 16px;}
    .card-name{font-family:'Playfair Display',serif;font-size:17px;font-weight:700;color:var(--navy);margin-bottom:4px;line-height:1.25;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
    .card-loc{font-size:12px;color:var(--slate-lt);margin-bottom:12px;display:flex;align-items:center;gap:4px;}
    .card-loc i{color:var(--blue-bright);font-size:11px;}
    .card-feats{display:flex;gap:12px;margin-bottom:14px;flex-wrap:wrap;}
    .feat{display:flex;align-items:center;gap:5px;font-size:12px;color:var(--slate);background:var(--ice);padding:4px 10px;border-radius:20px;}
    .feat i{color:var(--blue-bright);font-size:12px;}
    .card-footer{display:flex;justify-content:space-between;align-items:center;padding-top:14px;border-top:1.5px solid var(--border);}
    .card-price{font-family:'Playfair Display',serif;font-size:20px;font-weight:700;color:var(--blue);}
    .card-price span{font-size:12px;font-weight:400;color:var(--slate-lt);font-family:'Outfit',sans-serif;}
    .btn-card{display:inline-flex;align-items:center;gap:5px;padding:7px 16px;background:var(--blue-bright);border:none;border-radius:20px;color:var(--white);font-family:'Outfit',sans-serif;font-size:12px;font-weight:500;cursor:pointer;transition:background .2s;text-decoration:none;}
    .btn-card:hover{background:var(--sky);color:var(--white);}

    /* ── EMPTY STATE ── */
    .empty-wrap{text-align:center;padding:80px 32px;}
    .empty-ill{width:100px;height:100px;border-radius:50%;background:var(--ice);border:2px dashed var(--border);display:flex;align-items:center;justify-content:center;font-size:3rem;margin:0 auto 22px;color:var(--sky-lt);}
    .empty-title{font-family:'Playfair Display',serif;font-size:24px;font-weight:700;color:var(--navy);margin-bottom:8px;}
    .empty-sub{color:var(--slate-lt);font-size:14px;margin-bottom:24px;line-height:1.6;}
    .btn-empty{display:inline-flex;align-items:center;gap:7px;padding:11px 26px;background:var(--blue-bright);border:none;border-radius:40px;color:var(--white);font-family:'Outfit',sans-serif;font-size:14px;font-weight:500;cursor:pointer;text-decoration:none;transition:background .2s;}
    .btn-empty:hover{background:var(--sky);color:var(--white);}

    @media(max-width:768px){
      .navbar{padding:14px 20px;}
      .hero{padding:36px 20px 0;}
      .search-wrap{border-radius:10px 10px 0 0;}
      .content{padding:20px 16px 48px;}
      .nav-user{display:none;}
    }
  </style>
</head>
<body>

<!-- NAVBAR -->
<nav class="navbar">
  <a href="<%= request.getContextPath() %>/" class="nav-logo">Ser<span>eno</span></a>
  <div class="nav-right">
    <% if (usuarioNav != null) { %>
      <span class="nav-user"><%= usuarioNav.getNombreCompleto() %></span>
      <a href="<%= request.getContextPath() + usuarioNav.getDashboardUrl() %>" class="btn-nav-solid">
        <i class="bi bi-grid-1x2"></i> Mi Panel
      </a>
      <a href="<%= request.getContextPath() %>/logout" class="btn-nav-ghost">Salir</a>
    <% } else { %>
      <a href="<%= request.getContextPath() %>/login" class="btn-nav-ghost">Iniciar Sesión</a>
      <a href="<%= request.getContextPath() %>/register" class="btn-nav-solid">Registrarse</a>
    <% } %>
  </div>
</nav>

<!-- HERO + SEARCH -->
<div class="hero">
  <div class="hero-inner">
    <div class="hero-eyebrow">Catálogo de propiedades</div>
    <h1 class="hero-title">Encuentra tu propiedad <em>ideal</em></h1>
    <p class="hero-sub">Casas, apartamentos, terrenos y más — en venta y arriendo en las mejores zonas del país.</p>
  </div>
  <form method="get" action="">
    <div class="search-wrap">
      <input class="search-input" type="text" name="buscar"
             placeholder="Buscar por nombre, barrio o ciudad…"
             value="<%= buscar %>"/>
      <select class="search-select" name="tipo">
        <option value="">Tipo de propiedad</option>
        <option value="CASA"          <%= "CASA".equals(tipoParam)          ? "selected":"" %>>Casa</option>
        <option value="APARTAMENTO"   <%= "APARTAMENTO".equals(tipoParam)   ? "selected":"" %>>Apartamento</option>
        <option value="LOCAL"         <%= "LOCAL".equals(tipoParam)         ? "selected":"" %>>Local</option>
        <option value="OFICINA"       <%= "OFICINA".equals(tipoParam)       ? "selected":"" %>>Oficina</option>
        <option value="LOTE"          <%= "LOTE".equals(tipoParam)          ? "selected":"" %>>Lote</option>
        <option value="BODEGA"        <%= "BODEGA".equals(tipoParam)        ? "selected":"" %>>Bodega</option>
        <option value="FINCA"         <%= "FINCA".equals(tipoParam)         ? "selected":"" %>>Finca</option>
      </select>
      <select class="search-select" name="operacion">
        <option value="">Operación</option>
        <option value="VENTA"          <%= "VENTA".equals(opParam)          ? "selected":"" %>>Venta</option>
        <option value="ARRIENDO"       <%= "ARRIENDO".equals(opParam)       ? "selected":"" %>>Arriendo</option>
        <option value="VENTA_ARRIENDO" <%= "VENTA_ARRIENDO".equals(opParam) ? "selected":"" %>>Venta / Arriendo</option>
      </select>
      <button type="submit" class="btn-search">
        <i class="bi bi-search"></i> Buscar
      </button>
    </div>
  </form>
</div>

<!-- CONTENT -->
<div class="content">

  <!-- RESULTS BAR -->
  <div class="results-bar">
    <div class="results-count">
      Se encontraron <strong><%= propiedades.size() %></strong> propiedad<%= propiedades.size()!=1?"es":"" %>
      <% if (hasFilters) { %> con los filtros aplicados<% } %>
    </div>
    <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap;">
      <div class="filter-tags">
        <% if (!buscar.isEmpty()) { %>
          <span class="filter-tag"><i class="bi bi-search"></i> "<%= buscar %>"</span>
        <% } %>
        <% if (!tipoParam.isEmpty()) { %>
          <span class="filter-tag"><i class="bi bi-building"></i> <%= tipoParam %></span>
        <% } %>
        <% if (!opParam.isEmpty()) { %>
          <span class="filter-tag"><i class="bi bi-arrow-left-right"></i> <%= opParam %></span>
        <% } %>
      </div>
      <% if (hasFilters) { %>
        <a href="<%= request.getContextPath() %>/propiedades" class="btn-clear-filters">
          <i class="bi bi-x-lg" style="font-size:10px"></i> Limpiar filtros
        </a>
      <% } %>
    </div>
  </div>

  <!-- GRID -->
  <% if (propiedades.isEmpty()) { %>
  <div class="empty-wrap">
    <div class="empty-ill"><i class="bi bi-building-x"></i></div>
    <div class="empty-title">No encontramos propiedades</div>
    <div class="empty-sub">Intenta con otros filtros o busca en una ciudad diferente.<br>Nuestro catálogo se actualiza constantemente.</div>
    <a href="<%= request.getContextPath() %>/propiedades" class="btn-empty">
      <i class="bi bi-arrow-counterclockwise"></i> Ver todas las propiedades
    </a>
  </div>
  <% } else { %>
  <div class="props-grid">
    <% for (String[] p : propiedades) {
        boolean esArriendo = "ARRIENDO".equals(p[3]);
        boolean destacado  = "true".equals(p[13]);
    %>
    <a href="<%= request.getContextPath() %>/propiedades?id=<%= p[0] %>" class="prop-card">
      <div class="card-img-wrap">
        <div class="img-badges">
          <span class="ibadge ibadge-op"><%= p[3] %></span>
          <span class="ibadge ibadge-tipo"><%= p[2] %></span>
          <% if (destacado) { %><span class="ibadge ibadge-dest">⭐ Destacado</span><% } %>
        </div>
        <% if (!p[12].isEmpty()) { %>
          <img src="<%= p[12] %>" class="card-img" alt="<%= p[1] %>"/>
        <% } else { %>
          <div class="card-placeholder"><i class="bi bi-house"></i></div>
        <% } %>
      </div>
      <div class="card-body">
        <div class="card-name"><%= p[1] %></div>
        <div class="card-loc">
          <i class="bi bi-geo-alt-fill"></i>
          <%= p[9].isEmpty() ? "" : p[9]+", " %><%= p[10] %>
        </div>
        <div class="card-feats">
          <% if (!p[5].equals("0")) { %>
            <span class="feat"><i class="bi bi-door-open"></i> <%= p[5] %> hab.</span>
          <% } %>
          <% if (!p[6].equals("0")) { %>
            <span class="feat"><i class="bi bi-droplet"></i> <%= p[6] %> baños</span>
          <% } %>
          <% if (!p[7].isEmpty()) { %>
            <span class="feat"><i class="bi bi-rulers"></i> <%= p[7] %> m²</span>
          <% } %>
        </div>
        <div class="card-footer">
          <div class="card-price">
            $<%= p[4] %><span><%= esArriendo ? " /mes" : "" %></span>
          </div>
          <span class="btn-card"><i class="bi bi-eye"></i> Ver detalle</span>
        </div>
      </div>
    </a>
    <% } %>
  </div>
  <% } %>
</div>

</body>
</html>
