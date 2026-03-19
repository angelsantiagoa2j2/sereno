<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Propiedad, com.inmovista.model.Usuario" %>
<%
    Propiedad p = (Propiedad) request.getAttribute("propiedad");
    boolean esEdicion = p != null;
    Usuario usuario = (Usuario) session.getAttribute("usuario");
    String error = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Sereno — <%= esEdicion ? "Editar" : "Nueva" %> Propiedad</title>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,700;0,900;1,700&family=Outfit:wght@300;400;500;600&display=swap" rel="stylesheet"/>
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

    /* ── HEADER ── */
    header{
      background:var(--navy);
      padding:16px 48px;
      display:flex;justify-content:space-between;align-items:center;
      border-bottom:1px solid rgba(255,255,255,0.06);
      position:sticky;top:0;z-index:100;
    }
    .logo{font-family:'Playfair Display',serif;font-size:22px;font-weight:700;color:var(--white);text-decoration:none;}
    .logo span{color:var(--sky);}
    .header-right{display:flex;align-items:center;gap:10px;}
    .btn-back{display:inline-flex;align-items:center;gap:6px;padding:7px 16px;border:1.5px solid rgba(255,255,255,0.2);border-radius:20px;color:rgba(255,255,255,0.65);font-family:'Outfit',sans-serif;font-size:13px;text-decoration:none;cursor:pointer;background:transparent;transition:all .2s;}
    .btn-back:hover{border-color:rgba(255,255,255,0.45);color:var(--white);}

    /* ── LAYOUT ── */
    .page{display:grid;grid-template-columns:260px 1fr;min-height:calc(100vh - 57px);}

    /* ── LEFT NAV PANEL ── */
    .left-nav{
      background:var(--navy-mid);
      border-right:1px solid rgba(255,255,255,0.06);
      padding:36px 0;
      position:sticky;top:57px;height:calc(100vh - 57px);
      overflow-y:auto;
    }
    .ln-heading{padding:0 28px 16px;font-size:10px;font-weight:600;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,0.25);}
    .ln-item{display:flex;align-items:center;gap:12px;padding:12px 28px;color:rgba(255,255,255,0.4);font-size:13px;cursor:pointer;transition:all .2s;border-left:3px solid transparent;text-decoration:none;}
    .ln-item i{font-size:15px;flex-shrink:0;}
    .ln-item:hover{color:rgba(255,255,255,0.75);background:rgba(255,255,255,0.04);}
    .ln-item.active{color:var(--white);background:rgba(30,111,217,0.15);border-left-color:var(--blue-bright);}
    .ln-num{width:20px;height:20px;border-radius:50%;background:rgba(255,255,255,0.08);color:rgba(255,255,255,0.4);font-size:10px;font-weight:600;display:flex;align-items:center;justify-content:center;flex-shrink:0;transition:all .2s;}
    .ln-item.active .ln-num{background:var(--blue-bright);color:var(--white);}
    .ln-item.done .ln-num{background:#22c55e;color:var(--white);}

    /* ── FORM AREA ── */
    .form-area{padding:40px 52px 80px;}

    /* ── PAGE HEADER ── */
    .form-header{margin-bottom:36px;}
    .form-eyebrow{font-size:11px;font-weight:600;letter-spacing:3px;text-transform:uppercase;color:var(--blue-bright);margin-bottom:10px;display:flex;align-items:center;gap:8px;}
    .form-eyebrow::before{content:'';width:18px;height:1.5px;background:var(--blue-bright);}
    .form-title{font-family:'Playfair Display',serif;font-size:clamp(28px,3vw,38px);font-weight:900;color:var(--navy);line-height:1.05;}
    .form-sub{color:var(--slate-lt);font-size:14px;margin-top:6px;font-weight:300;}

    /* ── ALERT ── */
    .alert-err{display:flex;align-items:center;gap:10px;padding:12px 16px;border-radius:10px;background:rgba(224,85,85,0.08);border:1.5px solid rgba(224,85,85,0.25);color:#e05555;font-size:14px;margin-bottom:28px;}

    /* ── SECTION ── */
    .form-section{margin-bottom:36px;}
    .section-head{display:flex;align-items:center;gap:14px;margin-bottom:22px;padding-bottom:14px;border-bottom:1.5px solid var(--border);}
    .section-icon{width:38px;height:38px;border-radius:10px;background:rgba(30,111,217,0.1);color:var(--blue-bright);display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;}
    .section-title{font-family:'Playfair Display',serif;font-size:18px;font-weight:700;color:var(--navy);}
    .section-sub{font-size:12px;color:var(--slate-lt);margin-top:1px;}

    /* ── GRID ── */
    .grid-1{display:grid;grid-template-columns:1fr;gap:18px;}
    .grid-2{display:grid;grid-template-columns:1fr 1fr;gap:18px;}
    .grid-3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:18px;}
    .grid-4{display:grid;grid-template-columns:1fr 1fr 1fr 1fr;gap:18px;}
    .col-span-2{grid-column:span 2;}
    @media(max-width:700px){.grid-2,.grid-3,.grid-4{grid-template-columns:1fr;}.col-span-2{grid-column:span 1;}}

    /* ── FIELDS ── */
    .field label{display:block;font-size:11px;font-weight:600;letter-spacing:1px;text-transform:uppercase;color:var(--slate);margin-bottom:7px;}
    .field input,.field select,.field textarea{
      width:100%;padding:12px 14px;
      border:1.5px solid var(--border);border-radius:8px;
      background:var(--ice);font-family:'Outfit',sans-serif;font-size:14px;
      color:var(--navy);outline:none;
      transition:border-color .2s,background .2s;
    }
    .field input:focus,.field select:focus,.field textarea:focus{
      border-color:var(--blue-bright);background:var(--white);
      box-shadow:0 0 0 3px rgba(30,111,217,0.08);
    }
    .field input::placeholder,.field textarea::placeholder{color:rgba(0,0,0,0.25);}
    .field textarea{resize:vertical;min-height:100px;}
    .field-hint{font-size:11px;color:var(--slate-lt);margin-top:5px;}

    /* Tipo/Operacion toggle-style select */
    .select-group{display:grid;gap:10px;}
    .select-group.g2{grid-template-columns:1fr 1fr;}
    .select-group.g3{grid-template-columns:1fr 1fr 1fr;}
    @media(max-width:600px){.select-group.g2,.select-group.g3{grid-template-columns:1fr;}}

    /* ── FORM ACTIONS ── */
    .form-actions{
      display:flex;justify-content:flex-end;gap:12px;
      padding-top:32px;border-top:1.5px solid var(--border);
      margin-top:40px;
    }
    .btn-cancel{display:inline-flex;align-items:center;gap:6px;padding:12px 26px;border:1.5px solid var(--border);border-radius:40px;background:transparent;color:var(--slate);font-family:'Outfit',sans-serif;font-size:14px;font-weight:400;cursor:pointer;text-decoration:none;transition:all .2s;}
    .btn-cancel:hover{border-color:var(--slate);color:var(--navy);}
    .btn-save{display:inline-flex;align-items:center;gap:7px;padding:12px 32px;background:var(--blue-bright);border:none;border-radius:40px;color:var(--white);font-family:'Outfit',sans-serif;font-size:14px;font-weight:600;cursor:pointer;transition:background .2s;}
    .btn-save:hover{background:var(--sky);}

    @media(max-width:900px){
      .page{grid-template-columns:1fr;}
      .left-nav{display:none;}
      .form-area{padding:28px 24px 60px;}
    }
  </style>
</head>
<body>

<!-- HEADER -->
<header>
  <a href="${pageContext.request.contextPath}/" class="logo">Ser<span>eno</span></a>
  <div class="header-right">
    <button onclick="history.back()" class="btn-back">
      <i class="bi bi-arrow-left"></i> Volver
    </button>
  </div>
</header>

<div class="page">

  <!-- LEFT NAV -->
  <aside class="left-nav">
    <div class="ln-heading">Secciones del formulario</div>
    <a href="#sec-basica" class="ln-item active">
      <span class="ln-num">1</span>
      <i class="bi bi-file-text"></i>
      Información básica
    </a>
    <a href="#sec-tipo" class="ln-item">
      <span class="ln-num">2</span>
      <i class="bi bi-tag"></i>
      Tipo y operación
    </a>
    <a href="#sec-precio" class="ln-item">
      <span class="ln-num">3</span>
      <i class="bi bi-currency-dollar"></i>
      Precio y área
    </a>
    <a href="#sec-caract" class="ln-item">
      <span class="ln-num">4</span>
      <i class="bi bi-house-gear"></i>
      Características
    </a>
    <a href="#sec-ubic" class="ln-item">
      <span class="ln-num">5</span>
      <i class="bi bi-geo-alt"></i>
      Ubicación
    </a>
  </aside>

  <!-- FORM AREA -->
  <div class="form-area">

    <div class="form-header">
      <div class="form-eyebrow"><%= esEdicion ? "Editando propiedad" : "Nueva propiedad" %></div>
      <h1 class="form-title">
        <%= esEdicion ? "Editar propiedad" : "Publicar propiedad" %>
      </h1>
      <p class="form-sub">
        <%= esEdicion ? "Modifica los datos y guarda los cambios." : "Completa la información para publicar en el catálogo." %>
      </p>
    </div>

    <% if (error != null) { %>
    <div class="alert-err">
      <i class="bi bi-exclamation-circle-fill"></i> <%= error %>
    </div>
    <% } %>

    <form method="post" action="${pageContext.request.contextPath}/propiedades?action=save">
      <% if (esEdicion) { %>
        <input type="hidden" name="id" value="<%= p.getId() %>"/>
      <% } %>

      <!-- ── SECCIÓN 1: Información básica ── -->
      <div class="form-section" id="sec-basica">
        <div class="section-head">
          <div class="section-icon"><i class="bi bi-file-text"></i></div>
          <div>
            <div class="section-title">Información básica</div>
            <div class="section-sub">Título y descripción de la propiedad</div>
          </div>
        </div>
        <div class="grid-1">
          <div class="field">
            <label>Título *</label>
            <input type="text" name="titulo" required placeholder="Ej: Casa Colonial en Cañaveral"
                   value="<%= esEdicion ? p.getTitulo() : "" %>"/>
          </div>
          <div class="field">
            <label>Descripción</label>
            <textarea name="descripcion" placeholder="Describe la propiedad en detalle…"><%= esEdicion && p.getDescripcion() != null ? p.getDescripcion() : "" %></textarea>
            <div class="field-hint">Una descripción detallada aumenta el interés de los compradores.</div>
          </div>
        </div>
      </div>

      <!-- ── SECCIÓN 2: Tipo y operación ── -->
      <div class="form-section" id="sec-tipo">
        <div class="section-head">
          <div class="section-icon"><i class="bi bi-tag"></i></div>
          <div>
            <div class="section-title">Tipo y operación</div>
            <div class="section-sub">Clasifica la propiedad correctamente</div>
          </div>
        </div>
        <div class="grid-2">
          <div class="field">
            <label>Tipo de propiedad *</label>
            <select name="tipo" required>
              <option value="">Seleccionar…</option>
              <option value="CASA"        <%= esEdicion && p.getTipo().name().equals("CASA")        ? "selected":"" %>>Casa</option>
              <option value="APARTAMENTO" <%= esEdicion && p.getTipo().name().equals("APARTAMENTO") ? "selected":"" %>>Apartamento</option>
              <option value="TERRENO"     <%= esEdicion && p.getTipo().name().equals("TERRENO")     ? "selected":"" %>>Terreno</option>
              <option value="LOCAL"       <%= esEdicion && p.getTipo().name().equals("LOCAL")       ? "selected":"" %>>Local</option>
              <option value="FINCA"       <%= esEdicion && p.getTipo().name().equals("FINCA")       ? "selected":"" %>>Finca</option>
              <option value="BODEGA"      <%= esEdicion && p.getTipo().name().equals("BODEGA")      ? "selected":"" %>>Bodega</option>
            </select>
          </div>
          <div class="field">
            <label>Tipo de operación *</label>
            <select name="operacion" required>
              <option value="">Seleccionar…</option>
              <option value="VENTA"          <%= esEdicion && p.getOperacion().name().equals("VENTA")          ? "selected":"" %>>Venta</option>
              <option value="ARRIENDO"       <%= esEdicion && p.getOperacion().name().equals("ARRIENDO")       ? "selected":"" %>>Arriendo</option>
              <option value="VENTA_ARRIENDO" <%= esEdicion && p.getOperacion().name().equals("VENTA_ARRIENDO") ? "selected":"" %>>Venta / Arriendo</option>
            </select>
          </div>
        </div>
      </div>

      <!-- ── SECCIÓN 3: Precio y área ── -->
      <div class="form-section" id="sec-precio">
        <div class="section-head">
          <div class="section-icon"><i class="bi bi-currency-dollar"></i></div>
          <div>
            <div class="section-title">Precio y área</div>
            <div class="section-sub">Valor en pesos colombianos</div>
          </div>
        </div>
        <div class="grid-2">
          <div class="field">
            <label>Precio (COP) *</label>
            <input type="text" name="precio" required placeholder="Ej: 350000000"
                   value="<%= esEdicion ? p.getPrecio().toPlainString() : "" %>"/>
            <div class="field-hint">Ingresa el valor sin puntos ni comas.</div>
          </div>
          <div class="field">
            <label>Área (m²)</label>
            <input type="number" name="areaM2" min="1" step="0.1" placeholder="Ej: 180"
                   value="<%= esEdicion && p.getAreaM2() != null ? p.getAreaM2().toPlainString() : "" %>"/>
          </div>
        </div>
      </div>

      <!-- ── SECCIÓN 4: Características ── -->
      <div class="form-section" id="sec-caract">
        <div class="section-head">
          <div class="section-icon"><i class="bi bi-house-gear"></i></div>
          <div>
            <div class="section-title">Características</div>
            <div class="section-sub">Detalles físicos de la propiedad</div>
          </div>
        </div>
        <div class="grid-4">
          <div class="field">
            <label>Habitaciones</label>
            <input type="number" name="habitaciones" min="0" placeholder="0"
                   value="<%= esEdicion ? p.getHabitaciones() : "0" %>"/>
          </div>
          <div class="field">
            <label>Baños</label>
            <input type="number" name="banos" min="0" placeholder="0"
                   value="<%= esEdicion ? p.getBanos() : "0" %>"/>
          </div>
          <div class="field">
            <label>Parqueaderos</label>
            <input type="number" name="parqueaderos" min="0" placeholder="0"
                   value="<%= esEdicion ? p.getParqueaderos() : "0" %>"/>
          </div>
          <div class="field">
            <label>Estrato</label>
            <input type="number" name="estrato" min="1" max="6" placeholder="1–6"
                   value="<%= esEdicion && p.getEstrato() != null ? p.getEstrato() : "" %>"/>
          </div>
        </div>

        <% if (esEdicion && usuario != null && usuario.isAdmin()) { %>
        <div class="grid-2" style="margin-top:18px">
          <div class="field">
            <label>Estado de la propiedad</label>
            <select name="estado">
              <option value="DISPONIBLE" <%= p.getEstado().name().equals("DISPONIBLE") ? "selected":"" %>>Disponible</option>
              <option value="RESERVADO"  <%= p.getEstado().name().equals("RESERVADO")  ? "selected":"" %>>Reservado</option>
              <option value="VENDIDO"    <%= p.getEstado().name().equals("VENDIDO")    ? "selected":"" %>>Vendido</option>
              <option value="ARRENDADO"  <%= p.getEstado().name().equals("ARRENDADO")  ? "selected":"" %>>Arrendado</option>
            </select>
          </div>
        </div>
        <% } else { %>
          <input type="hidden" name="estado" value="<%= esEdicion ? p.getEstado().name() : "DISPONIBLE" %>"/>
        <% } %>
      </div>

      <!-- ── SECCIÓN 5: Ubicación ── -->
      <div class="form-section" id="sec-ubic">
        <div class="section-head">
          <div class="section-icon"><i class="bi bi-geo-alt"></i></div>
          <div>
            <div class="section-title">Ubicación</div>
            <div class="section-sub">Dirección y ciudad de la propiedad</div>
          </div>
        </div>
        <div class="grid-2">
          <div class="field">
            <label>Dirección *</label>
            <input type="text" name="direccion" required placeholder="Ej: Cra 28 # 52-14"
                   value="<%= esEdicion ? p.getDireccion() : "" %>"/>
          </div>
          <div class="field">
            <label>Barrio</label>
            <input type="text" name="barrio" placeholder="Ej: Cañaveral"
                   value="<%= esEdicion && p.getBarrio() != null ? p.getBarrio() : "" %>"/>
          </div>
          <div class="field">
            <label>Ciudad *</label>
            <select name="ciudadId" required>
              <option value="">Seleccionar…</option>
              <option value="1" <%= esEdicion && p.getCiudadId()==1 ? "selected":"" %>>Bucaramanga</option>
              <option value="2" <%= esEdicion && p.getCiudadId()==2 ? "selected":"" %>>Floridablanca</option>
              <option value="3" <%= esEdicion && p.getCiudadId()==3 ? "selected":"" %>>Girón</option>
              <option value="4" <%= esEdicion && p.getCiudadId()==4 ? "selected":"" %>>Piedecuesta</option>
              <option value="5" <%= esEdicion && p.getCiudadId()==5 ? "selected":"" %>>Bogotá</option>
              <option value="6" <%= esEdicion && p.getCiudadId()==6 ? "selected":"" %>>Medellín</option>
              <option value="7" <%= esEdicion && p.getCiudadId()==7 ? "selected":"" %>>Cali</option>
            </select>
          </div>
        </div>
      </div>

      <!-- ACTIONS -->
      <div class="form-actions">
        <button type="button" onclick="history.back()" class="btn-cancel">
          <i class="bi bi-x-lg"></i> Cancelar
        </button>
        <button type="submit" class="btn-save">
          <i class="bi bi-<%= esEdicion ? "floppy" : "send" %>"></i>
          <%= esEdicion ? "Guardar cambios" : "Publicar propiedad" %>
        </button>
      </div>

    </form>
  </div><!-- /form-area -->
</div><!-- /page -->

<script>
  // Highlight active section in left nav on scroll
  const sections = document.querySelectorAll('.form-section');
  const navItems = document.querySelectorAll('.ln-item');
  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const id = entry.target.id;
        navItems.forEach(n => {
          n.classList.remove('active');
          if (n.getAttribute('href') === '#' + id) n.classList.add('active');
        });
      }
    });
  }, { threshold: 0.4 });
  sections.forEach(s => observer.observe(s));

  // Smooth scroll for nav links
  navItems.forEach(item => {
    item.addEventListener('click', e => {
      e.preventDefault();
      const target = document.querySelector(item.getAttribute('href'));
      if (target) target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    });
  });
</script>
</body>
</html>
