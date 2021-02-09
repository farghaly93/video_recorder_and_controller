import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:clipboard/clipboard.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:wakelock/wakelock.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:farghaly_video_recorder/connectBluetooth.dart';
import 'package:farghaly_video_recorder/remoteConfig.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_socket_io/flutter_socket_io.dart';
import 'package:flutter_socket_io/socket_io_manager.dart';
import 'package:localstorage/localstorage.dart';
import 'package:web_socket_channel/io.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

class VideoRecorder extends StatefulWidget {
  List<CameraDescription> cameras;
  VideoRecorder(this.cameras);
  @override
  _VideoRecorderState createState() => _VideoRecorderState();
}

class _VideoRecorderState extends State<VideoRecorder> {
  StreamController streamController;
  var channel = IOWebSocketChannel.connect('ws://192.168.1.9:81/');
  SocketIO channel2 = SocketIOManager().createSocketIO('https://farghaly-socket-server.herokuapp.com', '/');
  LocalStorage storage = new LocalStorage('btnCodes');
  AudioCache audio = AudioCache();
  CameraController controller;
  Random random = Random.secure();
  XFile videoFile;
  int _chosenCameraIndex = 0;
  IconData icon = Icons.fiber_manual_record;
  IconData stopIcon  = Icons.stop_outlined;
  int _seconds = 0;
  String _timer = '00:00:00:00';
  bool _savingLoading = false;
  double _zoomValue = 1.000000;
  double _exposureOffsetValue = 1;
  String ev = "";
  bool channel2On = false;
  String _controllerSocketId;
  bool _copied = false;
  bool _recordLight = false;

