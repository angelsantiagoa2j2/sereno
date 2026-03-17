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
  <title>InmoVista — <%= esEdicion ? "Editar" : "Nueva" %> Propiedad</title>
  <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@300;400;600;700&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet"/>
  <style>
    *,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
    :root{--cream:#F5F0E8;--dark:#1A1A18;--gold:#C9A84C;--muted:#6B6455;--white:#fff;}
    body{font-family:'DM Sans',sans-serif;background:var(--cream);}
    header{background:var(--dark);padding:16px 40px;display:flex;justify-content:space-between;align-items:center;}
    .logo{font-family:'Cormorant Garamond',serif;font-size:22px;font-weight:700;color:#fff;text-decoration:none;}
    .logo span{color:var(--gold);}
    .back{color:rgba(255,255,255,.5);text-decoration:none;font-size:14px;transition:color .2s;}
    .back:hover{color:var(--gold);}

    main{max-width:780px;margin:0 auto;padding:50px 24px 80px;}
    .page-title{font-family:'Cormorant Garamond',serif;font-size:38px;font-weight:300;color:var(--dark);margin-bottom:6px;}
    .page-sub{color:var(--muted);font-size:14px;margin-bottom:36px;}

    .card{background:var(--white);border-radius:6px;padding:40px;box-shadow:0 4px 20px rgba(0,0,0,.06);}

    .alert{padding:12px 16px;border-radius:3px;background:#fde8e8;color:#c0392b;border-left:3px solid #e05555;margin-bottom:24px;font-size:14px;}

    .section-title{font-size:11px;font-weight:500;letter-spacing:2px;text-transform:uppercase;color:var(--muted);margin:28px 0 16px;padding-bottom:8px;border-bottom:1px solid rgba(0,0,0,.07);}
    .section-title:first-of-type{margin-top:0;}

    .grid{display:grid;gap:18px;}
    .grid-2{grid-template-columns:1fr 1fr;}
    .grid-3{grid-template-columns:1fr 1fr 1fr;}
    @media(max-width:580px){.grid-2,.grid-3{grid-template-columns:1fr;}}

    .field label{display:block;font-size:12px;font-weight:500;letter-spacing:.8px;text-transform:uppercase;color:var(--muted);margin-bottom:7px;}
    .field input,.field select,.field textarea{
      width:100%;padding:11px 14px;border:1.5px solid rgba(0,0,0,.12);border-radius:3px;
      background:var(--white);font-family:'DM Sans',sans-serif;font-size:14px;color:var(--dark);
      outline:none;transition:border-color .2s;
    }
    .field input:focus,.field select:focus,.field textarea:focus{border-color:var(--gold);box-shadow:0 0 0 3px rgba(201,168,76,.1);}
    .field textarea{resize:vertical;min-height:100px;}

    .form-actions{display:flex;gap:14px;margin-top:32px;justify-content:flex-end;}
    .btn-cancel{padding:12px 28px;border:1.5px solid rgba(0,0,0,.15);border-radius:3px;background:transparent;color:var(--muted);font-size:14px;cursor:pointer;font-family:'DM Sans',sans-serif;text-decoration:none;display:inline-block;}
    .btn-save{padding:12px 32px;background:var(--dark);color:#fff;border:none;border-radius:3px;font-size:14px;font-weight:500;cursor:pointer;font-family:'DM Sans',sans-serif;}
    .btn-save:hover{background:#2d2d2a;}
  </style>
</head>
<body>
<header>
  <a href="${pageContext.request.contextPath}/" class="logo">Inmo<span>Vista</span></a>
  <a href="javascript:history.back()" class="back">← Volver</a>
</header>

<main>
  <h1 class="page-title"><%= esEdicion ? "Editar propiedad" : "Nueva propiedad" %></h1>
  <p class="page-sub"><%= esEdicion ? "Modifica los datos de la propiedad" : "Completa los datos para publicar una nueva propiedad" %></p>

  <div class="card">
    <% if (error != null) { %><div class="alert">⚠ <%= error %></div><% } %>

    <form method="post" action="${pageContext.request.contextPath}/propiedades?action=save">
      <% if (esEdicion) { %>
        <input type="hidden" name="id" value="<%= p.getId() %>"/>
      <% } %>

      <div class="section-title">Información básica</div>
      <div class="grid">
        <div class="field">
          <label>Título *</label>
          <input type="text" name="titulo" required placeholder="Ej: Casa Colonial en Cañaveral"
                 value="<%= esEdicion ? p.getTitulo() : "" %>"/>
        </div>
        <div class="field">
          <label>Descripción</label>
          <textarea name="descripcion" placeholder="Describe la propiedad..."><%= esEdicion && p.getDescripcion() != null ? p.getDescripcion() : "" %></textarea>
        </div>
      </div>

      <div class="section-title">Tipo y operación</div>
      <div class="grid grid-2">
        <div class="field">
          <label>Tipo *</label>
          <select name="tipo" required>
            <option value="">Selecciona...</option>
            <option value="CASA"        <%= esEdicion && p.getTipo().name().equals("CASA")        ? "selected" : "" %>>Casa</option>
            <option value="APARTAMENTO" <%= esEdicion && p.getTipo().name().equals("APARTAMENTO") ? "selected" : "" %>>Apartamento</option>
            <option value="TERRENO"     <%= esEdicion && p.getTipo().name().equals("TERRENO")     ? "selected" : "" %>>Terreno</option>
            <option value="LOCAL"       <%= esEdicion && p.getTipo().name().equals("LOCAL")       ? "selected" : "" %>>Local</option>
            <option value="FINCA"       <%= esEdicion && p.getTipo().name().equals("FINCA")       ? "selected" : "" %>>Finca</option>
            <option value="BODEGA"      <%= esEdicion && p.getTipo().name().equals("BODEGA")      ? "selected" : "" %>>Bodega</option>
          </select>
        </div>
        <div class="field">
          <label>Operación *</label>
          <select name="operacion" required>
            <option value="">Selecciona...</option>
            <option value="VENTA"         <%= esEdicion && p.getOperacion().name().equals("VENTA")         ? "selected" : "" %>>Venta</option>
            <option value="ARRIENDO"      <%= esEdicion && p.getOperacion().name().equals("ARRIENDO")      ? "selected" : "" %>>Arriendo</option>
            <option value="VENTA_ARRIENDO"<%= esEdicion && p.getOperacion().name().equals("VENTA_ARRIENDO")? "selected" : "" %>>Venta / Arriendo</option>
          </select>
        </div>
      </div>

      <div class="section-title">Precio y área</div>
      <div class="grid grid-2">
        <div class="field">
          <label>Precio (COP) *</label>
          <input type="text" name="precio" required placeholder="Ej: 350000000"
                 value="<%= esEdicion ? p.getPrecio().toPlainString() : "" %>"/>
        </div>
        <div class="field">
          <label>Área (m²)</label>
          <input type="number" name="areaM2" min="1" step="0.1" placeholder="Ej: 180"
                 value="<%= esEdicion && p.getAreaM2() != null ? p.getAreaM2().toPlainString() : "" %>"/>
        </div>
      </div>

      <div class="section-title">Características</div>
      <div class="grid grid-3">
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
          <input type="number" name="estrato" min="1" max="6" placeholder="1-6"
                 value="<%= esEdicion && p.getEstrato() != null ? p.getEstrato() : "" %>"/>
        </div>
        <% if (esEdicion && usuario.isAdmin()) { %>
        <div class="field">
          <label>Estado</label>
          <select name="estado">
            <option value="DISPONIBLE" <%= p.getEstado().name().equals("DISPONIBLE") ? "selected" : "" %>>Disponible</option>
            <option value="RESERVADO"  <%= p.getEstado().name().equals("RESERVADO")  ? "selected" : "" %>>Reservado</option>
            <option value="VENDIDO"    <%= p.getEstado().name().equals("VENDIDO")    ? "selected" : "" %>>Vendido</option>
            <option value="ARRENDADO"  <%= p.getEstado().name().equals("ARRENDADO")  ? "selected" : "" %>>Arrendado</option>
          </select>
        </div>
        <% } else { %>
          <input type="hidden" name="estado" value="<%= esEdicion ? p.getEstado().name() : "DISPONIBLE" %>"/>
        <% } %>
      </div>

      <div class="section-title">Ubicación</div>
      <div class="grid grid-2">
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
            <option value="">Selecciona...</option>
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

      <div class="form-actions">
        <a href="javascript:history.back()" class="btn-cancel">Cancelar</a>
        <button type="submit" class="btn-save">
          <%= esEdicion ? "Guardar cambios" : "Publicar propiedad" %>
        </button>
      </div>
    </form>
  </div>
</main>
</body>
</html>
