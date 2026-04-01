package com.glados.checkin

import android.content.Context
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit

object CheckinWorker {

    private const val CHECKIN_URL = "https://glados.cloud/api/user/checkin"
    private const val STATUS_URL = "https://glados.cloud/api/user/status"
    private const val REFERER = "https://glados.cloud/console/checkin"
    private const val ORIGIN = "https://glados.cloud"
    private const val USER_AGENT =
        "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36"

    data class CheckinResult(
        val email: String,
        val success: Boolean,
        val message: String,
        val points: Int,
        val leftDays: Int
    )

    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()

    fun doCheckin(cookie: String): CheckinResult {
        val payload = JSONObject().put("token", "glados.cloud").toString()

        val checkinReq = Request.Builder()
            .url(CHECKIN_URL)
            .post(payload.toRequestBody("application/json;charset=UTF-8".toMediaType()))
            .header("Cookie", cookie)
            .header("Referer", REFERER)
            .header("Origin", ORIGIN)
            .header("User-Agent", USER_AGENT)
            .build()

        val statusReq = Request.Builder()
            .url(STATUS_URL)
            .get()
            .header("Cookie", cookie)
            .header("Referer", REFERER)
            .header("Origin", ORIGIN)
            .header("User-Agent", USER_AGENT)
            .build()

        var email = ""
        var leftDays = 0
        var points = 0
        var msg = ""
        var success = false

        try {
            client.newCall(checkinReq).execute().use { resp ->
                val body = resp.body?.string() ?: ""
                val json = JSONObject(body)
                msg = json.optString("message", "")
                points = json.optInt("points", 0)
                success = msg.contains("Checkin! Got")
            }
        } catch (e: Exception) {
            return CheckinResult("", false, "请求异常: ${e.message}", 0, 0)
        }

        try {
            client.newCall(statusReq).execute().use { resp ->
                val body = resp.body?.string() ?: ""
                val json = JSONObject(body)
                val data = json.optJSONObject("data")
                email = data?.optString("email", "") ?: ""
                leftDays = data?.optDouble("leftDays", 0.0)?.toInt() ?: 0
            }
        } catch (_: Exception) {}

        val finalMsg = when {
            msg.contains("Checkin! Got") -> "签到成功 +${points}点"
            msg.contains("Checkin Repeats!") -> "今天已签到"
            else -> "签到失败: $msg"
        }

        return CheckinResult(email, success, finalMsg, points, leftDays)
    }

    fun doCheckinAll(context: Context): List<CheckinResult> {
        val cookies = CookieManager.getCookies(context)
        return cookies.map { doCheckin(it) }
    }
}
