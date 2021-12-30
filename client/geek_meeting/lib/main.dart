import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geek_meeting/pages/login.dart';
import 'package:geek_meeting/route/routes.dart';
import 'package:geek_meeting/route/routes_path.dart';
import 'package:geek_meeting/utils/global.dart';
import 'package:get/get.dart';

void main() {
  NetUtil.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      initialRoute: RoutesPath.Initial,
      debugShowCheckedModeBanner: false,
      getPages: Routes.pages,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CH'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: Login(),
      builder: EasyLoading.init(),
    );
  }
}
