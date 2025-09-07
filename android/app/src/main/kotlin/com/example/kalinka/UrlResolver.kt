package com.example.kalinka

/**
 * URL resolver utility class for resolving relative paths against a base URL.
 */
class UrlResolver(private val base: String) {

    /**
     * Resolves a path to an absolute URL.
     * If the path is already absolute (starts with 'http'), returns it as-is.
     * Otherwise, combines it with the base URL.
     */
    fun abs(path: String): String {
        if (path.startsWith("http")) return path

        val b = if (base.endsWith("/")) {
            base.substring(0, base.length - 1)
        } else {
            base
        }

        val p = if (path.startsWith("/")) {
            path
        } else {
            "/$path"
        }

        return "$b$p"
    }

    /**
     * Returns the base URL as a stable key.
     */
    val baseKey: String
        get() = base
}
