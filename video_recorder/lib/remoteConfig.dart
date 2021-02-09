import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
class RemoteConfig extends StatefulWidget {
  @override
  _RemoteConfigState createState() => _RemoteConfigState();
}

class _RemoteConfigState extends State<RemoteConfig> {
  final channel = IOWebSocketChannel.connect('ws://192.168.1.9:81');
  String buttonToSave = "record";
  LocalStorage storage = new LocalStorage('btnCodes');
  Color color = Colors.green;
  @override
  void initState() {
    channel.stream.listen((event) {
      print(event);
      saveButtonCode(event);
    });
    super.initState();
  }

  void saveButtonCode(buttonCode) {
      storage.setItem(buttonToSave, buttonCode);
      setState(() {
        switch(buttonToSave) {
          case "record":  {buttonToSave = "stop"; color = Colors.teal;}
           break;
          case "stop":  {buttonToSave = "zoomIn"; color = Colors.black54;}
            break;
          case "zoomIn":  {buttonToSave = "zoomOut"; color = Colors.pinkAccent;}
            break;
          case "zoomOut":  {buttonToSave = "switchCamera"; color = Colors.deepPurple;}
            break;
          case "switchCamera": {buttonToSave = "record"; color = Colors.green;}
           break;
        }
      });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Remote configuration"),),
      backgroundColor: Colors.white,
      body: Container(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width*.6,
            height: MediaQuery.of(context).size.width*.6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width*.30),
              color: color,
            ),
            child: Center(
              child: Text(buttonToSave, textAlign: TextAlign.center, style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: MediaQuery.of(context).size.width*.1
              ),
              ),
            ),
          )
        ),
      ),
    );
  }
}
