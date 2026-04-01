import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPushToken();
  }

  Future<void> _loadPushToken() async {
    final token = await StorageService.getPushToken();
    setState(() {
      _controller.text = token;
    });
  }

  Future<void> _savePushToken() async {
    final token = _controller.text.trim();
    await StorageService.setPushToken(token);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PushPlus Token', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('用于签到结果推送到微信', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: '请输入 PushPlus Token',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(onPressed: _savePushToken, child: const Text('保存')),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: () { _controller.clear(); _savePushToken(); },
                        child: const Text('清除'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('使用说明', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  const Text('1. 点击首页"管理"添加 Cookie', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('2. 前往 GLaDOS 签到页面，按 F12 打开开发者工具', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('3. 切换到 Network 页面，刷新页面', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('4. 点击第一个请求，在 Request Headers 中找到 Cookie', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('5. 复制 Cookie 的值，粘贴到本 App 中', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('6. 在 pushplus.plus 获取 Token 用于微信推送', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
