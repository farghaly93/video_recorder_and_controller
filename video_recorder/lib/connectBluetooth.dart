import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
// import 'package:bluetooth_helper/bluetooth_helper.dart';
import 'package:farghaly_video_recorder/constants.dart';
import 'package:flutter/material.dart';
import 'dart:core';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
class ConnectBluetooth extends StatefulWidget {
  @override
  _ConnectBluetoothState createState() => _ConnectBluetoothState();
}

class _ConnectBluetoothState extends State<ConnectBluetooth> {
  bool _loading = false;
  StreamSubscription streamSubscription;
  List<BluetoothDiscoveryResult> _deviceList = List<BluetoothDiscoveryResult>();
  BluetoothConnection connection;


  void _discoverDevices() async{
    setState(() {_loading = true;});

    streamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((device) {
      var index = _deviceList.indexWhere((el) => el.device.address == device.device.address);
      if(index < 0) {
      setState(() {
        _deviceList.add(device);
      });
      }
    });

    streamSubscription.onDone(() {
      setState(() {_loading = false;});
    });
  }
  void _connectDevice(i) async{
     try {
        connection = await BluetoothConnection.toAddress(_deviceList[i].device.address);
        print('Connected to the device');

        connection.input.listen((Uint8List data) {
          //Data entry point
          print(ascii.decode(data));
        });

      } catch (exception) {
        print('Cannot connect, exception occured $exception');
      }
  }
  void _disconnectDevice(i) {

  }
  @override
  void initState() {

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('connect to bluetooth'),
      ),
      body: Center(
          child: Container(
            child: Column(
              children: [
                SizedBox(height: 20,),
                Text(
                  'Available devices',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                ),
                Container(
                  color: Colors.black54.withOpacity(.4),
                  margin: EdgeInsets.all(10),
                  height: 500,
                  child: ListView.builder(
                    itemCount: _deviceList.length,
                    itemBuilder: (context, i) {
                      var device = _deviceList[i];
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: ListTile(
                          tileColor: Colors.blueGrey,
                          leading: Icon(Icons.bluetooth, size: 30, color: Colors.white,),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(device.device.name != null?device.device.name: 'Unknown', style: KListTextStyle,),
                              Text(device.device.address != null?device.device.address: 'Unknown', style: KListTextStyle),
                              // if(device.bondState.stringValue == 'STATE_ON')
                              //   Text('Connecting...', style: KListTextStyle)
                              // else
                                Text(device.device.isConnected?'connected': 'disconnected', style: KListTextStyle),
                            ],
                          ),
                          trailing: FlatButton(
                            color: Colors.green,
                            child: Text(device.device.isConnected?'Disconnect': 'Connect', style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              if(device.device.isConnected) _disconnectDevice(i);
                              else _connectDevice(i);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if(_loading)
                  CircularProgressIndicator(semanticsLabel: 'Searching for devices',),
                RawMaterialButton(
                  child: Text('Refresh devices'),
                  fillColor: Colors.indigo,
                  textStyle: TextStyle(color: Colors.white),
                  hoverColor: Colors.blueGrey,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  onPressed: _discoverDevices,
                ),
              ],
            ),
          )
      ),
    );
  }
}