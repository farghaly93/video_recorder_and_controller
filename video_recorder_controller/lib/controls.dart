import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_socket_io/flutter_socket_io.dart';
import 'package:flutter_video_controller/socket.dart';

class Controls extends StatefulWidget {
  static String id = "controls";
  final String clientId;
  Controls(this.clientId);
  @override
  _ControlsState createState() => _ControlsState();
}

class _ControlsState extends State<Controls> {
  SocketIO socket = Socket.socket;
  Timer _timer;
  int seconds = 0;
  String timer = "00:00:00";
  String status;
  double _zoomValue = 1;
  void _sendInstruction(inst) {
    socket.sendMessage("sendInstruction", json.encode({"inst": inst, "id": widget.clientId}));
  }
  @override
  void initState() {
    socket.subscribe("status", (instruction) {
      var stat = json.decode(instruction)["status"];
      status = stat;
    });
    socket.subscribe("zoom", (data) {
      double val = json.decode(data)['zoomValue'];
      setState(() {
        _zoomValue = val;
      });
    });
    new Timer.periodic(Duration(seconds: 1), (t) {
      if(status == "started" || status == "resumed") {
        seconds++;
        print(seconds);
        String date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000).toString();

        List<String> time = date.substring(11, 19).split("");
        print(time);

        int hours = int.parse(time[1]) - 2;
        time[1] = hours.toString();
        setState(() {
          timer = time.join("");
        });
      }
      if(status == "stopped") {
        seconds = 0;
        setState(() {
          timer = "00:00:00";
        });
        t.cancel();
      }
    });

    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    double radius = MediaQuery.of(context).size.width * .3;
    return Scaffold(
      appBar: AppBar(title: Text("Controls"),),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            colorFilter: ColorFilter.mode(Colors.blueGrey.withOpacity(.5), BlendMode.srcOver),
            fit: BoxFit.cover,
            image: AssetImage("images/cover.png"),
          ),
        ),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * .9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    child: Center(
                      child: Text(
                        timer,
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.w500,
                          color: Colors.white
                        )
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ControlButton(
                              image: "images/record.png",
                              instruction: "record",
                              func: () {_sendInstruction("record");},
                              radius: radius,
                            ),

                            ControlButton(
                              image: "images/stop_empty.png",
                              instruction: "stop",
                              func: () {_sendInstruction("stop");},
                              radius: radius,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [

                            ControlButton(
                              image: "images/switch.png",
                              func: () {_sendInstruction("switchCamera");},
                              radius: radius,
                            ),
                          ],
                        ),
                        Center(
                          child: Slider(
                            value: _zoomValue,
                            min: 1.0000,
                            max: 4.0000,
                            divisions: 100,
                            activeColor: Colors.blue,
                            inactiveColor: Colors.black38,
                            onChanged: (val) {
                              setState(() {
                                _zoomValue = val;
                                socket.sendMessage("zoom", json.encode({"zoomValue": _zoomValue, "id": widget.clientId}));
                              });
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}






class ControlButton extends StatefulWidget {
  final String image;
  final String instruction;
  final Function func;
  final double radius;
  ControlButton({this.image, this.func, this.instruction, this.radius});

  @override
  _ControlButtonState createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton> {
  SocketIO socket = Socket.socket;
  String image;
  double radius;
  @override
  void initState() {
    image = widget.image;
    radius = widget.radius;
    socket.subscribe("status", (status) {
      print("status");
      var stat = json.decode(status)["status"];
      print(stat);

      if(stat == "started") {
        if(widget.instruction == "record") setState(() => image = "images/pause.png");
        if(widget.instruction == "stop") setState(() => image = "images/stop.png");
      }
      if(stat == "paused") {
        if(widget.instruction == "record") setState(() => image = "images/record.png");
      }
      if(stat == "resumed") {
        if(widget.instruction == "record") setState(() => image = "images/pause.png");
      }
      if(stat == "stopped") {
        if(widget.instruction == "record") setState(() => image = "images/record.png");
        if(widget.instruction == "stop") setState(() => image = "images/stop_empty.png");
      }
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        width: radius,
        height: radius,
        child: CircleAvatar(
          child: Image.asset(
            image,
            width: radius,
            height: radius,
          ),
        ),
      ),
      onTap: () {
        widget.func();
        setState(() {
          radius = radius * .8;
        });
        new Timer(Duration(milliseconds: 200), () {setState(() {radius = widget.radius;});});
      }
    );
  }
}
