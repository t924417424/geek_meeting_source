// 暂时保留，用于区分用户身份
import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

enum userIdentity {
  leader,
  follower,
}
typedef _callback = Function();

class MeetingUser extends GetxController {
  late int id;
  String name;
  String? streamId;
  bool _self = false;
  bool _display = false;
  bool _microphone = false;
  bool _hasAudioTracks = false;
  MediaStream? _stream;
  final videoRenderer = RTCVideoRenderer();
  userIdentity _identity = userIdentity.follower;
  final _callback _update;
  MeetingUser(this.id, this.name, this._update,
      {bool self = false, String? initStreamId}) {
    _self = self;
    streamId = initStreamId;
    videoRenderer.initialize();
  }

  bool get isSelf => _self;

  // String? get streamId => _streamId;

  // set streamId(String? streamId) => _streamId = streamId;

  /// 这里使用stream.id进行用户stream区分，故stream.id不再变动
  /// 若重新选择设备后需要产生新的流，则直接进行track替换
  set stream(MediaStream? newStream) {
    debugPrint("set userId:$id streamid:${newStream?.id}");
    if (newStream == null) {
      // videoRenderer.srcObject?.dispose();
      _stream = null;
      videoRenderer.srcObject = null;
      _display = false;
      _microphone = false;
      _update();
      return;
    }
    _stream = _stream ?? newStream;
    streamId = streamId ?? newStream.id;
    videoRenderer.srcObject = _stream;
    // debugPrint("video render:${videoRenderer.renderVideo}");
    // _stream?.getTracks().forEach((track) {
    //   debugPrint(
    //       "userId:$id trackKind:${track.kind} trackEnable:${track.enabled} trackMuted:${track.muted}");
    // });
    // 更新流，不更换streamid，替换track
    if (_stream?.id != newStream.id) {
      debugPrint("re streamId");
      // if (_stream!.getVideoTracks().isNotEmpty) {
      //   _stream!.removeTrack(_stream!.getVideoTracks()[0]);
      // }
      List<MediaStreamTrack>? tracks = _stream?.getTracks();
      tracks?.forEach((track) {
        _stream?.removeTrack(track);
      });
      tracks?.clear();
      tracks = newStream.getTracks();
      for (var track in tracks) {
        _stream?.addTrack(track);
      }
    }
    // end
    if (_stream!.getVideoTracks().isNotEmpty) {
      debugPrint("set $id display true");
      _display = true;
    }
    _hasAudioTracks = false;
    if (_stream!.getAudioTracks().isNotEmpty) {
      debugPrint("set $id microphone true");
      _hasAudioTracks = true;
      _microphone = true;
    }
    _setStreamEvent();
    _update();
  }

  void _setStreamEvent() {
    _stream!.getTracks().forEach((track) {
      // track停止推流事件
      track.onEnded = () {
        if (track.kind == 'video') {
          _display = false;
        } else {
          _microphone = false;
        }
        _update();
      };
      // track静音事件
      track.onMute = () {
        _microphone = false;
        _update();
      };
      // track取消静音事件
      track.onUnMute = () {
        // 如果audiotracks存在，则触发静音取消事件
        _hasAudioTracks ? _microphone = true : null;
        _update();
        // _microphone = true;
      };
    });
  }

  MediaStream? get stream => _stream;

  bool get display => _display;

  set display(bool state) {
    _display = state;
    _stream?.getVideoTracks().forEach((track) {
      track.enabled = state;
    });
    _update();
  }

  bool get microphone => _microphone;

  set microphone(bool state) {
    debugPrint("set user:$id microphone state:$state");
    _microphone = state;
    _stream?.getAudioTracks().forEach((track) {
      track.enabled = state;
    });
    _update();
  }

  userIdentity get identity => _identity;

  set identity(userIdentity identity) {
    _identity = identity;
    _update();
  }

  void disposeStream() {
    debugPrint("clear stream");
    videoRenderer.srcObject = null;
    _stream?.getTracks().forEach((track) async {
      debugPrint("stop track");
      track.onEnded = null;
      track.onMute = null;
      track.onUnMute = null;
      await track.stop();
    });
    // 防止Renderer被页面使用，使用延时关闭
    Future.delayed(const Duration(seconds: 1), () {
      videoRenderer.dispose();
      debugPrint("dispose stream");
    });
    _stream?.dispose();
    _stream = null;
    debugPrint("clear stream end");
  }
}
