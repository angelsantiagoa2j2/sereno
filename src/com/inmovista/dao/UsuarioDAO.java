package com.inmovista.dao;

import com.inmovista.db.DBManager;
import com.inmovista.model.Usuario;
import com.inmovista.model.Usuario.Rol;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * UsuarioDAO — Operaciones CRUD sobre la tabla `usuarios`.
 *
 * Usa DBManager para obtener conexiones (local o cloud automáticamente).
 */
public class UsuarioDAO {

    private static final Logger LOGGER = Logger.getLogger(UsuarioDAO.class.getName());

    // ─── SQL ─────────────────────────────────────────────────────────────────

    private static final String SQL_FIND_BY_ID =
        "SELECT u.*, r.nombre AS rol_nombre FROM usuarios u " +
        "JOIN roles r ON u.rol_id = r.id WHERE u.id = ?";

    private static final String SQL_FIND_BY_EMAIL =
        "SELECT u.*, r.nombre AS rol_nombre FROM usuarios u " +
        "JOIN roles r ON u.rol_id = r.id WHERE u.email = ? AND u.activo = 1";

    private static final String SQL_FIND_ALL =
        "SELECT u.*, r.nombre AS rol_nombre FROM usuarios u " +
        "JOIN roles r ON u.rol_id = r.id ORDER BY u.created_at DESC";

    private static final String SQL_FIND_BY_ROL =
        "SELECT u.*, r.nombre AS rol_nombre FROM usuarios u " +
        "JOIN roles r ON u.rol_id = r.id WHERE r.nombre = ? ORDER BY u.nombre";

    private static final String SQL_INSERT =
        "INSERT INTO usuarios (nombre, apellido, email, password_hash, telefono, " +
        "documento, foto_url, rol_id, activo, email_verificado) " +
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

    private static final String SQL_UPDATE =
        "UPDATE usuarios SET nombre=?, apellido=?, telefono=?, documento=?, " +
        "foto_url=?, activo=?, updated_at=NOW() WHERE id=?";

    private static final String SQL_UPDATE_PASSWORD =
        "UPDATE usuarios SET password_hash=?, updated_at=NOW() WHERE id=?";

    private static final String SQL_UPDATE_ULTIMO_LOGIN =
        "UPDATE usuarios SET ultimo_login=NOW() WHERE id=?";

    private static final String SQL_DELETE =
        "UPDATE usuarios SET activo=0, updated_at=NOW() WHERE id=?";    // soft delete

    private static final String SQL_EMAIL_EXISTS =
        "SELECT COUNT(*) FROM usuarios WHERE email = ?";

    // ─── Mapeo ResultSet → Usuario ────────────────────────────────────────────

    private Usuario mapRow(ResultSet rs) throws SQLException {
        Usuario u = new Usuario();
        u.setId(rs.getInt("id"));
        u.setNombre(rs.getString("nombre"));
        u.setApellido(rs.getString("apellido"));
        u.setEmail(rs.getString("email"));
        u.setPasswordHash(rs.getString("password_hash"));
        u.setTelefono(rs.getString("telefono"));
        u.setDocumento(rs.getString("documento"));
        u.setFotoUrl(rs.getString("foto_url"));
        u.setRol(Rol.fromNombre(rs.getString("rol_nombre")));
        u.setActivo(rs.getBoolean("activo"));
        u.setEmailVerificado(rs.getBoolean("email_verificado"));
        u.setUltimoLogin(rs.getTimestamp("ultimo_login"));
        u.setCreatedAt(rs.getTimestamp("created_at"));
        u.setUpdatedAt(rs.getTimestamp("updated_at"));
        return u;
    }

    // ─── CRUD ─────────────────────────────────────────────────────────────────

