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
    String filtroEstado = request.getParameter("estado") != null ? request.getParameter("estado") : "";
    String msg = request.getParameter("msg");

    List<String[]> propiedades = new ArrayList<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
        try {
            String sql = "SELECT p.id, p.titulo, p.tipo, p.operacion, p.precio, p.area_m2, p.estado, " +
                         "(SELECT url FROM propiedad_fotos WHERE propiedad_id=p.id AND es_portada=1 LIMIT 1) as foto " +
                         "FROM propiedades p WHERE p.inmobiliaria_id=? AND p.estado != 'INACTIVO'";
            if (!filtroEstado.isEmpty()) sql += " AND p.estado=?";
            sql += " ORDER BY p.id DESC";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, uid);
            if (!filtroEstado.isEmpty()) ps.setString(2, filtroEstado);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                propiedades.add(new String[]{
                    String.valueOf(rs.getInt("id")),
                    rs.getString("titulo"),
                    rs.getString("tipo"),
                    rs.getString("operacion"),
                    String.format("%,.0f", rs.getDouble("precio")),
                    rs.getObject("area_m2") != null ? String.valueOf(rs.getDouble("area_m2")) : "0",
                    rs.getString("estado"),
                    rs.getString("foto") != null ? rs.getString("foto") : ""
                });
            }
            rs.close(); ps.close();
        } finally { conn.close(); }
    } catch (Exception e) { /* continuar */ }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Mis Propiedades — InmoVista</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.0/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.0/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        :root { --dorado: #c9a84c; --oscuro: #1a1a18; }
        body { background: #f0ede8; font-family: 'Segoe UI', sans-serif; }
        .sidebar { width: 240px; min-height: 100vh; background: var(--oscuro); position: fixed; top: 0; left: 0; z-index: 100; overflow-y: auto; }
        .sidebar .brand { color: white; font-size: 1.3rem; padding: 1.5rem; border-bottom: 1px solid #333; }
        .sidebar .brand span { color: var(--dorado); }
        .sidebar .nav-link { color: #aaa; padding: .65rem 1.5rem; display: flex; align-items: center; gap: .75rem; transition: all .2s; border-left: 3px solid transparent; font-size: .9rem; }
        .sidebar .nav-link:hover, .sidebar .nav-link.active { color: white; background: rgba(201,168,76,.1); border-left-color: var(--dorado); }
        .sidebar .nav-section { color: #555; font-size: .7rem; text-transform: uppercase; letter-spacing: 1px; padding: 1rem 1.5rem .3rem; }
        .main { margin-left: 240px; padding: 2rem; }
        .topbar { background: white; border-radius: 12px; padding: 1rem 1.5rem; margin-bottom: 2rem; display: flex; justify-content: space-between; align-items: center; box-shadow: 0 2px 8px rgba(0,0,0,.06); }
        .card-section { background: white; border-radius: 12px; padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,.06); }
        .btn-dorado { background: var(--dorado); color: white; border: none; }
        .btn-dorado:hover { background: #b8962e; color: white; }
        .prop-card { border: 1px solid #e8e4dd; border-radius: 10px; overflow: hidden; background: white; transition: box-shadow .2s; }
        .prop-card:hover { box-shadow: 0 4px 16px rgba(0,0,0,.1); }
        .prop-img { width: 100%; height: 160px; object-fit: cover; }
        .prop-img-placeholder { width: 100%; height: 160px; background: #e8e4dd; display: flex; align-items: center; justify-content: center; color: #aaa; font-size: 2.5rem; }
    </style>
</head>
<body>
<div class="sidebar">
    <div class="brand">Inmo<span>Vista</span></div>
    <nav class="mt-2">
        <div class="nav-section">Principal</div>
        <a href="index.jsp" class="nav-link"><i class="bi bi-grid"></i> Inicio</a>
        <a href="mis-propiedades.jsp" class="nav-link active"><i class="bi bi-building"></i> Mis Propiedades</a>
        <div class="nav-section">Gestión</div>
        <a href="solicitudes.jsp" class="nav-link"><i class="bi bi-calendar-check"></i> Citas / Visitas</a>
        <a href="documentos.jsp" class="nav-link"><i class="bi bi-file-earmark-check"></i> Documentos</a>
        <div class="nav-section">Reportes</div>
        <a href="reportes.jsp" class="nav-link"><i class="bi bi-bar-chart"></i> Reportes</a>
        <div class="nav-section">Cuenta</div>
        <a href="<%= request.getContextPath() %>/logout" class="nav-link"><i class="bi bi-box-arrow-left"></i> Cerrar sesión</a>
    </nav>
</div>
<div class="main">
    <div class="topbar">
        <div><h5 class="mb-0 fw-bold">Mis Propiedades</h5><small class="text-muted">Gestiona tu portafolio inmobiliario</small></div>
        <a href="<%= request.getContextPath() %>/propiedades?action=form" class="btn btn-dorado"><i class="bi bi-plus-lg me-1"></i> Nueva Propiedad</a>
    </div>

    <% if (msg != null) { %>
    <div class="alert alert-success alert-dismissible fade show mb-3"><%= msg.replace("+"," ") %><button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>
    <% } %>

    <div class="card-section mb-3">
        <form method="get" class="row g-2 align-items-end">
            <div class="col-md-3">
                <label class="form-label small fw-semibold">Filtrar por estado</label>
                <select name="estado" class="form-select form-select-sm">
                    <option value="">Todos</option>
                    <option value="DISPONIBLE" <%= "DISPONIBLE".equals(filtroEstado)?"selected":"" %>>Disponible</option>
                    <option value="ARRENDADO"  <%= "ARRENDADO".equals(filtroEstado)?"selected":"" %>>Arrendado</option>
                    <option value="VENDIDO"    <%= "VENDIDO".equals(filtroEstado)?"selected":"" %>>Vendido</option>
                    <option value="RESERVADO"  <%= "RESERVADO".equals(filtroEstado)?"selected":"" %>>Reservado</option>
                </select>
            </div>
            <div class="col-md-2">
                <button type="submit" class="btn btn-sm btn-dorado">Filtrar</button>
                <a href="mis-propiedades.jsp" class="btn btn-sm btn-outline-secondary">Limpiar</a>
            </div>
        </form>
    </div>

    <div class="row g-3">
    <% if (propiedades.isEmpty()) { %>
        <div class="col-12 text-center py-5">
            <i class="bi bi-building" style="font-size:3rem;color:#ccc;"></i>
            <p class="text-muted mt-2">No tienes propiedades aún.</p>
            <a href="<%= request.getContextPath() %>/propiedades?action=form" class="btn btn-dorado">Agregar primera propiedad</a>
        </div>
    <% } else { for (String[] p : propiedades) {
        String est = p[6];
        String bc = "DISPONIBLE".equals(est)?"success":"ARRENDADO".equals(est)?"primary":"VENDIDO".equals(est)?"secondary":"warning text-dark";
        String foto = p[7]; %>
        <div class="col-md-4">
            <div class="prop-card">
                <% if (!foto.isEmpty()) { %>
                <img src="<%= foto %>" class="prop-img" alt="<%= p[1] %>">
                <% } else { %>
                <div class="prop-img-placeholder"><i class="bi bi-building"></i></div>
                <% } %>
                <div class="p-3">
                    <div class="d-flex justify-content-between align-items-start mb-1">
                        <h6 class="mb-0 fw-bold" style="font-size:.9rem;"><%= p[1] %></h6>
                        <span class="badge bg-<%= bc %>" style="font-size:.7rem;"><%= est %></span>
                    </div>
                    <div class="text-muted small mb-2"><%= p[2] %> · <%= p[3] %> · <%= p[5] %>m²</div>
                    <div class="fw-bold mb-3" style="color:var(--dorado);">$<%= p[4] %></div>
                    <div class="d-flex gap-2 flex-wrap">
                        <a href="<%= request.getContextPath() %>/propiedades?action=form&id=<%= p[0] %>" class="btn btn-sm btn-outline-secondary flex-fill"><i class="bi bi-pencil"></i> Editar</a>
                        <% if ("DISPONIBLE".equals(est)) { %>
                        <button onclick="cerrarNegocio('<%= p[0] %>')" class="btn btn-sm btn-dorado flex-fill"><i class="bi bi-handshake"></i> Cerrar</button>
                        <% } %>
                        <button onclick="confirmarEliminar('<%= p[0] %>','<%= p[1].replace("'","") %>')" class="btn btn-sm btn-outline-danger"><i class="bi bi-trash"></i></button>
                    </div>
                </div>
            </div>
        </div>
    <% }} %>
    </div>
</div>

<!-- Modal Cerrar Negocio -->
<div class="modal fade" id="modalNegocio" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header"><h5 class="modal-title"><i class="bi bi-handshake me-2"></i>Cerrar Negocio</h5><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div>
            <form method="post" action="<%= request.getContextPath() %>/transacciones">
                <div class="modal-body">
                    <input type="hidden" name="propiedadId" id="negocioPropId">
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">ID del Cliente</label>
                        <input type="number" name="clienteId" class="form-control" required placeholder="ID del usuario cliente">
                        <small class="text-muted">Puedes verlo en el panel de admin</small>
                    </div>
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Tipo de operación</label>
                        <select name="tipo" class="form-select" required>
                            <option value="VENTA">Venta</option>
                            <option value="ARRIENDO">Arriendo</option>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Valor ($)</label>
                        <input type="number" name="valor" class="form-control" required placeholder="Ej: 350000000">
                    </div>
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Comisión ($)</label>
                        <input type="number" name="comision" class="form-control" placeholder="Opcional, dejar en 0 si no aplica">
                    </div>
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Fecha de cierre</label>
                        <input type="date" name="fechaCierre" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Notas (opcional)</label>
                        <textarea name="notas" class="form-control" rows="2" placeholder="Observaciones del negocio..."></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                    <button type="submit" class="btn btn-dorado"><i class="bi bi-check-lg me-1"></i>Registrar negocio</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Modal Eliminar -->
<div class="modal fade" id="modalEliminar" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header"><h5 class="modal-title">Confirmar eliminación</h5><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div>
            <div class="modal-body"><p>¿Eliminar <strong id="nombreProp"></strong>?</p></div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                <form method="post" action="<%= request.getContextPath() %>/propiedades">
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="id" id="idPropEliminar">
                    <button type="submit" class="btn btn-danger">Eliminar</button>
                </form>
            </div>
        </div>
    </div>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.0/js/bootstrap.bundle.min.js"></script>
<script>
function confirmarEliminar(id, nombre) {
    document.getElementById('idPropEliminar').value = id;
    document.getElementById('nombreProp').textContent = nombre;
    new bootstrap.Modal(document.getElementById('modalEliminar')).show();
}
function cerrarNegocio(id) {
    document.getElementById('negocioPropId').value = id;
    new bootstrap.Modal(document.getElementById('modalNegocio')).show();
}
</script>
</body>
</html>
