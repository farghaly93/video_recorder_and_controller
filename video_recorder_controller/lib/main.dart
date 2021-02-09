import 'package:flutter/material.dart';
import 'package:flutter_video_controller/connectToDevice.dart';
import 'package:flutter_video_controller/controls.dart';
import 'package:flutter_video_controller/socket.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); Socket.initSocket();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: ConnectToDevice.id,
      routes: {
        ConnectToDevice.id:  (context) => ConnectToDevice(),
      },
    );
  }
}