    /** Busca un usuario por ID. Retorna null si no existe. */
    public Usuario findById(int id) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBManager.getConnection();
            ps = conn.prepareStatement(SQL_FIND_BY_ID);
            ps.setInt(1, id);
            rs = ps.executeQuery();
            return rs.next() ? mapRow(rs) : null;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error findById id=" + id, e);
            return null;
        } finally {
            DBManager.closeResources(rs, ps, conn);
        }
    }

    /** Busca un usuario activo por email. Retorna null si no existe. */
    public Usuario findByEmail(String email) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBManager.getConnection();
            ps = conn.prepareStatement(SQL_FIND_BY_EMAIL);
            ps.setString(1, email);
            rs = ps.executeQuery();
            return rs.next() ? mapRow(rs) : null;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error findByEmail email=" + email, e);
            return null;
        } finally {
            DBManager.closeResources(rs, ps, conn);
        }
    }

    /** Lista todos los usuarios. */
    public List<Usuario> findAll() {
        List<Usuario> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBManager.getConnection();
            ps = conn.prepareStatement(SQL_FIND_ALL);
            rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error findAll", e);
        } finally {
            DBManager.closeResources(rs, ps, conn);
        }
        return list;
    }

    /** Lista usuarios por rol (ej: "CLIENTE", "INMOBILIARIA"). */
    public List<Usuario> findByRol(String rolNombre) {
        List<Usuario> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBManager.getConnection();
            ps = conn.prepareStatement(SQL_FIND_BY_ROL);
            ps.setString(1, rolNombre.toUpperCase());
            rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error findByRol rol=" + rolNombre, e);
        } finally {
            DBManager.closeResources(rs, ps, conn);
        }
        return list;
    }

    /**
     * Inserta un nuevo usuario. Retorna el id generado, o -1 si falla.
     * NOTA: passwordHash debe venir ya encriptado con BCrypt.
     */
    public int insert(Usuario u) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet keys = null;
        try {
            conn = DBManager.getConnection();
            ps = conn.prepareStatement(SQL_INSERT, Statement.RETURN_GENERATED_KEYS);
            ps.setString(1, u.getNombre());
            ps.setString(2, u.getApellido());
            ps.setString(3, u.getEmail());
            ps.setString(4, u.getPasswordHash());
            ps.setString(5, u.getTelefono());
            ps.setString(6, u.getDocumento());
            ps.setString(7, u.getFotoUrl());
            ps.setInt(8, u.getRol().getId());
            ps.setBoolean(9, u.isActivo());
            ps.setBoolean(10, u.isEmailVerificado());
            ps.executeUpdate();
            keys = ps.getGeneratedKeys();
            return keys.next() ? keys.getInt(1) : -1;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error insert usuario email=" + u.getEmail(), e);
            return -1;
        } finally {
            if (keys != null) try { keys.close(); } catch (SQLException ignored) {}
            DBManager.closeResources(ps, conn);
        }
    }

    /** Actualiza datos básicos del usuario (no contraseña). */
    public boolean update(Usuario u) {
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBManager.getConnection();
            ps = conn.prepareStatement(SQL_UPDATE);
            ps.setString(1, u.getNombre());
            ps.setString(2, u.getApellido());
            ps.setString(3, u.getTelefono());
            ps.setString(4, u.getDocumento());
            ps.setString(5, u.getFotoUrl());
            ps.setBoolean(6, u.isActivo());
            ps.setInt(7, u.getId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error update usuario id=" + u.getId(), e);
            return false;
        } finally {
            DBManager.closeResources(ps, conn);
        }
    }

    /** Actualiza la contraseña (ya hasheada). */
    public boolean updatePassword(int userId, String newHash) {
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBManager.getConnection();
            ps = conn.prepareStatement(SQL_UPDATE_PASSWORD);
            ps.setString(1, newHash);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error updatePassword userId=" + userId, e);
            return false;
        } finally {
            DBManager.closeResources(ps, conn);
        }
    }

    /** Registra el último login del usuario. */
    public void registerLogin(int userId) {
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBManager.getConnection();
            ps = conn.prepareStatement(SQL_UPDATE_ULTIMO_LOGIN);
            ps.setInt(1, userId);
            ps.executeUpdate();
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error registerLogin userId=" + userId, e);
        } finally {
            DBManager.closeResources(ps, conn);
        }
    }

    /** Soft-delete: desactiva el usuario en lugar de eliminarlo. */
    public boolean delete(int userId) {
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBManager.getConnection();
            ps = conn.prepareStatement(SQL_DELETE);
            ps.setInt(1, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error delete userId=" + userId, e);
            return false;
        } finally {
            DBManager.closeResources(ps, conn);
        }
    }

    /** Verifica si un email ya existe en la BD. */
    public boolean emailExists(String email) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBManager.getConnection();
            ps = conn.prepareStatement(SQL_EMAIL_EXISTS);
            ps.setString(1, email);
            rs = ps.executeQuery();
            return rs.next() && rs.getInt(1) > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error emailExists email=" + email, e);
            return false;
        } finally {
            DBManager.closeResources(rs, ps, conn);
        }
    }
}
