<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>InmoVista — Iniciar Sesión</title>
  <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@300;400;600;700&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet"/>
  <style>
    *,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
    :root{
      --cream:#F5F0E8; --dark:#1A1A18; --gold:#C9A84C; --gold-lt:#E8C97A;
      --muted:#6B6455; --white:#FFFFFF; --red:#e05555;
    }
    body{
      font-family:'DM Sans',sans-serif;
      background:var(--dark);
      min-height:100vh; display:flex;
    }
    /* Panel izquierdo decorativo */
    .left-panel{
      flex:1; position:relative; overflow:hidden;
      display:none;
    }
    @media(min-width:900px){ .left-panel{display:block;} }
    .left-bg{
      position:absolute; inset:0;
      background:linear-gradient(145deg,#1a1a18 0%,#2c2a22 50%,#1f1d16 100%);
    }
    .left-bg::after{
      content:'';position:absolute;inset:0;
      background:radial-gradient(ellipse 70% 60% at 60% 40%,rgba(201,168,76,.15) 0%,transparent 70%);
    }
    .left-content{
      position:relative;z-index:1;
      height:100%;display:flex;flex-direction:column;
      justify-content:center;padding:60px;
    }
    .left-logo{
      font-family:'Cormorant Garamond',serif;
      font-size:32px;font-weight:700;color:var(--white);
      text-decoration:none;margin-bottom:60px;display:block;
    }
    .left-logo span{color:var(--gold);}
    .left-quote{
      font-family:'Cormorant Garamond',serif;
      font-size:42px;font-weight:300;color:var(--white);
      line-height:1.2;margin-bottom:20px;
    }
    .left-quote em{font-style:italic;color:var(--gold);}
    .left-sub{color:rgba(255,255,255,.45);font-size:15px;line-height:1.7;font-weight:300;}
    .left-stats{
      display:flex;gap:40px;margin-top:50px;
      padding-top:40px;border-top:1px solid rgba(255,255,255,.08);
    }
    .l-stat-num{
      font-family:'Cormorant Garamond',serif;
      font-size:32px;font-weight:700;color:var(--gold);
    }
    .l-stat-lbl{color:rgba(255,255,255,.35);font-size:12px;letter-spacing:1px;text-transform:uppercase;}

    /* Panel derecho — formulario */
    .right-panel{
      width:100%;max-width:480px;
      background:var(--cream);
      display:flex;flex-direction:column;
      justify-content:center;
      padding:60px 50px;
    }
    @media(max-width:900px){.right-panel{max-width:100%;padding:40px 28px;}}

    .form-logo{
      font-family:'Cormorant Garamond',serif;
      font-size:26px;font-weight:700;color:var(--dark);
      text-decoration:none;margin-bottom:40px;display:block;
    }
    .form-logo span{color:var(--gold);}
    @media(min-width:900px){.form-logo{display:none;}}

    .form-title{
      font-family:'Cormorant Garamond',serif;
      font-size:36px;font-weight:300;color:var(--dark);
      margin-bottom:8px;
    }
    .form-sub{color:var(--muted);font-size:14px;margin-bottom:36px;font-weight:300;}

    /* Alertas */
    .alert{
      padding:12px 16px;border-radius:3px;font-size:14px;
      margin-bottom:20px;display:flex;align-items:flex-start;gap:10px;
    }
    .alert-error{background:#fde8e8;color:#c0392b;border-left:3px solid var(--red);}
    .alert-success{background:#e8f5e9;color:#2e7d32;border-left:3px solid #4caf50;}

    /* Campos */
    .field{margin-bottom:20px;}
    .field label{
      display:block;font-size:12px;font-weight:500;
      letter-spacing:.8px;text-transform:uppercase;
      color:var(--muted);margin-bottom:8px;
    }
    .field input{
      width:100%;padding:13px 16px;
      border:1.5px solid rgba(0,0,0,.12);
      border-radius:3px;background:var(--white);
      font-family:'DM Sans',sans-serif;font-size:15px;
      color:var(--dark);outline:none;
      transition:border-color .2s,box-shadow .2s;
    }
    .field input:focus{
      border-color:var(--gold);
      box-shadow:0 0 0 3px rgba(201,168,76,.12);
    }
    .field input::placeholder{color:rgba(0,0,0,.3);}

    .field-row{display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;}
    .field-row label{margin-bottom:0;}
    .forgot{color:var(--gold);font-size:13px;text-decoration:none;}
    .forgot:hover{text-decoration:underline;}

    /* Checkbox */
    .check-row{display:flex;align-items:center;gap:10px;margin-bottom:28px;}
    .check-row input[type=checkbox]{
      width:16px;height:16px;accent-color:var(--gold);cursor:pointer;
    }
    .check-row label{font-size:13px;color:var(--muted);cursor:pointer;margin:0;}

    /* Botón */
    .btn-submit{
      width:100%;padding:14px;
      background:var(--dark);border:none;border-radius:3px;
      color:var(--white);font-family:'DM Sans',sans-serif;
      font-size:15px;font-weight:500;letter-spacing:.5px;
      cursor:pointer;transition:background .2s;
    }
    .btn-submit:hover{background:#2d2d2a;}

    .divider{
      display:flex;align-items:center;gap:14px;
      margin:24px 0;color:rgba(0,0,0,.25);font-size:13px;
    }
    .divider::before,.divider::after{
      content:'';flex:1;height:1px;background:rgba(0,0,0,.1);
    }

    .btn-register{
      width:100%;padding:13px;
      border:1.5px solid var(--gold);border-radius:3px;
      background:transparent;color:var(--gold);
      font-family:'DM Sans',sans-serif;font-size:15px;
      font-weight:500;cursor:pointer;transition:all .2s;
      text-align:center;text-decoration:none;display:block;
    }
    .btn-register:hover{background:var(--gold);color:var(--dark);}

    .back-link{
      text-align:center;margin-top:28px;
      color:var(--muted);font-size:13px;
    }
    .back-link a{color:var(--gold);text-decoration:none;}
    .back-link a:hover{text-decoration:underline;}
  </style>
</head>
<body>

<!-- Panel izquierdo -->
<div class="left-panel">
  <div class="left-bg"></div>
  <div class="left-content">
    <a href="${pageContext.request.contextPath}/" class="left-logo">Inmo<span>Vista</span></a>
    <h2 class="left-quote">Tu hogar ideal<br>te está <em>esperando</em></h2>
    <p class="left-sub">Accede a tu cuenta y gestiona propiedades,<br>citas y solicitudes desde un solo lugar.</p>
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
  <a href="${pageContext.request.contextPath}/" class="form-logo">Inmo<span>Vista</span></a>

  <h1 class="form-title">Bienvenido de vuelta</h1>
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

</body>
</html>
