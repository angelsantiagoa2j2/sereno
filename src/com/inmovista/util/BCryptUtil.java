package com.inmovista.util;

import org.mindrot.jbcrypt.BCrypt;

/**
 * BCryptUtil — Wrapper sobre la libreria jBCrypt.
 * Requiere jbcrypt-0.4.jar en WEB-INF/lib/
 */
public class BCryptUtil {

    private BCryptUtil() {}

    /** Genera un hash BCrypt de la contrasena. */
    public static String hashPassword(String password) {
        return BCrypt.hashpw(password, BCrypt.gensalt(12));
    }

    /** Verifica si la contrasena coincide con el hash. */
    public static boolean checkPassword(String plainPassword, String hashedPassword) {
        if (plainPassword == null || hashedPassword == null) return false;
        try {
            return BCrypt.checkpw(plainPassword, hashedPassword);
        } catch (Exception e) {
            return false;
        }
    }
}
