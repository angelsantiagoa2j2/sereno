<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    Usuario usuario = (Usuario) session.getAttribute("usuario");
    if (usuario == null || !usuario.isAdmin()) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }

    int totalPropiedades=0, totalUsuarios=0, totalCitas=0, totalSolicitudes=0;
    List<String[]> usuariosRecientes = new ArrayList<>();
    List<String[]> citasRecientes = new ArrayList<>();

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
        try {
            PreparedStatement ps;
            ResultSet rs;

            // Stats
            ps = conn.prepareStatement("SELECT COUNT(*) FROM propiedades WHERE estado != 'INACTIVO'");
            rs = ps.executeQuery(); if (rs.next()) totalPropiedades = rs.getInt(1); rs.close(); ps.close();

            ps = conn.prepareStatement("SELECT COUNT(*) FROM usuarios WHERE activo=1");
            rs = ps.executeQuery(); if (rs.next()) totalUsuarios = rs.getInt(1); rs.close(); ps.close();

            ps = conn.prepareStatement("SELECT COUNT(*) FROM citas WHERE estado='PENDIENTE'");
            rs = ps.executeQuery(); if (rs.next()) totalCitas = rs.getInt(1); rs.close(); ps.close();

            ps = conn.prepareStatement("SELECT COUNT(*) FROM solicitudes_documentos WHERE estado='PENDIENTE'");
            rs = ps.executeQuery(); if (rs.next()) totalSolicitudes = rs.getInt(1); rs.close(); ps.close();

            // Usuarios recientes
            ps = conn.prepareStatement(
                "SELECT u.id, u.nombre, u.apellido, u.email, u.activo, r.nombre AS rol " +
                "FROM usuarios u JOIN roles r ON u.rol_id=r.id ORDER BY u.id DESC LIMIT 5");
            rs = ps.executeQuery();
            while (rs.next()) {
                usuariosRecientes.add(new String[]{
                    String.valueOf(rs.getInt("id")),
                    rs.getString("nombre") + " " + rs.getString("apellido"),
                    rs.getString("email"),
                    rs.getString("rol"),
                    rs.getBoolean("activo") ? "Activo" : "Inactivo"
                });
            }
            rs.close(); ps.close();

            // Citas recientes
            ps = conn.prepareStatement(
                "SELECT c.id, c.fecha_solicitada, c.estado, p.titulo, u.nombre, u.apellido " +
                "FROM citas c JOIN propiedades p ON c.propiedad_id=p.id JOIN usuarios u ON c.cliente_id=u.id " +
                "ORDER BY c.id DESC LIMIT 5");
            rs = ps.executeQuery();
            while (rs.next()) {
                String fecha = rs.getString("fecha_solicitada") != null ? rs.getString("fecha_solicitada").substring(0,10) : "";
                citasRecientes.add(new String[]{
                    String.valueOf(rs.getInt("id")),
                    rs.getString("nombre") + " " + rs.getString("apellido"),
                    rs.getString("titulo"),
                    fecha,
                    rs.getString("estado")
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
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>InmoVista — Panel Admin</title>
    <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@300;400;600;700&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet"/>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.0/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        *,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
        :root{--dark:#1A1A18;--gold:#C9A84C;--muted:#6B6455;--white:#FFFFFF;--sidebar:220px;--red:#e05555;--green:#4caf50;--blue:#4a90d9;}
        body{font-family:'DM Sans',sans-serif;background:#F0EBE1;display:flex;min-height:100vh;}
        .sidebar{width:var(--sidebar);background:var(--dark);display:flex;flex-direction:column;position:fixed;top:0;left:0;bottom:0;z-index:50;}
        .sidebar-logo{padding:28px 24px 20px;font-family:'Cormorant Garamond',serif;font-size:22px;font-weight:700;color:var(--white);text-decoration:none;display:block;border-bottom:1px solid rgba(255,255,255,.06);}
        .sidebar-logo span{color:var(--gold);}
        .sidebar-role{padding:12px 24px 20px;font-size:11px;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.3);border-bottom:1px solid rgba(255,255,255,.06);}
        .sidebar-nav{flex:1;padding:16px 0;overflow-y:auto;}
        .nav-section{padding:16px 24px 8px;font-size:10px;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.2);}
        .nav-item{display:flex;align-items:center;gap:12px;padding:10px 24px;color:rgba(255,255,255,.55);text-decoration:none;font-size:14px;transition:all .2s;position:relative;}
        .nav-item:hover{color:var(--white);background:rgba(255,255,255,.04);}
        .nav-item.active{color:var(--gold);background:rgba(201,168,76,.08);}
        .nav-item.active::before{content:'';position:absolute;left:0;top:0;bottom:0;width:3px;background:var(--gold);border-radius:0 2px 2px 0;}
        .sidebar-footer{padding:20px 24px;border-top:1px solid rgba(255,255,255,.06);}
        .logout-btn{display:flex;align-items:center;gap:10px;color:rgba(255,255,255,.4);text-decoration:none;font-size:13px;transition:color .2s;}
        .logout-btn:hover{color:var(--red);}
        .main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;}
        .topbar{background:var(--white);padding:16px 36px;display:flex;justify-content:space-between;align-items:center;border-bottom:1px solid rgba(0,0,0,.06);position:sticky;top:0;z-index:40;}
        .topbar-title{font-family:'Cormorant Garamond',serif;font-size:22px;font-weight:600;color:var(--dark);}
        .avatar{width:36px;height:36px;border-radius:50%;background:var(--gold);display:flex;align-items:center;justify-content:center;font-weight:600;font-size:14px;color:var(--dark);}
        .content{padding:32px 36px;flex:1;}
        .stats-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:20px;margin-bottom:28px;}
        .stat-card{background:var(--white);border-radius:6px;padding:24px;border:1px solid rgba(0,0,0,.05);position:relative;overflow:hidden;}
        .stat-card::after{content:'';position:absolute;top:0;right:0;width:4px;height:100%;background:var(--gold);}
        .stat-card.green::after{background:var(--green);}
        .stat-card.blue::after{background:var(--blue);}
        .stat-card.red::after{background:var(--red);}
        .stat-icon{font-size:26px;margin-bottom:10px;display:block;}
        .stat-num{font-family:'Cormorant Garamond',serif;font-size:38px;font-weight:700;color:var(--dark);line-height:1;}
        .stat-label{color:var(--muted);font-size:13px;margin-top:4px;}
        .grid-3{display:grid;grid-template-columns:2fr 1fr;gap:24px;margin-bottom:24px;}
        .card{background:var(--white);border-radius:6px;border:1px solid rgba(0,0,0,.05);overflow:hidden;}
        .card-header{padding:18px 24px;display:flex;justify-content:space-between;align-items:center;border-bottom:1px solid rgba(0,0,0,.06);}
        .card-title{font-family:'Cormorant Garamond',serif;font-size:18px;font-weight:600;color:var(--dark);}
        .card-action{color:var(--gold);font-size:13px;text-decoration:none;font-weight:500;}
        table{width:100%;border-collapse:collapse;}
        th{padding:10px 20px;text-align:left;font-size:11px;font-weight:500;letter-spacing:1px;text-transform:uppercase;color:var(--muted);background:#fafaf8;border-bottom:1px solid rgba(0,0,0,.06);}
        td{padding:12px 20px;font-size:13px;color:var(--dark);border-bottom:1px solid rgba(0,0,0,.04);}
        tr:last-child td{border-bottom:none;}
        tr:hover td{background:#fafaf8;}
        .badge{display:inline-block;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:500;}
        .badge-gold{background:rgba(201,168,76,.12);color:#a07d2a;}
        .badge-green{background:rgba(76,175,80,.12);color:#2e7d32;}
        .badge-red{background:rgba(224,85,85,.12);color:#c0392b;}
        .badge-blue{background:rgba(74,144,217,.12);color:#1a5fa0;}
        .badge-gray{background:rgba(0,0,0,.06);color:var(--muted);}
        .actions-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px;padding:20px;}
        .action-btn{display:flex;flex-direction:column;align-items:center;gap:8px;padding:20px 12px;border:1.5px solid rgba(0,0,0,.08);border-radius:4px;text-decoration:none;color:var(--dark);transition:all .2s;text-align:center;}
        .action-btn:hover{border-color:var(--gold);background:rgba(201,168,76,.04);color:var(--dark);}
        .action-icon{font-size:22px;}
        .action-label{font-size:12px;font-weight:500;}
    </style>
</head>
<body>
<aside class="sidebar">
    <a href="<%= request.getContextPath() %>/" class="sidebar-logo">Inmo<span>Vista</span></a>
    <div class="sidebar-role">Administrador</div>
    <nav class="sidebar-nav">
        <div class="nav-section">Principal</div>
        <a href="index.jsp" class="nav-item active"><i class="bi bi-grid"></i> Dashboard</a>
        <a href="<%= request.getContextPath() %>/propiedades" class="nav-item"><i class="bi bi-building"></i> Propiedades</a>
        <div class="nav-section">Gestión</div>
        <a href="usuarios.jsp" class="nav-item"><i class="bi bi-people"></i> Usuarios</a>
        <a href="citas.jsp" class="nav-item"><i class="bi bi-calendar-check"></i> Citas</a>
        <a href="solicitudes.jsp" class="nav-item"><i class="bi bi-file-earmark-text"></i> Solicitudes</a>
        <a href="transacciones.jsp" class="nav-item"><i class="bi bi-cash-coin"></i> Transacciones</a>
    </nav>
    <div class="sidebar-footer">
        <a href="<%= request.getContextPath() %>/logout" class="logout-btn"><i class="bi bi-box-arrow-left"></i> Cerrar sesión</a>
    </div>
</aside>

<div class="main">
    <div class="topbar">
        <span class="topbar-title">Panel de Administración</span>
        <div style="display:flex;align-items:center;gap:16px;">
            <div style="text-align:right;">
                <div style="font-size:14px;font-weight:500;color:var(--dark);"><%= usuario.getNombreCompleto() %></div>
                <div style="font-size:11px;color:var(--muted);">Administrador</div>
            </div>
            <div class="avatar"><%= usuario.getNombre().charAt(0) %><%= usuario.getApellido().charAt(0) %></div>
        </div>
    </div>

    <div class="content">
        <!-- Stats -->
        <div class="stats-grid">
            <div class="stat-card">
                <span class="stat-icon">🏠</span>
                <div class="stat-num"><%= totalPropiedades %></div>
                <div class="stat-label">Propiedades activas</div>
            </div>
            <div class="stat-card green">
                <span class="stat-icon">👥</span>
                <div class="stat-num"><%= totalUsuarios %></div>
                <div class="stat-label">Usuarios registrados</div>
            </div>
            <div class="stat-card blue">
                <span class="stat-icon">📅</span>
                <div class="stat-num"><%= totalCitas %></div>
                <div class="stat-label">Citas pendientes</div>
            </div>
            <div class="stat-card red">
                <span class="stat-icon">📄</span>
                <div class="stat-num"><%= totalSolicitudes %></div>
                <div class="stat-label">Solicitudes pendientes</div>
            </div>
        </div>

        <!-- Usuarios recientes + acciones -->
        <div class="grid-3">
            <div class="card">
                <div class="card-header">
                    <span class="card-title">Usuarios recientes</span>
                </div>
                <table>
                    <thead><tr><th>Nombre</th><th>Email</th><th>Rol</th><th>Estado</th></tr></thead>
                    <tbody>
                    <% if (usuariosRecientes.isEmpty()) { %>
                    <tr><td colspan="4" style="text-align:center;color:var(--muted);padding:24px;">No hay usuarios aún.</td></tr>
                    <% } else { for (String[] u : usuariosRecientes) {
                        String rol = u[3];
                        String rolClass = "ADMIN".equals(rol)?"badge-red":"INMOBILIARIA".equals(rol)?"badge-gold":"CLIENTE".equals(rol)?"badge-blue":"badge-gray";
                        String estClass = "Activo".equals(u[4])?"badge-green":"badge-red";
                    %>
                    <tr>
                        <td><strong><%= u[1] %></strong></td>
                        <td style="color:var(--muted);font-size:12px;"><%= u[2] %></td>
                        <td><span class="badge <%= rolClass %>"><%= rol %></span></td>
                        <td><span class="badge <%= estClass %>"><%= u[4] %></span></td>
                    </tr>
                    <% }} %>
                    </tbody>
                </table>
            </div>

            <div class="card">
                <div class="card-header"><span class="card-title">Acciones rápidas</span></div>
                <div class="actions-grid">
                    <a href="<%= request.getContextPath() %>/propiedades?action=form" class="action-btn">
                        <span class="action-icon">🏠</span><span class="action-label">Nueva propiedad</span>
                    </a>
                    <a href="<%= request.getContextPath() %>/propiedades" class="action-btn">
                        <span class="action-icon">🔍</span><span class="action-label">Ver propiedades</span>
                    </a>
                    <a href="usuarios.jsp" class="action-btn">
                        <span class="action-icon">👥</span><span class="action-label">Gestionar usuarios</span>
                    </a>
                    <a href="transacciones.jsp" class="action-btn">
                        <span class="action-icon">💰</span><span class="action-label">Transacciones</span>
                    </a>
                </div>
            </div>
        </div>

        <!-- Citas recientes -->
        <div class="card">
            <div class="card-header">
                <span class="card-title">Citas recientes</span>
            </div>
            <table>
                <thead><tr><th>#</th><th>Cliente</th><th>Propiedad</th><th>Fecha</th><th>Estado</th></tr></thead>
                <tbody>
                <% if (citasRecientes.isEmpty()) { %>
                <tr><td colspan="5" style="text-align:center;color:var(--muted);padding:24px;">No hay citas aún.</td></tr>
                <% } else { for (String[] c : citasRecientes) {
                    String est = c[4];
                    String bc = "CONFIRMADA".equals(est)?"badge-green":"CANCELADA".equals(est)||"RECHAZADA".equals(est)?"badge-red":"REALIZADA".equals(est)?"badge-blue":"badge-gold";
                %>
                <tr>
                    <td style="color:var(--muted);">#<%= c[0] %></td>
                    <td><%= c[1] %></td>
                    <td><%= c[2] %></td>
                    <td><%= c[3] %></td>
                    <td><span class="badge <%= bc %>"><%= est %></span></td>
                </tr>
                <% }} %>
                </tbody>
            </table>
        </div>
    </div>
</div>
</body>
</html>
