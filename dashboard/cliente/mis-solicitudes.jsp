<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    Usuario usuario = (Usuario) session.getAttribute("usuario");
    if (usuario == null || !usuario.isCliente()) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }

    List<String[]> solicitudes = new ArrayList<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
        try {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT s.id, s.tipo_operacion, s.estado, s.observaciones, s.created_at, " +
                "p.id AS pid, p.titulo, p.tipo, p.direccion, " +
                "(SELECT url FROM propiedad_fotos WHERE propiedad_id=p.id AND es_portada=1 LIMIT 1) AS foto " +
                "FROM solicitudes_documentos s JOIN propiedades p ON s.propiedad_id=p.id " +
                "WHERE s.cliente_id=? ORDER BY s.created_at DESC");
            ps.setInt(1, usuario.getId());
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                solicitudes.add(new String[]{
                    String.valueOf(rs.getInt("id")),
                    rs.getString("tipo_operacion"),
                    rs.getString("estado"),
                    rs.getString("observaciones") != null ? rs.getString("observaciones") : "",
                    rs.getString("created_at") != null ? rs.getString("created_at").substring(0,10) : "",
                    String.valueOf(rs.getInt("pid")),
                    rs.getString("titulo"),
                    rs.getString("tipo"),
                    rs.getString("direccion") != null ? rs.getString("direccion") : "",
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
    <title>Mis Solicitudes — InmoVista</title>
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
        .sol-card{background:var(--white);border-radius:8px;border:1px solid rgba(0,0,0,.06);overflow:hidden;display:flex;transition:box-shadow .2s;}
        .sol-card:hover{box-shadow:0 4px 20px rgba(0,0,0,.08);}
        .sol-img{width:120px;min-height:100px;object-fit:cover;flex-shrink:0;}
        .sol-img-placeholder{width:120px;min-height:100px;background:#e8e0d0;display:flex;align-items:center;justify-content:center;font-size:2rem;flex-shrink:0;}
        .btn-nueva{background:var(--gold);color:white;padding:10px 20px;border-radius:4px;text-decoration:none;font-size:13px;font-weight:500;}
        .btn-ver{background:var(--dark);color:white;padding:6px 14px;border-radius:4px;font-size:12px;text-decoration:none;}
        .btn-ver:hover{background:#333;color:white;}
        .empty-msg{text-align:center;padding:60px;color:var(--muted);}
        .alert-success{background:#d4edda;color:#155724;padding:12px 20px;border-radius:6px;margin-bottom:20px;}
        .nueva-card{background:var(--white);border-radius:8px;border:1px solid rgba(0,0,0,.06);padding:24px;margin-bottom:24px;}
        .form-label{font-size:13px;font-weight:500;color:var(--dark);margin-bottom:6px;display:block;}
        .form-control{width:100%;padding:10px 14px;border:1px solid rgba(0,0,0,.12);border-radius:4px;font-family:'DM Sans',sans-serif;font-size:14px;outline:none;}
        .form-control:focus{border-color:var(--gold);}
        .btn-submit{background:var(--gold);color:white;border:none;padding:10px 24px;border-radius:4px;font-size:14px;font-weight:500;cursor:pointer;}
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
        <a href="mis-citas.jsp" class="nav-item"><i class="bi bi-calendar-check"></i> Mis citas</a>
        <a href="mis-solicitudes.jsp" class="nav-item active"><i class="bi bi-file-earmark-text"></i> Mis solicitudes</a>
    </nav>
    <div class="sidebar-footer">
        <a href="<%= request.getContextPath() %>/logout" class="logout-btn"><i class="bi bi-box-arrow-left"></i> Cerrar sesión</a>
    </div>
</aside>

<div class="main">
    <div class="topbar">
        <span class="topbar-title">Mis Solicitudes</span>
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
        <div class="alert-success"><i class="bi bi-check-circle"></i> <%= msg.replace("+"," ") %></div>
        <% } %>

        <!-- Formulario nueva solicitud -->
        <div class="nueva-card">
            <h4 style="font-family:'Cormorant Garamond',serif;font-size:20px;font-weight:600;margin-bottom:16px;color:var(--dark);">Nueva solicitud de documentos</h4>
            <form method="post" action="<%= request.getContextPath() %>/solicitudes">
                <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:16px;margin-bottom:16px;">
                    <div>
                        <label class="form-label">Propiedad (ID)</label>
                        <input type="number" name="propiedadId" class="form-control" placeholder="Ej: 25" required>
                    </div>
                    <div>
                        <label class="form-label">Tipo de operación</label>
                        <select name="tipoOperacion" class="form-control" required>
                            <option value="">Seleccionar...</option>
                            <option value="COMPRA">Compra</option>
                            <option value="ARRIENDO">Arriendo</option>
                        </select>
                    </div>
                    <div>
                        <label class="form-label">Observaciones (opcional)</label>
                        <input type="text" name="observaciones" class="form-control" placeholder="Algún comentario...">
                    </div>
                </div>
                <button type="submit" class="btn-submit"><i class="bi bi-send"></i> Enviar solicitud</button>
            </form>
        </div>

        <!-- Lista solicitudes -->
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
            <h4 style="font-family:'Cormorant Garamond',serif;font-size:20px;font-weight:600;color:var(--dark);">Mis solicitudes (<%= solicitudes.size() %>)</h4>
        </div>

        <% if (solicitudes.isEmpty()) { %>
        <div class="empty-msg">
            <div style="font-size:3rem;margin-bottom:12px;">📄</div>
            <h4 style="font-family:'Cormorant Garamond',serif;font-size:22px;margin-bottom:8px;">No tienes solicitudes</h4>
            <p>Envía tu primera solicitud de documentos para una propiedad.</p>
        </div>
        <% } else { %>
        <div style="display:flex;flex-direction:column;gap:14px;">
            <% for (String[] s : solicitudes) {
                String estado = s[2];
                String badgeClass = "APROBADO".equals(estado) ? "badge-green" :
                                    "RECHAZADO".equals(estado) ? "badge-red" :
                                    "EN_REVISION".equals(estado) ? "badge-blue" : "badge-gold";
            %>
            <div class="sol-card">
                <% if (!s[9].isEmpty()) { %>
                <img src="<%= s[9] %>" class="sol-img" alt="<%= s[6] %>">
                <% } else { %>
                <div class="sol-img-placeholder">🏠</div>
                <% } %>
                <div style="padding:16px 20px;flex:1;display:flex;justify-content:space-between;align-items:center;gap:16px;">
                    <div>
                        <div style="font-family:'Cormorant Garamond',serif;font-size:18px;font-weight:600;color:var(--dark);margin-bottom:4px;"><%= s[6] %></div>
                        <div style="font-size:12px;color:var(--muted);margin-bottom:8px;"><i class="bi bi-geo-alt"></i> <%= s[8] %></div>
                        <div style="font-size:13px;margin-bottom:4px;">Tipo: <strong><%= s[1] %></strong></div>
                        <div style="font-size:12px;color:var(--muted);">Fecha: <%= s[4] %></div>
                        <% if (!s[3].isEmpty()) { %>
                        <div style="font-size:12px;color:var(--muted);margin-top:4px;font-style:italic;">"<%= s[3] %>"</div>
                        <% } %>
                    </div>
                    <div style="display:flex;flex-direction:column;align-items:flex-end;gap:10px;">
                        <span class="badge <%= badgeClass %>"><%= estado.replace("_"," ") %></span>
                        <a href="<%= request.getContextPath() %>/propiedades?id=<%= s[5] %>" class="btn-ver">Ver propiedad</a>
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
