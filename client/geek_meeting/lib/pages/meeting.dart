import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:geek_meeting/components/meeting_list.dart';
import 'package:geek_meeting/components/setting.dart';
import 'package:geek_meeting/models/metting/meeting_room.dart';
import 'package:geek_meeting/route/routes_path.dart';
import 'package:get/get.dart';

class Meeting extends StatelessWidget {
  Meeting({Key? key}) : super(key: key);
  final String? roomId = Get.parameters["roomId"];
  final String? roomKey = Get.parameters["key"];
  late final MeetingRoom? room;
  late final MediaStream? stream;
  @override
  Widget build(BuildContext context) {
    // NetUtil.net.
    try {
      if (roomKey == null || roomId == null) {
        Future.delayed(const Duration(milliseconds: 100),
            () => {Get.offNamed(RoutesPath.Home)});
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    void _setting() {
      devices(context).then((setting) {
        if (setting.localRenderer.srcObject == null) {
          return;
        }
        setting.gcRender = true;
        stream = setting.localRenderer.srcObject;
        room!.initSelfStream(stream);
        room!.audioOutput = setting.audioDevices;
        Future.delayed(const Duration(seconds: 1), () => setting.dispose());
      });
    }

    // 初始化room;
    room = MeetingRoom(
      roomKey!,
      onOpen: (_) => {
        Future.delayed(
          const Duration(milliseconds: 1000),
          () => {_setting()},
        )
      },
      onError: (_) => {
        Future.delayed(
          const Duration(milliseconds: 3000),
          () => {
            Get.offNamed(RoutesPath.Home),
          },
        )
      },
    );
    room!.initClient();
    return WillPopScope(
      child: Scaffold(
        backgroundColor: Colors.black87,
        appBar: AppBar(
          title: Text("会议室：$roomId"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 50),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(50),
              child: GetBuilder<MeetingRoom>(
                init: room,
                builder: (_) {
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: room!.users
                        .map(
                          (e) => meetingItem(e, _setting),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ),
        ),
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () => {
        //     room?.join(MeetingUser(room.counter, name ?? "测试")
        //       ..stream = stream.clone()
        //       ..display = true)
        //   },
        //   child: const Icon(Icons.add),
        // ),
      ),
      onWillPop: () async {
        debugPrint("leave page");
        room?.leaveRoom();
        // Get.offAllNamed(RoutesPath.Home);
        Get.offAndToNamed(RoutesPath.Home);
        // debugPrint("back");
        return false;
      },
    );
  }
}
