import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geek_meeting/models/home.dart';
import 'package:geek_meeting/route/routes_path.dart';
import 'package:geek_meeting/utils/global.dart';
import 'package:get/get.dart';

// 加入会议Dialog
Future<Widget?> showJoinRoom(BuildContext context) {
  final home = HomeModel();
  final TextEditingController _roomId = TextEditingController();
  final TextEditingController _userName = TextEditingController();
  final TextEditingController _passWord = TextEditingController();
  return showDialog<Widget>(
    context: context,
    builder: (context) {
      return SimpleDialog(
        children: [
          Center(
            child: Container(
              width: 300,
              height: 330,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(
                      height: 240,
                      child: GetBuilder<HomeModel>(
                        init: home,
                        builder: (_) {
                          return Column(
                            children: [
                              TextField(
                                controller: _userName,
                                maxLength: 10,
                                onTap: () => {home.nameErr = null},
                                decoration: InputDecoration(
                                    icon: const Icon(Icons.person_pin),
                                    labelText: "请输入昵称",
                                    errorText: home.nameErr
                                    // suffix: ElevatedButton(
                                    //   onPressed: () {},
                                    //   child: const Icon(Icons.send_to_mobile),
                                    // ),
                                    ),
                              ),
                              TextField(
                                controller: _roomId,
                                maxLength: 6,
                                keyboardType: TextInputType.number,
                                onTap: () => {home.errType = null},
                                decoration: InputDecoration(
                                    icon:
                                        const Icon(Icons.meeting_room_rounded),
                                    labelText: "请输入房间号",
                                    prefixText: "MEETING - ",
                                    errorText: home.errMsg
                                    // suffix: ElevatedButton(
                                    //   onPressed: () {},
                                    //   child: const Icon(Icons.send_to_mobile),
                                    // ),
                                    ),
                              ),
                              TextField(
                                controller: _passWord,
                                obscureText: true,
                                maxLength: 6,
                                onTap: () => {home.passWordErr = false},
                                decoration: InputDecoration(
                                  icon: const Icon(Icons.keyboard_outlined),
                                  labelText: "会议密码，没有则留空。",
                                  errorText:
                                      home.passWordErr ? "会议密码错误！" : null,
                                  // suffix: ElevatedButton(
                                  //   onPressed: () {},
                                  //   child: const Icon(Icons.send_to_mobile),
                                  // ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_userName.text.trim().isEmpty) {
                            home.nameErr = "昵称不能为空！";
                            return;
                          }
                          if (_roomId.text.isEmpty) {
                            home.errType = err.roomIdErr;
                            return;
                          }
                          NetUtil.net.post("/join_meeting", data: {
                            "name": _userName.text,
                            "room_id": _roomId.text,
                            "password": _passWord.text
                          }, success: (data) {
                            Map<String, dynamic> result = jsonDecode(data);
                            debugPrint(data);
                            if (result["code"] == 200) {
                              Get.toNamed(RoutesPath.Meeting, parameters: {
                                // "name": _userName.text,
                                "roomId": result["data"]["id"].toString(),
                                // "password": _passWord.text,
                                // "uid": result["data"]["uid"].toString(),
                                "key": result["data"]["expand"].toString(),
                              });
                            } else {
                              EasyLoading.showError(result["msg"]);
                            }
                          });
                        },
                        child: const Icon(
                          Icons.keyboard_arrow_right_rounded,
                          size: 45,
                        ),
                        style: ButtonStyle(
                          shape: MaterialStateProperty.all(
                            const CircleBorder(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
          ),
        ],
      );
    },
  );
}
