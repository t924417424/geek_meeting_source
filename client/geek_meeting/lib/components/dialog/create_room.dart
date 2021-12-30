import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geek_meeting/models/create_meeting.dart';
import 'package:geek_meeting/utils/common.dart';
import 'package:geek_meeting/utils/global.dart';
import 'package:get/get.dart';

// 创建会议Dialog
Future<Widget?> showCreateRoom(BuildContext context) {
  final createMeeting = CreateMeetingModel();
  final TextEditingController _passwd = TextEditingController();
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
                      child: GetBuilder<CreateMeetingModel>(
                        init: createMeeting,
                        builder: (_) {
                          return Column(
                            children: [
                              // Text(fomatDate(createMeeting.startTime)),
                              // Text(fomatDate(createMeeting.endTime)),
                              const Text("创建会议"),
                              TextField(
                                readOnly: true,
                                onTap: () async {
                                  DateTime? startTime =
                                      await selectTime(context);
                                  if (startTime != null) {
                                    createMeeting.startTime = startTime;
                                  }
                                },
                                keyboardType: TextInputType.datetime,
                                decoration: InputDecoration(
                                  icon: const Icon(Icons.access_time),
                                  hintText: fomatDate(createMeeting.startTime),
                                  helperText: "开始时间",
                                ),
                              ),
                              TextField(
                                readOnly: true,
                                onTap: () async {
                                  DateTime? endTime = await selectTime(context,
                                      startTime: createMeeting.startTime);
                                  debugPrint(endTime.toString());
                                  if (endTime != null &&
                                      endTime
                                          .isAfter(createMeeting.startTime)) {
                                    createMeeting.endTime = endTime;
                                  }
                                },
                                decoration: InputDecoration(
                                  icon: const Icon(Icons.access_time),
                                  hintText: fomatDate(createMeeting.endTime),
                                  helperText: "结束时间",
                                ),
                              ),
                              TextField(
                                controller: _passwd,
                                maxLength: 6,
                                onTap: () async {},
                                decoration: const InputDecoration(
                                  icon: Icon(Icons.vpn_key_outlined),
                                  hintText: "会议密码",
                                  helperText: "会议密码,留空则不启用。",
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          // debugPrint(
                          // "start time:${createMeeting.startTime.formatNet()}\r\nend time:${createMeeting.endTime.formatNet()}\r\npasswd:${_passwd.text}");
                          NetUtil.net.post("/create_meeting", data: {
                            "start_time": createMeeting.startTime.formatNet(),
                            "end_time": createMeeting.endTime.formatNet(),
                            "password": _passwd.text
                          }, success: (data) {
                            Map<String, dynamic> result = jsonDecode(data);
                            if (result["code"] == 200) {
                              EasyLoading.showSuccess("会议创建成功！",
                                      dismissOnTap: true)
                                  .then(
                                (_) => Future.delayed(
                                  const Duration(seconds: 2),
                                  () => Navigator.pop(context),
                                ),
                              );
                            } else {
                              // Get.snackbar("系统提示", result["msg"]);
                              EasyLoading.showError(result["msg"],
                                  dismissOnTap: true);
                            }
                          });
                        },
                        child: const Text("创建会议"),
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

Future<DateTime?> selectTime(BuildContext context,
    {DateTime? startTime}) async {
  DateTime? date = await showDatePicker(
    context: context,
    locale: const Locale('zh'),
    initialDate: startTime ?? DateTime.now(),
    firstDate: startTime ?? DateTime.now(),
    lastDate: startTime ?? DateTime.now().add(const Duration(days: 7)),
    cancelText: "取消",
    helpText: "选择日期",
    confirmText: "选择时间",
    initialEntryMode: DatePickerEntryMode.calendarOnly,
  );
  if (date == null) return null;
  TimeOfDay? time = await showTimePicker(
    context: context,
    helpText: "选择时间",
    initialTime: startTime == null
        ? TimeOfDay.now()
        : TimeOfDay(hour: startTime.hour, minute: startTime.minute),
  );
  if (time == null) return null;
  DateTime meetinDate = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
  return meetinDate;
}
