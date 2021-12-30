import 'dart:convert';
import 'dart:html';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import 'meeting_user.dart';

typedef _callback = Function(dynamic e);

class MeetingRoom extends GetxController {
  late final WebSocket _signalServer;
  final List<MeetingUser> users = [];
  late MeetingUser _self;
  int get counter => users.length;
  late RTCPeerConnection _peerConnection;
  final Map<String, MediaStream> _streams = {};
  final String _url = "ws://127.0.0.1:8082/signal/";
  late String _key = "";
  String? _audioOutput;
  _callback? _onError;
  _callback? _onOpen;

  MeetingRoom(String key, {_callback? onError, _callback? onOpen}) {
    // _initSignal();
    _key = key;
    // _self = self;
    // users.add(_self);
    _onError = onError;
    _onOpen = onOpen;
  }

  set audioOutput(String? deviceId) {
    _audioOutput = deviceId;
    if (_audioOutput != null) {
      for (var user in users) {
        user.videoRenderer.audioOutput = _audioOutput!;
      }
    }
  }

  Future<void> initClient() async {
    String wsUrl = _url + _key;
    _signalServer = WebSocket(wsUrl);
    _initSignal();
    _initPeer();
    // _verifyId();
    // await _initPeer();
    return;
  }

  // 验证用户身份
  // void _verifyId() {
  //   _signalServer.sendString(const JsonEncoder()
  //       .convert({'event': 'verify', 'data': _self.id.toString()}));
  // }

  void initSelfStream(MediaStream? stream) {
    debugPrint("init stream $stream");
    stream?.getTracks().forEach((track) async {
      debugPrint("add track");
      await _peerConnection.addTrack(track, stream);
      debugPrint("add track end");
    });
    // 如果是第一次获取流，则广播自己的流id
    if (_self.stream == null && stream != null) {
      _signalServer.sendString(const JsonEncoder().convert({
        'event': 'set_stream',
        'data': const JsonEncoder()
            .convert({'uid': _self.id, 'streamId': stream.id})
      }));
    }
    // _signalServer.sendString(const JsonEncoder().convert({
    //   "event": "Renegotiation",
    // }));
    _self.stream = stream;
  }

  void _initSignal() {
    _signalServer.onOpen.listen((event) async {
      if (_onOpen != null) {
        _onOpen!(event);
      }
      debugPrint("start listener success");
    });
    _signalServer.onMessage.listen((event) async {
      // window.console.log(event.data);
      var raw = event.data;
      Map<String, dynamic> msg = jsonDecode(raw);
      switch (msg['event']) {
        // 同步上个页面所填写的个人信息
        case 'sync':
          Map<String, dynamic> parsed = jsonDecode(msg['data']);
          try {
            int uid = parsed['uid'];
            String name = parsed['name'];
            _self = MeetingUser(uid, name, () => update(), self: true);
            users.add(_self);
            update();
          } catch (e) {
            debugPrint(parsed.toString());
            debugPrint(e.toString());
          }
          return;
        // 用户流ID更新事件
        case 'set_stream':
          Map<String, dynamic> parsed = jsonDecode(msg['data']);
          try {
            int uid = parsed['uid'];
            String streamId = parsed['streamId'];
            // if (uid == _self.id) {
            //   _self.streamId = _self.streamId ?? streamId;
            // } else {
            //   MeetingUser? user =
            //       users.firstWhereOrNull((element) => element.id == uid);
            //   user?.streamId = streamId;
            // }
            MeetingUser? user =
                users.firstWhereOrNull((element) => element.id == uid);
            user?.streamId = streamId;
            MediaStream? stream = _streams[streamId];
            _streams.forEach((key, value) {
              debugPrint("streams $key = ${value.id}");
            });
            debugPrint("set user ${user?.id} streamId ${parsed['streamId']}");
            user?.stream = stream ?? user.stream;
            // update();
            _streams.removeWhere((key, value) => key == streamId);
          } catch (e) {
            debugPrint(e.toString());
          }
          return;
        // 用户加入事件
        case 'join':
          Map<String, dynamic> parsed = jsonDecode(msg['data']);
          try {
            MeetingUser user = MeetingUser(
                parsed["uid"], parsed["name"], () => update(),
                initStreamId:
                    parsed["streamId"] == "" ? null : parsed["streamId"]);
            MediaStream? stream = _streams[user.streamId];
            _streams.forEach((key, value) {
              debugPrint("join user streams $key = ${value.id}");
            });
            user.stream = stream ?? user.stream;
            // 设置音频输出设备
            if (_audioOutput != null) {
              user.videoRenderer.audioOutput = _audioOutput!;
            }
            // update();
            _streams.removeWhere((key, value) => key == user.streamId);
            join(user);
          } catch (e) {
            debugPrint(e.toString());
          }
          return;
        // 用户离开事件
        case 'leave':
          Map<String, dynamic> parsed = jsonDecode(msg['data']);
          try {
            leave(parsed["uid"]);
          } catch (e) {
            debugPrint(e.toString());
          }
          return;
        // webrtc事件
        case 'candidate':
          Map<String, dynamic> parsed = jsonDecode(msg['data']);
          _peerConnection
              .addCandidate(RTCIceCandidate(parsed['candidate'], null, 0));
          return;
        case 'offer':
          Map<String, dynamic> offer = jsonDecode(msg['data']);

          // SetRemoteDescription and create answer
          await _peerConnection.setRemoteDescription(
              RTCSessionDescription(offer['sdp'], offer['type']));
          RTCSessionDescription answer = await _peerConnection.createAnswer({});
          await _peerConnection.setLocalDescription(answer);

          // Send answer over WebSocket
          _signalServer.sendString(const JsonEncoder().convert({
            'event': 'answer',
            'data': const JsonEncoder()
                .convert({'type': answer.type, 'sdp': answer.sdp})
          }));
          return;
      }
    });
    _signalServer.onError.listen((event) {
      EasyLoading.showError("加入房间失败！");
      if (_onError != null) {
        _onError!(event);
      }
      window.console.log(event);
    });
    _signalServer.onClose.listen((event) {
      EasyLoading.showInfo("房间已关闭！");
      if (_onError != null) {
        _onError!(event);
      }
      window.console.log(event);
    });
  }

