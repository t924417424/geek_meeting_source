import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// 用户协议Dialog
Future<Widget?> showMyDiaLog(BuildContext context, String title, String text) {
  return showDialog<Widget>(
    context: context,
    builder: (context) {
      return SimpleDialog(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.height / 2,
            height: MediaQuery.of(context).size.height / 3,
            child: Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(text),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    "确定",
                    style: TextStyle(color: Colors.blue[300], fontSize: 15),
                  ),
                ),
                onTap: () => {Navigator.pop(context)},
              ),
            ],
          )
        ],
      );
    },
  );
}
