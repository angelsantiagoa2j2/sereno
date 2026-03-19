<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Sereno — Iniciar Sesión</title>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,700;0,900;1,400;1,700&family=Outfit:wght@300;400;500;600&display=swap" rel="stylesheet"/>
  <style>
    *,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
    :root{
      --navy:#0A1628;
      --navy-mid:#122040;
      --blue:#1455A4;
      --blue-bright:#1E6FD9;
      --sky:#4A9DE0;
      --sky-lt:#A8D4F5;
      --ice:#EAF4FD;
      --white:#FFFFFF;
      --slate:#4A5568;
      --slate-lt:#8A9BB0;
      --border:#D6E8F7;
      --red:#e05555;
    }
    body{
      font-family:'Outfit',sans-serif;
      min-height:100vh;
      display:flex;
      align-items:center;
      justify-content:center;
      background: var(--navy);
      position:relative;
      overflow:hidden;
    }

    /* Fondo decorativo */
    .bg-glow{
      position:fixed; inset:0; z-index:0; pointer-events:none;
      background:
        radial-gradient(ellipse 60% 70% at 20% 50%, rgba(20,85,164,0.35) 0%, transparent 65%),
        radial-gradient(ellipse 50% 60% at 80% 30%, rgba(74,157,224,0.18) 0%, transparent 60%),
        radial-gradient(ellipse 40% 50% at 60% 80%, rgba(10,22,40,0.8) 0%, transparent 70%);
    }
    .bg-circle{
      position:fixed; border-radius:50%; pointer-events:none; z-index:0;
    }
    .bg-circle-1{
      width:600px; height:600px;
      border:1px solid rgba(255,255,255,0.04);
      top:-150px; left:-150px;
    }
    .bg-circle-2{
      width:400px; height:400px;
      border:1px solid rgba(74,157,224,0.07);
      bottom:-100px; right:-100px;
    }

    /* Card centrada */
    .login-card{
      position:relative; z-index:1;
      display:flex;
      width:100%;
      max-width:900px;
      min-height:560px;
      margin:24px;
      border-radius:20px;
      overflow:hidden;
      box-shadow:0 40px 100px rgba(0,0,0,0.5);
    }

    /* Panel izquierdo */
    .left-panel{
      flex:1;
      background:linear-gradient(150deg, var(--navy-mid) 0%, var(--blue) 60%, #1a7ac4 100%);
      padding:56px 48px;
      display:flex; flex-direction:column; justify-content:space-between;
      position:relative; overflow:hidden;
    }
    .left-panel::before{
      content:'';
      position:absolute; inset:0;
      background:
        radial-gradient(ellipse 80% 70% at 70% 30%, rgba(74,157,224,0.25) 0%, transparent 65%),
        radial-gradient(circle 200px at 10% 90%, rgba(255,255,255,0.05) 0%, transparent 60%);
    }
    .left-geo{
      position:absolute;
      width:380px; height:380px;
      border:1px solid rgba(255,255,255,0.06);
      border-radius:50%;
      bottom:-100px; right:-80px;
    }
    .left-geo::before{
      content:'';
      position:absolute; inset:60px;
      border:1px solid rgba(255,255,255,0.04);
      border-radius:50%;
    }
    .left-top{ position:relative; z-index:1; }
    .left-logo{
      font-family:'Playfair Display',serif;
      font-size:26px; font-weight:700;
      color:var(--white); text-decoration:none; display:block;
      margin-bottom:48px;
    }
    .left-logo span{ color:var(--sky-lt); }
    .left-quote{
      font-family:'Playfair Display',serif;
      font-size:36px; font-weight:700;
      color:var(--white); line-height:1.15; margin-bottom:16px;
    }
    .left-quote em{ font-style:italic; color:var(--sky-lt); }
    .left-sub{
      color:rgba(255,255,255,0.55);
      font-size:14px; line-height:1.75; font-weight:300;
      max-width:280px;
    }
    .left-bottom{ position:relative; z-index:1; }
    .left-stats{
      display:flex; gap:32px;
      padding-top:32px;
      border-top:1px solid rgba(255,255,255,0.1);
    }
    .l-stat-num{
      font-family:'Playfair Display',serif;
      font-size:28px; font-weight:700; color:var(--sky-lt); line-height:1;
    }
    .l-stat-lbl{
      color:rgba(255,255,255,0.35);
      font-size:11px; letter-spacing:1.5px; text-transform:uppercase; margin-top:4px;
    }

    /* Panel derecho — formulario */
    .right-panel{
      width:400px; flex-shrink:0;
      background:var(--white);
      padding:52px 44px;
      display:flex; flex-direction:column; justify-content:center;
    }

    .form-logo{
      font-family:'Playfair Display',serif;
      font-size:22px; font-weight:700;
      color:var(--navy); text-decoration:none;
      margin-bottom:32px; display:none;
    }
    .form-logo span{ color:var(--blue-bright); }

    .form-eyebrow{
      display:inline-flex; align-items:center; gap:8px;
      color:var(--blue-bright); font-size:11px; font-weight:600;
      letter-spacing:3px; text-transform:uppercase; margin-bottom:12px;
    }
    .form-eyebrow::before{ content:''; width:16px; height:1.5px; background:var(--blue-bright); }

    .form-title{
      font-family:'Playfair Display',serif;
      font-size:30px; font-weight:700; color:var(--navy);
      margin-bottom:6px; line-height:1.2;
    }
    .form-sub{
      color:var(--slate-lt); font-size:14px;
      margin-bottom:32px; font-weight:300;
    }

    /* Alertas */
    .alert{
      padding:11px 14px; border-radius:8px; font-size:13px;
      margin-bottom:18px; display:flex; align-items:flex-start; gap:8px;
    }
    .alert-error{ background:#fde8e8; color:#c0392b; border-left:3px solid var(--red); }
    .alert-success{ background:#e8f4ff; color:var(--blue); border-left:3px solid var(--blue-bright); }

    /* Campos */
    .field{ margin-bottom:18px; }
    .field label{
      display:block; font-size:11px; font-weight:600;
      letter-spacing:1px; text-transform:uppercase;
      color:var(--slate); margin-bottom:7px;
    }
    .field input{
      width:100%; padding:12px 15px;
      border:1.5px solid var(--border);
      border-radius:8px; background:var(--ice);
      font-family:'Outfit',sans-serif; font-size:14px;
      color:var(--navy); outline:none;
      transition:border-color .2s, box-shadow .2s, background .2s;
    }
    .field input:focus{
      border-color:var(--blue-bright);
      background:var(--white);
      box-shadow:0 0 0 3px rgba(30,111,217,0.1);
    }
    .field input::placeholder{ color:rgba(0,0,0,0.25); }

    .field-row{
      display:flex; justify-content:space-between;
      align-items:center; margin-bottom:7px;
    }
    .field-row label{ margin-bottom:0; }
    .forgot{
      color:var(--blue-bright); font-size:12px;
      text-decoration:none; font-weight:400;
    }
    .forgot:hover{ text-decoration:underline; }

    .check-row{
      display:flex; align-items:center; gap:9px; margin-bottom:24px;
    }
    .check-row input[type=checkbox]{
      width:15px; height:15px; accent-color:var(--blue-bright); cursor:pointer;
    }
    .check-row label{
      font-size:13px; color:var(--slate-lt);
      cursor:pointer; margin:0; font-weight:300;
    }

    .btn-submit{
      width:100%; padding:13px;
      background:var(--blue-bright); border:none; border-radius:40px;
      color:var(--white); font-family:'Outfit',sans-serif;
      font-size:15px; font-weight:600; letter-spacing:0.3px;
      cursor:pointer; transition:background .2s;
    }
    .btn-submit:hover{ background:var(--sky); }

    .divider{
      display:flex; align-items:center; gap:12px;
      margin:20px 0; color:rgba(0,0,0,0.2); font-size:12px;
    }
    .divider::before,.divider::after{
      content:''; flex:1; height:1px; background:var(--border);
    }

    .btn-register{
      width:100%; padding:12px;
      border:1.5px solid var(--border); border-radius:40px;
      background:transparent; color:var(--slate);
      font-family:'Outfit',sans-serif; font-size:14px;
      font-weight:500; cursor:pointer; transition:all .2s;
      text-align:center; text-decoration:none; display:block;
    }
    .btn-register:hover{
      border-color:var(--blue-bright); color:var(--blue-bright);
      background:var(--ice);
    }

    .back-link{
      text-align:center; margin-top:24px;
      color:var(--slate-lt); font-size:13px;
    }
    .back-link a{ color:var(--blue-bright); text-decoration:none; }
    .back-link a:hover{ text-decoration:underline; }

    @media(max-width:780px){
      .left-panel{ display:none; }
      .login-card{ max-width:460px; }
      .right-panel{ width:100%; padding:44px 32px; }
      .form-logo{ display:block; }
    }
    @media(max-width:480px){
      .login-card{ margin:0; border-radius:0; min-height:100vh; }
      .right-panel{ padding:40px 24px; justify-content:flex-start; padding-top:60px; }
    }
  </style>
</head>
<body>

<div class="bg-glow"></div>
<div class="bg-circle bg-circle-1"></div>
<div class="bg-circle bg-circle-2"></div>

<div class="login-card">

  <!-- Panel izquierdo decorativo -->
  <div class="left-panel">
    <div class="left-geo"></div>
    <div class="left-top">
      <a href="${pageContext.request.contextPath}/" class="left-logo">Ser<span>eno</span></a>
      <h2 class="left-quote">Tu hogar ideal<br>te está <em>esperando</em></h2>
      <p class="left-sub">Accede a tu cuenta y gestiona propiedades, citas y solicitudes desde un solo lugar.</p>
    </div>
    <div class="left-bottom">
      <div class="left-stats">
        <div>
          <div class="l-stat-num">1.280</div>
          <div class="l-stat-lbl">Propiedades</div>
        </div>
        <div>
          <div class="l-stat-num">340+</div>
          <div class="l-stat-lbl">Clientes</div>
        </div>
        <div>
          <div class="l-stat-num">12</div>
          <div class="l-stat-lbl">Años</div>
        </div>
      </div>
    </div>
  </div>

  <!-- Panel derecho — formulario -->
  <div class="right-panel">
    <a href="${pageContext.request.contextPath}/" class="form-logo">Ser<span>eno</span></a>

    <div class="form-eyebrow">Bienvenido</div>
    <h1 class="form-title">Inicia sesión</h1>
    <p class="form-sub">Ingresa tus credenciales para continuar</p>

    <%-- Mensajes de error / éxito --%>
    <% String error   = (String) request.getAttribute("error"); %>
    <% String success = request.getParameter("success"); %>
    <% String logout  = request.getParameter("logout"); %>

    <% if (error != null && !error.isEmpty()) { %>
      <div class="alert alert-error">⚠ <%= error %></div>
    <% } %>
    <% if (success != null) { %>
      <div class="alert alert-success">✓ <%= success %></div>
    <% } %>
    <% if ("true".equals(logout)) { %>
      <div class="alert alert-success">✓ Has cerrado sesión correctamente.</div>
    <% } %>

    <form method="post" action="${pageContext.request.contextPath}/login">

      <div class="field">
        <label>Correo electrónico</label>
        <input type="email" name="email" placeholder="tucorreo@ejemplo.com"
               value="<%= request.getAttribute("emailValue") != null ? request.getAttribute("emailValue") : "" %>"
               required autocomplete="email"/>
      </div>

      <div class="field">
        <div class="field-row">
          <label>Contraseña</label>
          <a href="#" class="forgot">¿Olvidaste tu contraseña?</a>
        </div>
        <input type="password" name="password" placeholder="••••••••"
               required autocomplete="current-password"/>
      </div>

      <div class="check-row">
        <input type="checkbox" id="remember" name="remember"/>
        <label for="remember">Recordarme por 7 días</label>
      </div>

      <button type="submit" class="btn-submit">Iniciar Sesión</button>
    </form>

    <div class="divider">o</div>

    <a href="${pageContext.request.contextPath}/register" class="btn-register">
      Crear cuenta nueva
    </a>

    <p class="back-link">
      <a href="${pageContext.request.contextPath}/">← Volver al inicio</a>
    </p>
  </div>

</div>

</body>
</html>