  void _showSocketIdAlert(String id) {
    print("alert");
    _copied = false;
    Alert(
      context: context,
      type: AlertType.success,
      title: "insert it to the controller on the other side",
      desc: id,
      buttons: [
        DialogButton(
          child: Text(
            _copied? "Copied": "Copy",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () {
            print("copied");
            FlutterClipboard.copy(id).then((_) {
              setState(() {
                _copied = true;
              });
              Navigator.pop(context);
              // Scaffold.of(context).showSnackBar(SnackBar(content: Text("Copied", style: TextStyle(color: Colors.pink, fontSize: 30)),),);
            });
          },
          width: 160,
        )
      ],
    ).show();
  }

  void _stopButtonHandler() {
    if(controller.value.isRecordingVideo || controller.value.isRecordingPaused) {
      setState(() {
        _onStopButtonPressed();
        stopIcon = Icons.stop_outlined;
        icon = Icons.fiber_manual_record;
      });
    }
  }

  void _startPauseResume() async{
    if(!controller.value.isRecordingVideo) {
      print("stopped.....");
      await _playSound("record");
      _onStartButtonPressed();
      setState(() {
        icon = Icons.pause;
        stopIcon = Icons.stop;
      });
    } else if(controller.value.isRecordingPaused) {
      print("paused.....");
      await _playSound("resume");
      _onResumeButtonPressed();
      setState(() {
        icon = Icons.pause;
      });
    } else if(controller.value.isRecordingVideo) {
      print("recording.....");
      _onPauseButtonPressed();
      setState(() {
        icon = Icons.fiber_manual_record;
      });
    }
  }

  Future<void> _startRecording() async{
    if(!controller.value.isInitialized) {
      return;
    }
    if(controller.value.isRecordingVideo) {
      return;
    }
    try {
      print("starting recording...");
      await controller.startVideoRecording();
      print(controller.value.isRecordingVideo);
    } on CameraException catch(e) {
      print(e);
      return;
    }
  }

  Future<void> _pauseRecording() async{
    if(!controller.value.isInitialized) {
      return;
    }
    if(!controller.value.isRecordingVideo) {
      return;
    }
    try {
      print("pausing recording...");
      await controller.pauseVideoRecording();
    } on CameraException catch(e) {
      print(e);
      return;
    }
  }

  Future<void> _resumeRecording() async{
    if(!controller.value.isInitialized) {
      return;
    }
    if(!controller.value.isRecordingPaused) {
      return;
    }
    try {
      print("resuming recording...");
      await controller.resumeVideoRecording();
    } on CameraException catch(e) {
      print(e);
      return;
    }
  }

  Future<XFile> _stopRecording() async{
    if(!controller.value.isRecordingVideo) {
      return null;
    }
    try {
      print("stopping recording...");
      return controller.stopVideoRecording();
    } on CameraException catch(e) {
      print(e);
      return null;
    }
  }
  // Future<bool> _getPermission(Permission permission) async {
  //   bool granted = await permission.isGranted;
  //   if(granted) return true;
  //   else {
  //     PermissionStatus request = await permission.request();
  //     if(request == PermissionStatus.granted) return true;
  //     else return false;
  //   }
  // }


  void _onStartButtonPressed() {
    _startRecording().then((_) {
      if(mounted) setState(() {
        channel2.sendMessage("status", json.encode({"status": "started", "id": _controllerSocketId}));
      });
    });
  }

  void _onPauseButtonPressed() {
    _pauseRecording().then((_) {
      if(mounted) setState(() {
        channel2.sendMessage("status", json.encode({"status": "paused", "id": _controllerSocketId}));
      });
    });
  }

  void _onResumeButtonPressed() {
    _resumeRecording().then((_) {
      if(mounted) setState(() {
        channel2.sendMessage("status", json.encode({"status": "resumed", "id": _controllerSocketId}));
      });
    });
  }

  _switchCamera() async{
    if(_chosenCameraIndex == 1) _chosenCameraIndex = 0;
    else if(_chosenCameraIndex == 0) _chosenCameraIndex = 1;
    if(controller.value.isRecordingVideo || controller.value.isRecordingPaused) {
      await _onStopButtonPressed();
    }
    initiateCamera(_chosenCameraIndex);
  }


  Future<void> _onStopButtonPressed() async{
    _savingLoading = true;
    _stopRecording().then((file) async{
      if(mounted) setState(() {
        _playSound("stop");
        _seconds = 0;
        _timer = '00:00';
        channel2.sendMessage("status", json.encode({"status": "stopped", "id": _controllerSocketId}));
      });
      if(file != null) {
        videoFile = file;
        Directory directory = await getExternalStorageDirectory();
        List<String> paths = directory.path.split('/');
        String newPath = '';
        for(int i=1; i<paths.length; i++) {
          if(paths[i] != 'Android') {
            newPath += '/${paths[i]}';
          } else {
            break;
          }
        }

        // bool getPermission = await _getPermission(Permission.storage);
        // if(!getPermission) {
        //   return;
        // }
        newPath += '/farghaly_video_records';

        Directory newDirectory = Directory(newPath);
        if(!await newDirectory.exists()) {
          newDirectory.create(recursive: true);
        }
        if(await newDirectory.exists()) {
          List<String> temps = videoFile.path.split('/');
          String videoName = temps[temps.length-1];
          File file = File(newDirectory.path+'/$videoName');
          videoFile.saveTo(file.path);
          setState(() {
            _savingLoading = false;
          });
        }
      }
    });
  }

  void initiateCamera(int camera) async {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp
    ]);
    controller = CameraController(widget.cameras[camera], ResolutionPreset.high);
    controller.setExposureOffset(4);
    // controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }
  // @override
  // void didUpdateWidget(covariant VideoRecorder oldWidget) {
  //   if(oldWidget.createState()._zoomValue != _zoomValue) {
  //     controller.setZoomLevel(_zoomValue);
  //   }
  //   super.didUpdateWidget(oldWidget);
  // }
  _changeZoom(func) {
    if(func == "increase") {
      if(_zoomValue <= 3.5) _zoomValue = _zoomValue + .5;
    }
    if(func == "decrease") {
      if(_zoomValue >= 1.5) _zoomValue = _zoomValue - .5;
    }
    setState(() {
      controller.setZoomLevel(_zoomValue);
    });
  }
  _changeExposureOffset() {
    setState(() {
      controller.setExposureOffset(_exposureOffsetValue);
    });
  }

  _playSound(func) {
    print('sound');
    print(func);
    audio.play("$func.mp3");
  }

