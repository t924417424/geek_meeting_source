import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:geek_meeting/models/setting.dart';
import 'package:get/get.dart';

enum _deviceType { videoInput, audioInput, audioOutput }

Future<SettingModel> devices(BuildContext context) async {
  SettingModel setting = SettingModel();
  setting.getDevives();
  await showDialog<Widget>(
    context: context,
    builder: (context) {
      return SimpleDialog(
        title: const Text("设备选择"),
        children: [
          Container(
            width: MediaQuery.of(context).size.height / 2,
            height: MediaQuery.of(context).size.height / 2,
            padding: const EdgeInsets.all(30),
            child: SingleChildScrollView(
              child: GetBuilder(
                init: setting,
                builder: (_) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text(
                              "视频输入：",
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                          Expanded(
                            flex: 7,
                            child: _myDropDown(
                              setting,
                              _deviceType.videoInput,
                            ),
                          ),
                          const Expanded(
                            child: SizedBox(),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "视频预览：",
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              color: Colors.grey,
                              height: 100,
                              width: 100,
                              child: setting.gcRender
                                  ? const SizedBox()
                                  : RTCVideoView(setting.localRenderer),
                            ),
                          ),
                          const Expanded(
                            flex: 2,
                            child: SizedBox(),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text(
                              "音频输入：",
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                          Expanded(
                            flex: 7,
                            child: _myDropDown(
                              setting,
                              _deviceType.audioInput,
                            ),
                          ),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text(
                              "音频输出：",
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                          Expanded(
                            flex: 7,
                            child: _myDropDown(
                              setting,
                              _deviceType.audioOutput,
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              child: const Icon(
                                Icons.play_arrow,
                              ),
                              onTap: () {
                                debugPrint("play test sound");
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          )
        ],
      );
    },
  );
  return setting;
}

Widget _myDropDown(SettingModel setting, _deviceType deviceType) {
  String? devicesId;
  late String filter;
  switch (deviceType) {
    case _deviceType.videoInput:
      devicesId = setting.videoDevices;
      filter = "videoinput";
      break;
    case _deviceType.audioInput:
      filter = "audioinput";
      devicesId = setting.audioDevices;
      break;
    case _deviceType.audioOutput:
      filter = "audiooutput";
      devicesId = setting.audioOutputDevices;
      break;
    default:
  }
  return Container(
    padding: const EdgeInsets.only(left: 10),
    height: 38,
    color: Colors.grey[300],
    child: DropdownButton<String>(
      value: devicesId,
      // iconSize: 0,
      dropdownColor: Colors.white,
      hint: Text(devicesId ?? ""),
      underline: const SizedBox(),
      onChanged: (v) async {
        switch (deviceType) {
          case _deviceType.videoInput:
            setting.videoDevices = v;
            break;
          case _deviceType.audioInput:
            setting.audioDevices = v;
            break;
          case _deviceType.audioOutput:
            setting.audioOutputDevices = v;
            break;
          default:
        }
      },
      items: setting.devices
          .where((element) =>
              element.kind == filter && element.deviceId.isNotEmpty)
          .map<DropdownMenuItem<String>>((MediaDeviceInfo value) {
        return DropdownMenuItem<String>(
          value: value.deviceId,
          child:
              Text(value.deviceId, style: const TextStyle(color: Colors.black)),
        );
      }).toList(),
    ),
  );
}
