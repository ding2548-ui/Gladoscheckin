import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/schedule_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _tokenController = TextEditingController();
  bool _scheduleEnabled = false;
  int _scheduleHour = 8;
  int _scheduleMinute = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final token = await StorageService.getPushToken();
    final scheduled = await ScheduleService.isScheduled();
    final hour = await _getScheduleHour();
    final minute = await _getScheduleMinute();
    setState(() {
      _tokenController.text = token;
      _scheduleEnabled = scheduled;
      _scheduleHour = hour;
      _scheduleMinute = minute;
    });
  }

  Future<int> _getScheduleHour() async {
    final prefs = await _getPrefs();
    return prefs.getInt('schedule_hour') ?? 8;
  }

  Future<int> _getScheduleMinute() async {
    final prefs = await _getPrefs();
    return prefs.getInt('schedule_minute') ?? 0;
  }

  Future<void> _setScheduleTime(int hour, int minute) async {
    final prefs = await _getPrefs();
    await prefs.setInt('schedule_hour', hour);
    await prefs.setInt('schedule_minute', minute);
  }

  Future<dynamic> _getPrefs() async {
    // Import SharedPreferences
    final SharedPreferences prefs = await _getSharedPrefs();
    return prefs;
  }

  Future<SharedPreferences> _getSharedPrefs() async {
    return await SharedPreferences.getInstance();
  }

  Future<void> _saveToken() async {
    final token = _tokenController.text.trim();
    await StorageService.setPushToken(token);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token 已保存')),
      );
    }
  }

  Future<void> _toggleSchedule(bool enabled) async {
    if (enabled) {
      await ScheduleService.scheduleDaily(_scheduleHour, _scheduleMinute);
      setState(() => _scheduleEnabled = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('定时签到已开启，每天 $_scheduleHour:$_scheduleMinute 执行')),
        );
      }
    } else {
      await ScheduleService.cancelSchedule();
      setState(() => _scheduleEnabled = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('定时签到已关闭')),
        );
      }
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _scheduleHour, minute: _scheduleMinute),
    );
    if (picked != null) {
      setState(() {
        _scheduleHour = picked.hour;
        _scheduleMinute = picked.minute;
      });
      await _setScheduleTime(picked.hour, picked.minute);
      if (_scheduleEnabled) {
        await ScheduleService.scheduleDaily(picked.hour, picked.minute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PushPlus Token
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
                    controller: _tokenController,
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
                        child: FilledButton(onPressed: _saveToken, child: const Text('保存')),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: () {
                          _tokenController.clear();
                          _saveToken();
                        },
                        child: const Text('清除'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Schedule settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('定时签到', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Switch(
                        value: _scheduleEnabled,
                        onChanged: _toggleSchedule,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('开启后每天自动签到', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: const Text('签到时间'),
                    subtitle: Text(
                      '${_scheduleHour.toString().padLeft(2, '0')}:${_scheduleMinute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickTime,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Instructions
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
                  const Text('4. 点击第一个请求，找到 Cookie 复制', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('5. 在 pushplus.plus 获取 Token 用于微信推送', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('6. 开启定时签到，设置每天执行时间', style: TextStyle(fontSize: 14)),
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
    _tokenController.dispose();
    super.dispose();
  }
}
