package com.glados.checkin

import android.content.Context
import android.content.SharedPreferences

object CookieManager {
    private const val PREFS_NAME = "glados_cookies"
    private const val KEY_COOKIES = "cookies"

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun getCookies(context: Context): MutableList<String> {
        val raw = prefs(context).getString(KEY_COOKIES, "") ?: ""
        return raw.split("\n").filter { it.isNotBlank() }.toMutableList()
    }

    fun addCookie(context: Context, cookie: String): Boolean {
        val trimmed = cookie.trim()
        if (trimmed.isBlank()) return false
        val list = getCookies(context)
        if (list.contains(trimmed)) return false
        list.add(trimmed)
        save(context, list)
        return true
    }

    fun removeCookie(context: Context, index: Int) {
        val list = getCookies(context)
        if (index in list.indices) {
            list.removeAt(index)
            save(context, list)
        }
    }

    fun clearAll(context: Context) {
        save(context, emptyList())
    }

    private fun save(context: Context, list: List<String>) {
        prefs(context).edit().putString(KEY_COOKIES, list.joinToString("\n")).apply()
    }
}
