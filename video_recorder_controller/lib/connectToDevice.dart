import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_socket_io/flutter_socket_io.dart';
import 'package:flutter_socket_io/socket_io_manager.dart';
import 'package:flutter_video_controller/controls.dart';
import 'package:flutter_video_controller/socket.dart';
const maxMobileScreenWidth = 1440;

class ConnectToDevice extends StatefulWidget {
  static String id = "connectToDevice";
  @override
  _ConnectToDeviceState createState() => _ConnectToDeviceState();
}

class _ConnectToDeviceState extends State<ConnectToDevice> {
  SocketIO channel = Socket.socket;
  String _socketId;
  String error = "";
  void _checkSocketId() {
    channel.sendMessage("confirmId", json.encode({"id": _socketId}));
  }
  void initiateSocket() {
    channel.init();
    channel.connect();
    channel.subscribe("confirmed", (data) {
      var jsonData = json.decode(data);
      if(jsonData["confirmed"]) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => Controls(_socketId)));
      } else {
        setState(() {
          error = "There is no Device connected  with this ID";
        });
      }
    });
  }
  @override
  void initState() {
    initiateSocket();
    super.initState();
  }
  @override
  void dispose() {
    channel.disconnect();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: Text("connect to device"),),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/cover.png"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.teal.withOpacity(.5), BlendMode.srcOver ),
          )
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width * .9,
                height: MediaQuery.of(context).size.height > 600? MediaQuery.of(context).size.height*.4: MediaQuery.of(context).size.height*.6,
                color: Colors.blueGrey.withOpacity(.8),
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Enter Internet ID from your device", style: TextStyle(
                        fontSize: width >= maxMobileScreenWidth? 25: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white
                      ),
                    ),
                    TextField(
                      cursorHeight: 30,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "socket ID",
                        hintStyle: TextStyle(color: Colors.black38, fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      textAlign: TextAlign.center,
                      onChanged: (val) => _socketId = val,
                    ),
                    RaisedButton(
                      color: Colors.black38,
                      padding: EdgeInsets.symmetric(vertical: width >= maxMobileScreenWidth?20: 12, horizontal: width >= maxMobileScreenWidth? 60: 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text("Connect", style: TextStyle(color: Colors.white, fontSize: 20)),
                      onPressed: () {if(_socketId != null) _checkSocketId();}
                    ),
                    if(error != "") Container(
                      color: Colors.red.withOpacity(.7),
                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 3),
                      child: Text(error, style: TextStyle(fontSize: width >= maxMobileScreenWidth? 27: 15, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
