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

    int totalVentas = 0, totalArriendos = 0, totalCitas = 0, totalPropiedades = 0;
    double totalIngresos = 0;
    List<String[]> topPropiedades = new ArrayList<>();
    List<String[]> porTipo = new ArrayList<>();

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
        try {
            // Total propiedades
            PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM propiedades WHERE inmobiliaria_id=? AND estado != 'INACTIVO'");
            ps.setInt(1, uid); ResultSet rs = ps.executeQuery();
            if (rs.next()) totalPropiedades = rs.getInt(1);
            rs.close(); ps.close();

            // Ventas y arriendos completados
            ps = conn.prepareStatement(
                "SELECT estado, COUNT(*) as cnt FROM propiedades WHERE inmobiliaria_id=? AND estado IN ('VENDIDO','ARRENDADO') GROUP BY estado");
            ps.setInt(1, uid); rs = ps.executeQuery();
            while (rs.next()) {
                String est = rs.getString("estado");
                if ("VENDIDO".equals(est)) totalVentas = rs.getInt("cnt");
                else if ("ARRENDADO".equals(est)) totalArriendos = rs.getInt("cnt");
            }
            rs.close(); ps.close();

            // Total citas
            ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM citas c JOIN propiedades p ON c.propiedad_id=p.id WHERE p.inmobiliaria_id=?");
            ps.setInt(1, uid); rs = ps.executeQuery();
            if (rs.next()) totalCitas = rs.getInt(1);
            rs.close(); ps.close();

            // Intentar obtener ingresos de transacciones
            try {
                ps = conn.prepareStatement(
                    "SELECT COALESCE(SUM(t.valor),0) FROM transacciones t JOIN propiedades p ON t.propiedad_id=p.id WHERE p.inmobiliaria_id=?");
                ps.setInt(1, uid); rs = ps.executeQuery();
                if (rs.next()) totalIngresos = rs.getDouble(1);
                rs.close(); ps.close();
            } catch (Exception ignored) {}

            // Propiedades por tipo
            ps = conn.prepareStatement(
                "SELECT tipo, COUNT(*) as cnt FROM propiedades WHERE inmobiliaria_id=? AND estado != 'INACTIVO' GROUP BY tipo ORDER BY cnt DESC");
            ps.setInt(1, uid); rs = ps.executeQuery();
            while (rs.next()) porTipo.add(new String[]{rs.getString("tipo"), String.valueOf(rs.getInt("cnt"))});
            rs.close(); ps.close();

            // Top propiedades con mas citas
            ps = conn.prepareStatement(
                "SELECT p.titulo, COUNT(c.id) as citas FROM propiedades p LEFT JOIN citas c ON p.id=c.propiedad_id " +
                "WHERE p.inmobiliaria_id=? GROUP BY p.id, p.titulo ORDER BY citas DESC LIMIT 5");
            ps.setInt(1, uid); rs = ps.executeQuery();
            while (rs.next()) topPropiedades.add(new String[]{rs.getString("titulo"), String.valueOf(rs.getInt("citas"))});
            rs.close(); ps.close();

        } finally { conn.close(); }
    } catch (Exception e) { /* continuar */ }

    int totalTipo = 0;
    for (String[] t : porTipo) totalTipo += Integer.parseInt(t[1]);
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reportes — InmoVista</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.0/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.0/font/bootstrap-icons.min.css" rel="stylesheet">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.0/chart.umd.min.js"></script>
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
        .card-section { background: white; border-radius: 12px; padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,.06); margin-bottom: 1.5rem; }
        .stat-card { background: white; border-radius: 12px; padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,.06); border-left: 4px solid var(--dorado); }
        .stat-card .number { font-size: 1.8rem; font-weight: 700; }
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
        <a href="documentos.jsp" class="nav-link"><i class="bi bi-file-earmark-check"></i> Documentos</a>
        <div class="nav-section">Reportes</div>
        <a href="reportes.jsp" class="nav-link active"><i class="bi bi-bar-chart"></i> Reportes</a>
        <div class="nav-section">Cuenta</div>
        <a href="<%= request.getContextPath() %>/logout" class="nav-link"><i class="bi bi-box-arrow-left"></i> Cerrar sesión</a>
    </nav>
</div>

