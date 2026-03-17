<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    Usuario usuario = (Usuario) session.getAttribute("usuario");
    if (usuario == null || !usuario.isCliente()) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }

    List<String[]> citas = new ArrayList<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
        try {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT c.id, c.fecha_solicitada, c.fecha_confirmada, c.estado, c.notas_cliente, " +
                "p.id AS pid, p.titulo, p.tipo, p.direccion, p.barrio, " +
                "(SELECT url FROM propiedad_fotos WHERE propiedad_id=p.id AND es_portada=1 LIMIT 1) AS foto " +
                "FROM citas c JOIN propiedades p ON c.propiedad_id=p.id " +
                "WHERE c.cliente_id=? ORDER BY c.fecha_solicitada DESC");
            ps.setInt(1, usuario.getId());
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                citas.add(new String[]{
                    String.valueOf(rs.getInt("id")),
                    rs.getString("fecha_solicitada") != null ? rs.getString("fecha_solicitada") : "",
                    rs.getString("fecha_confirmada") != null ? rs.getString("fecha_confirmada") : "",
                    rs.getString("estado"),
                    rs.getString("notas_cliente") != null ? rs.getString("notas_cliente") : "",
                    String.valueOf(rs.getInt("pid")),
                    rs.getString("titulo"),
                    rs.getString("tipo"),
                    rs.getString("direccion") != null ? rs.getString("direccion") : "",
                    rs.getString("barrio") != null ? rs.getString("barrio") : "",
                    rs.getString("foto") != null ? rs.getString("foto") : ""
                });
            }
            rs.close(); ps.close();
        } finally { conn.close(); }
    } catch (Exception e) { /* continuar */ }

    String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Mis Citas — InmoVista</title>
    <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@300;400;600;700&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet"/>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.0/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        *,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
        :root{--dark:#1A1A18;--gold:#C9A84C;--muted:#6B6455;--white:#FFFFFF;--sidebar:220px;}
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
        .badge{display:inline-block;padding:4px 12px;border-radius:20px;font-size:12px;font-weight:500;}
        .badge-gold{background:rgba(201,168,76,.15);color:#a07d2a;}
        .badge-green{background:rgba(76,175,80,.15);color:#2e7d32;}
        .badge-red{background:rgba(220,53,69,.15);color:#dc3545;}
        .badge-blue{background:rgba(74,144,217,.15);color:#1a5fa0;}
        .badge-gray{background:rgba(0,0,0,.08);color:#555;}
        .cita-card{background:var(--white);border-radius:8px;border:1px solid rgba(0,0,0,.06);overflow:hidden;transition:box-shadow .2s;}
        .cita-card:hover{box-shadow:0 4px 20px rgba(0,0,0,.08);}
        .cita-img{width:120px;min-height:100px;object-fit:cover;flex-shrink:0;}
        .cita-img-placeholder{width:120px;min-height:100px;background:#e8e0d0;display:flex;align-items:center;justify-content:center;font-size:2rem;flex-shrink:0;}
        .btn-cancelar{background:transparent;border:1px solid #e05555;color:#e05555;padding:6px 14px;border-radius:4px;font-size:12px;cursor:pointer;transition:all .2s;}
        .btn-cancelar:hover{background:#e05555;color:white;}
        .btn-ver{background:var(--dark);color:white;padding:6px 14px;border-radius:4px;font-size:12px;text-decoration:none;transition:background .2s;}
        .btn-ver:hover{background:#333;color:white;}
        .empty-msg{text-align:center;padding:60px;color:var(--muted);}
        .empty-msg .icon{font-size:3rem;margin-bottom:12px;}
        .alert-success{background:#d4edda;color:#155724;padding:12px 20px;border-radius:6px;margin-bottom:20px;}
    </style>
</head>
<body>
<aside class="sidebar">
    <a href="<%= request.getContextPath() %>/" class="sidebar-logo">Inmo<span>Vista</span></a>
    <nav class="sidebar-nav">
        <div class="nav-section">Principal</div>
        <a href="index.jsp" class="nav-item"><i class="bi bi-grid"></i> Inicio</a>
        <a href="<%= request.getContextPath() %>/propiedades" class="nav-item"><i class="bi bi-search"></i> Buscar propiedades</a>
        <div class="nav-section">Mi cuenta</div>
        <a href="mis-citas.jsp" class="nav-item active"><i class="bi bi-calendar-check"></i> Mis citas</a>
        <a href="mis-solicitudes.jsp" class="nav-item"><i class="bi bi-file-earmark-text"></i> Mis solicitudes</a>
    </nav>
    <div class="sidebar-footer">
        <a href="<%= request.getContextPath() %>/logout" class="logout-btn"><i class="bi bi-box-arrow-left"></i> Cerrar sesión</a>
    </div>
</aside>

<div class="main">
    <div class="topbar">
        <span class="topbar-title">Mis Citas</span>
        <div style="display:flex;align-items:center;gap:16px;">
            <div style="text-align:right;">
                <div style="font-size:14px;font-weight:500;color:var(--dark);"><%= usuario.getNombreCompleto() %></div>
                <div style="font-size:11px;color:var(--muted);">Cliente</div>
            </div>
            <div class="avatar"><%= usuario.getNombre().charAt(0) %><%= usuario.getApellido().charAt(0) %></div>
        </div>
    </div>

    <div class="content">
        <% if (msg != null) { %>
        <div class="alert-success"><i class="bi bi-check-circle me-2"></i><%= msg.replace("+"," ") %></div>
        <% } %>

        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:24px;">
            <div>
                <h3 style="font-family:'Cormorant Garamond',serif;font-size:24px;font-weight:600;color:var(--dark);">Mis visitas agendadas</h3>
                <p style="color:var(--muted);font-size:13px;"><%= citas.size() %> cita<%= citas.size() != 1 ? "s" : "" %> en total</p>
            </div>
            <a href="<%= request.getContextPath() %>/propiedades" style="background:var(--gold);color:white;padding:10px 20px;border-radius:4px;text-decoration:none;font-size:13px;font-weight:500;">
                <i class="bi bi-plus"></i> Nueva cita
            </a>
        </div>

        <% if (citas.isEmpty()) { %>
        <div class="empty-msg">
            <div class="icon">📅</div>
            <h4 style="font-family:'Cormorant Garamond',serif;font-size:22px;margin-bottom:8px;">No tienes citas agendadas</h4>
            <p style="color:var(--muted);margin-bottom:20px;">Busca una propiedad y agenda tu primera visita</p>
            <a href="<%= request.getContextPath() %>/propiedades" style="background:var(--gold);color:white;padding:10px 24px;border-radius:4px;text-decoration:none;">Ver propiedades</a>
        </div>
        <% } else { %>
        <div style="display:flex;flex-direction:column;gap:16px;">
            <% for (String[] c : citas) {
                String estado = c[3];
                String badgeClass = "CONFIRMADA".equals(estado) ? "badge-green" :
                                    "CANCELADA".equals(estado) || "RECHAZADA".equals(estado) ? "badge-red" :
                                    "REALIZADA".equals(estado) ? "badge-blue" : "badge-gold";
                String fecha = c[1].length() >= 16 ? c[1].substring(0,16).replace("T"," ") : c[1];
                boolean cancelable = "PENDIENTE".equals(estado) || "CONFIRMADA".equals(estado);
            %>
            <div class="cita-card" style="display:flex;">
                <% if (!c[10].isEmpty()) { %>
                <img src="<%= c[10] %>" class="cita-img" alt="<%= c[6] %>">
                <% } else { %>
                <div class="cita-img-placeholder">🏠</div>
                <% } %>
                <div style="padding:16px 20px;flex:1;display:flex;justify-content:space-between;align-items:center;gap:16px;">
                    <div>
                        <div style="font-family:'Cormorant Garamond',serif;font-size:18px;font-weight:600;color:var(--dark);margin-bottom:4px;"><%= c[6] %></div>
                        <div style="font-size:12px;color:var(--muted);margin-bottom:8px;"><i class="bi bi-geo-alt"></i> <%= c[8] %><%= !c[9].isEmpty() ? ", "+c[9] : "" %></div>
                        <div style="font-size:13px;color:var(--dark);margin-bottom:6px;"><i class="bi bi-calendar3" style="color:var(--gold);"></i> <strong><%= fecha %></strong></div>
                        <% if (!c[4].isEmpty()) { %>
                        <div style="font-size:12px;color:var(--muted);font-style:italic;">"<%= c[4] %>"</div>
                        <% } %>
                    </div>
                    <div style="display:flex;flex-direction:column;align-items:flex-end;gap:10px;">
                        <span class="badge <%= badgeClass %>"><%= estado %></span>
                        <div style="display:flex;gap:8px;">
                            <a href="<%= request.getContextPath() %>/propiedades?id=<%= c[5] %>" class="btn-ver">Ver propiedad</a>
                            <% if (cancelable) { %>
                            <form method="post" action="<%= request.getContextPath() %>/citas" style="margin:0;">
                                <input type="hidden" name="action" value="cancelar">
                                <input type="hidden" name="citaId" value="<%= c[0] %>">
                                <button type="submit" class="btn-cancelar">Cancelar</button>
                            </form>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>
            <% } %>
        </div>
        <% } %>
    </div>
</div>
</body>
</html>
