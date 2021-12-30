import 'package:get/get.dart';

class CreateMeetingModel extends GetxController {
  // 开启loading
  bool showLoading = false;
  // 是否为预约会议
  bool _reserved = false;
  // 是否需要密码
  bool usePassword = false;
  DateTime? _startTime;
  DateTime? _endTime;

  bool get reserved => _reserved;
  set reserved(bool r) {
    _reserved = r;
    update();
  }

  DateTime get startTime {
    DateTime time = _startTime ?? DateTime.now();
    return time;
  }

  set startTime(DateTime date) {
    _startTime = date;
    update();
    _endTime = date.add(const Duration(minutes: 15));
  }

  DateTime get endTime {
    DateTime time = _endTime ??
        _startTime?.add(const Duration(minutes: 15)) ??
        DateTime.now().add(const Duration(minutes: 15));
    return time;
  }

  set endTime(DateTime date) {
    _endTime = date;
    update();
  }
}

// 扩展方法 - 将时间转换为后端需要的格式
extension ToNetParse on DateTime {
  String formatNet() {
    DateTime date = this;
    return "${date.year.toString()}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
  }
}
