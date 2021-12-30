// 会议记录Dialog
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geek_meeting/models/metting/meeting_recond.dart';
import 'package:get/get.dart';

Future<Widget?> showMeetingRecond(BuildContext context) {
  MeetingRecond _recond = MeetingRecond();
  DateTime _currentTime = DateTime.now();
  ScrollController _scrollController = ScrollController();
  _recond.fetch();
  // 监听ListView是否滚动到底部
  _scrollController.addListener(() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent) {
      if (!_recond.isLoading) {
        _recond.fetch();
      }
      // 这里可以执行上拉加载逻辑
    }
  });
  // _record.fetch();
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
                padding: const EdgeInsets.all(5),
                child: GetBuilder<MeetingRecond>(
                  init: _recond,
                  builder: (_) => ListView.builder(
                    controller: _scrollController,
                    itemCount: _recond.recond.length,
                    itemBuilder: (_, index) {
                      var endtime =
                          DateTime.parse(_recond.recond[index]["end_time"]);
                      Color color = _currentTime.isAfter(endtime)
                          ? Colors.grey
                          : Colors.black;
                      return Container(
                        height: 80,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Icon(
                                Icons.meeting_room,
                                size: 50,
                                color: color,
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "MEETING - ${_recond.recond[index]["id"]}",
                                    style: TextStyle(color: color),
                                  ),
                                  Text(
                                    "开始时间：${_recond.recond[index]["start_time"]}",
                                    style: TextStyle(color: color),
                                  ),
                                  Text(
                                    "结束时间：${_recond.recond[index]["end_time"]}",
                                    style: TextStyle(color: color),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(width: 1, color: Colors.grey),
                        ),
                      );
                    },
                  ),
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
