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

    int totalVentas = 0, totalArriendos = 0, totalCitas = 0, totalPropiedades = 0, totalDisponibles = 0;
    double totalIngresos = 0;
    List<String[]> topPropiedades = new ArrayList<>();
    List<String[]> porTipo = new ArrayList<>();

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
        try {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM propiedades WHERE inmobiliaria_id=? AND estado != 'INACTIVO'");
            ps.setInt(1, uid); ResultSet rs = ps.executeQuery();
            if (rs.next()) totalPropiedades = rs.getInt(1); rs.close(); ps.close();

            ps = conn.prepareStatement(
                "SELECT estado, COUNT(*) as cnt FROM propiedades WHERE inmobiliaria_id=? AND estado IN ('VENDIDO','ARRENDADO','DISPONIBLE') GROUP BY estado");
            ps.setInt(1, uid); rs = ps.executeQuery();
            while (rs.next()) {
                String est = rs.getString("estado");
                if ("VENDIDO".equals(est)) totalVentas = rs.getInt("cnt");
                else if ("ARRENDADO".equals(est)) totalArriendos = rs.getInt("cnt");
                else if ("DISPONIBLE".equals(est)) totalDisponibles = rs.getInt("cnt");
            } rs.close(); ps.close();

            ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM citas c JOIN propiedades p ON c.propiedad_id=p.id WHERE p.inmobiliaria_id=?");
            ps.setInt(1, uid); rs = ps.executeQuery();
            if (rs.next()) totalCitas = rs.getInt(1); rs.close(); ps.close();

            try {
                ps = conn.prepareStatement(
                    "SELECT COALESCE(SUM(t.valor),0) FROM transacciones t JOIN propiedades p ON t.propiedad_id=p.id WHERE p.inmobiliaria_id=?");
                ps.setInt(1, uid); rs = ps.executeQuery();
                if (rs.next()) totalIngresos = rs.getDouble(1); rs.close(); ps.close();
            } catch (Exception ignored) {}

            ps = conn.prepareStatement(
                "SELECT tipo, COUNT(*) as cnt FROM propiedades WHERE inmobiliaria_id=? AND estado != 'INACTIVO' GROUP BY tipo ORDER BY cnt DESC");
            ps.setInt(1, uid); rs = ps.executeQuery();
            while (rs.next()) porTipo.add(new String[]{rs.getString("tipo"), String.valueOf(rs.getInt("cnt"))});
            rs.close(); ps.close();

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

    // Format ingresos
    String ingresosStr = totalIngresos >= 1_000_000
        ? String.format("$%.1fM", totalIngresos / 1_000_000)
        : totalIngresos >= 1_000 ? String.format("$%.0fK", totalIngresos / 1_000)
        : String.format("$%.0f", totalIngresos);
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Reportes — Sereno</title>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&family=Outfit:wght@300;400;500;600&display=swap" rel="stylesheet"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.0/font/bootstrap-icons.min.css" rel="stylesheet"/>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.0/chart.umd.min.js"></script>
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

    /* ── MAIN ── */
    .main{margin-left:248px;padding:32px 36px;min-height:100vh;}

    /* ── TOPBAR ── */
    .topbar{display:flex;justify-content:space-between;align-items:center;margin-bottom:32px;}
    .topbar-left h1{font-family:'Playfair Display',serif;font-size:26px;font-weight:900;color:var(--navy);}
    .topbar-left p{color:var(--slate-lt);font-size:14px;margin-top:2px;}
    .btn-print{display:inline-flex;align-items:center;gap:7px;padding:9px 20px;border:1.5px solid var(--border);border-radius:20px;background:var(--white);color:var(--slate);font-family:'Outfit',sans-serif;font-size:13px;font-weight:500;cursor:pointer;transition:all .2s;}
    .btn-print:hover{border-color:var(--blue-bright);color:var(--blue-bright);}

    /* ── KPI STRIP ── */
    .kpi-row{display:grid;grid-template-columns:repeat(5,1fr);gap:14px;margin-bottom:28px;}
    .kpi-card{background:var(--white);border-radius:14px;border:1.5px solid var(--border);padding:20px 20px 16px;position:relative;overflow:hidden;transition:box-shadow .2s;}
    .kpi-card:hover{box-shadow:0 8px 28px rgba(20,85,164,0.08);}
    .kpi-card::after{content:'';position:absolute;top:0;left:0;right:0;height:3px;}
    .kpi-card.c1::after{background:var(--blue-bright);}
    .kpi-card.c2::after{background:#22c55e;}
    .kpi-card.c3::after{background:var(--sky);}
    .kpi-card.c4::after{background:#f59e0b;}
    .kpi-card.c5::after{background:#8b5cf6;}
    .kpi-icon{width:38px;height:38px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:16px;margin-bottom:14px;}
    .kpi-card.c1 .kpi-icon{background:rgba(30,111,217,0.1);color:var(--blue-bright);}
    .kpi-card.c2 .kpi-icon{background:rgba(34,197,94,0.1);color:#22c55e;}
    .kpi-card.c3 .kpi-icon{background:rgba(74,157,224,0.1);color:var(--sky);}
    .kpi-card.c4 .kpi-icon{background:rgba(245,158,11,0.1);color:#f59e0b;}
    .kpi-card.c5 .kpi-icon{background:rgba(139,92,246,0.1);color:#8b5cf6;}
    .kpi-val{font-family:'Playfair Display',serif;font-size:32px;font-weight:900;color:var(--navy);line-height:1;margin-bottom:4px;}
    .kpi-lbl{font-size:12px;color:var(--slate-lt);}

    /* ── CONTENT ROW ── */
    .content-row{display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-bottom:20px;}
    .panel{background:var(--white);border-radius:14px;border:1.5px solid var(--border);padding:24px;}
    .panel-title{font-family:'Playfair Display',serif;font-size:17px;font-weight:700;color:var(--navy);margin-bottom:20px;display:flex;align-items:center;gap:8px;}
    .panel-title i{color:var(--blue-bright);font-size:15px;}

    /* Chart wrapper */
    .chart-wrap{position:relative;height:260px;display:flex;align-items:center;justify-content:center;}

    /* Progress bars */
    .prog-item{margin-bottom:18px;}
    .prog-item:last-child{margin-bottom:0;}
    .prog-header{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:6px;}
    .prog-name{font-size:13px;font-weight:500;color:var(--navy);max-width:70%;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;}
    .prog-val{font-size:12px;color:var(--slate-lt);}
    .prog-track{height:6px;background:var(--border);border-radius:3px;overflow:hidden;}
    .prog-bar{height:100%;border-radius:3px;background:linear-gradient(90deg, var(--blue) 0%, var(--sky) 100%);transition:width .6s ease;}

    /* Type table */
    .type-table{width:100%;border-collapse:collapse;}
    .type-table th{font-size:11px;font-weight:600;letter-spacing:1.5px;text-transform:uppercase;color:var(--slate-lt);padding:0 0 12px;text-align:left;}
    .type-table td{padding:10px 0;border-top:1.5px solid var(--border);font-size:14px;vertical-align:middle;}
    .type-table tr:first-child td{border-top:none;}
    .type-badge{display:inline-block;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:600;background:rgba(30,111,217,0.08);color:var(--blue-bright);}
    .pct-wrap{display:flex;align-items:center;gap:10px;}
    .pct-track{flex:1;height:5px;background:var(--border);border-radius:3px;overflow:hidden;}
    .pct-bar{height:100%;border-radius:3px;background:var(--blue-bright);}
    .pct-label{font-size:12px;color:var(--slate-lt);white-space:nowrap;}

    /* Empty */
    .empty{text-align:center;padding:40px 0;color:var(--slate-lt);font-size:14px;}
    .empty i{font-size:36px;color:var(--border);display:block;margin-bottom:10px;}

    @media(max-width:1300px){.kpi-row{grid-template-columns:repeat(3,1fr);}}
    @media(max-width:1100px){.content-row{grid-template-columns:1fr;}}
    @media(max-width:900px){.kpi-row{grid-template-columns:repeat(2,1fr);}}
    @media(max-width:768px){.sidebar{transform:translateX(-100%);}  .main{margin-left:0;padding:20px 16px;}}

    @media print{
      .sidebar,.btn-print{display:none!important;}
      .main{margin-left:0;padding:0;}
      .kpi-card,.panel{box-shadow:none;border:1px solid #ddd;}
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
    <a href="solicitudes.jsp" class="nav-link"><i class="bi bi-calendar-check"></i> Citas / Visitas</a>
    <a href="documentos.jsp" class="nav-link"><i class="bi bi-file-earmark-check"></i> Documentos</a>
    <div class="nav-section">Reportes</div>
    <a href="reportes.jsp" class="nav-link active"><i class="bi bi-bar-chart-line"></i> Reportes</a>
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
      <h1>Reportes</h1>
      <p>Resumen de rendimiento de tu portafolio</p>
    </div>
    <button class="btn-print" onclick="window.print()">
      <i class="bi bi-printer"></i> Imprimir
    </button>
  </div>

  <!-- KPIs -->
  <div class="kpi-row">
    <div class="kpi-card c1">
      <div class="kpi-icon"><i class="bi bi-building"></i></div>
      <div class="kpi-val"><%= totalPropiedades %></div>
      <div class="kpi-lbl">Total propiedades</div>
    </div>
    <div class="kpi-card c2">
      <div class="kpi-icon"><i class="bi bi-house-check"></i></div>
      <div class="kpi-val"><%= totalDisponibles %></div>
      <div class="kpi-lbl">Disponibles</div>
    </div>
    <div class="kpi-card c3">
      <div class="kpi-icon"><i class="bi bi-bag-check"></i></div>
      <div class="kpi-val"><%= totalVentas %></div>
      <div class="kpi-lbl">Vendidas</div>
    </div>
    <div class="kpi-card c4">
      <div class="kpi-icon"><i class="bi bi-calendar-event"></i></div>
      <div class="kpi-val"><%= totalCitas %></div>
      <div class="kpi-lbl">Citas recibidas</div>
    </div>
    <div class="kpi-card c5">
      <div class="kpi-icon"><i class="bi bi-currency-dollar"></i></div>
      <div class="kpi-val"><%= ingresosStr %></div>
      <div class="kpi-lbl">Ingresos registrados</div>
    </div>
  </div>

  <!-- CHARTS ROW -->
  <div class="content-row">

    <!-- Donut chart -->
    <div class="panel">
      <div class="panel-title"><i class="bi bi-pie-chart"></i> Distribución por Tipo</div>
      <% if (porTipo.isEmpty()) { %>
        <div class="empty"><i class="bi bi-building"></i>No hay propiedades aún.</div>
      <% } else { %>
        <div class="chart-wrap"><canvas id="chartTipo"></canvas></div>
      <% } %>
    </div>

    <!-- Estado bar chart -->
    <div class="panel">
      <div class="panel-title"><i class="bi bi-bar-chart-line"></i> Estado del Portafolio</div>
      <% if (totalPropiedades == 0) { %>
        <div class="empty"><i class="bi bi-graph-up"></i>Sin datos disponibles.</div>
      <% } else { %>
        <div class="chart-wrap"><canvas id="chartEstado"></canvas></div>
      <% } %>
    </div>
  </div>

  <div class="content-row">

    <!-- Top propiedades con más citas -->
    <div class="panel">
      <div class="panel-title"><i class="bi bi-trophy"></i> Top Propiedades por Citas</div>
      <% if (topPropiedades.isEmpty()) { %>
        <div class="empty"><i class="bi bi-calendar-x"></i>No hay citas registradas aún.</div>
      <% } else {
          int maxCitas = Integer.parseInt(topPropiedades.get(0)[1]);
          if (maxCitas == 0) maxCitas = 1;
          for (String[] tp : topPropiedades) {
              int citas = Integer.parseInt(tp[1]);
              int pct = (citas * 100) / maxCitas;
      %>
        <div class="prog-item">
          <div class="prog-header">
            <span class="prog-name"><%= tp[0].length() > 38 ? tp[0].substring(0,38)+"…" : tp[0] %></span>
            <span class="prog-val"><%= citas %> cita<%= citas != 1 ? "s" : "" %></span>
          </div>
          <div class="prog-track"><div class="prog-bar" style="width:<%= pct %>%"></div></div>
        </div>
      <% }} %>
    </div>

    <!-- Tabla por tipo -->
    <div class="panel">
      <div class="panel-title"><i class="bi bi-table"></i> Resumen por Tipo</div>
      <% if (porTipo.isEmpty()) { %>
        <div class="empty"><i class="bi bi-inbox"></i>Sin datos aún.</div>
      <% } else { %>
      <table class="type-table">
        <thead>
          <tr>
            <th>Tipo</th>
            <th>Cant.</th>
            <th>Participación</th>
          </tr>
        </thead>
        <tbody>
        <% for (String[] t : porTipo) {
            int cnt = Integer.parseInt(t[1]);
            int pct = totalTipo > 0 ? (cnt * 100) / totalTipo : 0;
        %>
          <tr>
            <td style="font-weight:500"><%= t[0] %></td>
            <td><span class="type-badge"><%= cnt %></span></td>
            <td>
              <div class="pct-wrap">
                <div class="pct-track"><div class="pct-bar" style="width:<%= pct %>%"></div></div>
                <span class="pct-label"><%= pct %>%</span>
              </div>
            </td>
          </tr>
        <% } %>
        </tbody>
      </table>
      <% } %>
    </div>
  </div>

</div>

<script>
<% if (!porTipo.isEmpty()) { %>
// Donut — tipo
const tipoLabels = [<% for(int i=0;i<porTipo.size();i++){%>'<%= porTipo.get(i)[0] %>'<%= i<porTipo.size()-1?",":"" %><% } %>];
const tipoData   = [<% for(int i=0;i<porTipo.size();i++){%><%= porTipo.get(i)[1] %><%= i<porTipo.size()-1?",":"" %><% } %>];
const palette = ['#1E6FD9','#4A9DE0','#A8D4F5','#1455A4','#122040','#6AB4E8','#2D86C9','#85C2F0'];
new Chart(document.getElementById('chartTipo'), {
  type: 'doughnut',
  data: {
    labels: tipoLabels,
    datasets: [{ data: tipoData, backgroundColor: palette, borderWidth: 0, hoverOffset: 6 }]
  },
  options: {
    responsive: true, maintainAspectRatio: false,
    cutout: '65%',
    plugins: {
      legend: { position: 'bottom', labels: { padding: 16, font: { family: 'Outfit', size: 12 }, color: '#4A5568' } }
    }
  }
});
<% } %>

<% if (totalPropiedades > 0) { %>
// Bar — estado
new Chart(document.getElementById('chartEstado'), {
  type: 'bar',
  data: {
    labels: ['Disponibles', 'Vendidas', 'Arrendadas'],
    datasets: [{
      data: [<%= totalDisponibles %>, <%= totalVentas %>, <%= totalArriendos %>],
      backgroundColor: ['rgba(30,111,217,0.15)', 'rgba(34,197,94,0.15)', 'rgba(74,157,224,0.15)'],
      borderColor: ['#1E6FD9', '#22c55e', '#4A9DE0'],
      borderWidth: 2, borderRadius: 8, borderSkipped: false
    }]
  },
  options: {
    responsive: true, maintainAspectRatio: false,
    plugins: { legend: { display: false } },
    scales: {
      x: { grid: { display: false }, ticks: { font: { family: 'Outfit', size: 12 }, color: '#8A9BB0' } },
      y: { grid: { color: '#D6E8F7' }, ticks: { font: { family: 'Outfit', size: 11 }, color: '#8A9BB0', stepSize: 1 }, beginAtZero: true }
    }
  }
});
<% } %>
</script>
</body>
</html>
