package com.inmovista.model;

import java.sql.Timestamp;

/**
 * Modelo: Usuario
 * Representa un usuario del sistema con su rol asociado.
 */
public class Usuario {

    // ─── ENUM de Roles ───────────────────────────────────────────────────────
    public enum Rol {
        ADMIN(1, "ADMIN", "Acceso total al sistema"),
        USUARIO(2, "USUARIO", "Solo visita la página"),
        CLIENTE(3, "CLIENTE", "Busca propiedades y solicita citas"),
        INMOBILIARIA(4, "INMOBILIARIA", "Gestiona propiedades y solicitudes");

        private final int id;
        private final String nombre;
        private final String descripcion;

        Rol(int id, String nombre, String descripcion) {
            this.id = id;
            this.nombre = nombre;
            this.descripcion = descripcion;
        }

        public int getId()           { return id; }
        public String getNombre()    { return nombre; }
        public String getDesc()      { return descripcion; }

        public static Rol fromId(int id) {
            for (Rol r : values()) {
                if (r.id == id) return r;
            }
            throw new IllegalArgumentException("Rol no encontrado para id: " + id);
        }

        public static Rol fromNombre(String nombre) {
            for (Rol r : values()) {
                if (r.nombre.equalsIgnoreCase(nombre)) return r;
            }
            throw new IllegalArgumentException("Rol no encontrado: " + nombre);
        }
    }

    // ─── Atributos ───────────────────────────────────────────────────────────
    private int       id;
    private String    nombre;
    private String    apellido;
    private String    email;
    private String    passwordHash;
    private String    telefono;
    private String    documento;
    private String    fotoUrl;
    private Rol       rol;
    private boolean   activo;
    private boolean   emailVerificado;
    private Timestamp ultimoLogin;
    private Timestamp createdAt;
    private Timestamp updatedAt;

    // ─── Constructor vacío ───────────────────────────────────────────────────
    public Usuario() {}

    // ─── Constructor completo ────────────────────────────────────────────────
    public Usuario(int id, String nombre, String apellido, String email,
                   String passwordHash, String telefono, String documento,
                   String fotoUrl, Rol rol, boolean activo,
                   boolean emailVerificado, Timestamp ultimoLogin,
                   Timestamp createdAt, Timestamp updatedAt) {
        this.id              = id;
        this.nombre          = nombre;
        this.apellido        = apellido;
        this.email           = email;
        this.passwordHash    = passwordHash;
        this.telefono        = telefono;
        this.documento       = documento;
        this.fotoUrl         = fotoUrl;
        this.rol             = rol;
        this.activo          = activo;
        this.emailVerificado = emailVerificado;
        this.ultimoLogin     = ultimoLogin;
        this.createdAt       = createdAt;
        this.updatedAt       = updatedAt;
    }

    // ─── Helpers de autorización ─────────────────────────────────────────────
    public boolean isAdmin()        { return rol == Rol.ADMIN; }
    public boolean isCliente()      { return rol == Rol.CLIENTE; }
    public boolean isInmobiliaria() { return rol == Rol.INMOBILIARIA; }
    public boolean isUsuario()      { return rol == Rol.USUARIO; }

    public String getNombreCompleto() {
        return nombre + " " + apellido;
    }

    /** Retorna la URL del dashboard según el rol */
    public String getDashboardUrl() {
        switch (rol) {
            case ADMIN:        return "/dashboard/admin/index.jsp";
            case INMOBILIARIA: return "/dashboard/inmobiliaria/index.jsp";
            case CLIENTE:      return "/dashboard/cliente/index.jsp";
            default:           return "/index.jsp";
        }
    }

    // ─── Getters & Setters ───────────────────────────────────────────────────
    public int       getId()               { return id; }
    public void      setId(int id)         { this.id = id; }

    public String    getNombre()           { return nombre; }
    public void      setNombre(String n)   { this.nombre = n; }

    public String    getApellido()         { return apellido; }
    public void      setApellido(String a) { this.apellido = a; }

    public String    getEmail()            { return email; }
    public void      setEmail(String e)    { this.email = e; }

    public String    getPasswordHash()            { return passwordHash; }
    public void      setPasswordHash(String p)    { this.passwordHash = p; }

    public String    getTelefono()               { return telefono; }
    public void      setTelefono(String t)       { this.telefono = t; }

    public String    getDocumento()              { return documento; }
    public void      setDocumento(String d)      { this.documento = d; }

    public String    getFotoUrl()                { return fotoUrl; }
    public void      setFotoUrl(String f)        { this.fotoUrl = f; }

    public Rol       getRol()                    { return rol; }
    public void      setRol(Rol rol)             { this.rol = rol; }

    public boolean   isActivo()                  { return activo; }
    public void      setActivo(boolean a)        { this.activo = a; }

    public boolean   isEmailVerificado()         { return emailVerificado; }
    public void      setEmailVerificado(boolean e){ this.emailVerificado = e; }

    public Timestamp getUltimoLogin()            { return ultimoLogin; }
    public void      setUltimoLogin(Timestamp t) { this.ultimoLogin = t; }

    public Timestamp getCreatedAt()              { return createdAt; }
    public void      setCreatedAt(Timestamp t)   { this.createdAt = t; }

    public Timestamp getUpdatedAt()              { return updatedAt; }
    public void      setUpdatedAt(Timestamp t)   { this.updatedAt = t; }

    @Override
    public String toString() {
        return "Usuario{id=" + id + ", email='" + email + "', rol=" + rol.getNombre() + "}";
    }
}
