<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%@ page import="com.inmovista.db.DBManager" %>
<%@ page import="java.sql.*" %>
<%
    Usuario usuario = (Usuario) session.getAttribute("usuario");
    if (usuario == null || (!usuario.isInmobiliaria() && !usuario.isAdmin())) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }
    int uid = usuario.getId();
    int totalPropiedades = 0, propDisponibles = 0, propArrendadas = 0, propVendidas = 0;
    int citasPendientes = 0, citasHoy = 0, docsPendientes = 0;
    java.util.List<String[]> propsRecientes = new java.util.ArrayList<>();
    java.util.List<String[]> citasRecientes = new java.util.ArrayList<>();

    try (Connection conn = DBManager.getConnection("cloud")) {
        // Stats propiedades
        try (PreparedStatement ps = conn.prepareStatement(
            "SELECT estado, COUNT(*) as cnt FROM propiedades WHERE inmobiliaria_id=? GROUP BY estado")) {
            ps.setInt(1, uid); ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                int cnt = rs.getInt("cnt"); totalPropiedades += cnt;
                String est = rs.getString("estado");
                if ("DISPONIBLE".equals(est)) propDisponibles += cnt;
                else if ("ARRENDADO".equals(est)) propArrendadas += cnt;
                else if ("VENDIDO".equals(est)) propVendidas += cnt;
            }
        }
        // Citas pendientes
        try (PreparedStatement ps = conn.prepareStatement(
            "SELECT COUNT(*) FROM citas c JOIN propiedades p ON c.propiedad_id=p.id WHERE p.inmobiliaria_id=? AND c.estado='PENDIENTE'")) {
            ps.setInt(1, uid); ResultSet rs = ps.executeQuery();
            if (rs.next()) citasPendientes = rs.getInt(1);
        }
        // Citas hoy
        try (PreparedStatement ps = conn.prepareStatement(
            "SELECT COUNT(*) FROM citas c JOIN propiedades p ON c.propiedad_id=p.id WHERE p.inmobiliaria_id=? AND DATE(c.fecha_hora)=CURDATE()")) {
            ps.setInt(1, uid); ResultSet rs = ps.executeQuery();
            if (rs.next()) citasHoy = rs.getInt(1);
        }
        // Docs pendientes
        try (PreparedStatement ps = conn.prepareStatement(
            "SELECT COUNT(*) FROM solicitudes_documentos sd JOIN propiedades p ON sd.propiedad_id=p.id WHERE p.inmobiliaria_id=? AND sd.estado='PENDIENTE'")) {
            ps.setInt(1, uid); ResultSet rs = ps.executeQuery();
            if (rs.next()) docsPendientes = rs.getInt(1);
        }
        // Propiedades recientes
        try (PreparedStatement ps = conn.prepareStatement(
            "SELECT id, titulo, tipo, operacion, precio, estado FROM propiedades WHERE inmobiliaria_id=? ORDER BY fecha_creacion DESC LIMIT 5")) {
            ps.setInt(1, uid); ResultSet rs = ps.executeQuery();
            while (rs.next()) propsRecientes.add(new String[]{
                String.valueOf(rs.getInt("id")), rs.getString("titulo"), rs.getString("tipo"),
                rs.getString("operacion"), String.format("%,.0f", rs.getDouble("precio")), rs.getString("estado")
            });
        }
        // Citas recientes
        try (PreparedStatement ps = conn.prepareStatement(
            "SELECT c.id, c.fecha_hora, c.estado, p.titulo, u.nombre, u.apellido FROM citas c " +
            "JOIN propiedades p ON c.propiedad_id=p.id JOIN usuarios u ON c.cliente_id=u.id " +
            "WHERE p.inmobiliaria_id=? ORDER BY c.fecha_hora DESC LIMIT 5")) {
            ps.setInt(1, uid); ResultSet rs = ps.executeQuery();
            while (rs.next()) citasRecientes.add(new String[]{
                String.valueOf(rs.getInt("id")),
                rs.getTimestamp("fecha_hora") != null ? rs.getTimestamp("fecha_hora").toString().substring(0,16) : "Sin fecha",
                rs.getString("estado"), rs.getString("titulo"),
                rs.getString("nombre") + " " + rs.getString("apellido")
            });
        }
    } catch (Exception e) { /* continuar con ceros */ }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Inmobiliaria — InmoVista</title>
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
        .stat-card { background: white; border-radius: 12px; padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,.06); border-left: 4px solid var(--dorado); }
        .stat-card .number { font-size: 2rem; font-weight: 700; color: var(--oscuro); }
        .stat-card .label { color: #888; font-size: .85rem; }
        .stat-card .icon { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 1.4rem; }
        .card-section { background: white; border-radius: 12px; padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,.06); margin-bottom: 1.5rem; }
        .btn-dorado { background: var(--dorado); color: white; border: none; }
        .btn-dorado:hover { background: #b8962e; color: white; }
        .alert-badge { background: #dc3545; color: white; border-radius: 50%; padding: 1px 6px; font-size: .7rem; margin-left: auto; }
    </style>
</head>
<body>
<div class="sidebar">
    <div class="brand">Inmo<span>Vista</span></div>
    <nav class="mt-2">
        <div class="nav-section">Principal</div>
        <a href="index.jsp" class="nav-link active"><i class="bi bi-grid"></i> Inicio</a>
        <a href="mis-propiedades.jsp" class="nav-link"><i class="bi bi-building"></i> Mis Propiedades <span class="alert-badge"><%= totalPropiedades %></span></a>
        <div class="nav-section">Gestión</div>
        <a href="solicitudes.jsp" class="nav-link"><i class="bi bi-calendar-check"></i> Citas / Visitas <% if(citasPendientes>0){%><span class="alert-badge"><%= citasPendientes %></span><%}%></a>
        <a href="documentos.jsp" class="nav-link"><i class="bi bi-file-earmark-check"></i> Documentos <% if(docsPendientes>0){%><span class="alert-badge"><%= docsPendientes %></span><%}%></a>
        <div class="nav-section">Reportes</div>
        <a href="reportes.jsp" class="nav-link"><i class="bi bi-bar-chart"></i> Reportes</a>
        <div class="nav-section">Cuenta</div>
        <a href="<%= request.getContextPath() %>/logout" class="nav-link"><i class="bi bi-box-arrow-left"></i> Cerrar sesión</a>
    </nav>
</div>
<div class="main">
    <div class="topbar">
        <div>
            <h5 class="mb-0 fw-bold">Mi Panel</h5>
            <small class="text-muted">Bienvenido, <%= usuario.getNombre() %></small>
        </div>
        <div class="d-flex align-items-center gap-3">
            <a href="<%= request.getContextPath() %>/propiedades?action=form" class="btn btn-dorado btn-sm"><i class="bi bi-plus-lg me-1"></i> Nueva Propiedad</a>
            <div class="d-flex align-items-center gap-2">
                <div style="width:36px;height:36px;border-radius:50%;background:var(--dorado);color:white;display:flex;align-items:center;justify-content:center;font-weight:700;"><%= usuario.getNombre().substring(0,1).toUpperCase() %></div>
                <div><div class="fw-semibold" style="font-size:.9rem;"><%= usuario.getNombreCompleto() %></div><div class="text-muted" style="font-size:.75rem;">Inmobiliaria</div></div>
            </div>
        </div>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-md-3"><div class="stat-card"><div class="d-flex justify-content-between"><div><div class="number"><%= totalPropiedades %></div><div class="label">Total Propiedades</div></div><div class="icon" style="background:#f0ede8;color:var(--dorado);"><i class="bi bi-building"></i></div></div></div></div>
        <div class="col-md-3"><div class="stat-card" style="border-left-color:#198754;"><div class="d-flex justify-content-between"><div><div class="number" style="color:#198754;"><%= propDisponibles %></div><div class="label">Disponibles</div></div><div class="icon" style="background:#d1e7dd;color:#198754;"><i class="bi bi-check-circle"></i></div></div></div></div>
        <div class="col-md-3"><div class="stat-card" style="border-left-color:#0d6efd;"><div class="d-flex justify-content-between"><div><div class="number" style="color:#0d6efd;"><%= citasPendientes %></div><div class="label">Citas Pendientes</div></div><div class="icon" style="background:#cfe2ff;color:#0d6efd;"><i class="bi bi-calendar-event"></i></div></div></div></div>
        <div class="col-md-3"><div class="stat-card" style="border-left-color:#dc3545;"><div class="d-flex justify-content-between"><div><div class="number" style="color:#dc3545;"><%= docsPendientes %></div><div class="label">Docs. Pendientes</div></div><div class="icon" style="background:#f8d7da;color:#dc3545;"><i class="bi bi-file-earmark-text"></i></div></div></div></div>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-md-8">
            <div class="card-section">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h6 class="mb-0 fw-bold">Mis Propiedades Recientes</h6>
                    <a href="mis-propiedades.jsp" class="btn btn-sm btn-outline-secondary">Ver todas</a>
                </div>
                <% if (propsRecientes.isEmpty()) { %>
                <p class="text-muted text-center py-3">No tienes propiedades. <a href="<%= request.getContextPath() %>/propiedades?action=form">Agregar una</a></p>
                <% } else { for (String[] p : propsRecientes) {
                    String est = p[5];
                    String bc = "DISPONIBLE".equals(est)?"success":"ARRENDADO".equals(est)?"primary":"VENDIDO".equals(est)?"secondary":"warning text-dark"; %>
                <div class="d-flex align-items-center justify-content-between py-2 border-bottom">
                    <div><div class="fw-semibold" style="font-size:.9rem;"><%= p[1] %></div><small class="text-muted"><%= p[2] %> · <%= p[3] %></small></div>
                    <div class="d-flex align-items-center gap-2">
                        <span class="fw-bold" style="font-size:.9rem;">$<%= p[4] %></span>
                        <span class="badge bg-<%= bc %>"><%= est %></span>
                        <a href="<%= request.getContextPath() %>/propiedades?action=form&id=<%= p[0] %>" class="btn btn-sm btn-outline-secondary py-0"><i class="bi bi-pencil"></i></a>
                    </div>
                </div>
                <% }} %>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card-section h-100">
                <h6 class="fw-bold mb-3">Resumen de Estado</h6>
                <div class="d-flex justify-content-between py-2 border-bottom"><span class="text-muted">Disponibles</span><span class="badge bg-success"><%= propDisponibles %></span></div>
                <div class="d-flex justify-content-between py-2 border-bottom"><span class="text-muted">Arrendadas</span><span class="badge bg-primary"><%= propArrendadas %></span></div>
                <div class="d-flex justify-content-between py-2 border-bottom"><span class="text-muted">Vendidas</span><span class="badge bg-secondary"><%= propVendidas %></span></div>
                <div class="d-flex justify-content-between py-2"><span class="text-muted">Citas hoy</span><span class="badge" style="background:var(--dorado);"><%= citasHoy %></span></div>
                <div class="mt-3"><a href="reportes.jsp" class="btn btn-dorado w-100 btn-sm"><i class="bi bi-bar-chart me-1"></i> Ver Reportes</a></div>
            </div>
        </div>
    </div>

    <div class="card-section">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h6 class="mb-0 fw-bold">Citas / Visitas Recientes</h6>
            <a href="solicitudes.jsp" class="btn btn-sm btn-outline-secondary">Ver todas</a>
        </div>
        <% if (citasRecientes.isEmpty()) { %>
        <p class="text-muted text-center py-3">No hay citas registradas aún.</p>
        <% } else { for (String[] c : citasRecientes) {
            String est = c[2];
            String bc = "PENDIENTE".equals(est)?"warning text-dark":"CONFIRMADA".equals(est)?"success":"CANCELADA".equals(est)?"danger":"secondary"; %>
        <div class="d-flex align-items-center justify-content-between py-2 border-bottom">
            <div><div class="fw-semibold" style="font-size:.9rem;"><%= c[4] %></div><small class="text-muted"><%= c[3] %></small></div>
            <div class="d-flex align-items-center gap-2">
                <small class="text-muted"><%= c[1] %></small>
                <span class="badge bg-<%= bc %>"><%= est %></span>
                <% if ("PENDIENTE".equals(est)) { %><a href="solicitudes.jsp?action=confirmar&id=<%= c[0] %>" class="btn btn-sm btn-success py-0" style="font-size:.75rem;">Confirmar</a><% } %>
            </div>
        </div>
        <% }} %>
    </div>
</div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.0/js/bootstrap.bundle.min.js"></script>
</body>
</html>
