package com.glados.checkin

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView

class CookieAdapter(
    var cookies: MutableList<String>,
    private val onDelete: (Int) -> Unit
) : RecyclerView.Adapter<CookieAdapter.ViewHolder>() {

    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val tvCookie: TextView = view.findViewById(R.id.tvCookie)
        val btnDelete: ImageButton = view.findViewById(R.id.btnDelete)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_cookie, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val cookie = cookies[position]
        // 显示前 40 个字符，隐藏完整 cookie
        val display = if (cookie.length > 40) cookie.take(40) + "..." else cookie
        holder.tvCookie.text = "账号 ${position + 1}: $display"
        holder.btnDelete.setOnClickListener { onDelete(position) }
    }

    override fun getItemCount() = cookies.size
}
