import 'package:flutter/material.dart';

class CheckinResult {
  final String email;
  final int points;
  final int leftDays;
  final String message;
  final CheckinStatus status;

  CheckinResult._(this.email, this.points, this.leftDays, this.message, this.status);

  factory CheckinResult.success(String email, int points, int leftDays, String msg) =>
      CheckinResult._(email, points, leftDays, msg, CheckinStatus.success);
  factory CheckinResult.repeat(String email, int leftDays) =>
      CheckinResult._(email, 0, leftDays, '今日已签到', CheckinStatus.repeat);
  factory CheckinResult.fail(String email, String msg) =>
      CheckinResult._(email, 0, 0, msg, CheckinStatus.fail);
  factory CheckinResult.error(String msg) =>
      CheckinResult._('', 0, 0, '请求异常: $msg', CheckinStatus.error);

  IconData get icon {
    switch (status) {
      case CheckinStatus.success: return Icons.check_circle;
      case CheckinStatus.repeat: return Icons.replay_circle_filled;
      case CheckinStatus.fail: return Icons.cancel;
      case CheckinStatus.error: return Icons.error;
    }
  }

  Color get color {
    switch (status) {
      case CheckinStatus.success: return Colors.green;
      case CheckinStatus.repeat: return Colors.orange;
      case CheckinStatus.fail: return Colors.red;
      case CheckinStatus.error: return Colors.grey;
    }
  }
}

enum CheckinStatus { success, repeat, fail, error }
