package com.glados.checkin

import android.os.Bundle
import android.text.InputType
import android.view.Gravity
import android.view.ViewGroup
import android.widget.*
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.floatingactionbutton.FloatingActionButton
import java.text.SimpleDateFormat
import java.util.*

class MainActivity : AppCompatActivity() {

    private lateinit var cookieList: RecyclerView
    private lateinit var logText: TextView
    private lateinit var adapter: CookieAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        cookieList = findViewById(R.id.cookieList)
        logText = findViewById(R.id.logText)
        val fabAdd = findViewById<FloatingActionButton>(R.id.fabAdd)
        val btnCheckin = findViewById<Button>(R.id.btnCheckin)
        val btnSchedule = findViewById<Button>(R.id.btnSchedule)

        adapter = CookieAdapter(
            cookies = CookieManager.getCookies(this),
            onDelete = { index ->
                CookieManager.removeCookie(this, index)
                refreshList()
            }
        )
        cookieList.layoutManager = LinearLayoutManager(this)
        cookieList.adapter = adapter

        fabAdd.setOnClickListener { showAddDialog() }
        btnCheckin.setOnClickListener { doManualCheckin() }
        btnSchedule.setOnClickListener { toggleSchedule(btnSchedule) }
    }

    private fun refreshList() {
        adapter.cookies = CookieManager.getCookies(this)
        adapter.notifyDataSetChanged()
    }

    private fun showAddDialog() {
        val input = EditText(this).apply {
            hint = "粘贴 cookie（koa:sess=...; koa:sess.sig=...;）"
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINES
            minLines = 2
            gravity = Gravity.TOP
        }

        AlertDialog.Builder(this)
            .setTitle("添加 Cookie")
            .setView(input)
            .setPositiveButton("添加") { _, _ ->
                val cookie = input.text.toString().trim()
                if (CookieManager.addCookie(this, cookie)) {
                    refreshList()
                    appendLog("✅ Cookie 已添加")
                } else {
                    appendLog("⚠️ Cookie 为空或已存在")
                }
            }
            .setNegativeButton("取消", null)
            .show()
    }

    private fun doManualCheckin() {
        val cookies = CookieManager.getCookies(this)
        if (cookies.isEmpty()) {
            appendLog("⚠️ 请先添加 Cookie")
            return
        }

        appendLog("🚀 开始签到...")
        Thread {
            val results = CheckinWorker.doCheckinAll(this)
            runOnUiThread {
                val time = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
                results.forEach { r ->
                    val label = r.email.ifBlank { "未知" }
                    appendLog("[$time] ${r.message} ($label) 剩余${r.leftDays}天")
                }
            }
        }.start()
    }

    private fun toggleSchedule(btn: Button) {
        val prefs = getSharedPreferences("glados_checkin", MODE_PRIVATE)
        val scheduled = prefs.getBoolean("scheduled", false)
        if (scheduled) {
            CheckinReceiver.cancel(this)
            prefs.edit().putBoolean("scheduled", false).apply()
            btn.text = "开启定时签到"
            appendLog("⏹ 已关闭定时签到")
        } else {
            CheckinReceiver.schedule(this)
            prefs.edit().putBoolean("scheduled", true).apply()
            btn.text = "关闭定时签到"
            appendLog("⏰ 已开启定时签到（每天 8:30）")
        }
    }

    private fun appendLog(msg: String) {
        logText.append("$msg\n")
    }
}
