import 'package:get/get.dart';

enum err { roomIdErr, roomNotFound, passWordError }

class HomeModel extends GetxController {
  String? _errInfo;
  String? _userNameErr;
  bool _passWordErr = false;

  String? get errMsg => _errInfo;

  String? get nameErr => _userNameErr;

  bool get passWordErr => _passWordErr;

  set nameErr(String? msg) {
    _userNameErr = msg;
    update();
  }

  set passWordErr(bool b) {
    _passWordErr = b;
    update();
  }

  set errType(err? e) {
    String? msg;
    switch (e) {
      case err.roomIdErr:
        msg = "RoomID不正确";
        break;
      case err.roomNotFound:
        msg = "会议未找到";
        break;
      default:
        msg = null;
    }
    _errInfo = msg;
    update();
  }
}