<div class="main">
    <div class="topbar">
        <div><h5 class="mb-0 fw-bold">Reportes</h5><small class="text-muted">Resumen de tu portafolio</small></div>
        <button onclick="window.print()" class="btn btn-sm btn-outline-secondary"><i class="bi bi-printer me-1"></i> Imprimir</button>
    </div>

    <!-- Stats -->
    <div class="row g-3 mb-4">
        <div class="col-md-3">
            <div class="stat-card">
                <div class="number" style="color:var(--dorado);"><%= totalPropiedades %></div>
                <div class="text-muted small">Total propiedades</div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="stat-card" style="border-left-color:#198754;">
                <div class="number" style="color:#198754;"><%= totalVentas %></div>
                <div class="text-muted small">Propiedades vendidas</div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="stat-card" style="border-left-color:#0d6efd;">
                <div class="number" style="color:#0d6efd;"><%= totalArriendos %></div>
                <div class="text-muted small">Propiedades arrendadas</div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="stat-card" style="border-left-color:#fd7e14;">
                <div class="number" style="color:#fd7e14;"><%= totalCitas %></div>
                <div class="text-muted small">Total citas recibidas</div>
            </div>
        </div>
    </div>

    <div class="row g-3">
        <!-- Gráfico por tipo -->
        <div class="col-md-6">
            <div class="card-section">
                <h6 class="fw-bold mb-3">Propiedades por Tipo</h6>
                <% if (porTipo.isEmpty()) { %>
                <p class="text-muted text-center py-3">No hay propiedades aún.</p>
                <% } else { %>
                <canvas id="chartTipo" height="200"></canvas>
                <% } %>
            </div>
        </div>
        <!-- Top propiedades -->
        <div class="col-md-6">
            <div class="card-section">
                <h6 class="fw-bold mb-3">Top Propiedades con más Citas</h6>
                <% if (topPropiedades.isEmpty()) { %>
                <p class="text-muted text-center py-3">No hay citas registradas aún.</p>
                <% } else {
                    int maxCitas = Integer.parseInt(topPropiedades.get(0)[1]);
                    if (maxCitas == 0) maxCitas = 1;
                    for (String[] tp : topPropiedades) {
                        int citas = Integer.parseInt(tp[1]);
                        int pct = (citas * 100) / maxCitas;
                %>
                <div class="mb-3">
                    <div class="d-flex justify-content-between mb-1">
                        <small class="fw-semibold"><%= tp[0].length() > 35 ? tp[0].substring(0,35)+"..." : tp[0] %></small>
                        <small class="text-muted"><%= citas %> citas</small>
                    </div>
                    <div class="progress" style="height:8px;">
                        <div class="progress-bar" style="width:<%= pct %>%;background:var(--dorado);"></div>
                    </div>
                </div>
                <% }} %>
            </div>
        </div>
    </div>

    <!-- Tabla resumen -->
    <div class="card-section">
        <h6 class="fw-bold mb-3">Resumen por Tipo de Propiedad</h6>
        <% if (porTipo.isEmpty()) { %>
        <p class="text-muted text-center py-3">No hay datos aún.</p>
        <% } else { %>
        <table class="table table-sm">
            <thead><tr class="text-muted small"><th>Tipo</th><th>Cantidad</th><th>% del portafolio</th></tr></thead>
            <tbody>
            <% for (String[] t : porTipo) {
                int cnt = Integer.parseInt(t[1]);
                int pct = totalTipo > 0 ? (cnt * 100) / totalTipo : 0;
            %>
            <tr>
                <td><%= t[0] %></td>
                <td><span class="badge" style="background:var(--dorado);"><%= cnt %></span></td>
                <td>
                    <div class="d-flex align-items-center gap-2">
                        <div class="progress flex-fill" style="height:6px;">
                            <div class="progress-bar" style="width:<%= pct %>%;background:var(--dorado);"></div>
                        </div>
                        <small><%= pct %>%</small>
                    </div>
                </td>
            </tr>
            <% } %>
            </tbody>
        </table>
        <% } %>
    </div>
</div>

<script>
<% if (!porTipo.isEmpty()) { %>
const tipoLabels = [<% for(int i=0;i<porTipo.size();i++){%>'<%= porTipo.get(i)[0] %>'<%= i<porTipo.size()-1?",":"" %><% } %>];
const tipoData   = [<% for(int i=0;i<porTipo.size();i++){%><%= porTipo.get(i)[1] %><%= i<porTipo.size()-1?",":"" %><% } %>];
const colors = ['#c9a84c','#1a1a18','#198754','#0d6efd','#dc3545','#fd7e14','#6f42c1','#20c997'];
new Chart(document.getElementById('chartTipo'), {
    type: 'doughnut',
    data: { labels: tipoLabels, datasets: [{ data: tipoData, backgroundColor: colors, borderWidth: 2 }] },
    options: { responsive: true, plugins: { legend: { position: 'bottom' } } }
});
<% } %>
</script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.0/js/bootstrap.bundle.min.js"></script>
</body>
</html>
