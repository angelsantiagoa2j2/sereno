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
                rs.getString("operacion").equals("ARRIENDO") ? "/mes" : ""
            });
        }
    } catch (Exception e) { out.println("ERROR: " + e.getMessage()); }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Propiedades — InmoVista</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.0/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.0/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        :root { --dorado: #c9a84c; --oscuro: #1a1a18; }
        body { background: #f0ede8; }
        .navbar { background: var(--oscuro) !important; }
        .navbar-brand span { color: var(--dorado); }
        .hero { background: var(--oscuro); padding: 60px 0 40px; color: white; }
        .hero h1 { font-size: 2.4rem; font-weight: 300; }
        .hero h1 em { font-style: italic; color: var(--dorado); }
        .search-bar { background: white; border-radius: 50px; padding: 8px 8px 8px 20px; display: flex; gap: 8px; align-items: center; }
        .search-bar input, .search-bar select { border: none; outline: none; background: transparent; font-size: .9rem; }
        .search-bar select { border-left: 1px solid #eee; padding: 0 12px; color: #555; }
        .btn-buscar { background: var(--dorado); color: white; border: none; border-radius: 50px; padding: 8px 24px; font-weight: 500; }
        .prop-card { background: white; border-radius: 12px; overflow: hidden; transition: transform .2s, box-shadow .2s; border: none; }
        .prop-card:hover { transform: translateY(-4px); box-shadow: 0 12px 30px rgba(0,0,0,.1); }
        .prop-img { height: 200px; object-fit: cover; width: 100%; }
        .prop-img-placeholder { height: 200px; background: linear-gradient(135deg,#e8e0d0,#d4c8b0); display: flex; align-items: center; justify-content: center; font-size: 3rem; }
        .badge-tipo { background: var(--oscuro); color: white; font-size: .7rem; padding: 3px 8px; border-radius: 4px; }
        .badge-op { background: var(--dorado); color: white; font-size: .7rem; padding: 3px 8px; border-radius: 4px; }
        .precio { color: var(--dorado); font-size: 1.3rem; font-weight: 700; }
        .btn-ver { background: var(--oscuro); color: white; border: none; border-radius: 6px; padding: 8px 16px; font-size: .85rem; width: 100%; transition: background .2s; }
        .btn-ver:hover { background: #333; color: white; }
        .tag-destacado { background: #fff3cd; color: #856404; font-size: .7rem; padding: 2px 8px; border-radius: 4px; }
    </style>
</head>
<body>

<!-- Navbar -->
<nav class="navbar navbar-dark px-4">
    <a class="navbar-brand fw-bold fs-5" href="<%= request.getContextPath() %>/">Inmo<span>Vista</span></a>
    <div class="d-flex gap-2 align-items-center">
        <% if (usuarioNav != null) { %>
        <span class="text-white-50 small"><%= usuarioNav.getNombreCompleto() %></span>
        <a href="<%= request.getContextPath() + usuarioNav.getDashboardUrl() %>" class="btn btn-sm" style="background:var(--dorado);color:white;">Mi Panel</a>
        <a href="<%= request.getContextPath() %>/logout" class="btn btn-sm btn-outline-light">Salir</a>
        <% } else { %>
        <a href="<%= request.getContextPath() %>/login" class="btn btn-sm btn-outline-light">Iniciar Sesión</a>
        <a href="<%= request.getContextPath() %>/register" class="btn btn-sm" style="background:var(--dorado);color:white;">Registrarse</a>
        <% } %>
    </div>
</nav>

<!-- Hero + Búsqueda -->
<div class="hero">
    <div class="container">
        <h1 class="mb-2">Encuentra tu propiedad <em>ideal</em></h1>
        <p class="text-white-50 mb-4">Catálogo completo de propiedades en venta y arriendo</p>
        <form method="get" action="">
            <div class="search-bar">
                <i class="bi bi-search text-muted"></i>
                <input type="text" name="buscar" placeholder="Buscar por nombre, barrio, ciudad..." value="<%= buscar %>" style="flex:1; min-width:0;">
                <select name="tipo">
                    <option value="">Tipo</option>
                    <option value="CASA"          <%= "CASA".equals(tipoParam)          ? "selected" : "" %>>Casa</option>
                    <option value="APARTAMENTO"   <%= "APARTAMENTO".equals(tipoParam)   ? "selected" : "" %>>Apartamento</option>
                    <option value="LOCAL"         <%= "LOCAL".equals(tipoParam)         ? "selected" : "" %>>Local</option>
                    <option value="OFICINA"       <%= "OFICINA".equals(tipoParam)       ? "selected" : "" %>>Oficina</option>
                    <option value="LOTE"          <%= "LOTE".equals(tipoParam)          ? "selected" : "" %>>Lote</option>
                    <option value="BODEGA"        <%= "BODEGA".equals(tipoParam)        ? "selected" : "" %>>Bodega</option>
                    <option value="FINCA"         <%= "FINCA".equals(tipoParam)         ? "selected" : "" %>>Finca</option>
                </select>
                <select name="operacion">
                    <option value="">Operación</option>
                    <option value="VENTA"          <%= "VENTA".equals(opParam)          ? "selected" : "" %>>Venta</option>
                    <option value="ARRIENDO"       <%= "ARRIENDO".equals(opParam)       ? "selected" : "" %>>Arriendo</option>
                    <option value="VENTA_ARRIENDO" <%= "VENTA_ARRIENDO".equals(opParam) ? "selected" : "" %>>Venta/Arriendo</option>
                </select>
                <button type="submit" class="btn-buscar">Buscar</button>
            </div>
        </form>
    </div>
</div>

<!-- Resultados -->
<div class="container py-4">
    <p class="text-muted mb-3">Se encontraron <strong><%= propiedades.size() %></strong> propiedades</p>

    <% if (propiedades.isEmpty()) { %>
    <div class="text-center py-5">
        <div style="font-size:4rem;">🏠</div>
        <h4 class="mt-3">No se encontraron propiedades</h4>
        <p class="text-muted">Intenta con otros filtros</p>
    </div>
    <% } else { %>
    <div class="row g-4">
        <% for (String[] p : propiedades) { %>
        <div class="col-md-6 col-lg-4">
            <div class="prop-card card h-100">
                <% if (!p[12].isEmpty()) { %>
                <img src="<%= p[12] %>" class="prop-img" alt="<%= p[1] %>">
                <% } else { %>
                <div class="prop-img-placeholder">🏠</div>
                <% } %>
                <div class="card-body d-flex flex-column">
                    <div class="d-flex gap-1 mb-2">
                        <span class="badge-tipo"><%= p[2] %></span>
                        <span class="badge-op"><%= p[3] %></span>
                        <% if ("true".equals(p[11])) { %><span class="tag-destacado">⭐ Destacado</span><% } %>
                    </div>
                    <h6 class="fw-bold mb-1"><%= p[1] %></h6>
                    <p class="text-muted small mb-2"><i class="bi bi-geo-alt"></i> <%= p[9].isEmpty() ? "" : p[9]+", " %><%= p[10] %></p>
                    <div class="d-flex gap-3 text-muted small mb-3">
                        <% if (!p[5].equals("0")) { %><span><i class="bi bi-door-open"></i> <%= p[5] %></span><% } %>
                        <% if (!p[6].equals("0")) { %><span><i class="bi bi-droplet"></i> <%= p[6] %></span><% } %>
                        <% if (!p[7].isEmpty()) { %><span><i class="bi bi-rulers"></i> <%= p[7] %>m²</span><% } %>
                    </div>
                    <div class="precio mt-auto mb-3">$<%= p[4] %><small class="text-muted fs-6"><%= p[13] %></small></div>
                    <a href="<%= request.getContextPath() %>/propiedades?id=<%= p[0] %>" class="btn-ver">Ver detalle</a>
                </div>
            </div>
        </div>
        <% } %>
    </div>
    <% } %>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.0/js/bootstrap.bundle.min.js"></script>
</body>
</html>
