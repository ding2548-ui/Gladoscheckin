import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class CookiePage extends StatefulWidget {
  const CookiePage({super.key});

  @override
  State<CookiePage> createState() => _CookiePageState();
}

class _CookiePageState extends State<CookiePage> {
  List<String> _cookies = [];
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCookies();
  }

  Future<void> _loadCookies() async {
    final cookies = await StorageService.getCookies();
    setState(() => _cookies = cookies);
  }

  Future<void> _addCookie() async {
    final cookie = _controller.text.trim();
    if (cookie.isEmpty) return;
    await StorageService.addCookie(cookie);
    _controller.clear();
    await _loadCookies();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已添加')),
      );
    }
  }

  Future<void> _removeCookie(int index) async {
    await StorageService.removeCookie(index);
    await _loadCookies();
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('添加 Cookie', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('格式: koa:sess=xxx; koa:sess.sig=xxx;', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '粘贴 Cookie 内容...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  _addCookie();
                  Navigator.pop(context);
                },
                child: const Text('添加'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cookie 管理')),
      body: _cookies.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cookie_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('暂无 Cookie', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  const Text('点击下方按钮添加', style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cookies.length,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex--;
                final cookie = _cookies.removeAt(oldIndex);
                _cookies.insert(newIndex, cookie);
                await StorageService.setCookies(_cookies);
                setState(() {});
              },
              itemBuilder: (context, i) {
                final cookie = _cookies[i];
                final preview = cookie.length > 40 ? '${cookie.substring(0, 40)}...' : cookie;
                return Card(
                  key: ValueKey(i),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text('${i + 1}'),
                    ),
                    title: Text('账号 ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(preview, style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removeCookie(i),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFFFF6D00),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
