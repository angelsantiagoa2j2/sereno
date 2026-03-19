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

    String action = request.getParameter("action");
    String citaId = request.getParameter("id");
    if (action != null && citaId != null) {
        String nuevoEstado = "confirmar".equals(action) ? "CONFIRMADA" : "cancelar".equals(action) ? "CANCELADA" : null;
        if (nuevoEstado != null) {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection conn = java.sql.DriverManager.getConnection(
                    "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
                    "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
                PreparedStatement ps = conn.prepareStatement("UPDATE citas SET estado=? WHERE id=?");
                ps.setString(1, nuevoEstado); ps.setInt(2, Integer.parseInt(citaId));
                ps.executeUpdate(); ps.close(); conn.close();
            } catch (Exception e) { /* ignorar */ }
        }
        response.sendRedirect("solicitudes.jsp?msg=Cita+actualizada"); return;
    }

    String filtro = request.getParameter("estado") != null ? request.getParameter("estado") : "";
    String msg = request.getParameter("msg");

    List<String[]> citas = new ArrayList<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
        try {
            StringBuilder sql = new StringBuilder(
                "SELECT c.id, c.fecha_solicitada, c.estado, c.notas_cliente, " +
                "p.titulo, u.nombre, u.apellido, u.telefono " +
                "FROM citas c JOIN propiedades p ON c.propiedad_id=p.id " +
                "JOIN usuarios u ON c.cliente_id=u.id WHERE p.inmobiliaria_id=?");
            if (!filtro.isEmpty()) sql.append(" AND c.estado=?");
            sql.append(" ORDER BY c.fecha_solicitada DESC");
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            ps.setInt(1, uid);
            if (!filtro.isEmpty()) ps.setString(2, filtro);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                String fecha = rs.getString("fecha_solicitada") != null ? rs.getString("fecha_solicitada").substring(0,16) : "Sin fecha";
                String notas = rs.getString("notas_cliente") != null ? rs.getString("notas_cliente") : "";
                citas.add(new String[]{
                    String.valueOf(rs.getInt("id")), fecha, rs.getString("estado"),
                    notas.length() > 60 ? notas.substring(0,60)+"…" : notas,
                    rs.getString("titulo"),
                    rs.getString("nombre") + " " + rs.getString("apellido"),
                    rs.getString("telefono") != null ? rs.getString("telefono") : ""
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
  <title>Citas y Visitas — Sereno</title>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&family=Outfit:wght@300;400;500;600&display=swap" rel="stylesheet"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.0/font/bootstrap-icons.min.css" rel="stylesheet"/>
  <style>
    *,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
    :root{
      --navy:#0A1628; --navy-mid:#122040;
      --blue:#1455A4; --blue-bright:#1E6FD9;
      --sky:#4A9DE0; --sky-lt:#A8D4F5;
      --ice:#EAF4FD; --white:#FFFFFF;
      --slate:#4A5568; --slate-lt:#8A9BB0;
      --border:#D6E8F7; --bg:#F4F8FD;
    }
    body{font-family:'Outfit',sans-serif;background:var(--bg);color:var(--navy);min-height:100vh;}

    /* SIDEBAR */
    .sidebar{width:248px;min-height:100vh;background:var(--navy);position:fixed;top:0;left:0;z-index:100;overflow-y:auto;display:flex;flex-direction:column;border-right:1px solid rgba(255,255,255,0.04);}
    .sidebar-brand{padding:26px 24px 22px;border-bottom:1px solid rgba(255,255,255,0.06);}
    .brand-logo{font-family:'Playfair Display',serif;font-size:22px;font-weight:700;color:var(--white);text-decoration:none;display:block;}
    .brand-logo span{color:var(--sky);}
    .brand-sub{color:rgba(255,255,255,0.25);font-size:11px;letter-spacing:1px;text-transform:uppercase;margin-top:3px;}
    .nav-section{color:rgba(255,255,255,0.2);font-size:10px;font-weight:600;letter-spacing:2px;text-transform:uppercase;padding:20px 24px 6px;}
    .nav-link{color:rgba(255,255,255,0.45);padding:10px 24px;display:flex;align-items:center;gap:10px;font-size:14px;text-decoration:none;transition:all .2s;border-left:3px solid transparent;}
    .nav-link i{font-size:15px;flex-shrink:0;}
    .nav-link:hover{color:rgba(255,255,255,0.85);background:rgba(255,255,255,0.04);}
    .nav-link.active{color:var(--white);background:rgba(30,111,217,0.15);border-left-color:var(--blue-bright);}
    .sidebar-footer{margin-top:auto;padding:20px 24px;border-top:1px solid rgba(255,255,255,0.06);}
    .user-mini{display:flex;align-items:center;gap:10px;margin-bottom:4px;}
    .user-avatar{width:34px;height:34px;border-radius:50%;background:var(--blue-bright);color:var(--white);font-weight:700;font-size:14px;display:flex;align-items:center;justify-content:center;flex-shrink:0;}
    .user-name{color:rgba(255,255,255,0.8);font-size:13px;font-weight:500;line-height:1.2;}
    .user-role{color:rgba(255,255,255,0.3);font-size:11px;}

    /* MAIN */
    .main{margin-left:248px;padding:32px 36px;min-height:100vh;}

    /* TOPBAR */
    .topbar{display:flex;justify-content:space-between;align-items:center;margin-bottom:28px;}
    .topbar-left h1{font-family:'Playfair Display',serif;font-size:26px;font-weight:900;color:var(--navy);}
    .topbar-left p{color:var(--slate-lt);font-size:14px;margin-top:2px;}
    .count-pill{background:var(--navy);color:var(--sky-lt);font-size:13px;font-weight:500;padding:6px 16px;border-radius:20px;}

    /* ALERT */
    .alert-success{display:flex;align-items:center;gap:10px;background:rgba(34,197,94,0.08);border:1.5px solid rgba(34,197,94,0.25);border-radius:10px;padding:12px 16px;color:#16a34a;font-size:14px;margin-bottom:20px;}
    .alert-close{margin-left:auto;background:none;border:none;color:#16a34a;cursor:pointer;font-size:16px;}

    /* FILTER TABS */
    .filter-tabs{display:flex;gap:6px;flex-wrap:wrap;margin-bottom:20px;}
    .tab{padding:7px 18px;border-radius:20px;font-size:13px;font-weight:500;text-decoration:none;cursor:pointer;border:1.5px solid var(--border);background:var(--white);color:var(--slate);transition:all .2s;font-family:'Outfit',sans-serif;}
    .tab:hover{border-color:var(--blue-bright);color:var(--blue-bright);}
    .tab.active-all{background:var(--navy);color:var(--white);border-color:var(--navy);}
    .tab.active-pending{background:rgba(234,179,8,0.12);color:#ca8a04;border-color:rgba(234,179,8,0.4);}
    .tab.active-confirmed{background:rgba(34,197,94,0.1);color:#16a34a;border-color:rgba(34,197,94,0.35);}
    .tab.active-cancelled{background:rgba(224,85,85,0.1);color:#e05555;border-color:rgba(224,85,85,0.3);}
    .tab.active-done{background:rgba(74,157,224,0.1);color:var(--sky);border-color:rgba(74,157,224,0.35);}

    /* TABLE */
    .table-wrap{background:var(--white);border-radius:14px;border:1.5px solid var(--border);overflow:hidden;}
    table{width:100%;border-collapse:collapse;}
    thead tr{border-bottom:1.5px solid var(--border);}
    thead th{padding:14px 18px;font-size:11px;font-weight:600;letter-spacing:1.5px;text-transform:uppercase;color:var(--slate-lt);}
    tbody tr{border-bottom:1.5px solid var(--border);transition:background .15s;}
    tbody tr:last-child{border-bottom:none;}
    tbody tr:hover{background:var(--ice);}
    td{padding:15px 18px;vertical-align:middle;}

    .client-name{font-size:14px;font-weight:500;color:var(--navy);margin-bottom:2px;}
    .client-phone{font-size:12px;color:var(--slate-lt);}
    .prop-name{font-size:13px;color:var(--slate);font-weight:400;}
    .date-cell{font-size:13px;color:var(--slate);white-space:nowrap;}
    .notes-cell{font-size:12px;color:var(--slate-lt);max-width:200px;}

    /* Badges */
    .badge{display:inline-block;padding:4px 12px;border-radius:20px;font-size:11px;font-weight:600;letter-spacing:0.3px;white-space:nowrap;}
    .badge-pending{background:rgba(234,179,8,0.12);color:#ca8a04;}
    .badge-confirmed{background:rgba(34,197,94,0.1);color:#16a34a;}
    .badge-cancelled{background:rgba(224,85,85,0.1);color:#e05555;}
    .badge-done{background:rgba(74,157,224,0.1);color:var(--sky);}
    .badge-default{background:rgba(0,0,0,0.06);color:var(--slate);}

    /* Action buttons */
    .actions-cell{display:flex;align-items:center;gap:8px;flex-wrap:nowrap;}
    .btn-confirm{display:inline-flex;align-items:center;gap:5px;padding:6px 14px;border:none;border-radius:20px;background:rgba(34,197,94,0.1);color:#16a34a;font-family:'Outfit',sans-serif;font-size:12px;font-weight:600;cursor:pointer;text-decoration:none;transition:all .2s;white-space:nowrap;}
    .btn-confirm:hover{background:#22c55e;color:var(--white);}
    .btn-cancel{display:inline-flex;align-items:center;gap:5px;padding:6px 14px;border:1.5px solid rgba(224,85,85,0.25);border-radius:20px;background:transparent;color:#e05555;font-family:'Outfit',sans-serif;font-size:12px;font-weight:500;cursor:pointer;text-decoration:none;transition:all .2s;white-space:nowrap;}
    .btn-cancel:hover{background:#e05555;color:var(--white);border-color:#e05555;}

    /* Empty state */
    .empty-row td{padding:56px 20px;text-align:center;}
    .empty-icon{font-size:40px;color:var(--border);margin-bottom:12px;}
    .empty-title{font-family:'Playfair Display',serif;font-size:18px;font-weight:700;color:var(--navy);margin-bottom:6px;}
    .empty-sub{color:var(--slate-lt);font-size:13px;}

    @media(max-width:1100px){
      td:nth-child(4){display:none;}
      th:nth-child(4){display:none;}
    }
    @media(max-width:900px){
      td:nth-child(3){display:none;}
      th:nth-child(3){display:none;}
    }
    @media(max-width:768px){
      .sidebar{transform:translateX(-100%);}
      .main{margin-left:0;padding:20px 16px;}
    }
  </style>
</head>
<body>

<!-- SIDEBAR -->
<aside class="sidebar">
  <div class="sidebar-brand">
    <a href="${pageContext.request.contextPath}/" class="brand-logo">Ser<span>eno</span></a>
    <div class="brand-sub">Panel Inmobiliaria</div>
  </div>
  <nav>
    <div class="nav-section">Principal</div>
    <a href="index.jsp" class="nav-link"><i class="bi bi-grid-1x2"></i> Inicio</a>
    <a href="mis-propiedades.jsp" class="nav-link"><i class="bi bi-building"></i> Mis Propiedades</a>
    <div class="nav-section">Gestión</div>
    <a href="solicitudes.jsp" class="nav-link active"><i class="bi bi-calendar-check"></i> Citas / Visitas</a>
    <a href="documentos.jsp" class="nav-link"><i class="bi bi-file-earmark-check"></i> Documentos</a>
    <div class="nav-section">Reportes</div>
    <a href="reportes.jsp" class="nav-link"><i class="bi bi-bar-chart-line"></i> Reportes</a>
  </nav>
  <div class="sidebar-footer">
    <div class="user-mini">
      <div class="user-avatar"><%= usuario.getNombre().substring(0,1).toUpperCase() %></div>
      <div>
        <div class="user-name"><%= usuario.getNombreCompleto() %></div>
        <div class="user-role">Inmobiliaria</div>
      </div>
    </div>
    <a href="<%= request.getContextPath() %>/logout" class="nav-link" style="padding:12px 0 0;border-left:none;">
      <i class="bi bi-box-arrow-left"></i> Cerrar sesión
    </a>
  </div>
</aside>

<!-- MAIN -->
<div class="main">

  <div class="topbar">
    <div class="topbar-left">
      <h1>Citas y Visitas</h1>
      <p>Gestiona las solicitudes de tus clientes</p>
    </div>
    <span class="count-pill"><%= citas.size() %> cita<%= citas.size() != 1 ? "s" : "" %></span>
  </div>

  <% if (msg != null) { %>
  <div class="alert-success" id="alertMsg">
    <i class="bi bi-check-circle-fill"></i>
    <%= msg.replace("+"," ") %>
    <button class="alert-close" onclick="document.getElementById('alertMsg').remove()">×</button>
  </div>
  <% } %>

  <!-- FILTER TABS -->
  <div class="filter-tabs">
    <a href="solicitudes.jsp" class="tab <%= filtro.isEmpty() ? "active-all" : "" %>">
      <i class="bi bi-list-ul"></i> Todas
    </a>
    <a href="solicitudes.jsp?estado=PENDIENTE" class="tab <%= "PENDIENTE".equals(filtro) ? "active-pending" : "" %>">
      <i class="bi bi-clock"></i> Pendientes
    </a>
    <a href="solicitudes.jsp?estado=CONFIRMADA" class="tab <%= "CONFIRMADA".equals(filtro) ? "active-confirmed" : "" %>">
      <i class="bi bi-check-circle"></i> Confirmadas
    </a>
    <a href="solicitudes.jsp?estado=CANCELADA" class="tab <%= "CANCELADA".equals(filtro) ? "active-cancelled" : "" %>">
      <i class="bi bi-x-circle"></i> Canceladas
    </a>
    <a href="solicitudes.jsp?estado=REALIZADA" class="tab <%= "REALIZADA".equals(filtro) ? "active-done" : "" %>">
      <i class="bi bi-calendar2-check"></i> Realizadas
    </a>
  </div>

  <!-- TABLE -->
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>Cliente</th>
          <th>Propiedad</th>
          <th>Fecha solicitada</th>
          <th>Notas</th>
          <th>Estado</th>
          <th>Acciones</th>
        </tr>
      </thead>
      <tbody>
        <% if (citas.isEmpty()) { %>
        <tr class="empty-row">
          <td colspan="6">
            <div class="empty-icon"><i class="bi bi-calendar-x"></i></div>
            <div class="empty-title">No hay citas<%= !filtro.isEmpty() ? " con estado " + filtro.toLowerCase() : "" %></div>
            <div class="empty-sub">Cuando tus clientes soliciten visitas aparecerán aquí.</div>
          </td>
        </tr>
        <% } else { for (String[] c : citas) {
            String est = c[2];
            String bc = "PENDIENTE".equals(est)  ? "badge-pending"
                      : "CONFIRMADA".equals(est) ? "badge-confirmed"
                      : "CANCELADA".equals(est)  ? "badge-cancelled"
                      : "REALIZADA".equals(est)  ? "badge-done" : "badge-default";
        %>
        <tr>
          <td>
            <div class="client-name"><%= c[5] %></div>
            <% if (!c[6].isEmpty()) { %>
            <div class="client-phone"><i class="bi bi-telephone" style="font-size:10px"></i> <%= c[6] %></div>
            <% } %>
          </td>
          <td><span class="prop-name"><%= c[4] %></span></td>
          <td><span class="date-cell"><i class="bi bi-clock" style="font-size:11px;margin-right:4px"></i><%= c[1] %></span></td>
          <td><span class="notes-cell"><%= c[3].isEmpty() ? "—" : c[3] %></span></td>
          <td><span class="badge <%= bc %>"><%= est %></span></td>
          <td>
            <% if ("PENDIENTE".equals(est)) { %>
            <div class="actions-cell">
              <a href="solicitudes.jsp?action=confirmar&id=<%= c[0] %>" class="btn-confirm">
                <i class="bi bi-check-lg"></i> Confirmar
              </a>
              <a href="solicitudes.jsp?action=cancelar&id=<%= c[0] %>" class="btn-cancel">
                <i class="bi bi-x-lg"></i> Cancelar
              </a>
            </div>
            <% } else { %>
            <span style="color:var(--border);font-size:18px;">—</span>
            <% } %>
          </td>
        </tr>
        <% }} %>
      </tbody>
    </table>
  </div>
</div>
</body>
</html>
