import 'dart:convert';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geek_meeting/utils/global.dart';
import 'package:get/get.dart';

class MeetingRecond extends GetxController {
  int _page = 1;
  bool isLoading = false;
  final List<dynamic> _recond = [];
  List<dynamic> get recond => _recond;
  void fetch() {
    EasyLoading.show(dismissOnTap: true);
    isLoading = true;
    NetUtil.net.get("/recond", data: {"page": _page}, success: (data) {
      Map<String, dynamic> result = jsonDecode(data);
      isLoading = false;
      if (result["code"] == 200 && result["data"] != null) {
        _page += 1;
        _recond.addAllIf(result["data"] is List<dynamic>, result["data"]);
        update();
      }
    });
    EasyLoading.dismiss();
  }
}