  Future<void> _initPeer() async {
    var _iceServers = {
      'iceServers': [
        {
          "url": "stun:stun.l.google.com:19302",
        },
        {
          'url': 'turn:numb.viagenie.ca',
          'credential': 'muazkh',
          'username': 'webrtc@live.com'
        },
      ],
      'iceTransportPolicy': 'relay',
    };
    _peerConnection = await createPeerConnection({..._iceServers}, {});
    _peerConnection.onRenegotiationNeeded = () {
      // debugPrint("need Renegotiation");
      _signalServer.sendString(const JsonEncoder().convert({
        "event": "Renegotiation",
      }));
    };
    _peerConnection.onIceConnectionState = (state) {
      debugPrint("onIceConnectionState:${state.toString()}");
    };
    _peerConnection.onConnectionState = (state) {
      window.console.log(state.toString());
      // debugPrint("onConnectionState:${state.toString()}");
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        EasyLoading.showError("由于您的网络环境原因，可能暂不支持加入会话");
      }
    };
    // 收到ice消息
    _peerConnection.onIceCandidate = (candidate) {
      if (candidate == null) {
        return;
      }
      window.console.log("on candidate");
      _signalServer.sendString(const JsonEncoder().convert({
        "event": "candidate",
        "data": const JsonEncoder().convert({
          'sdpMLineIndex': candidate.sdpMlineIndex,
          'sdpMid': candidate.sdpMid,
          'candidate': candidate.candidate,
        })
      }));
    };

    // 收到track
    _peerConnection.onTrack = (event) async {
      debugPrint("recv track ${event.streams[0].id},users:${users.length}");
      // users.map((e) {
      //   debugPrint("${e.streamId} === ${event.streams[0].id}");
      // }).toSet();
      // event.track.kind == 'video' &&
      if (event.streams.isNotEmpty) {
        // var renderer = RTCVideoRenderer();
        // 设置音频输出设备
        // renderer.audioOutput = "";
        // await renderer.initialize();
        // renderer.srcObject = event.streams[0];
        // renderer.srcObject!.getAudioTracks()[0].setVolume();
        // 收到stream后与房间内用户进行匹配，并设置用户stream
        MeetingUser? user = users
            .firstWhereOrNull((user) => user.streamId == event.streams[0].id);
        // 如果用户还未加入房间，则先暂存流数据
        if (user == null) {
          debugPrint("cache stream");
          _streams[event.streams[0].id] = event.streams[0];
        } else {
          user.stream = event.streams[0];
          // 设置音频输出设备
          if (_audioOutput != null) {
            user.videoRenderer.audioOutput = _audioOutput!;
          }
          // update();
        }
        // debugPrint(users.toList().toString());
      }
    };

    // RemoteStream事件
    _peerConnection.onRemoveStream = (stream) {
      debugPrint("remove stream ${stream.id}");
      // Filter existing renderers for the stream that has been stopped
      for (var r in users) {
        if (r.videoRenderer.srcObject?.id == stream.id) {
          r.stream = null;
        }
      }
      _streams.removeWhere((key, value) => value.id == stream.id);
    };
    return;
  }

  // 用户加入
  void join(MeetingUser user) {
    // debugPrint("Join - - - ${user.toString()}");
    // debugPrint("Join Befor - - - ${users.length.toString()}");
    users.addIf(
        users.firstWhereOrNull((element) => element.id == user.id) == null,
        user);
    // debugPrint("Join after - - - ${users.length.toString()}");
    update();
  }

  // 用户离开
  void leave(int id) {
    MeetingUser? user = users.firstWhereOrNull((user) => user.id == id);
    user?.display = false;
    user?.disposeStream();
    users.remove(user);
    update();
  }

  void leaveRoom() async {
    debugPrint(users.length.toString());
    _signalServer.sendString(const JsonEncoder().convert({
      'event': 'leave',
    }));
    // users.map((e) {
    //   debugPrint("del ${e.id}");
    //   users.firstWhere((user) => user.id == e.id)
    //     ..display = false
    //     ..disposeStream();
    // }).toSet();
    for (var e in users) {
      debugPrint("del ${e.id}");
      MeetingUser user = users.firstWhere((user) => user.id == e.id);
      user.display = false;
      user.disposeStream();
    }
    _streams.forEach((key, value) {
      value.dispose();
    });
    users.clear();
    _peerConnection.dispose();
    _signalServer.close();
  }

  // void pushStream(MediaStream stream) {
  //   stream.getTracks().forEach((track) async {
  //     await _peerConnection.addTrack(track, stream);
  //   });
  // }

  // @override
  // void dispose() {
  //   _peerConnection.dispose();
  //   users.map((e) => leave(e.id)).toSet();
  //   _signalServer.close();
  //   super.dispose();
  // }
}
