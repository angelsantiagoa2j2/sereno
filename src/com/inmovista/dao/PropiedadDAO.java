package com.inmovista.dao;

import com.inmovista.db.DBManager;
import com.inmovista.model.Propiedad;
import com.inmovista.model.Propiedad.*;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class PropiedadDAO {

    private static final Logger LOGGER = Logger.getLogger(PropiedadDAO.class.getName());

    private static final String SQL_BASE =
        "SELECT p.*, c.nombre AS ciudad_nombre, " +
        "CONCAT(u.nombre,' ',u.apellido) AS inmobiliaria_nombre, " +
        "(SELECT url FROM propiedad_fotos WHERE propiedad_id=p.id AND es_portada=1 LIMIT 1) AS foto_portada " +
        "FROM propiedades p " +
        "JOIN ciudades c ON p.ciudad_id = c.id " +
        "JOIN usuarios u ON p.inmobiliaria_id = u.id ";

    private static final String SQL_FIND_ALL =
        SQL_BASE + "WHERE p.estado != 'INACTIVO' ORDER BY p.destacado DESC, p.fecha_creacion DESC";

    private static final String SQL_FIND_BY_ID =
        SQL_BASE + "WHERE p.id = ?";

    private static final String SQL_FIND_BY_INMOBILIARIA =
        SQL_BASE + "WHERE p.inmobiliaria_id = ? ORDER BY p.fecha_creacion DESC";

    private static final String SQL_FIND_DISPONIBLES =
        SQL_BASE + "WHERE p.estado = 'DISPONIBLE' ORDER BY p.destacado DESC, p.fecha_creacion DESC";

    private static final String SQL_INSERT =
        "INSERT INTO propiedades (titulo, descripcion, tipo, operacion, precio, area_m2, " +
        "habitaciones, banos, parqueaderos, piso, estrato, direccion, barrio, ciudad_id, " +
        "latitud, longitud, estado, inmobiliaria_id, destacado) " +
        "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

    private static final String SQL_UPDATE =
        "UPDATE propiedades SET titulo=?, descripcion=?, tipo=?, operacion=?, precio=?, " +
        "area_m2=?, habitaciones=?, banos=?, parqueaderos=?, piso=?, estrato=?, " +
        "direccion=?, barrio=?, ciudad_id=?, estado=? WHERE id=?";

    private static final String SQL_DELETE =
        "UPDATE propiedades SET estado='INACTIVO' WHERE id=?";

    private static final String SQL_COUNT =
        "SELECT COUNT(*) FROM propiedades WHERE estado != 'INACTIVO'";

    // ── Mapeo ─────────────────────────────────────────────────────────────────

    private Propiedad mapRow(ResultSet rs) throws SQLException {
        Propiedad p = new Propiedad();
        p.setId(rs.getInt("id"));
        p.setTitulo(rs.getString("titulo"));
        p.setDescripcion(rs.getString("descripcion"));
        p.setTipo(Tipo.valueOf(rs.getString("tipo")));
        p.setOperacion(Operacion.valueOf(rs.getString("operacion")));
        p.setPrecio(rs.getBigDecimal("precio"));
        p.setAreaM2(rs.getBigDecimal("area_m2"));
        p.setHabitaciones(rs.getInt("habitaciones"));
        p.setBanos(rs.getInt("banos"));
        p.setParqueaderos(rs.getInt("parqueaderos"));
        p.setPiso(rs.getObject("piso") != null ? rs.getInt("piso") : null);
        p.setEstrato(rs.getObject("estrato") != null ? rs.getInt("estrato") : null);
        p.setDireccion(rs.getString("direccion"));
        p.setBarrio(rs.getString("barrio"));
        p.setCiudadId(rs.getInt("ciudad_id"));
        p.setCiudadNombre(rs.getString("ciudad_nombre"));
        p.setEstado(Estado.valueOf(rs.getString("estado")));
        p.setInmobiliariaId(rs.getInt("inmobiliaria_id"));
        p.setInmobiliariaNombre(rs.getString("inmobiliaria_nombre"));
        p.setDestacado(rs.getBoolean("destacado"));
        p.setFotoPortadaUrl(rs.getString("foto_portada"));
        p.setCreatedAt(rs.getTimestamp("fecha_creacion"));
        return p;
    }

    // ── READ ──────────────────────────────────────────────────────────────────

    public List<Propiedad> findAll() { return query(SQL_FIND_ALL); }

    public List<Propiedad> findDisponibles() { return query(SQL_FIND_DISPONIBLES); }

    public List<Propiedad> findByInmobiliaria(int inmobiliariaId) {
        List<Propiedad> list = new ArrayList<>();
        Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            conn = DBManager.getConnection("cloud");
            ps = conn.prepareStatement(SQL_FIND_BY_INMOBILIARIA);
            ps.setInt(1, inmobiliariaId);
            rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error findByInmobiliaria", e);
        } finally { DBManager.closeResources(rs, ps, conn); }
        return list;
    }

    public Propiedad findById(int id) {
        Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            conn = DBManager.getConnection("cloud");
            ps = conn.prepareStatement(SQL_FIND_BY_ID);
            ps.setInt(1, id);
            rs = ps.executeQuery();
            return rs.next() ? mapRow(rs) : null;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error findById id=" + id, e);
            return null;
        } finally { DBManager.closeResources(rs, ps, conn); }
    }

    public List<Propiedad> search(String keyword, String tipo, String operacion,
                                   Double precioMin, Double precioMax, Integer ciudadId) {
        StringBuilder sql = new StringBuilder(SQL_BASE + "WHERE p.estado = 'DISPONIBLE' ");
        List<Object> params = new ArrayList<>();

        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append("AND (p.titulo LIKE ? OR p.descripcion LIKE ? OR p.barrio LIKE ?) ");
            String k = "%" + keyword.trim() + "%";
            params.add(k); params.add(k); params.add(k);
        }
        if (tipo != null && !tipo.isEmpty()) { sql.append("AND p.tipo=? "); params.add(tipo.toUpperCase()); }
        if (operacion != null && !operacion.isEmpty()) { sql.append("AND p.operacion=? "); params.add(operacion.toUpperCase()); }
        if (precioMin != null) { sql.append("AND p.precio>=? "); params.add(precioMin); }
        if (precioMax != null) { sql.append("AND p.precio<=? "); params.add(precioMax); }
        if (ciudadId != null) { sql.append("AND p.ciudad_id=? "); params.add(ciudadId); }
        sql.append("ORDER BY p.destacado DESC, p.fecha_creacion DESC");

        List<Propiedad> list = new ArrayList<>();
        Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            conn = DBManager.getConnection("cloud");
            ps = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) ps.setObject(i+1, params.get(i));
            rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error search", e);
        } finally { DBManager.closeResources(rs, ps, conn); }
        return list;
    }

    public int count() {
        Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            conn = DBManager.getConnection("cloud");
            ps = conn.prepareStatement(SQL_COUNT);
            rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error count", e);
            return 0;
        } finally { DBManager.closeResources(rs, ps, conn); }
    }

    // ── CREATE ────────────────────────────────────────────────────────────────

    public int insert(Propiedad p) {
        Connection conn = null; PreparedStatement ps = null; ResultSet keys = null;
        try {
            conn = DBManager.getConnection("cloud");
            ps = conn.prepareStatement(SQL_INSERT, Statement.RETURN_GENERATED_KEYS);
            ps.setString(1, p.getTitulo());
            ps.setString(2, p.getDescripcion());
            ps.setString(3, p.getTipo().name());
            ps.setString(4, p.getOperacion().name());
            ps.setBigDecimal(5, p.getPrecio());
            ps.setBigDecimal(6, p.getAreaM2());
            ps.setInt(7, p.getHabitaciones());
            ps.setInt(8, p.getBanos());
            ps.setInt(9, p.getParqueaderos());
            ps.setObject(10, p.getPiso());
            ps.setObject(11, p.getEstrato());
            ps.setString(12, p.getDireccion());
            ps.setString(13, p.getBarrio());
            ps.setInt(14, p.getCiudadId());
            ps.setObject(15, p.getLatitud());
            ps.setObject(16, p.getLongitud());
            ps.setString(17, p.getEstado() != null ? p.getEstado().name() : "DISPONIBLE");
            ps.setInt(18, p.getInmobiliariaId());
            ps.setBoolean(19, p.isDestacado());
            ps.executeUpdate();
            keys = ps.getGeneratedKeys();
            return keys.next() ? keys.getInt(1) : -1;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error insert propiedad", e);
            return -1;
        } finally {
            if (keys != null) try { keys.close(); } catch (SQLException ignored) {}
            DBManager.closeResources(ps, conn);
        }
    }

    // ── UPDATE ────────────────────────────────────────────────────────────────

    public boolean update(Propiedad p) {
        Connection conn = null; PreparedStatement ps = null;
        try {
            conn = DBManager.getConnection("cloud");
            ps = conn.prepareStatement(SQL_UPDATE);
            ps.setString(1, p.getTitulo());
            ps.setString(2, p.getDescripcion());
            ps.setString(3, p.getTipo().name());
            ps.setString(4, p.getOperacion().name());
            ps.setBigDecimal(5, p.getPrecio());
            ps.setBigDecimal(6, p.getAreaM2());
            ps.setInt(7, p.getHabitaciones());
            ps.setInt(8, p.getBanos());
            ps.setInt(9, p.getParqueaderos());
            ps.setObject(10, p.getPiso());
            ps.setObject(11, p.getEstrato());
            ps.setString(12, p.getDireccion());
            ps.setString(13, p.getBarrio());
            ps.setInt(14, p.getCiudadId());
            ps.setString(15, p.getEstado().name());
            ps.setInt(16, p.getId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error update propiedad id=" + p.getId(), e);
            return false;
        } finally { DBManager.closeResources(ps, conn); }
    }

    // ── DELETE (soft) ─────────────────────────────────────────────────────────

    public boolean delete(int id) {
        Connection conn = null; PreparedStatement ps = null;
        try {
            conn = DBManager.getConnection("cloud");
            ps = conn.prepareStatement(SQL_DELETE);
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error delete propiedad id=" + id, e);
            return false;
        } finally { DBManager.closeResources(ps, conn); }
    }

    // ── Helper ────────────────────────────────────────────────────────────────

    private List<Propiedad> query(String sql) {
        List<Propiedad> list = new ArrayList<>();
        Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            conn = DBManager.getConnection("cloud");
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error query: " + sql, e);
        } finally { DBManager.closeResources(rs, ps, conn); }
        return list;
    }
}
