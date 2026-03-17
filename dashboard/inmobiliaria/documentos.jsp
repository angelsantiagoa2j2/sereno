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

    // Procesar aprobar/rechazar
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
                ps.setString(1, nuevoEstado);
                ps.setInt(2, uid);
                ps.setInt(3, Integer.parseInt(solId));
                ps.executeUpdate();
                ps.close(); conn.close();
            } catch (Exception e) { /* ignorar */ }
        }
        response.sendRedirect("documentos.jsp?msg=Solicitud+actualizada");
        return;
    }

    String filtro = request.getParameter("estado") != null ? request.getParameter("estado") : "";
    String msg    = request.getParameter("msg");

    List<String[]> solicitudes = new ArrayList<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
        try {
            StringBuilder sql = new StringBuilder(
                "SELECT sd.id, sd.tipo_operacion, sd.estado, sd.observaciones, sd.created_at, " +
                "p.titulo, u.nombre, u.apellido " +
                "FROM solicitudes_documentos sd " +
                "JOIN propiedades p ON sd.propiedad_id=p.id " +
                "JOIN usuarios u ON sd.cliente_id=u.id " +
                "WHERE p.inmobiliaria_id=?");
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
    <meta charset="UTF-8">
    <title>Documentos — InmoVista</title>
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
    </style>
</head>
<body>
<div class="sidebar">
    <div class="brand">Inmo<span>Vista</span></div>
    <nav class="mt-2">
        <div class="nav-section">Principal</div>
        <a href="index.jsp" class="nav-link"><i class="bi bi-grid"></i> Inicio</a>
        <a href="mis-propiedades.jsp" class="nav-link"><i class="bi bi-building"></i> Mis Propiedades</a>
        <div class="nav-section">Gestión</div>
        <a href="solicitudes.jsp" class="nav-link"><i class="bi bi-calendar-check"></i> Citas / Visitas</a>
        <a href="documentos.jsp" class="nav-link active"><i class="bi bi-file-earmark-check"></i> Documentos</a>
        <div class="nav-section">Reportes</div>
        <a href="reportes.jsp" class="nav-link"><i class="bi bi-bar-chart"></i> Reportes</a>
        <div class="nav-section">Cuenta</div>
        <a href="<%= request.getContextPath() %>/logout" class="nav-link"><i class="bi bi-box-arrow-left"></i> Cerrar sesión</a>
    </nav>
</div>

<div class="main">
    <div class="topbar">
        <div>
            <h5 class="mb-0 fw-bold">Documentos</h5>
            <small class="text-muted">Aprueba o rechaza solicitudes de clientes</small>
        </div>
        <span class="badge bg-secondary"><%= solicitudes.size() %> solicitudes</span>
    </div>

    <% if (msg != null) { %>
    <div class="alert alert-success alert-dismissible fade show mb-3">
        <i class="bi bi-check-circle me-2"></i><%= msg.replace("+"," ") %>
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
    <% } %>

    <!-- Filtros -->
    <div class="card-section mb-3">
        <div class="d-flex gap-2 flex-wrap">
            <a href="documentos.jsp" class="btn btn-sm <%= filtro.isEmpty()?"btn-dorado":"btn-outline-secondary" %>">Todos</a>
            <a href="documentos.jsp?estado=PENDIENTE" class="btn btn-sm <%= "PENDIENTE".equals(filtro)?"btn-warning":"btn-outline-warning" %>">Pendientes</a>
            <a href="documentos.jsp?estado=EN_REVISION" class="btn btn-sm <%= "EN_REVISION".equals(filtro)?"btn-info":"btn-outline-info" %>">En revisión</a>
            <a href="documentos.jsp?estado=APROBADO" class="btn btn-sm <%= "APROBADO".equals(filtro)?"btn-success":"btn-outline-success" %>">Aprobados</a>
            <a href="documentos.jsp?estado=RECHAZADO" class="btn btn-sm <%= "RECHAZADO".equals(filtro)?"btn-danger":"btn-outline-danger" %>">Rechazados</a>
        </div>
    </div>

    <!-- Tabla -->
    <div class="card-section">
        <table class="table table-hover align-middle">
            <thead>
                <tr class="text-muted small">
                    <th>#</th>
                    <th>Cliente</th>
                    <th>Propiedad</th>
                    <th>Tipo</th>
                    <th>Fecha</th>
                    <th>Observaciones</th>
                    <th>Estado</th>
                    <th>Acciones</th>
                </tr>
            </thead>
            <tbody>
            <% if (solicitudes.isEmpty()) { %>
                <tr><td colspan="8" class="text-center text-muted py-4">No hay solicitudes aún.</td></tr>
            <% } else { for (String[] s : solicitudes) {
                String est = s[2];
                String bc = "PENDIENTE".equals(est) ? "warning text-dark" :
                            "APROBADO".equals(est) ? "success" :
                            "RECHAZADO".equals(est) ? "danger" : "info";
            %>
                <tr>
                    <td><small class="text-muted">#<%= s[0] %></small></td>
                    <td><div class="fw-semibold small"><%= s[6] %></div></td>
                    <td><small><%= s[5] %></small></td>
                    <td><small><%= s[1] %></small></td>
                    <td><small><%= s[4] %></small></td>
                    <td><small class="text-muted"><%= s[3].isEmpty() ? "—" : s[3] %></small></td>
                    <td><span class="badge bg-<%= bc %>"><%= est.replace("_"," ") %></span></td>
                    <td>
                        <% if ("PENDIENTE".equals(est) || "EN_REVISION".equals(est)) { %>
                        <a href="documentos.jsp?action=aprobar&id=<%= s[0] %>" class="btn btn-sm btn-success me-1">
                            <i class="bi bi-check-lg"></i> Aprobar
                        </a>
                        <a href="documentos.jsp?action=rechazar&id=<%= s[0] %>" class="btn btn-sm btn-outline-danger">
                            <i class="bi bi-x-lg"></i> Rechazar
                        </a>
                        <% } else { %>
                        <span class="text-muted small">—</span>
                        <% } %>
                    </td>
                </tr>
            <% }} %>
            </tbody>
        </table>
    </div>
</div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.0/js/bootstrap.bundle.min.js"></script>
</body>
</html>
