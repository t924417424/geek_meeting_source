import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MeetingMiddleware extends GetMiddleware {
  // MeetingMiddleware();
  @override
  RouteSettings? redirect(String? route) {
    debugPrint(Get.arguments);
    return null;
  }
}