  _startChannel2() {
    print("startChannel2");
    channel2.init();
    channel2.subscribe("socketId", (id) {
      print("channel2");
      _showSocketIdAlert(id);
    });
    channel2.subscribe("instruction", (instruction) {
      print("channel2");
      print(instruction);
      var data = json.decode(instruction);
      _controllerSocketId = data['id'];
      String inst = data["inst"];
      if(inst == "record") _startPauseResume();
      else if(inst == "stop") _stopButtonHandler();
      else if(inst == "switchCamera") _switchCamera();
    });
    channel2.subscribe("zoom", (data) {
      print("zoom");
      print(data);
      double val = json.decode(data)["zoomValue"];
      setState(() {
        _zoomValue = val;
        _changeZoom("slider");
      });
    });
    channel2.connect();
    setState(() {
      channel2On = true;
    });
  }
  @override
  void initState() {
    streamController = new StreamController();
    new Timer.periodic(Duration(seconds: 3), (t) {
      if(controller.value.isRecordingPaused) {
        _playSound("pause");
      }
    });
    initiateCamera(_chosenCameraIndex);
    new Timer.periodic(Duration(seconds: 1), (t) {
      if(controller.value.isRecordingVideo && !controller.value.isRecordingPaused) {
        _seconds++;
        String date = DateTime.fromMillisecondsSinceEpoch(_seconds * 1000).toString();
        List<String> time = date.substring(11, 19).split("");
        int hours = int.parse(time[1]) - 2;
        time[1] = hours.toString();
        streamController.sink.add(time.join(""));
        // setState(() {
        //   _timer = time.join("");
        // });
      }
    });

    channel.stream.listen((event) {
      if(event == storage.getItem("record")) _startPauseResume();
      else if(event == storage.getItem("stop")) _stopButtonHandler();
      else if(event == storage.getItem("zoomIn")) _changeZoom("increase");
      else if(event == storage.getItem("zoomOut")) _changeZoom("decrease");
      else if(event == storage.getItem("switchCamera")) _switchCamera();
    });
    _startChannel2();
    Wakelock.enable();
    ImageStreamListener((image, isAvailable) {
      if(isAvailable) {
        print("image available");
        channel2.sendMessage("image", image);
      }
    });
    super.initState();
  }
  _getSocketId() {
    channel2.sendMessage('getId', json.encode({"ok": "ppp"}), (e) => print(e));
  }
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      initiateCamera(_chosenCameraIndex);
      setState(() {
      });
    }
  }
  @override
  void dispose() {
    _stopButtonHandler();
    channel2.disconnect();
    controller?.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if(!controller.value.isInitialized) return Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(
        title: Text('Farghaly recorder'),
        actions: [
          IconButton(
              icon: Icon(Icons.wifi),
              onPressed: _getSocketId
                // if(channel2On) {
                //   setState(() {
                //     channel2.disconnect();
                //     channel2On = false;
                //   });
                // }
                // else if(!channel2On) {
                //   _startChannel2();
                // }
              // }
          ),
          IconButton(
            icon: Icon(Icons.bluetooth),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ConnectBluetooth()));
            }
          ),
          IconButton(
              icon: Icon(Icons.settings_remote),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => RemoteConfig()));
              }
          ),
        ],
      ),
      body: Stack(
        children: [
          ClipRRect(
            child: Container(
              height: double.infinity,
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: CameraPreview(controller),
              ),
            ),
          ),
          Positioned(
              bottom: 0,
              child: Container(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Container(
                    //     height: 100,
                    //     child: StreamBuilder(stream:channel.stream.asBroadcastStream() ,builder: (context, snapshot) => Text(snapshot.data, style: TextStyle(fontSize: 40),),)),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Text('Zoom', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))
                          ),
                          Expanded(
                            flex: 25,
                            child: Slider(
                              value: _zoomValue,
                              min: 1.000000,
                              max: 4.000000,
                              divisions: 100,
                              activeColor: Colors.indigo,
                              inactiveColor: Colors.grey,
                              onChanged: (val) {
                                // setState(() {
                                  _zoomValue = val;
                                  _changeZoom("slider");
                                  channel2.sendMessage(("zoom"), json.encode({"zoomValue": _zoomValue, "id": _controllerSocketId}));
                                // });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.symmetric( horizontal: 10.0),
                    //   child: Row(
                    //     children: [
                    //       Expanded(
                    //         flex: 6,
                    //         child: Text('Exposure', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),)
                    //       ),
                    //       Expanded(
                    //         flex: 25,
                    //         child: Slider(
                    //           value: _exposureOffsetValue,
                    //           min: 1.000000,
                    //           max: 4.000000,
                    //           divisions: 100,
                    //           activeColor: Colors.black54,
                    //           inactiveColor: Colors.grey,
                    //           onChanged: (val) {
                    //             // setState(() {
                    //             _exposureOffsetValue = val;
                    //             _changeExposureOffset();
                    //             // });
                    //           },
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    !_savingLoading? Container(
                      color: Colors.white60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(icon, size: 30, color: Colors.red,),
                            onPressed: _startPauseResume
                          ),
                          IconButton(
                              icon: Icon(stopIcon, size: 30),
                              onPressed: _stopButtonHandler
                          ),
                          IconButton(
                            icon: Icon(Icons.flip_camera_ios, size: 30),
                            onPressed: _switchCamera,
                          ),
                        ],
                      ),
                    ) :
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.all(10),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(child: CircularProgressIndicator()),
                          Text('Saving....', style: TextStyle(fontWeight: FontWeight.w700),),
                        ],
                      ),
                    ),
                  ]
                ),
              ),
            ),
          StreamBuilder(
            stream: streamController.stream,
            builder: (context, val) {
              _recordLight = !_recordLight;
              return Positioned(
                top: 50,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if(_seconds > 0)Icon(Icons.circle, color: _recordLight?Colors.red: Colors.red.withOpacity(0), size: 40,),
                      Container(
                        color: Colors.black.withOpacity(.4),
                        child: Text(
                          _seconds>0?val.data:"",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width > 500? 60: 30,
                              fontWeight: FontWeight.w700,
                              color: Colors.red
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          )
          ],
        ),
    );
  }
}
