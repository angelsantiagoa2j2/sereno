<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%@ page import="com.inmovista.db.DBManager" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
out.println("ID recibido: " + request.getParameter("id"));
out.flush();
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
        } finally {
            conn.close();
        }
    } catch (Exception e) {
        errorMsg = e.getMessage();
    }

    if (!encontrado) {
    out.println("<h2>No encontrado. Error: " + errorMsg + "</h2>");
    out.println("<p>ID buscado: " + idParam + "</p>");
    return;
    }

    Usuario usuario  = (Usuario) session.getAttribute("usuario");
    boolean logueado  = usuario != null;
    boolean esCliente = logueado && usuario.isCliente();
    String fotoPortada = fotos.isEmpty() ? "" : fotos.get(0)[0];
    String sufijoPrecio = "ARRIENDO".equals(operacion) ? "/mes" : "";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= titulo %> — InmoVista</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.0/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.0/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        :root { --dorado: #c9a84c; --oscuro: #1a1a18; }
        body { background: #f0ede8; font-family: 'Segoe UI', sans-serif; }
        .navbar { background: var(--oscuro) !important; }
        .navbar-brand span { color: var(--dorado); }
        .btn-dorado { background: var(--dorado); color: white; border: none; }
        .btn-dorado:hover { background: #b8962e; color: white; }
        .hero-img { width: 100%; height: 420px; object-fit: cover; border-radius: 16px; }
        .hero-placeholder { width: 100%; height: 420px; background: #e8e4dd; border-radius: 16px; display: flex; align-items: center; justify-content: center; color: #aaa; font-size: 4rem; }
        .thumb { width: 100%; height: 90px; object-fit: cover; border-radius: 8px; cursor: pointer; border: 2px solid transparent; transition: border .2s; }
        .thumb.active, .thumb:hover { border-color: var(--dorado); }
        .info-card { background: white; border-radius: 16px; padding: 2rem; box-shadow: 0 2px 12px rgba(0,0,0,.08); }
        .badge-tipo { background: var(--oscuro); color: white; padding: .4rem .9rem; border-radius: 20px; font-size: .8rem; }
        .badge-op  { background: var(--dorado);  color: white; padding: .4rem .9rem; border-radius: 20px; font-size: .8rem; }
        .feature-item { display: flex; align-items: center; gap: .5rem; padding: .5rem 0; border-bottom: 1px solid #f0ede8; font-size: .9rem; }
        .feature-item i { color: var(--dorado); width: 20px; }
        .cita-card { background: white; border-radius: 16px; padding: 1.5rem; box-shadow: 0 2px 12px rgba(0,0,0,.08); border-top: 4px solid var(--dorado); }
        .precio { font-size: 2rem; font-weight: 700; color: var(--dorado); }
    </style>
</head>
<body>
<nav class="navbar navbar-dark sticky-top px-4">
    <a class="navbar-brand fw-bold" href="<%= request.getContextPath() %>/">Inmo<span>Vista</span></a>
    <div class="d-flex gap-2">
        <a href="<%= request.getContextPath() %>/propiedades" class="btn btn-outline-light btn-sm"><i class="bi bi-arrow-left me-1"></i>Volver</a>
        <% if (logueado) { %>
        <a href="<%= request.getContextPath() + usuario.getDashboardUrl() %>" class="btn btn-sm btn-dorado">Mi Panel</a>
        <% } else { %>
        <a href="<%= request.getContextPath() %>/login" class="btn btn-sm btn-dorado">Iniciar Sesión</a>
        <% } %>
    </div>
</nav>

<div class="container py-4">
    <% if (errorMsg != null) { %><div class="alert alert-warning">Debug: <%= errorMsg %></div><% } %>
    <% if (msgCita != null) { %><div class="alert alert-success alert-dismissible fade show"><i class="bi bi-check-circle me-2"></i><%= msgCita.replace("+"," ") %><button type="button" class="btn-close" data-bs-dismiss="alert"></button></div><% } %>
    <% if (errCita != null) { %><div class="alert alert-danger alert-dismissible fade show"><i class="bi bi-exclamation-circle me-2"></i><%= errCita.replace("+"," ") %><button type="button" class="btn-close" data-bs-dismiss="alert"></button></div><% } %>

    <div class="row g-4">
        <div class="col-lg-8">
            <% if (!fotoPortada.isEmpty()) { %>
            <img id="fotoMain" src="<%= fotoPortada %>" class="hero-img mb-3" alt="<%= titulo %>">
            <% } else { %>
            <div class="hero-placeholder mb-3"><i class="bi bi-building"></i></div>
            <% } %>

            <% if (fotos.size() > 1) { %>
            <div class="row g-2 mb-3">
                <% for (int fi=0; fi<fotos.size(); fi++) { String[] f = fotos.get(fi); %>
                <div class="col-3">
                    <img src="<%= f[0] %>" class="thumb <%= fi==0?"active":"" %>"
                         onclick="cambiarFoto(this,'<%= f[0] %>')" alt="<%= f[1] %>">
                </div>
                <% } %>
            </div>
            <% } %>

            <div class="info-card mb-4">
                <div class="d-flex flex-wrap gap-2 mb-2">
                    <span class="badge-tipo"><%= tipo %></span>
                    <span class="badge-op"><%= operacion %></span>
                    <% if ("true".equals(destacado)) { %><span class="badge bg-warning text-dark">⭐ Destacado</span><% } %>
                </div>
                <h1 class="fw-bold mb-1" style="font-size:1.6rem;"><%= titulo %></h1>
                <p class="text-muted mb-2"><i class="bi bi-geo-alt me-1"></i><%= direccion %><% if (!barrio.isEmpty()) { %>, <%= barrio %><% } %><% if (!ciudadNombre.isEmpty()) { %> — <%= ciudadNombre %><% } %></p>
                <div class="precio mb-3">$<%= precio %> <small class="text-muted fs-6"><%= sufijoPrecio %></small></div>
                <p style="color:#555; line-height:1.7;"><%= descripcion %></p>
            </div>

            <div class="info-card">
                <h5 class="fw-bold mb-3">Características</h5>
                <div class="row">
                    <div class="col-md-6">
                        <% if (habitaciones > 0) { %><div class="feature-item"><i class="bi bi-door-open"></i><span><strong><%= habitaciones %></strong> Habitaciones</span></div><% } %>
                        <% if (banos > 0) { %><div class="feature-item"><i class="bi bi-droplet"></i><span><strong><%= banos %></strong> Baños</span></div><% } %>
                        <% if (parqueaderos > 0) { %><div class="feature-item"><i class="bi bi-car-front"></i><span><strong><%= parqueaderos %></strong> Parqueaderos</span></div><% } %>
                    </div>
                    <div class="col-md-6">
                        <% if (!area.isEmpty()) { %><div class="feature-item"><i class="bi bi-rulers"></i><span><strong><%= area %></strong> m²</span></div><% } %>
                        <% if (!estrato.isEmpty()) { %><div class="feature-item"><i class="bi bi-layers"></i><span>Estrato <strong><%= estrato %></strong></span></div><% } %>
                        <div class="feature-item"><i class="bi bi-check-circle"></i><span>Estado: <strong><%= estado %></strong></span></div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-lg-4">
            <div class="cita-card sticky-top" style="top:80px;" id="cita">
                <h5 class="fw-bold mb-1">¿Te interesa esta propiedad?</h5>
                <p class="text-muted small mb-3">Agenda una visita con el agente</p>
                <% if ("DISPONIBLE".equals(estado)) { %>
                    <% if (esCliente) { %>
                    <!-- debug: propId=<%= propId %> -->
                    <form method="post" action="<%= request.getContextPath() %>/citas">
                        <input type="hidden" name="propiedadId" value="<%= propId %>">
                        <div class="mb-3">
                            <label class="form-label small fw-semibold">Fecha y hora</label>
                            <input type="datetime-local" name="fechaHora" class="form-control" required
                                   min="<%= new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm").format(new java.util.Date()) %>">
                        </div>
                        <div class="mb-3">
                            <label class="form-label small fw-semibold">Mensaje (opcional)</label>
                            <textarea name="mensaje" class="form-control" rows="3" placeholder="Alguna pregunta o comentario..."></textarea>
                        </div>
                        <button type="submit" class="btn btn-dorado w-100"><i class="bi bi-calendar-check me-2"></i>Agendar Visita</button>
                    </form>
                    <% } else if (logueado) { %>
                    <div class="alert alert-info small">Solo los clientes pueden agendar citas.</div>
                    <% } else { %>
                    <p class="text-muted small mb-3">Inicia sesión para agendar una visita.</p>
                    <a href="<%= request.getContextPath() %>/login" class="btn btn-dorado w-100 mb-2"><i class="bi bi-box-arrow-in-right me-2"></i>Iniciar Sesión</a>
                    <a href="<%= request.getContextPath() %>/register" class="btn btn-outline-secondary w-100">Crear cuenta gratis</a>
                    <% } %>
                <% } else { %>
                <div class="alert alert-secondary text-center"><i class="bi bi-x-circle me-2"></i>Esta propiedad no está disponible.</div>
                <% } %>
                <hr>
                <div class="text-center"><small class="text-muted">Ref. #<%= propId %></small></div>
            </div>
        </div>
    </div>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.0/js/bootstrap.bundle.min.js"></script>
<script>
function cambiarFoto(el, url) {
    document.getElementById('fotoMain').src = url;
    document.querySelectorAll('.thumb').forEach(t => t.classList.remove('active'));
    el.classList.add('active');
}
</script>
</body>
</html>
