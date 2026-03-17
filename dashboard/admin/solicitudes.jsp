<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    Usuario usuario = (Usuario) session.getAttribute("usuario");
    if (usuario == null || !usuario.isAdmin()) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
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
                "SELECT s.id, s.tipo_operacion, s.estado, s.observaciones, s.created_at, " +
                "p.titulo, p.id AS pid, " +
                "uc.nombre AS cnombre, uc.apellido AS capellido, " +
                "ui.nombre AS inombre, ui.apellido AS iapellido " +
                "FROM solicitudes_documentos s " +
                "JOIN propiedades p ON s.propiedad_id=p.id " +
                "JOIN usuarios uc ON s.cliente_id=uc.id " +
                "JOIN usuarios ui ON p.inmobiliaria_id=ui.id");
            if (!filtro.isEmpty()) sql.append(" WHERE s.estado=?");
            sql.append(" ORDER BY s.id DESC");
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            if (!filtro.isEmpty()) ps.setString(1, filtro);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                String fecha = rs.getString("created_at") != null ? rs.getString("created_at").substring(0,10) : "";
                solicitudes.add(new String[]{
                    String.valueOf(rs.getInt("id")),
                    rs.getString("tipo_operacion"),
                    rs.getString("estado"),
                    rs.getString("observaciones") != null ? rs.getString("observaciones") : "",
                    fecha,
                    rs.getString("titulo"),
                    String.valueOf(rs.getInt("pid")),
                    rs.getString("cnombre") + " " + rs.getString("capellido"),
                    rs.getString("inombre") + " " + rs.getString("iapellido")
                });
            }
            rs.close(); ps.close();
        } finally { conn.close(); }
    } catch (Exception e) { /* continuar */ }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"/>
    <title>Solicitudes — InmoVista Admin</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.0/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.0/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        :root{--dark:#1A1A18;--gold:#C9A84C;--muted:#6B6455;--white:#FFFFFF;--sidebar:220px;}
        body{font-family:'DM Sans',sans-serif;background:#F0EBE1;display:flex;min-height:100vh;}
        .sidebar{width:var(--sidebar);background:var(--dark);display:flex;flex-direction:column;position:fixed;top:0;left:0;bottom:0;z-index:50;}
        .sidebar-logo{padding:28px 24px 20px;font-family:'Cormorant Garamond',serif;font-size:22px;font-weight:700;color:var(--white);text-decoration:none;display:block;border-bottom:1px solid rgba(255,255,255,.06);}
        .sidebar-logo span{color:var(--gold);}
        .sidebar-role{padding:12px 24px 20px;font-size:11px;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.3);border-bottom:1px solid rgba(255,255,255,.06);}
        .sidebar-nav{flex:1;padding:16px 0;}
        .nav-section{padding:16px 24px 8px;font-size:10px;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.2);}
        .nav-item{display:flex;align-items:center;gap:12px;padding:10px 24px;color:rgba(255,255,255,.55);text-decoration:none;font-size:14px;transition:all .2s;position:relative;}
        .nav-item:hover{color:var(--white);background:rgba(255,255,255,.04);}
        .nav-item.active{color:var(--gold);background:rgba(201,168,76,.08);}
        .nav-item.active::before{content:'';position:absolute;left:0;top:0;bottom:0;width:3px;background:var(--gold);border-radius:0 2px 2px 0;}
        .sidebar-footer{padding:20px 24px;border-top:1px solid rgba(255,255,255,.06);}
        .logout-btn{display:flex;align-items:center;gap:10px;color:rgba(255,255,255,.4);text-decoration:none;font-size:13px;}
        .logout-btn:hover{color:#e05555;}
        .main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;}
        .topbar{background:var(--white);padding:16px 36px;display:flex;justify-content:space-between;align-items:center;border-bottom:1px solid rgba(0,0,0,.06);position:sticky;top:0;z-index:40;}
        .topbar-title{font-family:'Cormorant Garamond',serif;font-size:22px;font-weight:600;color:var(--dark);}
        .avatar{width:36px;height:36px;border-radius:50%;background:var(--gold);display:flex;align-items:center;justify-content:center;font-weight:600;font-size:14px;color:var(--dark);}
        .content{padding:32px 36px;flex:1;}
        .card{background:var(--white);border-radius:8px;border:1px solid rgba(0,0,0,.06);overflow:hidden;}
        .btn-dorado{background:var(--gold);color:white;border:none;}
        .btn-dorado:hover{background:#b8962e;color:white;}
        .badge{display:inline-block;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:500;}
        .badge-gold{background:rgba(201,168,76,.12);color:#a07d2a;}
        .badge-green{background:rgba(76,175,80,.12);color:#2e7d32;}
        .badge-red{background:rgba(220,53,69,.12);color:#dc3545;}
        .badge-blue{background:rgba(74,144,217,.12);color:#1a5fa0;}
    </style>
</head>
<body>
<aside class="sidebar">
    <a href="<%= request.getContextPath() %>/" class="sidebar-logo">Inmo<span>Vista</span></a>
    <div class="sidebar-role">Administrador</div>
    <nav class="sidebar-nav">
        <div class="nav-section">Principal</div>
        <a href="index.jsp" class="nav-item"><i class="bi bi-grid"></i> Dashboard</a>
        <a href="<%= request.getContextPath() %>/propiedades" class="nav-item"><i class="bi bi-building"></i> Propiedades</a>
        <div class="nav-section">Gestión</div>
        <a href="usuarios.jsp" class="nav-item"><i class="bi bi-people"></i> Usuarios</a>
        <a href="citas.jsp" class="nav-item"><i class="bi bi-calendar-check"></i> Citas</a>
        <a href="solicitudes.jsp" class="nav-item active"><i class="bi bi-file-earmark-text"></i> Solicitudes</a>
        <a href="transacciones.jsp" class="nav-item"><i class="bi bi-cash-coin"></i> Transacciones</a>
    </nav>
    <div class="sidebar-footer">
        <a href="<%= request.getContextPath() %>/logout" class="logout-btn"><i class="bi bi-box-arrow-left"></i> Cerrar sesión</a>
    </div>
</aside>

<div class="main">
    <div class="topbar">
        <span class="topbar-title">Gestión de Solicitudes</span>
        <div style="display:flex;align-items:center;gap:16px;">
            <div style="text-align:right;">
                <div style="font-size:14px;font-weight:500;color:var(--dark);"><%= usuario.getNombreCompleto() %></div>
                <div style="font-size:11px;color:var(--muted);">Administrador</div>
            </div>
            <div class="avatar"><%= usuario.getNombre().charAt(0) %><%= usuario.getApellido().charAt(0) %></div>
        </div>
    </div>

    <div class="content">
        <!-- Filtros -->
        <div class="card mb-3 p-3">
            <div class="d-flex gap-2 flex-wrap align-items-center">
                <span class="text-muted small fw-semibold">Filtrar:</span>
                <a href="solicitudes.jsp" class="btn btn-sm <%= filtro.isEmpty()?"btn-dorado":"btn-outline-secondary" %>">Todas (<%= solicitudes.size() %>)</a>
                <a href="solicitudes.jsp?estado=PENDIENTE" class="btn btn-sm <%= "PENDIENTE".equals(filtro)?"btn-warning":"btn-outline-warning" %>">Pendientes</a>
                <a href="solicitudes.jsp?estado=EN_REVISION" class="btn btn-sm <%= "EN_REVISION".equals(filtro)?"btn-info":"btn-outline-info" %>">En revisión</a>
                <a href="solicitudes.jsp?estado=APROBADO" class="btn btn-sm <%= "APROBADO".equals(filtro)?"btn-success":"btn-outline-success" %>">Aprobadas</a>
                <a href="solicitudes.jsp?estado=RECHAZADO" class="btn btn-sm <%= "RECHAZADO".equals(filtro)?"btn-danger":"btn-outline-danger" %>">Rechazadas</a>
            </div>
        </div>

        <div class="card">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr class="text-muted small">
                        <th>#</th>
                        <th>Cliente</th>
                        <th>Propiedad</th>
                        <th>Inmobiliaria</th>
                        <th>Tipo</th>
                        <th>Fecha</th>
                        <th>Observaciones</th>
                        <th>Estado</th>
                    </tr>
                </thead>
                <tbody>
                <% if (solicitudes.isEmpty()) { %>
                <tr><td colspan="8" class="text-center text-muted py-4">No hay solicitudes.</td></tr>
                <% } else { for (String[] s : solicitudes) {
                    String est = s[2];
                    String bc = "APROBADO".equals(est)?"badge-green":"RECHAZADO".equals(est)?"badge-red":"EN_REVISION".equals(est)?"badge-blue":"badge-gold";
                %>
                <tr>
                    <td><small class="text-muted">#<%= s[0] %></small></td>
                    <td><div class="fw-semibold small"><%= s[7] %></div></td>
                    <td><a href="<%= request.getContextPath() %>/propiedades?id=<%= s[6] %>" class="text-decoration-none small"><%= s[5] %></a></td>
                    <td><small><%= s[8] %></small></td>
                    <td><small><%= s[1] %></small></td>
                    <td><small><%= s[4] %></small></td>
                    <td><small class="text-muted"><%= s[3].length()>40?s[3].substring(0,40)+"...":s[3].isEmpty()?"—":s[3] %></small></td>
                    <td><span class="badge <%= bc %>"><%= est.replace("_"," ") %></span></td>
                </tr>
                <% }} %>
                </tbody>
            </table>
        </div>
    </div>
</div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.0/js/bootstrap.bundle.min.js"></script>
</body>
</html>
