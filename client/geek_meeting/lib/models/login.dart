import 'dart:async';
import 'package:get/get.dart';

class LoginModel extends GetxController {
  bool _userProtocol = false;
  bool _privacyProtocol = false;
  int _time = 120;
  bool _sending = false;
  bool get userProtocol => _userProtocol;
  bool get privacyProtocol => _privacyProtocol;

  set userProtocol(bool? e) {
    _userProtocol = e == null
        ? false
        : e == false
            ? e
            : true;
    update();
  }

  set privacyProtocol(bool? e) {
    _privacyProtocol = e == null
        ? false
        : e == false
            ? e
            : true;
    update();
  }

  int get time => _time;

  set time(int t) {
    _time = t;
    update();
  }

  sendOk() {
    if (_sending) {
      return;
    }
    _sending = true;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      // 只在倒计时结束时回调
      if (_time > 0) {
        time -= 1;
      } else {
        time = 120;
        timer.cancel();
        _sending = false;
      }
    });
  }
}
