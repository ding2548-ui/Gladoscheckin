import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/account_model.dart';
import 'cookie_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _cookies = [];
  String _pushToken = '';
  bool _loading = false;
  List<CheckinResult> _results = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cookies = await StorageService.getCookies();
    final token = await StorageService.getPushToken();
    setState(() {
      _cookies = cookies;
      _pushToken = token;
    });
  }

  Future<void> _checkin() async {
    if (_cookies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加 Cookie')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _results = [];
    });

    final results = <CheckinResult>[];
    for (final cookie in _cookies) {
      if (cookie.trim().isEmpty) continue;
      final result = await ApiService.checkin(cookie.trim());
      results.add(result);
      setState(() => _results = List.from(results));
    }

    // Push notification
    final success = results.where((r) => r.status == CheckinStatus.success).length;
    final fail = results.where((r) => r.status == CheckinStatus.fail || r.status == CheckinStatus.error).length;
    final repeat = results.where((r) => r.status == CheckinStatus.repeat).length;

    String title;
    if (fail > 0) {
      title = '签到异常：成功$success，失败$fail，重复$repeat';
    } else if (success > 0) {
      title = '签到成功（${results.length}个账号）';
    } else {
      title = '全部重复签到';
    }

    final content = results.map((r) => '${r.email}: ${r.message}').join('<br>');

    if (_pushToken.isNotEmpty) {
      await ApiService.pushNotification(_pushToken, title, content);
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.computer, size: 24),
            SizedBox(width: 8),
            Text('GLaDOS 签到'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
              _loadData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Account list header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  '账号列表 (${_cookies.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CookiePage()),
                    );
                    _loadData();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('管理'),
                ),
              ],
            ),
          ),

          // Results list
          Expanded(
            child: _results.isEmpty && !_loading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_queue, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _cookies.isEmpty ? '点击右上角"管理"添加Cookie' : '点击下方按钮开始签到',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _results.length + (_loading && _results.length < _cookies.length ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _results.length) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 16),
                                Text('签到中...'),
                              ],
                            ),
                          ),
                        );
                      }
                      final r = _results[i];
                      return Card(
                        child: ListTile(
                          leading: Icon(r.icon, color: r.color, size: 32),
                          title: Text(r.email.isNotEmpty ? r.email : '账号 ${i + 1}'),
                          subtitle: Text(r.message),
                          trailing: r.leftDays > 0
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${r.leftDays}天', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    if (r.points > 0) Text('+${r.points}P', style: TextStyle(fontSize: 12, color: Colors.green[700])),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _checkin,
        icon: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.play_arrow),
        label: Text(_loading ? '签到中...' : '立即签到'),
        backgroundColor: const Color(0xFFFF6D00),
        foregroundColor: Colors.white,
      ),
    );
  }
}
