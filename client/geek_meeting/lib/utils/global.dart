import 'package:geek_meeting/utils/net.dart';

class NetUtil {
  static late Net _net;
  static Net get net => _net;
  static init() {
    _net = Net();
  }
}
