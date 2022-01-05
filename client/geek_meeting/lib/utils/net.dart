import 'dart:convert';
import 'dart:html';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geek_meeting/route/routes_path.dart';
import 'package:geek_meeting/utils/common.dart';
import 'package:get/get.dart';
import 'package:dio/src/response.dart' as d;

typedef BackError = Function(int? code, String msg);
defaultError(int? code, String msg) {
  Get.showSnackbar(GetSnackBar(
    title: "系统错误",
    message: msg,
    icon: const Icon(
      Icons.dangerous,
      color: Colors.red,
    ),
    duration: const Duration(seconds: 3),
  ));
}

class Net {
  late Dio dio;
  static bool _refreshing = false;
  static const String baseUrl = 'http://127.0.0.1:8082';
  static late List<String> _recond;
  //普通格式的header
  static final Map<String, dynamic> headers = {
    "Accept": "application/json",
    "Content-Type": "application/x-www-form-urlencoded",
    // "Access-Control-Request-Method": "GET, POST, PATCH, PUT, OPTIONS"
  };
  Net() {
    _recond = [];
    BaseOptions options = BaseOptions();
    //注册请求服务器
    options.baseUrl = baseUrl;
    //设置连接超时单位毫秒
    options.connectTimeout = 5000;
    //  响应流上前后两次接受到数据的间隔，单位为毫秒。如果两次间隔超过[receiveTimeout]，
    //  [Dio] 将会抛出一个[DioErrorType.RECEIVE_TIMEOUT]的异常.
    //  注意: 这并不是接收数据的总时限.
    options.receiveTimeout = 3000;
    //设置请求超时单位毫秒
    options.sendTimeout = 5000;
    //如果返回数据是json(content-type)，
    // dio默认会自动将数据转为json，
    // 无需再手动转](https://github.com/flutterchina/dio/issues/30)
    options.responseType = ResponseType.json;
    options.headers = headers;

    dio = Dio(options);

    dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      EasyLoading.show(dismissOnTap: true);
      // Do something before request is sent
      debugPrint("before request");
      var accessToken = "";
      var refreshToken = "";
      window.localStorage.forEach((key, value) {
        if (key == "access_token") {
          accessToken = value;
        }
        if (key == "refresh_token") {
          refreshToken = value;
        }
      });
      // 刷新token，为防止重复刷新，需要添加一个标识区别是否正在进行token刷新
      if (!_refreshing &&
          !checkToken(accessToken) &&
          checkToken(refreshToken)) {
        debugPrint("start refresh");
        _refreshing = true;
        try {
          await dio
              .post("/refresh_token", data: {"refresh_token": refreshToken});
        } catch (e) {
          defaultError(0, "服务器连接失败！");
          debugPrint(e.toString());
        } finally {
          _recond.remove("/refresh_token");
          _refreshing = false;
        }
        // 更新token完成，重新获取本地token
        window.localStorage.forEach((key, value) {
          if (key == "access_token") {
            accessToken = value;
          }
          if (key == "refresh_token") {
            refreshToken = value;
          }
        });
        _refreshing = false;
      }
      if (accessToken != "") {
        options.headers.addAll({"Authorization": "Bearer " + accessToken});
      }
      return handler.next(options); //continue
      // 如果你想完成请求并返回一些自定义数据，你可以resolve一个Response对象 `handler.resolve(response)`。
      // 这样请求将会被终止，上层then会被调用，then中返回的数据将是你的自定义response.
      //
      // 如果你想终止请求并触发一个错误,你可以返回一个`DioError`对象,如`handler.reject(error)`，
      // 这样请求将被中止并触发异常，上层catchError会被调用。
    }, onResponse: (response, handler) {
      EasyLoading.dismiss();
      debugPrint("onresponse");
      // 添加拦截器，处理token
      Map<String, dynamic> data;
      if (response.statusCode == HttpStatus.ok) {
        data = jsonDecode(response.data);
        debugPrint(data.toString());
        debugPrint(data["token"].toString());
        debugPrint(data["token"]["access_token"].toString());
        if (data["token"]["access_token"].toString() != "") {
          window.localStorage.addAll({
            "access_token": data["token"]["access_token"]!,
            "refresh_token": data["token"]["refresh_token"]
          });
        }
      } else if (response.statusCode == HttpStatus.unauthorized) {
        window.localStorage.remove("access_token");
        window.localStorage.remove("refresh_token");
        Get.showSnackbar(
          const GetSnackBar(
            title: "提示",
            message: "身份验证过期，请重新登陆。",
          ),
        );
        try {
          Future.delayed(const Duration(milliseconds: 100),
              () => {window.location.href = "/"});
        } catch (_) {}
        // var access_token = "";
        // var refresh_token = "";
        // window.localStorage.forEach((key, value) {
        //   if (key == "access_token") {
        //     access_token = value;
        //   }
        //   if (key == "refresh_token") {
        //     refresh_token = value;
        //   }
        // });
        // 检测是否双token全部过期
        // if (!checkToken(access_token) && !checkToken(refresh_token)) {
        //   window.localStorage.remove("access_token");
        //   window.localStorage.remove("refresh_token");
        //   Get.showSnackbar(
        //     GetSnackBar(
        //       title: "提示",
        //       message: "身份验证过期，请重新登陆。",
        //       snackbarStatus: (status) {
        //         if (status != null) {
        //           if (status == SnackbarStatus.CLOSED) {
        //             try {
        //               Future.delayed(const Duration(milliseconds: 100),
        //                   () => {Get.offNamed(RoutesPath.Home)});
        //             } catch (e) {}
        //           }
        //         }
        //       },
        //     ),
        //   );
        // }
        return;
      }
      // Do something with response data
      return handler.next(response); // continue
      // 如果你想终止请求并触发一个错误,你可以 reject 一个`DioError`对象,如`handler.reject(error)`，
      // 这样请求将被中止并触发异常，上层catchError会被调用。
    }, onError: (DioError e, handler) {
      EasyLoading.dismiss();
      // Do something with response error
      if (e.response?.statusCode == HttpStatus.unauthorized) {
        window.localStorage.remove("access_token");
        window.localStorage.remove("refresh_token");
        Get.showSnackbar(
          const GetSnackBar(
            title: "提示",
            message: "身份验证过期，请重新登陆。",
          ),
        );
        try {
          Future.delayed(const Duration(milliseconds: 1000),
              () => {window.location.href = "/"});
        } catch (_) {}
        return;
      }
      return handler.next(e); //continue
      // 如果你想完成请求并返回一些自定义数据，可以resolve 一个`Response`,如`handler.resolve(response)`。
      // 这样请求将会被终止，上层then会被调用，then中返回的数据将是你的自定义response.
    }));
  }

  void get(String url,
      {Map<String, dynamic>? data,
      success,
      BackError? error = defaultError}) async {
    debugPrint("start get request");
    if (_recond.contains(url)) {
      return;
    }
    _recond.add(url);
    d.Response response;
    try {
      if (data == null) {
        response = await dio.get(url);
      } else {
        response = await dio.get(url, queryParameters: data);
      }

      if (response.statusCode == HttpStatus.ok) {
        success(response.data);
      } else {
        if (error != null) {
          error(response.statusCode, "服务异常！");
        }
        debugPrint(response.statusCode.toString());
      }
    } on DioError catch (e) {
      if (error != null) {
        error(null, "服务异常！");
      }
      debugPrint(e.toString());
    } finally {
      _recond.remove(url);
    }
  }

  void post(String url,
      {Map<String, dynamic>? data,
      success,
      BackError? error = defaultError}) async {
    debugPrint("start post request");
    if (_recond.contains(url)) {
      return;
    }
    _recond.add(url);
    d.Response response;
    try {
      if (data == null) {
        response = await dio.post(url);
      } else {
        response = await dio.post(url, data: data);
      }

      if (response.statusCode == 200) {
        success(response.data);
      } else {
        if (error != null) {
          error(response.statusCode, "服务异常！");
        }
        debugPrint(response.statusCode.toString());
      }
    } on DioError catch (e) {
      if (error != null) {
        error(null, "服务异常！");
      }
      debugPrint(e.toString());
    } finally {
      _recond.remove(url);
    }
  }
}
