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
    String filtroEstado = request.getParameter("estado") != null ? request.getParameter("estado") : "";
    String msg = request.getParameter("msg");

    List<String[]> propiedades = new ArrayList<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://by8sl4ll3wmw8dex7qzt-mysql.services.clever-cloud.com:3306/by8sl4ll3wmw8dex7qzt?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "uf7uiezwq3tjedqa", "9vpBUmwZ8xqi4kP8FmXe");
        try {
            String sql = "SELECT p.id, p.titulo, p.tipo, p.operacion, p.precio, p.area_m2, p.estado, " +
                         "(SELECT url FROM propiedad_fotos WHERE propiedad_id=p.id AND es_portada=1 LIMIT 1) as foto " +
                         "FROM propiedades p WHERE p.inmobiliaria_id=? AND p.estado != 'INACTIVO'";
            if (!filtroEstado.isEmpty()) sql += " AND p.estado=?";
            sql += " ORDER BY p.id DESC";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, uid);
            if (!filtroEstado.isEmpty()) ps.setString(2, filtroEstado);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                propiedades.add(new String[]{
                    String.valueOf(rs.getInt("id")),
                    rs.getString("titulo"),
                    rs.getString("tipo"),
                    rs.getString("operacion"),
                    String.format("%,.0f", rs.getDouble("precio")),
                    rs.getObject("area_m2") != null ? String.valueOf(rs.getDouble("area_m2")) : "0",
                    rs.getString("estado"),
                    rs.getString("foto") != null ? rs.getString("foto") : ""
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
  <title>Mis Propiedades — Sereno</title>
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
    .sidebar{
      width:248px;min-height:100vh;background:var(--navy);
      position:fixed;top:0;left:0;z-index:100;overflow-y:auto;
      display:flex;flex-direction:column;
      border-right:1px solid rgba(255,255,255,0.04);
    }
    .sidebar-brand{padding:26px 24px 22px;border-bottom:1px solid rgba(255,255,255,0.06);}
    .brand-logo{font-family:'Playfair Display',serif;font-size:22px;font-weight:700;color:var(--white);text-decoration:none;display:block;}
    .brand-logo span{color:var(--sky);}
    .brand-sub{color:rgba(255,255,255,0.25);font-size:11px;letter-spacing:1px;text-transform:uppercase;margin-top:3px;}
    .nav-section{color:rgba(255,255,255,0.2);font-size:10px;font-weight:600;letter-spacing:2px;text-transform:uppercase;padding:20px 24px 6px;}
    .nav-link{color:rgba(255,255,255,0.45);padding:10px 24px;display:flex;align-items:center;gap:10px;font-size:14px;font-weight:400;text-decoration:none;transition:all .2s;border-left:3px solid transparent;position:relative;}
    .nav-link i{font-size:15px;flex-shrink:0;}
    .nav-link:hover{color:rgba(255,255,255,0.85);background:rgba(255,255,255,0.04);}
    .nav-link.active{color:var(--white);background:rgba(30,111,217,0.15);border-left-color:var(--blue-bright);}
    .nav-badge{margin-left:auto;background:var(--blue-bright);color:var(--white);font-size:10px;font-weight:600;padding:2px 7px;border-radius:20px;}
    .sidebar-footer{margin-top:auto;padding:20px 24px;border-top:1px solid rgba(255,255,255,0.06);}
    .user-mini{display:flex;align-items:center;gap:10px;}
    .user-avatar{width:34px;height:34px;border-radius:50%;background:var(--blue-bright);color:var(--white);font-weight:700;font-size:14px;display:flex;align-items:center;justify-content:center;flex-shrink:0;}
    .user-name{color:rgba(255,255,255,0.8);font-size:13px;font-weight:500;line-height:1.2;}
    .user-role{color:rgba(255,255,255,0.3);font-size:11px;}

    /* MAIN */
    .main{margin-left:248px;padding:32px 36px;min-height:100vh;}

    /* TOPBAR */
    .topbar{display:flex;justify-content:space-between;align-items:center;margin-bottom:28px;}
    .topbar-left h1{font-family:'Playfair Display',serif;font-size:26px;font-weight:900;color:var(--navy);line-height:1.1;}
    .topbar-left p{color:var(--slate-lt);font-size:14px;margin-top:2px;}
    .btn-primary-sereno{display:inline-flex;align-items:center;gap:7px;padding:10px 22px;background:var(--blue-bright);border:none;border-radius:40px;color:var(--white);font-family:'Outfit',sans-serif;font-size:14px;font-weight:500;cursor:pointer;text-decoration:none;transition:background .2s;}
    .btn-primary-sereno:hover{background:var(--sky);color:var(--white);}

    /* ALERT */
    .alert-success{
      display:flex;align-items:center;gap:10px;
      background:rgba(34,197,94,0.08);border:1.5px solid rgba(34,197,94,0.25);
      border-radius:10px;padding:12px 16px;
      color:#16a34a;font-size:14px;margin-bottom:20px;
    }
    .alert-close{margin-left:auto;background:none;border:none;color:#16a34a;cursor:pointer;font-size:16px;line-height:1;}

    /* FILTER BAR */
    .filter-bar{
      background:var(--white);border-radius:12px;
      border:1.5px solid var(--border);
      padding:16px 20px;margin-bottom:24px;
      display:flex;align-items:center;gap:12px;flex-wrap:wrap;
    }
    .filter-label{font-size:12px;font-weight:600;color:var(--slate);letter-spacing:0.5px;white-space:nowrap;}
    .filter-select{
      padding:8px 14px;border:1.5px solid var(--border);border-radius:8px;
      background:var(--ice);color:var(--navy);
      font-family:'Outfit',sans-serif;font-size:13px;outline:none;cursor:pointer;
      transition:border-color .2s;
    }
    .filter-select:focus{border-color:var(--blue-bright);}
    .btn-filter{padding:8px 18px;background:var(--blue-bright);border:none;border-radius:20px;color:var(--white);font-family:'Outfit',sans-serif;font-size:13px;font-weight:500;cursor:pointer;transition:background .2s;}
    .btn-filter:hover{background:var(--sky);}
    .btn-clear{padding:8px 18px;background:transparent;border:1.5px solid var(--border);border-radius:20px;color:var(--slate);font-family:'Outfit',sans-serif;font-size:13px;font-weight:400;cursor:pointer;text-decoration:none;transition:all .2s;}
    .btn-clear:hover{border-color:var(--blue-bright);color:var(--blue-bright);}

    /* GRID */
    .props-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;}
    @media(max-width:1200px){.props-grid{grid-template-columns:repeat(2,1fr);}}
    @media(max-width:800px){.props-grid{grid-template-columns:1fr;}}

    /* PROP CARD */
    .prop-card{
      background:var(--white);border-radius:14px;
      border:1.5px solid var(--border);overflow:hidden;
      transition:all .25s;
    }
    .prop-card:hover{transform:translateY(-4px);box-shadow:0 16px 48px rgba(20,85,164,0.1);border-color:var(--sky-lt);}
    .prop-img{width:100%;height:180px;object-fit:cover;display:block;}
    .prop-img-placeholder{
      width:100%;height:180px;
      background:linear-gradient(135deg,var(--ice) 0%,#cce3f5 100%);
      display:flex;align-items:center;justify-content:center;
      color:var(--sky-lt);font-size:3rem;
    }
    .prop-body{padding:18px 18px 16px;}
    .prop-head{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:6px;gap:8px;}
    .prop-title{font-family:'Playfair Display',serif;font-size:16px;font-weight:700;color:var(--navy);line-height:1.25;}
    .prop-meta{color:var(--slate-lt);font-size:12px;margin-bottom:10px;}
    .prop-price{font-family:'Playfair Display',serif;font-size:20px;font-weight:700;color:var(--blue);margin-bottom:14px;}
    .prop-actions{display:flex;gap:8px;flex-wrap:wrap;}

    /* Badges */
    .badge{display:inline-block;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:600;letter-spacing:0.3px;white-space:nowrap;flex-shrink:0;}
    .badge-green{background:rgba(34,197,94,0.1);color:#16a34a;}
    .badge-blue{background:rgba(30,111,217,0.1);color:var(--blue-bright);}
    .badge-gray{background:rgba(0,0,0,0.06);color:var(--slate);}
    .badge-yellow{background:rgba(234,179,8,0.1);color:#ca8a04;}

    /* Action buttons */
    .btn-edit{display:inline-flex;align-items:center;gap:5px;padding:7px 14px;border:1.5px solid var(--border);border-radius:20px;background:transparent;color:var(--slate);font-family:'Outfit',sans-serif;font-size:12px;font-weight:500;cursor:pointer;text-decoration:none;transition:all .2s;flex:1;justify-content:center;}
    .btn-edit:hover{border-color:var(--blue-bright);color:var(--blue-bright);}
    .btn-close-deal{display:inline-flex;align-items:center;gap:5px;padding:7px 14px;border:none;border-radius:20px;background:var(--blue-bright);color:var(--white);font-family:'Outfit',sans-serif;font-size:12px;font-weight:500;cursor:pointer;transition:background .2s;flex:1;justify-content:center;}
    .btn-close-deal:hover{background:var(--sky);}
    .btn-delete{display:inline-flex;align-items:center;justify-content:center;width:34px;height:34px;border:1.5px solid rgba(224,85,85,0.2);border-radius:20px;background:transparent;color:#e05555;font-size:13px;cursor:pointer;transition:all .2s;flex-shrink:0;}
    .btn-delete:hover{background:#e05555;color:var(--white);border-color:#e05555;}

    /* Empty state */
    .empty-state{grid-column:1/-1;text-align:center;padding:64px 20px;}
    .empty-icon{font-size:48px;color:var(--border);margin-bottom:16px;}
    .empty-title{font-family:'Playfair Display',serif;font-size:20px;font-weight:700;color:var(--navy);margin-bottom:8px;}
    .empty-sub{color:var(--slate-lt);font-size:14px;margin-bottom:24px;}

    /* MODAL */
    .modal-overlay{display:none;position:fixed;inset:0;z-index:200;background:rgba(10,22,40,0.6);backdrop-filter:blur(4px);align-items:center;justify-content:center;}
    .modal-overlay.open{display:flex;}
    .modal-box{background:var(--white);border-radius:16px;width:100%;max-width:480px;margin:24px;box-shadow:0 40px 80px rgba(0,0,0,0.3);overflow:hidden;}
    .modal-header{padding:22px 24px 18px;border-bottom:1.5px solid var(--border);display:flex;justify-content:space-between;align-items:center;}
    .modal-title{font-family:'Playfair Display',serif;font-size:18px;font-weight:700;color:var(--navy);}
    .modal-close{background:none;border:none;color:var(--slate-lt);font-size:20px;cursor:pointer;line-height:1;padding:0;}
    .modal-close:hover{color:var(--navy);}
    .modal-body{padding:24px;}
    .modal-footer{padding:16px 24px;border-top:1.5px solid var(--border);display:flex;justify-content:flex-end;gap:10px;}

    /* Form fields inside modal */
    .field{margin-bottom:16px;}
    .field label{display:block;font-size:11px;font-weight:600;letter-spacing:1px;text-transform:uppercase;color:var(--slate);margin-bottom:6px;}
    .field input,.field select,.field textarea{width:100%;padding:11px 14px;border:1.5px solid var(--border);border-radius:8px;background:var(--ice);font-family:'Outfit',sans-serif;font-size:14px;color:var(--navy);outline:none;transition:border-color .2s,background .2s;}
    .field input:focus,.field select:focus,.field textarea:focus{border-color:var(--blue-bright);background:var(--white);}
    .field textarea{resize:vertical;min-height:72px;}
    .field-hint{color:var(--slate-lt);font-size:11px;margin-top:4px;}

    .btn-modal-cancel{padding:10px 20px;border:1.5px solid var(--border);border-radius:20px;background:transparent;color:var(--slate);font-family:'Outfit',sans-serif;font-size:14px;cursor:pointer;transition:all .2s;}
    .btn-modal-cancel:hover{border-color:var(--slate);color:var(--navy);}
    .btn-modal-confirm{padding:10px 22px;background:var(--blue-bright);border:none;border-radius:20px;color:var(--white);font-family:'Outfit',sans-serif;font-size:14px;font-weight:500;cursor:pointer;transition:background .2s;}
    .btn-modal-confirm:hover{background:var(--sky);}
    .btn-modal-danger{padding:10px 22px;background:#e05555;border:none;border-radius:20px;color:var(--white);font-family:'Outfit',sans-serif;font-size:14px;font-weight:500;cursor:pointer;transition:background .2s;}
    .btn-modal-danger:hover{background:#c0392b;}

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
    <a href="mis-propiedades.jsp" class="nav-link active"><i class="bi bi-building"></i> Mis Propiedades</a>
    <div class="nav-section">Gestión</div>
    <a href="solicitudes.jsp" class="nav-link"><i class="bi bi-calendar-check"></i> Citas / Visitas</a>
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
      <h1>Mis Propiedades</h1>
      <p>Gestiona tu portafolio inmobiliario</p>
    </div>
    <a href="<%= request.getContextPath() %>/propiedades?action=form" class="btn-primary-sereno">
      <i class="bi bi-plus-lg"></i> Nueva Propiedad
    </a>
  </div>

  <% if (msg != null) { %>
  <div class="alert-success" id="alertMsg">
    <i class="bi bi-check-circle-fill"></i>
    <%= msg.replace("+"," ") %>
    <button class="alert-close" onclick="document.getElementById('alertMsg').remove()">×</button>
  </div>
  <% } %>

  <!-- FILTER -->
  <div class="filter-bar">
    <span class="filter-label">Filtrar por estado:</span>
    <form method="get" style="display:flex;align-items:center;gap:10px;flex-wrap:wrap;">
      <select name="estado" class="filter-select">
        <option value="">Todos</option>
        <option value="DISPONIBLE" <%= "DISPONIBLE".equals(filtroEstado)?"selected":"" %>>Disponible</option>
        <option value="ARRENDADO"  <%= "ARRENDADO".equals(filtroEstado)?"selected":"" %>>Arrendado</option>
        <option value="VENDIDO"    <%= "VENDIDO".equals(filtroEstado)?"selected":"" %>>Vendido</option>
        <option value="RESERVADO"  <%= "RESERVADO".equals(filtroEstado)?"selected":"" %>>Reservado</option>
      </select>
      <button type="submit" class="btn-filter">Filtrar</button>
      <a href="mis-propiedades.jsp" class="btn-clear">Limpiar</a>
    </form>
    <span style="margin-left:auto;color:var(--slate-lt);font-size:13px;"><%= propiedades.size() %> propiedad<%= propiedades.size() != 1 ? "es" : "" %></span>
  </div>

  <!-- GRID -->
  <div class="props-grid">
    <% if (propiedades.isEmpty()) { %>
      <div class="empty-state">
        <div class="empty-icon"><i class="bi bi-building"></i></div>
        <div class="empty-title">No tienes propiedades aún</div>
        <div class="empty-sub">Agrega tu primera propiedad para comenzar a gestionar tu portafolio.</div>
        <a href="<%= request.getContextPath() %>/propiedades?action=form" class="btn-primary-sereno">
          <i class="bi bi-plus-lg"></i> Agregar propiedad
        </a>
      </div>
    <% } else { for (String[] p : propiedades) {
        String est = p[6];
        String bc = "DISPONIBLE".equals(est) ? "badge-green"
                  : "ARRENDADO".equals(est)  ? "badge-blue"
                  : "VENDIDO".equals(est)     ? "badge-gray" : "badge-yellow";
        String foto = p[7]; %>
      <div class="prop-card">
        <% if (!foto.isEmpty()) { %>
          <img src="<%= foto %>" class="prop-img" alt="<%= p[1] %>"/>
        <% } else { %>
          <div class="prop-img-placeholder"><i class="bi bi-building"></i></div>
        <% } %>
        <div class="prop-body">
          <div class="prop-head">
            <div class="prop-title"><%= p[1] %></div>
            <span class="badge <%= bc %>"><%= est %></span>
          </div>
          <div class="prop-meta"><%= p[2] %> · <%= p[3] %> · <%= p[5] %> m²</div>
          <div class="prop-price">$<%= p[4] %></div>
          <div class="prop-actions">
            <a href="<%= request.getContextPath() %>/propiedades?action=form&id=<%= p[0] %>" class="btn-edit">
              <i class="bi bi-pencil"></i> Editar
            </a>
            <% if ("DISPONIBLE".equals(est)) { %>
            <button onclick="cerrarNegocio('<%= p[0] %>')" class="btn-close-deal">
              <i class="bi bi-handshake"></i> Cerrar
            </button>
            <% } %>
            <button onclick="confirmarEliminar('<%= p[0] %>','<%= p[1].replace("'","") %>')" class="btn-delete">
              <i class="bi bi-trash"></i>
            </button>
          </div>
        </div>
      </div>
    <% }} %>
  </div>
</div>

<!-- MODAL CERRAR NEGOCIO -->
<div class="modal-overlay" id="modalNegocio">
  <div class="modal-box">
    <div class="modal-header">
      <div class="modal-title"><i class="bi bi-handshake" style="color:var(--blue-bright);margin-right:8px"></i>Cerrar Negocio</div>
      <button class="modal-close" onclick="closeModal('modalNegocio')">×</button>
    </div>
    <form method="post" action="<%= request.getContextPath() %>/transacciones">
      <div class="modal-body">
        <input type="hidden" name="propiedadId" id="negocioPropId"/>
        <div class="field">
          <label>ID del Cliente</label>
          <input type="number" name="clienteId" required placeholder="ID del usuario cliente"/>
          <div class="field-hint">Puedes verlo en el panel de administración</div>
        </div>
        <div class="field">
          <label>Tipo de operación</label>
          <select name="tipo" required>
            <option value="VENTA">Venta</option>
            <option value="ARRIENDO">Arriendo</option>
          </select>
        </div>
        <div class="field">
          <label>Valor ($)</label>
          <input type="number" name="valor" required placeholder="Ej: 350000000"/>
        </div>
        <div class="field">
          <label>Comisión ($)</label>
          <input type="number" name="comision" placeholder="Opcional — dejar en 0 si no aplica"/>
        </div>
        <div class="field">
          <label>Fecha de cierre</label>
          <input type="date" name="fechaCierre" required/>
        </div>
        <div class="field">
          <label>Notas (opcional)</label>
          <textarea name="notas" placeholder="Observaciones del negocio..."></textarea>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn-modal-cancel" onclick="closeModal('modalNegocio')">Cancelar</button>
        <button type="submit" class="btn-modal-confirm"><i class="bi bi-check-lg"></i> Registrar negocio</button>
      </div>
    </form>
  </div>
</div>

<!-- MODAL ELIMINAR -->
<div class="modal-overlay" id="modalEliminar">
  <div class="modal-box">
    <div class="modal-header">
      <div class="modal-title">Confirmar eliminación</div>
      <button class="modal-close" onclick="closeModal('modalEliminar')">×</button>
    </div>
    <div class="modal-body">
      <p style="color:var(--slate);font-size:15px;line-height:1.6;">
        ¿Estás seguro de que deseas eliminar <strong id="nombreProp" style="color:var(--navy)"></strong>?
        <br><span style="font-size:13px;color:var(--slate-lt);">Esta acción no se puede deshacer.</span>
      </p>
    </div>
    <div class="modal-footer">
      <button type="button" class="btn-modal-cancel" onclick="closeModal('modalEliminar')">Cancelar</button>
      <form method="post" action="<%= request.getContextPath() %>/propiedades" style="margin:0">
        <input type="hidden" name="action" value="delete"/>
        <input type="hidden" name="id" id="idPropEliminar"/>
        <button type="submit" class="btn-modal-danger"><i class="bi bi-trash"></i> Eliminar</button>
      </form>
    </div>
  </div>
</div>

<script>
  function openModal(id) { document.getElementById(id).classList.add('open'); }
  function closeModal(id) { document.getElementById(id).classList.remove('open'); }

  function confirmarEliminar(id, nombre) {
    document.getElementById('idPropEliminar').value = id;
    document.getElementById('nombreProp').textContent = nombre;
    openModal('modalEliminar');
  }
  function cerrarNegocio(id) {
    document.getElementById('negocioPropId').value = id;
    openModal('modalNegocio');
  }

  // Cerrar al click en overlay
  document.querySelectorAll('.modal-overlay').forEach(overlay => {
    overlay.addEventListener('click', e => {
      if (e.target === overlay) overlay.classList.remove('open');
    });
  });
</script>
</body>
</html>
