import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _batteryIgnored = false;
  String _batteryStatus = '检查中...';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final token = await StorageService.getPushToken();
    final hour = await _getInt('schedule_hour', 8);
    final minute = await _getInt('schedule_minute', 0);
    final scheduled = await ScheduleService.isScheduled();

    // 检查电池优化状态
    String batteryStatus = '未知';
    bool batteryIgnored = false;
    try {
      const channel = MethodChannel('glados/battery');
      batteryIgnored = await channel.invokeMethod('isIgnoringBatteryOpt') ?? false;
      batteryStatus = batteryIgnored ? '已忽略' : '未忽略';
    } catch (e) {
      batteryStatus = '检查失败';
    }

    if (mounted) {
      setState(() {
        _tokenController.text = token;
        _scheduleEnabled = scheduled;
        _scheduleHour = hour;
        _scheduleMinute = minute;
        _batteryIgnored = batteryIgnored;
        _batteryStatus = batteryStatus;
      });
    }
  }

  Future<int> _getInt(String key, int def) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? def;
  }

  Future<void> _setInt(String key, int val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, val);
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
    try {
      if (enabled) {
        await ScheduleService.scheduleDaily(_scheduleHour, _scheduleMinute);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('定时签到已开启，每天 ${_scheduleHour.toString().padLeft(2, '0')}:${_scheduleMinute.toString().padLeft(2, '0')} 执行')),
          );
        }
      } else {
        await ScheduleService.cancelSchedule();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('定时签到已关闭')),
          );
        }
      }
      if (mounted) setState(() => _scheduleEnabled = enabled);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
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
      await _setInt('schedule_hour', picked.hour);
      await _setInt('schedule_minute', picked.minute);
      if (_scheduleEnabled) {
        await _toggleSchedule(true);
      }
    }
  }

  Future<void> _requestBatteryOpt() async {
    try {
      const channel = MethodChannel('glados/battery');
      await channel.invokeMethod('requestIgnoreBatteryOpt');
      // 延迟检查状态
      await Future.delayed(const Duration(seconds: 2));
      final ignored = await channel.invokeMethod('isIgnoringBatteryOpt') ?? false;
      if (mounted) {
        setState(() {
          _batteryIgnored = ignored;
          _batteryStatus = ignored ? '已忽略' : '未忽略（可能已取消）';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ignored ? '电池优化已忽略 ✅' : '未完成授权')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请求失败: $e')),
        );
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
          // 推送通知
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('推送通知', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('签到结果推送到微信', style: TextStyle(fontSize: 13, color: Colors.grey)),
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

          // 定时签到
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

          // 保后台
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('保后台设置', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('防止系统杀后台导致定时签到失效', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 16),
                  // 电池优化
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _batteryIgnored ? Icons.battery_saver : Icons.battery_alert,
                      color: _batteryIgnored ? Colors.green : Colors.orange,
                    ),
                    title: const Text('忽略电池优化'),
                    subtitle: Text(_batteryStatus),
                    trailing: FilledButton.tonal(
                      onPressed: _batteryIgnored ? null : _requestBatteryOpt,
                      child: Text(_batteryIgnored ? '已开启' : '去开启'),
                    ),
                  ),
                  const Divider(),
                  // 自启动提醒
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.power_settings_new, color: Colors.orange),
                    title: Text('自启动权限'),
                    subtitle: Text('请在系统设置中手动开启本应用的自启动权限'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                  const SizedBox(height: 8),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.lock_open, color: Colors.orange),
                    title: Text('锁定后台'),
                    subtitle: Text('建议在最近任务中锁定本应用，防止被清理'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 使用说明
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
                  const SizedBox(height: 4),
                  const Text('7. 开启保后台设置，防止系统杀进程', style: TextStyle(fontSize: 14)),
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
