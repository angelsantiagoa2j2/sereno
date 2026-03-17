<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.inmovista.model.Usuario" %>
<%
    Usuario u = (Usuario) session.getAttribute("usuario");
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <title>InmoVista — Acceso Denegado</title>
  <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@300;700&family=DM+Sans:wght@300;400&display=swap" rel="stylesheet"/>
  <style>
    body{font-family:'DM Sans',sans-serif;background:#1A1A18;
      min-height:100vh;display:flex;align-items:center;justify-content:center;text-align:center;}
    .box{max-width:440px;padding:20px;}
    .code{font-family:'Cormorant Garamond',serif;font-size:120px;font-weight:700;
      color:rgba(201,168,76,.2);line-height:1;}
    h1{font-family:'Cormorant Garamond',serif;font-size:32px;font-weight:300;
      color:#fff;margin-bottom:12px;}
    p{color:rgba(255,255,255,.45);font-size:15px;font-weight:300;margin-bottom:36px;}
    .btn{display:inline-block;padding:12px 32px;background:#C9A84C;color:#1A1A18;
      border-radius:3px;text-decoration:none;font-size:14px;font-weight:500;}
  </style>
</head>
<body>
<div class="box">
  <div class="code">403</div>
  <h1>Acceso denegado</h1>
  <p>No tienes permisos para ver esta página.<br>
     <%= u != null ? "Tu rol actual es: <strong style='color:#C9A84C'>" + u.getRol().getNombre() + "</strong>" : "" %>
  </p>
  <a href="${pageContext.request.contextPath}/<%= u != null ? u.getDashboardUrl().substring(1) : "" %>" class="btn">
    Ir a mi dashboard
  </a>
</div>
</body>
</html>
