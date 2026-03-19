<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    Usuario usuario = (Usuario) session.getAttribute("usuario");
    if (usuario == null || !usuario.isAdmin()) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }

    String filtro = request.getParameter("tipo") != null ? request.getParameter("tipo") : "";
    double totalValor = 0, totalComision = 0;
    int cntVenta = 0, cntArriendo = 0;
    List<String[]> transacciones = new ArrayList<>();

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
        try {
            // Totales globales
            try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COALESCE(SUM(valor),0), COALESCE(SUM(comision),0) FROM transacciones")) {
                ResultSet rs = ps.executeQuery();
                if (rs.next()) { totalValor = rs.getDouble(1); totalComision = rs.getDouble(2); }
            }
            // Contadores por tipo
            try (PreparedStatement ps = conn.prepareStatement(
                "SELECT tipo, COUNT(*) as cnt FROM transacciones GROUP BY tipo")) {
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    String t = rs.getString("tipo"); int c = rs.getInt("cnt");
                    if ("VENTA".equals(t)) cntVenta = c;
                    else if ("ARRIENDO".equals(t)) cntArriendo = c;
                }
            }
            StringBuilder sql = new StringBuilder(
                "SELECT t.id, t.tipo, t.valor, t.comision, t.fecha_cierre, t.notas, " +
                "p.titulo, p.id AS pid, " +
                "uc.nombre AS cnombre, uc.apellido AS capellido, " +
                "ui.nombre AS inombre, ui.apellido AS iapellido " +
                "FROM transacciones t " +
                "JOIN propiedades p ON t.propiedad_id=p.id " +
                "JOIN usuarios uc ON t.cliente_id=uc.id " +
                "JOIN usuarios ui ON t.inmobiliaria_id=ui.id");
            if (!filtro.isEmpty()) sql.append(" WHERE t.tipo=?");
            sql.append(" ORDER BY t.id DESC");
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            if (!filtro.isEmpty()) ps.setString(1, filtro);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) transacciones.add(new String[]{
                String.valueOf(rs.getInt("id")), rs.getString("tipo"),
                String.format("%,.0f", rs.getDouble("valor")),
                String.format("%,.0f", rs.getDouble("comision")),
                rs.getString("fecha_cierre") != null ? rs.getString("fecha_cierre") : "",
                rs.getString("notas") != null ? rs.getString("notas") : "",
                rs.getString("titulo"), String.valueOf(rs.getInt("pid")),
                rs.getString("cnombre") + " " + rs.getString("capellido"),
                rs.getString("inombre") + " " + rs.getString("iapellido")
            });
            rs.close(); ps.close();
        } finally { conn.close(); }
    } catch (Exception e) { /* continuar */ }

    // Formato legible para totales
    String valorStr = totalValor >= 1_000_000_000
        ? String.format("$%.1fB", totalValor / 1_000_000_000)
        : totalValor >= 1_000_000 ? String.format("$%.1fM", totalValor / 1_000_000)
        : String.format("$%,.0f", totalValor);
    String comisionStr = totalComision >= 1_000_000
        ? String.format("$%.1fM", totalComision / 1_000_000)
        : String.format("$%,.0f", totalComision);
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Transacciones — Sereno Admin</title>
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

    /* ── SIDEBAR ── */
    .sidebar{width:248px;min-height:100vh;background:var(--navy);position:fixed;top:0;left:0;z-index:100;overflow-y:auto;display:flex;flex-direction:column;border-right:1px solid rgba(255,255,255,0.04);}
    .sidebar-brand{padding:26px 24px 14px;border-bottom:1px solid rgba(255,255,255,0.06);}
    .brand-logo{font-family:'Playfair Display',serif;font-size:22px;font-weight:700;color:var(--white);text-decoration:none;display:block;}
    .brand-logo span{color:var(--sky);}
    .brand-sub{color:rgba(255,255,255,0.25);font-size:11px;letter-spacing:1px;text-transform:uppercase;margin-top:3px;}
    .brand-role{margin:14px 16px 4px;padding:8px 12px;background:rgba(248,113,113,0.12);border:1px solid rgba(248,113,113,0.2);border-radius:8px;font-size:11px;font-weight:600;letter-spacing:1.5px;text-transform:uppercase;color:#fca5a5;display:flex;align-items:center;gap:6px;}
    .nav-section{color:rgba(255,255,255,0.2);font-size:10px;font-weight:600;letter-spacing:2px;text-transform:uppercase;padding:18px 24px 6px;}
    .nav-link{color:rgba(255,255,255,0.45);padding:10px 24px;display:flex;align-items:center;gap:10px;font-size:14px;text-decoration:none;transition:all .2s;border-left:3px solid transparent;}
    .nav-link i{font-size:15px;flex-shrink:0;}
    .nav-link:hover{color:rgba(255,255,255,0.85);background:rgba(255,255,255,0.04);}
    .nav-link.active{color:var(--white);background:rgba(30,111,217,0.15);border-left-color:var(--blue-bright);}
    .sidebar-footer{margin-top:auto;padding:20px 24px;border-top:1px solid rgba(255,255,255,0.06);}
    .user-mini{display:flex;align-items:center;gap:10px;margin-bottom:4px;}
    .user-avatar{width:34px;height:34px;border-radius:50%;background:#e05555;color:var(--white);font-weight:700;font-size:13px;display:flex;align-items:center;justify-content:center;flex-shrink:0;}
    .user-name{color:rgba(255,255,255,0.8);font-size:13px;font-weight:500;}
    .user-role{color:rgba(255,255,255,0.3);font-size:11px;}

    /* ── MAIN ── */
    .main{margin-left:248px;min-height:100vh;display:flex;flex-direction:column;}

    /* ── HEADER BANNER con métricas integradas ── */
    .header-banner{
      background:var(--navy);
      padding:28px 40px 0;
      position:relative;overflow:hidden;
    }
    .header-banner::after{content:'';position:absolute;right:-40px;top:-60px;width:280px;height:280px;border-radius:50%;background:radial-gradient(circle,rgba(34,197,94,0.08) 0%,transparent 70%);pointer-events:none;}
    .hb-top{display:grid;grid-template-columns:1fr auto;align-items:flex-start;gap:24px;margin-bottom:28px;}
    .hb-eyebrow{font-size:11px;font-weight:600;letter-spacing:3px;text-transform:uppercase;color:rgba(255,255,255,0.35);margin-bottom:6px;}
    .hb-title{font-family:'Playfair Display',serif;font-size:28px;font-weight:900;color:var(--white);line-height:1.1;}
    .hb-title em{font-style:italic;color:#86efac;}
    .hb-sub{color:rgba(255,255,255,0.4);font-size:13px;margin-top:4px;font-weight:300;}

    /* KPI cards dentro del banner (parte inferior del header) */
    .kpi-bar{display:grid;grid-template-columns:repeat(4,1fr);gap:0;border-top:1px solid rgba(255,255,255,0.06);}
    .kpi-cell{padding:20px 28px;border-right:1px solid rgba(255,255,255,0.06);transition:background .2s;}
    .kpi-cell:last-child{border-right:none;}
    .kpi-cell:hover{background:rgba(255,255,255,0.02);}
    .kpi-label{font-size:10px;font-weight:600;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,0.35);margin-bottom:6px;}
    .kpi-val{font-family:'Playfair Display',serif;font-size:26px;font-weight:900;color:var(--white);line-height:1;}
    .kpi-val.green{color:#86efac;}
    .kpi-val.blue{color:var(--sky-lt);}
    .kpi-val.amber{color:#fcd34d;}
    .kpi-sub{font-size:11px;color:rgba(255,255,255,0.3);margin-top:3px;}

    /* ── FILTER TABS ── */
    .filter-row{display:flex;gap:8px;padding:24px 40px 0;flex-wrap:wrap;}
    .ftab{padding:7px 18px;border-radius:20px;font-size:13px;font-weight:500;text-decoration:none;border:1.5px solid var(--border);background:var(--white);color:var(--slate);cursor:pointer;transition:all .2s;font-family:'Outfit',sans-serif;}
    .ftab:hover{border-color:var(--blue-bright);color:var(--blue-bright);}
    .ftab.on{background:var(--navy);color:var(--white);border-color:var(--navy);}
    .ftab.on-green{background:rgba(34,197,94,0.1);color:#16a34a;border-color:rgba(34,197,94,0.35);}
    .ftab.on-blue{background:rgba(30,111,217,0.1);color:var(--blue-bright);border-color:rgba(30,111,217,0.3);}

    /* ── CONTENT ── */
    .content{padding:20px 40px 48px;flex:1;}

    /* ── TABLE PANEL ── */
    .panel{background:var(--white);border-radius:14px;border:1.5px solid var(--border);overflow:hidden;}
    .panel-head{display:flex;justify-content:space-between;align-items:center;padding:18px 24px;border-bottom:1.5px solid var(--border);}
    .panel-title{font-family:'Playfair Display',serif;font-size:17px;font-weight:700;color:var(--navy);}
    .panel-count{font-size:13px;color:var(--slate-lt);}

    table{width:100%;border-collapse:collapse;}
    th{padding:11px 18px;font-size:10px;font-weight:600;letter-spacing:1.5px;text-transform:uppercase;color:var(--slate-lt);text-align:left;background:var(--ice);border-bottom:1.5px solid var(--border);}
    td{padding:14px 18px;font-size:13px;border-bottom:1.5px solid var(--border);vertical-align:middle;}
    tr:last-child td{border-bottom:none;}
    tbody tr{transition:background .15s;}
    tbody tr:hover{background:var(--ice);}

    .td-id{font-size:11px;color:var(--slate-lt);font-weight:600;letter-spacing:.5px;}
    .td-prop{color:var(--blue-bright);text-decoration:none;font-weight:600;font-size:13px;transition:color .2s;}
    .td-prop:hover{color:var(--sky);}
    .td-person{font-size:13px;color:var(--navy);font-weight:500;}
    .td-sub{font-size:11px;color:var(--slate-lt);}
    .td-valor{font-family:'Playfair Display',serif;font-size:16px;font-weight:700;color:#16a34a;}
    .td-comision{font-family:'Playfair Display',serif;font-size:15px;font-weight:600;color:var(--blue-bright);}
    .td-date{font-size:12px;color:var(--slate);white-space:nowrap;}
    .td-notes{font-size:12px;color:var(--slate-lt);max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;}

    .badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:600;white-space:nowrap;}
    .badge-venta{background:rgba(34,197,94,0.1);color:#16a34a;}
    .badge-arriendo{background:rgba(30,111,217,0.1);color:var(--blue-bright);}

    .empty-state{padding:48px;text-align:center;color:var(--slate-lt);font-size:14px;}
    .empty-state i{font-size:36px;color:var(--border);display:block;margin-bottom:10px;}

    @media(max-width:1100px){.kpi-bar{grid-template-columns:repeat(2,1fr);}}
    @media(max-width:768px){.sidebar{transform:translateX(-100);}  .main{margin-left:0;}.content{padding:20px 16px;}.filter-row{padding:16px 16px 0;}}
  </style>
</head>
<body>

<!-- SIDEBAR -->
<aside class="sidebar">
  <div class="sidebar-brand">
    <a href="${pageContext.request.contextPath}/" class="brand-logo">Ser<span>eno</span></a>
    <div class="brand-sub">Panel de Control</div>
  </div>
  <div class="brand-role"><i class="bi bi-shield-fill"></i> Administrador</div>
  <nav>
    <div class="nav-section">Principal</div>
    <a href="index.jsp" class="nav-link"><i class="bi bi-grid-1x2"></i> Dashboard</a>
    <a href="<%= request.getContextPath() %>/propiedades" class="nav-link"><i class="bi bi-building"></i> Propiedades</a>
    <div class="nav-section">Gestión</div>
    <a href="usuarios.jsp" class="nav-link"><i class="bi bi-people"></i> Usuarios</a>
    <a href="citas.jsp" class="nav-link"><i class="bi bi-calendar-check"></i> Citas</a>
    <a href="solicitudes.jsp" class="nav-link"><i class="bi bi-file-earmark-text"></i> Solicitudes</a>
    <a href="transacciones.jsp" class="nav-link active"><i class="bi bi-cash-coin"></i> Transacciones</a>
  </nav>
  <div class="sidebar-footer">
    <div class="user-mini">
      <div class="user-avatar"><%= usuario.getNombre().charAt(0) %><%= usuario.getApellido().charAt(0) %></div>
      <div>
        <div class="user-name"><%= usuario.getNombreCompleto() %></div>
        <div class="user-role">Administrador</div>
      </div>
    </div>
    <a href="<%= request.getContextPath() %>/logout" class="nav-link" style="padding:10px 0 0;border-left:none;color:rgba(255,255,255,0.35);">
      <i class="bi bi-box-arrow-left"></i> Cerrar sesión
    </a>
  </div>
</aside>

<!-- MAIN -->
<div class="main">

  <!-- HEADER BANNER con KPIs integrados -->
  <div class="header-banner">
    <div class="hb-top">
      <div>
        <div class="hb-eyebrow">Administración</div>
        <h1 class="hb-title">Historial de <em>Transacciones</em></h1>
        <p class="hb-sub"><%= cntVenta + cntArriendo %> negocios cerrados en total</p>
      </div>
    </div>
    <!-- KPI Bar integrada en el banner -->
    <div class="kpi-bar">
      <div class="kpi-cell">
        <div class="kpi-label">Total negocios</div>
        <div class="kpi-val"><%= cntVenta + cntArriendo %></div>
        <div class="kpi-sub">registrados</div>
      </div>
      <div class="kpi-cell">
        <div class="kpi-label">Ventas</div>
        <div class="kpi-val amber"><%= cntVenta %></div>
        <div class="kpi-sub">propiedades vendidas</div>
      </div>
      <div class="kpi-cell">
        <div class="kpi-label">Arriendos</div>
        <div class="kpi-val blue"><%= cntArriendo %></div>
        <div class="kpi-sub">propiedades arrendadas</div>
      </div>
      <div class="kpi-cell">
        <div class="kpi-label">Valor total</div>
        <div class="kpi-val green"><%= valorStr %></div>
        <div class="kpi-sub">comisiones: <%= comisionStr %></div>
      </div>
    </div>
  </div>

  <!-- FILTER TABS -->
  <div class="filter-row">
    <a href="transacciones.jsp" class="ftab <%= filtro.isEmpty() ? "on" : "" %>">
      <i class="bi bi-list-ul" style="margin-right:5px"></i> Todas
    </a>
    <a href="transacciones.jsp?tipo=VENTA" class="ftab <%= "VENTA".equals(filtro) ? "on-green" : "" %>">
      <i class="bi bi-house-check" style="margin-right:5px"></i> Ventas
    </a>
    <a href="transacciones.jsp?tipo=ARRIENDO" class="ftab <%= "ARRIENDO".equals(filtro) ? "on-blue" : "" %>">
      <i class="bi bi-key" style="margin-right:5px"></i> Arriendos
    </a>
  </div>

  <!-- CONTENT -->
  <div class="content" style="padding-top:20px;">

    <div class="panel">
      <div class="panel-head">
        <div class="panel-title">
          <% if (!filtro.isEmpty()) { %>
            Transacciones · <span style="font-style:italic;color:var(--blue-bright)"><%= filtro.toLowerCase() %></span>
          <% } else { %>
            Todas las transacciones
          <% } %>
        </div>
        <span class="panel-count"><%= transacciones.size() %> resultado<%= transacciones.size()!=1?"s":"" %></span>
      </div>

      <% if (transacciones.isEmpty()) { %>
        <div class="empty-state">
          <i class="bi bi-cash-coin"></i>
          No hay transacciones<%= !filtro.isEmpty() ? " de tipo " + filtro.toLowerCase() : "" %> registradas.
        </div>
      <% } else { %>
      <table>
        <thead>
          <tr>
            <th>#</th>
            <th>Propiedad</th>
            <th>Cliente</th>
            <th>Inmobiliaria</th>
            <th>Tipo</th>
            <th>Valor</th>
            <th>Comisión</th>
            <th>Fecha cierre</th>
            <th>Notas</th>
          </tr>
        </thead>
        <tbody>
          <% for (String[] t : transacciones) {
              boolean esVenta = "VENTA".equals(t[1]);
          %>
          <tr>
            <td><span class="td-id">TRX-<%= t[0] %></span></td>
            <td>
              <a href="<%= request.getContextPath() %>/propiedades?id=<%= t[7] %>" class="td-prop">
                <i class="bi bi-building" style="font-size:11px;margin-right:3px"></i><%= t[6] %>
              </a>
            </td>
            <td><span class="td-person"><%= t[8] %></span></td>
            <td><span class="td-sub"><%= t[9] %></span></td>
            <td>
              <span class="badge <%= esVenta ? "badge-venta" : "badge-arriendo" %>">
                <i class="bi bi-<%= esVenta ? "house-check" : "key" %>"></i> <%= t[1] %>
              </span>
            </td>
            <td><span class="td-valor">$<%= t[2] %></span></td>
            <td><span class="td-comision">$<%= t[3] %></span></td>
            <td>
              <span class="td-date">
                <i class="bi bi-calendar3" style="font-size:10px;margin-right:3px"></i><%= t[4].isEmpty() ? "—" : t[4] %>
              </span>
            </td>
            <td>
              <span class="td-notes" title="<%= t[5] %>">
                <%= t[5].isEmpty() ? "—" : t[5].length()>40 ? t[5].substring(0,40)+"…" : t[5] %>
              </span>
            </td>
          </tr>
          <% } %>
        </tbody>
      </table>
      <% } %>
    </div>

  </div>
</div>

</body>
</html>
