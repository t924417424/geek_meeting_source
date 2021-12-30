import 'dart:html' as html;
import 'package:flutter/cupertino.dart';
// import 'package:sky_engine/web_audio/dart2js/web_audio_dart2js.dart' as audio;
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

class SettingModel extends GetxController {
  String? _videoDevices;
  String? _audioDevices;
  String? _audioOutputDevices;
  bool _gcRender = false;
  bool checkScreen = false;
  bool _mute = true;
  // 用于渲染预览视频
  final localRenderer = RTCVideoRenderer();
  List<MediaDeviceInfo> devices = [];

  SettingModel() {
    // AudioElement.created().sinkId
    localRenderer.initialize();
  }

  @override
  void dispose() {
    super.dispose();
    localRenderer.srcObject = null;
    localRenderer.dispose();
  }

  bool get gcRender => _gcRender;

  set gcRender(bool sign) {
    _gcRender = sign;
    update();
  }

  String? get videoDevices => _videoDevices;

  set videoDevices(String? id) {
    _videoDevices = id;
    if (id != null) {
      if (id == "Desktop") {
        webrtc.navigator.mediaDevices
            .getDisplayMedia({"video": true, "audio": true}).then((stream) {
          if (localRenderer.srcObject == null) {
            stream.getAudioTracks().forEach((track) {
              track.setMicrophoneMute(_mute);
            });
            localRenderer.srcObject = stream;
          } else {
            var tracks = localRenderer.srcObject?.getVideoTracks();
            var videoTracks = stream.getVideoTracks();
            tracks?.forEach((track) {
              localRenderer.srcObject?.removeTrack(track);
            });
            for (var track in videoTracks) {
              localRenderer.srcObject?.addTrack(track);
            }
          }
        });
      } else {
        webrtc.navigator.mediaDevices.getUserMedia({
          "video": {"deviceId": id},
        }).then((stream) => localRenderer.srcObject = stream);
      }
    }
    update();
  }

  String? get audioDevices => _audioDevices;

  set audioDevices(String? id) {
    _audioDevices = id;
    if (id != null) {
      if (id == "Desktop") {
        // 如果视频输入设备暂未选择，则修改静音标识，否则打开视频音源
        if (localRenderer.srcObject == null) {
          _mute = false;
        } else {
          localRenderer.srcObject?.getAudioTracks().forEach((track) {
            track.setMicrophoneMute(false);
          });
        }
        // webrtc.navigator.mediaDevices
        //     .getDisplayMedia({"video": true, "audio": true}).then(
        //         (stream) => localRenderer.srcObject = stream);
      } else {
        webrtc.navigator.mediaDevices.getUserMedia({
          "audio": {"deviceId": id},
        }).then((stream) {
          if (localRenderer.srcObject == null) {
            localRenderer.srcObject = stream;
          } else {
            var tracks = localRenderer.srcObject?.getAudioTracks();
            var audioTracks = stream.getAudioTracks();
            tracks?.forEach((track) {
              localRenderer.srcObject?.removeTrack(track);
            });
            for (var track in audioTracks) {
              localRenderer.srcObject?.addTrack(track);
            }
            // localRenderer.srcObject.
          }
          // localRenderer.srcObject = stream;
        });
      }
    }
    update();
  }

  String? get audioOutputDevices => _audioOutputDevices;

  set audioOutputDevices(String? id) {
    _audioOutputDevices = id;
    update();
  }

  // void _listenAudio(webrtc.MediaStream stream) {
  //   var AudioContext = audio.AudioContext();
  //   var s = stream as html.MediaStream;
  //   AudioContext.createMediaStreamSource(s);
  // }

  getDevives() async {
    if (devices.isEmpty) {
      devices = await webrtc.navigator.mediaDevices.enumerateDevices();
      devices.addAll(
        [
          webrtc.MediaDeviceInfo(
              label: "Desktop", deviceId: "Desktop", kind: "videoinput"),
          webrtc.MediaDeviceInfo(
              label: "Desktop", deviceId: "Desktop", kind: "audioinput")
        ],
      ); // 添加桌面屏幕设备选项
      update();
    }
  }
}
