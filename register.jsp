<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>InmoVista — Crear Cuenta</title>
  <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@300;400;600;700&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet"/>
  <style>
    *,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
    :root{
      --cream:#F5F0E8;--dark:#1A1A18;--gold:#C9A84C;--gold-lt:#E8C97A;
      --muted:#6B6455;--white:#FFFFFF;--red:#e05555;
    }
    body{font-family:'DM Sans',sans-serif;background:var(--cream);min-height:100vh;}
    header{
      background:var(--dark);padding:18px 40px;
      display:flex;justify-content:space-between;align-items:center;
    }
    .logo{
      font-family:'Cormorant Garamond',serif;
      font-size:24px;font-weight:700;color:var(--white);text-decoration:none;
    }
    .logo span{color:var(--gold);}
    .login-link{
      color:rgba(255,255,255,.6);font-size:14px;text-decoration:none;
      transition:color .2s;
    }
    .login-link:hover{color:var(--gold);}

    main{
      max-width:680px;margin:0 auto;
      padding:60px 24px 80px;
    }
    .page-title{
      font-family:'Cormorant Garamond',serif;
      font-size:42px;font-weight:300;color:var(--dark);
      margin-bottom:8px;text-align:center;
    }
    .page-sub{
      text-align:center;color:var(--muted);
      font-size:15px;margin-bottom:40px;font-weight:300;
    }

    .card{
      background:var(--white);border-radius:6px;
      padding:44px 48px;
      box-shadow:0 4px 30px rgba(0,0,0,.06);
    }
    @media(max-width:600px){.card{padding:28px 20px;}}

    /* Selector de rol */
    .rol-selector{
      display:grid;grid-template-columns:1fr 1fr;
      gap:14px;margin-bottom:32px;
    }
    .rol-option{position:relative;}
    .rol-option input[type=radio]{position:absolute;opacity:0;width:0;height:0;}
    .rol-label{
      display:flex;flex-direction:column;align-items:center;
      gap:10px;padding:20px 16px;border:2px solid rgba(0,0,0,.1);
      border-radius:4px;cursor:pointer;transition:all .2s;text-align:center;
    }
    .rol-label:hover{border-color:var(--gold);}
    .rol-option input:checked + .rol-label{
      border-color:var(--gold);background:rgba(201,168,76,.06);
    }
    .rol-icon{font-size:30px;}
    .rol-name{font-family:'Cormorant Garamond',serif;font-size:18px;font-weight:600;color:var(--dark);}
    .rol-desc{font-size:12px;color:var(--muted);font-weight:300;}

    .section-title{
      font-size:11px;font-weight:500;letter-spacing:2px;
      text-transform:uppercase;color:var(--muted);
      margin-bottom:20px;padding-bottom:10px;
      border-bottom:1px solid rgba(0,0,0,.07);
    }

    .fields-grid{display:grid;grid-template-columns:1fr 1fr;gap:18px;}
    @media(max-width:500px){.fields-grid{grid-template-columns:1fr;}}
    .field-full{grid-column:1/-1;}

    .field{margin-bottom:0;}
    .field label{
      display:block;font-size:12px;font-weight:500;
      letter-spacing:.8px;text-transform:uppercase;
      color:var(--muted);margin-bottom:7px;
    }
    .field input,.field select{
      width:100%;padding:12px 14px;
      border:1.5px solid rgba(0,0,0,.12);border-radius:3px;
      background:var(--white);font-family:'DM Sans',sans-serif;
      font-size:14px;color:var(--dark);outline:none;
      transition:border-color .2s,box-shadow .2s;
    }
    .field input:focus,.field select:focus{
      border-color:var(--gold);
      box-shadow:0 0 0 3px rgba(201,168,76,.12);
    }
    .field input::placeholder{color:rgba(0,0,0,.3);}
    .hint{color:var(--muted);font-size:11px;margin-top:5px;}

    .password-strength{
      height:3px;background:rgba(0,0,0,.08);
      border-radius:2px;margin-top:6px;overflow:hidden;
    }
    .strength-bar{height:100%;width:0%;transition:width .3s,background .3s;border-radius:2px;}

    .alert{
      padding:12px 16px;border-radius:3px;font-size:14px;
      margin-bottom:24px;border-left:3px solid var(--red);
      background:#fde8e8;color:#c0392b;
    }

    .terms-row{
      display:flex;align-items:flex-start;gap:10px;
      margin-top:28px;margin-bottom:24px;
    }
    .terms-row input{width:16px;height:16px;accent-color:var(--gold);margin-top:2px;flex-shrink:0;}
    .terms-row label{font-size:13px;color:var(--muted);}
    .terms-row a{color:var(--gold);text-decoration:none;}

    .btn-submit{
      width:100%;padding:14px;
      background:var(--dark);border:none;border-radius:3px;
      color:var(--white);font-family:'DM Sans',sans-serif;
      font-size:15px;font-weight:500;letter-spacing:.5px;
      cursor:pointer;transition:background .2s;
    }
    .btn-submit:hover{background:#2d2d2a;}

    .login-cta{
      text-align:center;margin-top:24px;
      color:var(--muted);font-size:14px;
    }
    .login-cta a{color:var(--gold);text-decoration:none;font-weight:500;}
  </style>
</head>
<body>

<header>
  <a href="${pageContext.request.contextPath}/" class="logo">Inmo<span>Vista</span></a>
  <a href="${pageContext.request.contextPath}/login" class="login-link">Ya tengo cuenta →</a>
</header>

<main>
  <h1 class="page-title">Crear cuenta</h1>
  <p class="page-sub">Únete a InmoVista y encuentra tu próximo hogar</p>

  <div class="card">

    <% String error = (String) request.getAttribute("error"); %>
    <% if (error != null && !error.isEmpty()) { %>
      <div class="alert">⚠ <%= error %></div>
    <% } %>

    <form method="post" action="${pageContext.request.contextPath}/register">

      <!-- Selector de rol -->
      <div class="section-title">¿Cómo quieres usar InmoVista?</div>
      <div class="rol-selector">
        <div class="rol-option">
          <input type="radio" id="rol-cliente" name="rol" value="CLIENTE"
            <%= "CLIENTE".equals(request.getAttribute("fRol")) || request.getAttribute("fRol") == null ? "checked" : "" %>/>
          <label class="rol-label" for="rol-cliente">
            <span class="rol-icon">🔍</span>
            <span class="rol-name">Cliente</span>
            <span class="rol-desc">Busco propiedades para comprar o arrendar</span>
          </label>
        </div>
        <div class="rol-option">
          <input type="radio" id="rol-inmo" name="rol" value="INMOBILIARIA"
            <%= "INMOBILIARIA".equals(request.getAttribute("fRol")) ? "checked" : "" %>/>
          <label class="rol-label" for="rol-inmo">
            <span class="rol-icon">🏢</span>
            <span class="rol-name">Inmobiliaria</span>
            <span class="rol-desc">Listo y gestiono propiedades</span>
          </label>
        </div>
      </div>

      <!-- Datos personales -->
      <div class="section-title">Datos personales</div>
      <div class="fields-grid">

        <div class="field">
          <label>Nombre *</label>
          <input type="text" name="nombre" placeholder="Ej: María"
                 value="<%= request.getAttribute("fNombre") != null ? request.getAttribute("fNombre") : "" %>"
                 required/>
        </div>

        <div class="field">
          <label>Apellido *</label>
          <input type="text" name="apellido" placeholder="Ej: López"
                 value="<%= request.getAttribute("fApellido") != null ? request.getAttribute("fApellido") : "" %>"
                 required/>
        </div>

        <div class="field field-full">
          <label>Correo electrónico *</label>
          <input type="email" name="email" placeholder="tucorreo@ejemplo.com"
                 value="<%= request.getAttribute("fEmail") != null ? request.getAttribute("fEmail") : "" %>"
                 required autocomplete="email"/>
        </div>

        <div class="field field-full">
          <label>Teléfono</label>
          <input type="tel" name="telefono" placeholder="Ej: 3001234567"
                 value="<%= request.getAttribute("fTelefono") != null ? request.getAttribute("fTelefono") : "" %>"/>
        </div>

        <div class="field">
          <label>Contraseña *</label>
          <input type="password" id="password" name="password"
                 placeholder="Mínimo 8 caracteres" required
                 autocomplete="new-password" oninput="checkStrength(this.value)"/>
          <div class="password-strength"><div class="strength-bar" id="strengthBar"></div></div>
        </div>

        <div class="field">
          <label>Confirmar contraseña *</label>
          <input type="password" name="password2"
                 placeholder="Repite tu contraseña" required
                 autocomplete="new-password"/>
        </div>

      </div>

      <div class="terms-row">
        <input type="checkbox" id="terms" required/>
        <label for="terms">
          Acepto los <a href="#">Términos de uso</a> y la
          <a href="#">Política de privacidad</a> de InmoVista
        </label>
      </div>

      <button type="submit" class="btn-submit">Crear mi cuenta</button>
    </form>

    <p class="login-cta">
      ¿Ya tienes cuenta?
      <a href="${pageContext.request.contextPath}/login">Inicia sesión aquí</a>
    </p>
  </div>
</main>

<script>
  function checkStrength(val) {
    const bar = document.getElementById('strengthBar');
    let score = 0;
    if (val.length >= 8)  score++;
    if (/[A-Z]/.test(val)) score++;
    if (/[0-9]/.test(val)) score++;
    if (/[^A-Za-z0-9]/.test(val)) score++;
    const colors = ['#e05555','#f0a500','#4caf50','#2e7d32'];
    bar.style.width  = (score * 25) + '%';
    bar.style.background = colors[score - 1] || 'transparent';
  }
</script>
</body>
</html>
