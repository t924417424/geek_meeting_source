import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:geek_meeting/models/metting/meeting_user.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

Widget meetingItem(MeetingUser e, Function setting) {
  debugPrint(
      "display:${e.display},userId:${e.id},stream not null:${e.stream != null},display:${e.display},,microphone:${e.microphone}");
  return Container(
    width: 300,
    height: 260,
    child: GetBuilder<MeetingUser>(
      init: e,
      builder: (_) {
        return Column(
          children: [
            Expanded(
              flex: 5,
              child: Center(
                child: e.display && e.stream != null
                    ? RTCVideoView(e.videoRenderer)
                    : Text(
                        e.name.split("").last,
                        style: const TextStyle(fontSize: 50),
                      ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.black87,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(
                      Icons.volume_up_rounded,
                      color: e.microphone ? Colors.green : Colors.grey,
                    ),
                    InkWell(
                      child: Icon(
                        e.microphone ? Icons.mic_none : Icons.mic_off,
                        color: e.microphone ? Colors.blue : Colors.red,
                      ),
                      onTap: e.isSelf
                          ? () {
                              e.microphone = !e.microphone;
                            }
                          : null,
                    ),
                    InkWell(
                      child: Icon(
                        Icons.screen_share_outlined,
                        color: e.display ? Colors.blue : Colors.grey,
                      ),
                      onTap: e.isSelf
                          ? () {
                              e.display = !e.display;
                            }
                          : null,
                    ),
                    InkWell(
                      child: Icon(
                        Icons.settings,
                        color: e.isSelf ? Colors.white : Colors.grey,
                      ),
                      onTap: e.isSelf ? () => setting() : null,
                    )
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
    decoration: e.isSelf
        ? const BoxDecoration(
            color: Colors.blueAccent,
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent,
                // offset: Offset(3.0, 6.0),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          )
        : const BoxDecoration(color: Colors.blueAccent),
  );
}
