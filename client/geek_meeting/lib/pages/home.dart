import 'package:flutter/material.dart';
import 'package:geek_meeting/components/dialog/create_room.dart';
import 'package:geek_meeting/components/dialog/join_room.dart';
import 'package:geek_meeting/components/dialog/room_recond.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // if (Navigator.canPop(context)) Navigator.pop(context);
    // final TextEditingController _roomId = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Geek 云会议系统"),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Wrap(
          spacing: 50,
          runSpacing: 50,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: ElevatedButton(
                onPressed: () => {showMeetingRecond(context)},
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.person_pin,
                      size: 60,
                    ),
                    Text("我的会议"),
                  ],
                ),
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all(Colors.blueGrey[200]),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ), //圆角弧度
                ),
              ),
            ),
            SizedBox(
              width: 200,
              height: 200,
              child: ElevatedButton(
                onPressed: () => {
                  showCreateRoom(context)
                      .then((_) => showMeetingRecond(context))
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.add_comment_rounded,
                      size: 60,
                    ),
                    Text("创建会议"),
                  ],
                ),
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all(Colors.blueGrey[200]),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ), //圆角弧度
                ),
              ),
            ),
            SizedBox(
              width: 200,
              height: 200,
              child: ElevatedButton(
                onPressed: () => {showJoinRoom(context)},
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.meeting_room_outlined,
                      size: 60,
                    ),
                    Text("加入会议"),
                  ],
                ),
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all(Colors.blueGrey[200]),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ), //圆角弧度
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
