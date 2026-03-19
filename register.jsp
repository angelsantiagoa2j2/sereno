<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Sereno — Crear Cuenta</title>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,700;0,900;1,400;1,700&family=Outfit:wght@300;400;500;600&display=swap" rel="stylesheet"/>
  <style>
    *,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
    :root{
      --navy:#0A1628; --navy-mid:#122040;
      --blue:#1455A4; --blue-bright:#1E6FD9;
      --sky:#4A9DE0; --sky-lt:#A8D4F5;
      --ice:#EAF4FD; --white:#FFFFFF;
      --slate:#4A5568; --slate-lt:#8A9BB0;
      --border:#D6E8F7; --red:#e05555;
    }
    body{font-family:'Outfit',sans-serif;background:var(--navy);min-height:100vh;position:relative;overflow-x:hidden;}
    .bg-glow{position:fixed;inset:0;z-index:0;pointer-events:none;background:radial-gradient(ellipse 50% 60% at 10% 30%,rgba(20,85,164,0.3) 0%,transparent 65%),radial-gradient(ellipse 40% 50% at 90% 70%,rgba(74,157,224,0.15) 0%,transparent 60%);}

    header{position:relative;z-index:10;display:flex;justify-content:space-between;align-items:center;padding:20px 64px;border-bottom:1px solid rgba(255,255,255,0.05);}
    .logo{font-family:'Playfair Display',serif;font-size:24px;font-weight:700;color:var(--white);text-decoration:none;}
    .logo span{color:var(--sky);}
    .login-link{color:rgba(255,255,255,0.5);font-size:14px;text-decoration:none;transition:color .2s;display:flex;align-items:center;gap:6px;}
    .login-link:hover{color:var(--sky-lt);}

    main{position:relative;z-index:1;max-width:720px;margin:0 auto;padding:52px 24px 80px;}
    .page-eyebrow{display:flex;align-items:center;justify-content:center;gap:10px;color:var(--sky);font-size:11px;font-weight:600;letter-spacing:3px;text-transform:uppercase;margin-bottom:12px;}
    .page-eyebrow::before,.page-eyebrow::after{content:'';width:24px;height:1.5px;background:var(--sky);opacity:0.5;}
    .page-title{font-family:'Playfair Display',serif;font-size:clamp(32px,4vw,46px);font-weight:900;color:var(--white);text-align:center;margin-bottom:8px;line-height:1.1;}
    .page-sub{text-align:center;color:rgba(255,255,255,0.4);font-size:15px;margin-bottom:36px;font-weight:300;}

    .card{background:var(--white);border-radius:20px;padding:48px 44px;box-shadow:0 40px 80px rgba(0,0,0,0.4);}
    @media(max-width:600px){.card{padding:32px 22px;}header{padding:16px 24px;}}

    .alert{padding:12px 16px;border-radius:8px;font-size:13px;margin-bottom:24px;display:flex;align-items:flex-start;gap:8px;background:#fde8e8;color:#c0392b;border-left:3px solid var(--red);}
    .sec-label{font-size:11px;font-weight:600;letter-spacing:2px;text-transform:uppercase;color:var(--slate-lt);margin-bottom:14px;padding-bottom:10px;border-bottom:1.5px solid var(--border);}

    /* ── ROLE SELECTOR: 3 columnas ── */
    .rol-selector{display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px;margin-bottom:32px;}
    @media(max-width:560px){.rol-selector{grid-template-columns:1fr;}}

    .rol-option{position:relative;}
    .rol-option input[type=radio]{position:absolute;opacity:0;width:0;height:0;}
    .rol-label{
      display:flex;flex-direction:column;align-items:center;gap:8px;
      padding:20px 14px;border:2px solid var(--border);
      border-radius:12px;cursor:pointer;transition:all .2s;
      text-align:center;background:var(--ice);height:100%;
    }
    .rol-label:hover{border-color:var(--sky);background:var(--white);}
    .rol-option input:checked + .rol-label{
      border-color:var(--blue-bright);
      background:rgba(30,111,217,0.05);
      box-shadow:0 0 0 3px rgba(30,111,217,0.1);
    }

    /* Admin — estilo morado diferenciado */
    .rol-option.admin-opt .rol-label{border-color:rgba(139,92,246,0.25);background:rgba(139,92,246,0.04);}
    .rol-option.admin-opt .rol-label:hover{border-color:#8b5cf6;background:rgba(139,92,246,0.07);}
    .rol-option.admin-opt input:checked + .rol-label{border-color:#8b5cf6;background:rgba(139,92,246,0.06);box-shadow:0 0 0 3px rgba(139,92,246,0.12);}
    .rol-option.admin-opt .rol-name{color:#5b21b6;}
    .admin-badge{display:inline-flex;align-items:center;gap:4px;font-size:9px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;padding:2px 8px;background:rgba(139,92,246,0.1);color:#7c3aed;border-radius:20px;border:1px solid rgba(139,92,246,0.2);margin-top:2px;}

    .rol-icon{font-size:28px;}
    .rol-name{font-family:'Playfair Display',serif;font-size:16px;font-weight:700;color:var(--navy);}
    .rol-desc{font-size:11px;color:var(--slate-lt);font-weight:300;line-height:1.4;}

    /* Fields */
    .fields-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px;}
    @media(max-width:500px){.fields-grid{grid-template-columns:1fr;}}
    .field-full{grid-column:1/-1;}
    .field{margin-bottom:0;}
    .field label{display:block;font-size:11px;font-weight:600;letter-spacing:1px;text-transform:uppercase;color:var(--slate);margin-bottom:7px;}
    .field input,.field select{width:100%;padding:12px 14px;border:1.5px solid var(--border);border-radius:8px;background:var(--ice);font-family:'Outfit',sans-serif;font-size:14px;color:var(--navy);outline:none;transition:border-color .2s,box-shadow .2s,background .2s;}
    .field input:focus,.field select:focus{border-color:var(--blue-bright);background:var(--white);box-shadow:0 0 0 3px rgba(30,111,217,0.1);}
    .field input::placeholder{color:rgba(0,0,0,0.25);}
    .hint{color:var(--slate-lt);font-size:11px;margin-top:5px;}
    .password-strength{height:3px;background:var(--border);border-radius:2px;margin-top:6px;overflow:hidden;}
    .strength-bar{height:100%;width:0%;transition:width .3s,background .3s;border-radius:2px;}

    .terms-row{display:flex;align-items:flex-start;gap:10px;margin-top:28px;margin-bottom:24px;}
    .terms-row input{width:16px;height:16px;accent-color:var(--blue-bright);margin-top:2px;flex-shrink:0;cursor:pointer;}
    .terms-row label{font-size:13px;color:var(--slate-lt);font-weight:300;line-height:1.6;}
    .terms-row a{color:var(--blue-bright);text-decoration:none;}
    .terms-row a:hover{text-decoration:underline;}

    .btn-submit{width:100%;padding:14px;background:var(--blue-bright);border:none;border-radius:40px;color:var(--white);font-family:'Outfit',sans-serif;font-size:15px;font-weight:600;letter-spacing:0.3px;cursor:pointer;transition:background .2s;}
    .btn-submit:hover{background:var(--sky);}

    .login-cta{text-align:center;margin-top:22px;color:var(--slate-lt);font-size:14px;}
    .login-cta a{color:var(--blue-bright);text-decoration:none;font-weight:500;}
    .login-cta a:hover{text-decoration:underline;}
  </style>
</head>
<body>

<div class="bg-glow"></div>

<header>
  <a href="${pageContext.request.contextPath}/" class="logo">Ser<span>eno</span></a>
  <a href="${pageContext.request.contextPath}/login" class="login-link">Ya tengo cuenta →</a>
</header>

<main>
  <div class="page-eyebrow">Únete</div>
  <h1 class="page-title">Crea tu cuenta</h1>
  <p class="page-sub">Encuentra tu próximo hogar con Sereno</p>

  <div class="card">

    <% String error = (String) request.getAttribute("error"); %>
    <% if (error != null && !error.isEmpty()) { %>
      <div class="alert">⚠ <%= error %></div>
    <% } %>

    <form method="post" action="${pageContext.request.contextPath}/register">

      <div class="sec-label">¿Cómo quieres usar Sereno?</div>
      <div class="rol-selector">

        <div class="rol-option">
          <input type="radio" id="rol-cliente" name="rol" value="cliente"
            <%= "cliente".equals(request.getAttribute("fRol")) || request.getAttribute("fRol") == null ? "checked" : "" %>/>
          <label class="rol-label" for="rol-cliente">
            <span class="rol-icon">🔍</span>
            <span class="rol-name">Cliente</span>
            <span class="rol-desc">Busco propiedades para comprar o arrendar</span>
          </label>
        </div>

        <div class="rol-option">
          <input type="radio" id="rol-inmo" name="rol" value="agente"
            <%= "agente".equals(request.getAttribute("fRol")) ? "checked" : "" %>/>
          <label class="rol-label" for="rol-inmo">
            <span class="rol-icon">🏢</span>
            <span class="rol-name">Inmobiliaria</span>
            <span class="rol-desc">Listo y gestiono propiedades</span>
          </label>
        </div>

        <div class="rol-option admin-opt">
          <input type="radio" id="rol-admin" name="rol" value="admin"
            <%= "admin".equals(request.getAttribute("fRol")) ? "checked" : "" %>/>
          <label class="rol-label" for="rol-admin">
            <span class="rol-icon">🛡️</span>
            <span class="rol-name">Administrador</span>
            <span class="admin-badge">⚙ Acceso total</span>
            <span class="rol-desc">Gestión completa de la plataforma</span>
          </label>
        </div>

      </div>

      <div class="sec-label" style="margin-bottom:20px">Datos personales</div>
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
          <div class="hint" id="strengthHint"></div>
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
          <a href="#">Política de privacidad</a> de Sereno
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
    const hint = document.getElementById('strengthHint');
    let score = 0;
    if (val.length >= 8)           score++;
    if (/[A-Z]/.test(val))         score++;
    if (/[0-9]/.test(val))         score++;
    if (/[^A-Za-z0-9]/.test(val))  score++;
    const colors = ['#e05555','#f0a500','#4A9DE0','#1455A4'];
    const labels = ['Muy débil','Regular','Buena','Muy segura'];
    bar.style.width = (score * 25) + '%';
    bar.style.background = colors[score - 1] || 'transparent';
    hint.textContent = score > 0 ? labels[score - 1] : '';
    hint.style.color = colors[score - 1] || 'transparent';
  }
</script>
</body>
</html>
