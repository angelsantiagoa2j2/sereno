package com.inmovista.model;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class Propiedad {

    public enum Tipo {
        CASA, APARTAMENTO, TERRENO, LOCAL, FINCA, BODEGA
    }

    public enum Operacion {
        VENTA, ARRIENDO, VENTA_ARRIENDO
    }

    public enum Estado {
        DISPONIBLE, RESERVADO, VENDIDO, ARRENDADO, INACTIVO
    }

    private int        id;
    private String     titulo;
    private String     descripcion;
    private Tipo       tipo;
    private Operacion  operacion;
    private BigDecimal precio;
    private BigDecimal areaM2;
    private int        habitaciones;
    private int        banos;
    private int        parqueaderos;
    private Integer    piso;
    private Integer    estrato;
    private String     direccion;
    private String     barrio;
    private int        ciudadId;
    private String     ciudadNombre;   // JOIN
    private Double     latitud;
    private Double     longitud;
    private Estado     estado;
    private int        inmobiliariaId;
    private String     inmobiliariaNombre; // JOIN
    private boolean    destacado;
    private int        visitasCount;
    private String     fotoPortadaUrl; // JOIN propiedad_fotos
    private Timestamp  createdAt;
    private Timestamp  updatedAt;

    public Propiedad() {}

    // ── Helpers ──────────────────────────────────────────────────────────────

    public String getPrecioFormateado() {
        if (precio == null) return "$0";
        return "$" + String.format("%,.0f", precio).replace(",", ".");
    }

    public String getTipoLabel() {
        if (tipo == null) return "";
        switch (tipo) {
            case CASA:        return "Casa";
            case APARTAMENTO: return "Apartamento";
            case TERRENO:     return "Terreno";
            case LOCAL:       return "Local";
            case FINCA:       return "Finca";
            case BODEGA:      return "Bodega";
            default:          return tipo.name();
        }
    }

    public String getOperacionLabel() {
        if (operacion == null) return "";
        switch (operacion) {
            case VENTA:         return "Venta";
            case ARRIENDO:      return "Arriendo";
            case VENTA_ARRIENDO: return "Venta / Arriendo";
            default:            return operacion.name();
        }
    }

    public String getEstadoLabel() {
        if (estado == null) return "";
        switch (estado) {
            case DISPONIBLE: return "Disponible";
            case RESERVADO:  return "Reservado";
            case VENDIDO:    return "Vendido";
            case ARRENDADO:  return "Arrendado";
            case INACTIVO:   return "Inactivo";
            default:         return estado.name();
        }
    }

    public String getIcono() {
        if (tipo == null) return "🏠";
        switch (tipo) {
            case CASA:        return "🏡";
            case APARTAMENTO: return "🏢";
            case TERRENO:     return "🌿";
            case LOCAL:       return "🏪";
            case FINCA:       return "🌳";
            case BODEGA:      return "🏭";
            default:          return "🏠";
        }
    }

    // ── Getters & Setters ─────────────────────────────────────────────────────

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getTitulo() { return titulo; }
    public void setTitulo(String titulo) { this.titulo = titulo; }

    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }

    public Tipo getTipo() { return tipo; }
    public void setTipo(Tipo tipo) { this.tipo = tipo; }

    public Operacion getOperacion() { return operacion; }
    public void setOperacion(Operacion operacion) { this.operacion = operacion; }

    public BigDecimal getPrecio() { return precio; }
    public void setPrecio(BigDecimal precio) { this.precio = precio; }

    public BigDecimal getAreaM2() { return areaM2; }
    public void setAreaM2(BigDecimal areaM2) { this.areaM2 = areaM2; }

    public int getHabitaciones() { return habitaciones; }
    public void setHabitaciones(int habitaciones) { this.habitaciones = habitaciones; }

    public int getBanos() { return banos; }
    public void setBanos(int banos) { this.banos = banos; }

    public int getParqueaderos() { return parqueaderos; }
    public void setParqueaderos(int parqueaderos) { this.parqueaderos = parqueaderos; }

    public Integer getPiso() { return piso; }
    public void setPiso(Integer piso) { this.piso = piso; }

    public Integer getEstrato() { return estrato; }
    public void setEstrato(Integer estrato) { this.estrato = estrato; }

    public String getDireccion() { return direccion; }
    public void setDireccion(String direccion) { this.direccion = direccion; }

    public String getBarrio() { return barrio; }
    public void setBarrio(String barrio) { this.barrio = barrio; }

    public int getCiudadId() { return ciudadId; }
    public void setCiudadId(int ciudadId) { this.ciudadId = ciudadId; }

    public String getCiudadNombre() { return ciudadNombre; }
    public void setCiudadNombre(String ciudadNombre) { this.ciudadNombre = ciudadNombre; }

    public Double getLatitud() { return latitud; }
    public void setLatitud(Double latitud) { this.latitud = latitud; }

    public Double getLongitud() { return longitud; }
    public void setLongitud(Double longitud) { this.longitud = longitud; }

    public Estado getEstado() { return estado; }
    public void setEstado(Estado estado) { this.estado = estado; }

    public int getInmobiliariaId() { return inmobiliariaId; }
    public void setInmobiliariaId(int inmobiliariaId) { this.inmobiliariaId = inmobiliariaId; }

    public String getInmobiliariaNombre() { return inmobiliariaNombre; }
    public void setInmobiliariaNombre(String n) { this.inmobiliariaNombre = n; }

    public boolean isDestacado() { return destacado; }
    public void setDestacado(boolean destacado) { this.destacado = destacado; }

    public int getVisitasCount() { return visitasCount; }
    public void setVisitasCount(int visitasCount) { this.visitasCount = visitasCount; }

    public String getFotoPortadaUrl() { return fotoPortadaUrl; }
    public void setFotoPortadaUrl(String fotoPortadaUrl) { this.fotoPortadaUrl = fotoPortadaUrl; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public Timestamp getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Timestamp updatedAt) { this.updatedAt = updatedAt; }
}
