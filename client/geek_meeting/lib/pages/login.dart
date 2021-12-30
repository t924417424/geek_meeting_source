import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geek_meeting/components/dialog/agreement.dart';
import 'package:geek_meeting/models/login.dart';
import 'package:geek_meeting/route/routes_path.dart';
import 'package:geek_meeting/utils/common.dart';
import 'package:geek_meeting/utils/global.dart';
import 'package:get/get.dart';

class Login extends StatelessWidget {
  Login({Key? key}) : super(key: key);
  final TextEditingController _username = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final LoginModel login = LoginModel();
  @override
  Widget build(BuildContext context) {
    var token = "";
    window.localStorage.forEach((key, value) => {
          if (key == "access_token") {token = value}
        });
    if (token != "") {
      Future.delayed(
          const Duration(seconds: 1), () => Get.offAllNamed(RoutesPath.Home));
    }
    var size = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 50),
          width: size.height / 3,
          height: size.height / 3,
          child: Column(
            children: [
              TextField(
                controller: _username,
                // maxLength: 11,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  icon: const Icon(Icons.mail),
                  helperText: "未注册账户将自动注册",
                  labelText: "请输入邮箱地址",
                  // prefixText: "",
                  suffix: ElevatedButton(
                    onPressed: () {
                      // Get.offAllNamed(RoutesPath.Home);
                      // return;
                      // ignore: dead_code
                      if (!login.userProtocol || !login.privacyProtocol) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("请先阅读并同意以下协议：《用户使用协议》、《用户隐私协议》"),
                            duration: Duration(milliseconds: 1500),
                          ),
                        );
                        return;
                      }
                      if (!isEmail(_username.text)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("请输入正确的邮箱地址。"),
                            duration: Duration(milliseconds: 1500),
                          ),
                        );
                        return;
                      }
                      NetUtil.net.post("/send", data: {"email": _username.text},
                          success: (data) {
                        Map<String, dynamic> result = jsonDecode(data);
                        if (result["code"] == 200) {
                          Get.snackbar("系统通知", "发送成功！");
                          login.sendOk();
                        } else {
                          Get.snackbar("系统通知", result["msg"]);
                        }
                      });
                      // login.sendOk();
                    },
                    child: GetBuilder<LoginModel>(
                      init: login,
                      builder: (_) {
                        return login.time == 120
                            ? const Icon(Icons.outgoing_mail)
                            : Text(login.time.toString());
                      },
                    ),
                  ),
                ),
              ),
              TextField(
                controller: _code,
                // maxLength: 11,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  icon: const Icon(Icons.verified),
                  helperText: "请输入邮箱收到的验证码",
                  labelText: "验证码",
                  // prefixText: "",
                  suffix: ElevatedButton(
                      onPressed: () {
                        // Get.offAllNamed(RoutesPath.Home);
                        // return;
                        // ignore: dead_code
                        if (!login.userProtocol || !login.privacyProtocol) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("请先阅读并同意以下协议：《用户使用协议》、《用户隐私协议》"),
                              duration: Duration(milliseconds: 1500),
                            ),
                          );
                          return;
                        }
                        if (!isEmail(_username.text)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("请输入正确的邮箱地址。"),
                              duration: Duration(milliseconds: 1500),
                            ),
                          );
                          return;
                        }
                        NetUtil.net.post("/verify", data: {
                          "email": _username.text,
                          "verify_code": _code.text
                        }, success: (data) {
                          Map<String, dynamic> result = jsonDecode(data);
                          // Get.snackbar("系统通知", "发送成功！");
                          if (result["code"] == 200 &&
                              result["token"]["access_token"] != "") {
                            Get.offAllNamed(RoutesPath.Home);
                          } else {
                            EasyLoading.showError(result["msg"]);
                          }
                        });
                      },
                      child: const Text("登陆")),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GetBuilder<LoginModel>(
                    init: login,
                    builder: (_) {
                      return Checkbox(
                        value: login.userProtocol,
                        onChanged: (e) => {login.userProtocol = e},
                      );
                    },
                  ),
                  InkWell(
                    child: const Text("用户使用协议"),
                    onTap: () async {
                      await showMyDiaLog(context, "用户使用协议", p1);
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GetBuilder<LoginModel>(
                    init: login,
                    builder: (_) {
                      return Checkbox(
                        value: login.privacyProtocol,
                        onChanged: (e) {
                          login.privacyProtocol = e;
                        },
                      );
                    },
                  ),
                  InkWell(
                    child: const Text("用户隐私协议"),
                    onTap: () async {
                      await showMyDiaLog(context, "用户隐私协议", p2);
                    },
                  ),
                ],
              ),
            ],
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey,
                offset: Offset(0.0, 6.0),
                blurRadius: 3,
              ),
            ],
          ),
          constraints: const BoxConstraints(
            minWidth: 280,
            minHeight: 300,
          ),
        ),
      ),
    );
  }
}
