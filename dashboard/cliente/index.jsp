<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    Usuario usuario = (Usuario) session.getAttribute("usuario");
    if (usuario == null || !usuario.isCliente()) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }
    int uid = usuario.getId();

    int numCitas = 0, numSolicitudes = 0;
    List<String[]> citasProximas = new ArrayList<>();
    List<String[]> propsRecientes = new ArrayList<>();

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
        try {
            // Contar citas próximas
            PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM citas WHERE cliente_id=? AND estado IN ('PENDIENTE','CONFIRMADA') AND fecha_solicitada >= NOW()");
            ps.setInt(1, uid); ResultSet rs = ps.executeQuery();
            if (rs.next()) numCitas = rs.getInt(1);
            rs.close(); ps.close();

            // Contar solicitudes
            ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM solicitudes_documentos WHERE cliente_id=? AND estado='PENDIENTE'");
            ps.setInt(1, uid); rs = ps.executeQuery();
            if (rs.next()) numSolicitudes = rs.getInt(1);
            rs.close(); ps.close();

            // Citas próximas
            ps = conn.prepareStatement(
                "SELECT c.id, c.fecha_solicitada, c.estado, p.id as pid, p.titulo FROM citas c " +
                "JOIN propiedades p ON c.propiedad_id=p.id " +
                "WHERE c.cliente_id=? AND c.fecha_solicitada >= NOW() ORDER BY c.fecha_solicitada ASC LIMIT 3");
            ps.setInt(1, uid); rs = ps.executeQuery();
            while (rs.next()) {
                String fecha = rs.getString("fecha_solicitada") != null ? rs.getString("fecha_solicitada").substring(0,16) : "Sin fecha";
                citasProximas.add(new String[]{
                    String.valueOf(rs.getInt("id")), fecha, rs.getString("estado"),
                    String.valueOf(rs.getInt("pid")), rs.getString("titulo")
                });
            }
            rs.close(); ps.close();

            // Propiedades recientes disponibles
            ps = conn.prepareStatement(
                "SELECT p.id, p.titulo, p.tipo, p.operacion, p.precio, " +
                "(SELECT url FROM propiedad_fotos WHERE propiedad_id=p.id AND es_portada=1 LIMIT 1) as foto " +
                "FROM propiedades p WHERE p.estado='DISPONIBLE' ORDER BY p.fecha_creacion DESC LIMIT 3");
            rs = ps.executeQuery();
            while (rs.next()) propsRecientes.add(new String[]{
                String.valueOf(rs.getInt("id")), rs.getString("titulo"), rs.getString("tipo"),
                rs.getString("operacion"), String.format("%,.0f", rs.getDouble("precio")),
                rs.getString("foto") != null ? rs.getString("foto") : ""
            });
            rs.close(); ps.close();
        } finally { conn.close(); }
    } catch (Exception e) { /* continuar */ }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>InmoVista — Mi Panel</title>
    <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@300;400;600;700&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet"/>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.0/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        *,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
        :root{--cream:#F5F0E8;--dark:#1A1A18;--gold:#C9A84C;--muted:#6B6455;--white:#FFFFFF;--sidebar:220px;}
        body{font-family:'DM Sans',sans-serif;background:#F0EBE1;display:flex;min-height:100vh;}
        .sidebar{width:var(--sidebar);background:var(--dark);display:flex;flex-direction:column;position:fixed;top:0;left:0;bottom:0;z-index:50;}
        .sidebar-logo{padding:28px 24px 20px;font-family:'Cormorant Garamond',serif;font-size:22px;font-weight:700;color:var(--white);text-decoration:none;display:block;border-bottom:1px solid rgba(255,255,255,.06);}
        .sidebar-logo span{color:var(--gold);}
        .sidebar-nav{flex:1;padding:16px 0;}
        .nav-section{padding:16px 24px 8px;font-size:10px;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.2);}
        .nav-item{display:flex;align-items:center;gap:12px;padding:10px 24px;color:rgba(255,255,255,.55);text-decoration:none;font-size:14px;transition:all .2s;position:relative;}
        .nav-item:hover{color:var(--white);background:rgba(255,255,255,.04);}
        .nav-item.active{color:var(--gold);background:rgba(201,168,76,.08);}
        .nav-item.active::before{content:'';position:absolute;left:0;top:0;bottom:0;width:3px;background:var(--gold);border-radius:0 2px 2px 0;}
        .sidebar-footer{padding:20px 24px;border-top:1px solid rgba(255,255,255,.06);}
        .logout-btn{display:flex;align-items:center;gap:10px;color:rgba(255,255,255,.4);text-decoration:none;font-size:13px;transition:color .2s;}
        .logout-btn:hover{color:#e05555;}
        .main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;}
        .topbar{background:var(--white);padding:16px 36px;display:flex;justify-content:space-between;align-items:center;border-bottom:1px solid rgba(0,0,0,.06);position:sticky;top:0;z-index:40;}
        .topbar-title{font-family:'Cormorant Garamond',serif;font-size:22px;font-weight:600;color:var(--dark);}
        .avatar{width:36px;height:36px;border-radius:50%;background:var(--gold);display:flex;align-items:center;justify-content:center;font-weight:600;font-size:14px;color:var(--dark);}
        .content{padding:32px 36px;flex:1;}
        .welcome{background:var(--dark);border-radius:6px;padding:32px 36px;margin-bottom:28px;position:relative;overflow:hidden;}
        .welcome::after{content:'🏡';position:absolute;right:36px;top:50%;transform:translateY(-50%);font-size:80px;opacity:.12;}
        .welcome-label{font-size:11px;letter-spacing:2px;text-transform:uppercase;color:var(--gold);margin-bottom:10px;}
        .welcome-title{font-family:'Cormorant Garamond',serif;font-size:32px;font-weight:300;color:var(--white);margin-bottom:8px;}
        .welcome-title em{font-style:italic;color:var(--gold);}
        .welcome-sub{color:rgba(255,255,255,.45);font-size:14px;}
        .stats-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;margin-bottom:28px;}
        .stat-card{background:var(--white);border-radius:6px;padding:24px;border:1px solid rgba(0,0,0,.05);}
        .stat-icon{font-size:28px;margin-bottom:10px;display:block;}
        .stat-num{font-family:'Cormorant Garamond',serif;font-size:36px;font-weight:700;color:var(--dark);line-height:1;}
        .stat-label{color:var(--muted);font-size:13px;margin-top:4px;}
        .props-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:18px;margin-bottom:28px;}
        .prop-mini{background:var(--white);border-radius:6px;overflow:hidden;border:1px solid rgba(0,0,0,.05);transition:transform .2s,box-shadow .2s;}
        .prop-mini:hover{transform:translateY(-3px);box-shadow:0 10px 30px rgba(0,0,0,.08);}
        .prop-img-wrap{height:140px;overflow:hidden;background:#e8e0d0;display:flex;align-items:center;justify-content:center;font-size:48px;}
        .prop-img-wrap img{width:100%;height:140px;object-fit:cover;}
        .prop-body{padding:16px;}
        .prop-name{font-family:'Cormorant Garamond',serif;font-size:16px;font-weight:600;color:var(--dark);}
        .prop-tipo{color:var(--muted);font-size:12px;margin:4px 0 10px;}
        .prop-price{color:var(--gold);font-family:'Cormorant Garamond',serif;font-size:18px;font-weight:700;}
        .prop-actions{display:flex;gap:8px;margin-top:12px;}
        .btn-sm{flex:1;padding:8px;border-radius:3px;font-size:12px;font-weight:500;cursor:pointer;border:none;font-family:'DM Sans',sans-serif;text-align:center;text-decoration:none;display:block;}
        .btn-dark{background:var(--dark);color:var(--white);}
        .btn-dark:hover{background:#333;color:var(--white);}
        .btn-outline{background:transparent;border:1.5px solid rgba(0,0,0,.12);color:var(--muted);}
        .btn-outline:hover{background:#f0ede8;color:var(--dark);}
        .card{background:var(--white);border-radius:6px;border:1px solid rgba(0,0,0,.05);}
        .card-header{padding:18px 24px;display:flex;justify-content:space-between;align-items:center;border-bottom:1px solid rgba(0,0,0,.06);}
        .card-title{font-family:'Cormorant Garamond',serif;font-size:18px;font-weight:600;color:var(--dark);}
        .card-action{color:var(--gold);font-size:13px;text-decoration:none;font-weight:500;}
        .cita-item{display:flex;align-items:center;gap:16px;padding:16px 24px;border-bottom:1px solid rgba(0,0,0,.04);}
        .cita-item:last-child{border-bottom:none;}
        .cita-date-box{min-width:52px;text-align:center;background:#f8f5f0;border-radius:4px;padding:8px;}
        .cita-day{font-family:'Cormorant Garamond',serif;font-size:24px;font-weight:700;color:var(--dark);line-height:1;}
        .cita-month{font-size:11px;text-transform:uppercase;color:var(--muted);letter-spacing:1px;}
        .cita-info{flex:1;}
        .cita-prop{font-size:14px;font-weight:500;color:var(--dark);}
        .cita-hora{font-size:12px;color:var(--muted);margin-top:2px;}
        .badge{display:inline-block;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:500;}
        .badge-gold{background:rgba(201,168,76,.12);color:#a07d2a;}
        .badge-green{background:rgba(76,175,80,.12);color:#2e7d32;}
        .badge-red{background:rgba(220,53,69,.12);color:#dc3545;}
        .empty-msg{padding:32px;text-align:center;color:var(--muted);font-size:14px;}
    </style>
</head>
<body>
<aside class="sidebar">
    <a href="<%= request.getContextPath() %>/" class="sidebar-logo">Inmo<span>Vista</span></a>
    <nav class="sidebar-nav">
        <div class="nav-section">Principal</div>
        <a href="index.jsp" class="nav-item active"><i class="bi bi-grid"></i> Inicio</a>
        <a href="<%= request.getContextPath() %>/propiedades" class="nav-item"><i class="bi bi-search"></i> Buscar propiedades</a>
        <div class="nav-section">Mi cuenta</div>
        <a href="mis-citas.jsp" class="nav-item"><i class="bi bi-calendar-check"></i> Mis citas</a>
        <a href="mis-solicitudes.jsp" class="nav-item"><i class="bi bi-file-earmark-text"></i> Mis solicitudes</a>
    </nav>
    <div class="sidebar-footer">
        <a href="<%= request.getContextPath() %>/logout" class="logout-btn"><i class="bi bi-box-arrow-left"></i> Cerrar sesión</a>
    </div>
</aside>

<div class="main">
    <div class="topbar">
        <span class="topbar-title">Mi Panel</span>
        <div style="display:flex;align-items:center;gap:16px;">
            <div style="text-align:right;">
                <div style="font-size:14px;font-weight:500;color:var(--dark);"><%= usuario.getNombreCompleto() %></div>
                <div style="font-size:11px;color:var(--muted);">Cliente</div>
            </div>
            <div class="avatar"><%= usuario.getNombre().charAt(0) %><%= usuario.getApellido().charAt(0) %></div>
        </div>
    </div>

    <div class="content">
        <div class="welcome">
            <div class="welcome-label">Bienvenido de nuevo</div>
            <h2 class="welcome-title">Hola, <em><%= usuario.getNombre() %></em></h2>
            <p class="welcome-sub">Tienes <%= numCitas %> cita<%= numCitas != 1 ? "s" : "" %> próxima<%= numCitas != 1 ? "s" : "" %> y <%= numSolicitudes %> solicitud<%= numSolicitudes != 1 ? "es" : "" %> pendiente<%= numSolicitudes != 1 ? "s" : "" %>.</p>
        </div>

        <div class="stats-grid">
            <div class="stat-card"><span class="stat-icon">📅</span><div class="stat-num"><%= numCitas %></div><div class="stat-label">Citas próximas</div></div>
            <div class="stat-card"><span class="stat-icon">📄</span><div class="stat-num"><%= numSolicitudes %></div><div class="stat-label">Solicitudes pendientes</div></div>
            <div class="stat-card"><span class="stat-icon">🔍</span><div class="stat-num"><%= propsRecientes.size() %>+</div><div class="stat-label">Propiedades disponibles</div></div>
        </div>

        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
            <h3 style="font-family:'Cormorant Garamond',serif;font-size:20px;font-weight:600;color:var(--dark);">Propiedades disponibles</h3>
            <a href="<%= request.getContextPath() %>/propiedades" style="color:var(--gold);font-size:13px;text-decoration:none;">Ver todas →</a>
        </div>
        <div class="props-grid">
            <% if (propsRecientes.isEmpty()) { %>
            <div style="grid-column:1/-1;" class="empty-msg">No hay propiedades disponibles aún.</div>
            <% } else { for (String[] p : propsRecientes) { %>
            <div class="prop-mini">
                <div class="prop-img-wrap">
                    <% if (!p[5].isEmpty()) { %><img src="<%= p[5] %>" alt="<%= p[1] %>">
                    <% } else { %>🏠<% } %>
                </div>
                <div class="prop-body">
                    <div class="prop-name"><%= p[1] %></div>
                    <div class="prop-tipo"><%= p[2] %> · <%= p[3] %></div>
                    <div class="prop-price">$<%= p[4] %><%= "ARRIENDO".equals(p[3]) ? "/mes" : "" %></div>
                    <div class="prop-actions">
                        <a href="<%= request.getContextPath() %>/propiedades?id=<%= p[0] %>" class="btn-sm btn-dark">Ver detalle</a>
                        <a href="<%= request.getContextPath() %>/propiedades?id=<%= p[0] %>#cita" class="btn-sm btn-outline">Agendar cita</a>
                    </div>
                </div>
            </div>
            <% }} %>
        </div>

        <div class="card">
            <div class="card-header">
                <span class="card-title">Mis citas próximas</span>
                <a href="mis-citas.jsp" class="card-action">Ver todas →</a>
            </div>
            <% if (citasProximas.isEmpty()) { %>
            <div class="empty-msg">No tienes citas próximas. <a href="<%= request.getContextPath() %>/propiedades" style="color:var(--gold);">Buscar propiedades</a></div>
            <% } else { for (String[] c : citasProximas) {
                String est = c[2];
                String badgeClass = "CONFIRMADA".equals(est) ? "badge-green" : "CANCELADA".equals(est) ? "badge-red" : "badge-gold";
                String fecha = c[1];
                String dia = fecha.length() >= 10 ? fecha.substring(8,10) : "--";
                String mes = fecha.length() >= 7 ? fecha.substring(5,7) : "--";
                String hora = fecha.length() >= 16 ? fecha.substring(11,16) : "";
                String[] meses = {"","Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dic"};
                String mesNom = ""; try { mesNom = meses[Integer.parseInt(mes)]; } catch(Exception ex) { mesNom = mes; }
            %>
            <div class="cita-item">
                <div class="cita-date-box"><div class="cita-day"><%= dia %></div><div class="cita-month"><%= mesNom %></div></div>
                <div class="cita-info">
                    <div class="cita-prop"><%= c[4] %></div>
                    <div class="cita-hora">🕐 <%= hora %></div>
                </div>
                <span class="badge <%= badgeClass %>"><%= est %></span>
            </div>
            <% }} %>
        </div>
    </div>
</div>
</body>
</html>
