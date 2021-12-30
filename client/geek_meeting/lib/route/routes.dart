import 'package:geek_meeting/pages/home.dart';
import 'package:geek_meeting/pages/login.dart';
import 'package:geek_meeting/pages/meeting.dart';
import 'package:geek_meeting/route/routes_path.dart';
import 'package:get/get.dart';

abstract class Routes {
  static final pages = [
    GetPage(
      name: RoutesPath.Initial,
      page: () => Login(),
    ),
    GetPage(
      name: RoutesPath.Login,
      page: () => Login(),
    ),
    GetPage(
      name: RoutesPath.Home,
      page: () => Home(),
    ),
    GetPage(
      name: RoutesPath.Meeting,
      page: () => Meeting(),
      // middlewares: [MeetingMiddleware()],
    ),
  ];
}
