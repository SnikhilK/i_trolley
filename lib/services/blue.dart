import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:i_trolley/rounded_button.dart';
import 'package:i_trolley/screens/my_cart.dart';
import 'package:i_trolley/screens/welcome_screen.dart';

class Blue extends StatefulWidget {
  var testIdAddress; //device Address from Narnia
  Blue({this.testIdAddress});
  // Blue({this.testIdAddress});

  static const String id = 'blue_screen';

  var rfidData; //main data variables
  var loadData;

  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;

  late final BluetoothDevice cartDevice;

  @override
  State<Blue> createState() => _BlueState();
}

class _BlueState extends State<Blue> {
  // final BluetoothDevice cartDevice = BluetoothDevice.fromId(
  //     Constants.constIdAddress,
  //     name: Constants.constName,
  //     type: BluetoothDeviceType.le);

  Future<void> createDevice() async {
    try {
      widget.cartDevice.disconnect();
    } catch (e) {
      print(e);
    } finally {
      await widget.flutterBlue.startScan(timeout: Duration(seconds: 2));
      widget.flutterBlue.scanResults.listen(
        (results) async {
          for (ScanResult r in results) {
            print('${r.device.name} found! ${r.rssi}db and id:${r.device.id}');
            if (r.device.id.toString() == widget.testIdAddress) {
              widget.cartDevice = r.device;
              print(widget.cartDevice);
              widget.flutterBlue.stopScan();
              return;
            }
          }
        },
      );
    }
  }

  Future<void> initConnect() async {
    try {
      await widget.cartDevice.connect(autoConnect: true);
    } catch (e) {
      print(e);
    }
  }

  Future<void> checkServices() async {
    try {
      List<BluetoothService> services =
          await widget.cartDevice.discoverServices();
      services.forEach(
        (service) {
          print(service);
        },
      );
    } catch (e) {
      print(e);
    }
  }

  Future<void> dataRFID() async {
    try {
      List<BluetoothService> services =
          await widget.cartDevice.discoverServices();
      List<int> value = await services[2].characteristics[1].read();
      setState(() {
        widget.rfidData = utf8.decode(value).trim();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Uh-oh: ${e}')));
    }
  }

  Future<void> dataTotalLoad() async {
    try {
      List<BluetoothService> services =
          await widget.cartDevice.discoverServices();
      List<int> value = await services[2].characteristics[0].read();
      setState(() {
        widget.loadData = utf8.decode(value).trim();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Uh-oh: ${e}')));
      ;
    }
  }

  Future<void> decideDeviceState() async {
    try {
      if (widget.loadData == null && widget.rfidData == null) {
        widget.deviceState = BluetoothDeviceState.disconnected;
      } else {
        widget.deviceState = BluetoothDeviceState.connected;
      }
    } catch (e) {
      return;
    }
  }

  Future<void> checkCurrentState() async {
    await dataTotalLoad();
    await dataRFID();
    await decideDeviceState();

    if (widget.deviceState == BluetoothDeviceState.connected) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text('Connected! Yay! :${widget.deviceState}')));
    } else {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text('No Connection Yet :${widget.deviceState}')));
    }
  }

  @override
  void initState() {
    super.initState();
    createDevice(); //.whenComplete(() => initConnect());
    Future.delayed(const Duration(seconds: 5), () {
      initConnect();
    });
  }

  Widget build(BuildContext context) {
    widget.testIdAddress = '58:BF:25:33:01:5A';
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Bluetooth Debug')),
        body: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: RoundedButton(
                  colour: const Color(0xFF0C1E1E),
                  boxTitle: 'Check Status & Proceed',
                  onPressed: () async {
                    await checkCurrentState();
                    if (widget.deviceState == BluetoothDeviceState.connected) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyCart(
                              cartDeviceData: widget.cartDevice,
                            ),
                          ));
                    }
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 3.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 3, horizontal: 7),
                    decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: RoundedButton(
                            colour: const Color(0xFF1F4141),
                            boxTitle: '1. Retry Initialization',
                            onPressed: () async {
                              try {
                                await createDevice();
                              } catch (e) {
                                ScaffoldMessenger.of(context)
                                  ..removeCurrentSnackBar()
                                  ..showSnackBar(
                                      SnackBar(content: Text('Uh-oh: ${e}')));
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: RoundedButton(
                            colour: const Color(0xFF1F4141),
                            boxTitle: '2. Manually Connect',
                            onPressed: () async {
                              try {
                                print(widget.cartDevice);
                                await widget.cartDevice.connect(
                                    autoConnect: true,
                                    timeout: const Duration(seconds: 10));
                              } catch (e) {
                                ScaffoldMessenger.of(context)
                                  ..removeCurrentSnackBar()
                                  ..showSnackBar(
                                      SnackBar(content: Text('Uh-oh: ${e}')));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      child: RoundedButton(
                          colour: const Color(0xFF586F6C),
                          boxTitle: widget.rfidData == null
                              ? 'Waiting ..'
                              : 'RFID Value: ${widget.rfidData}',
                          onPressed: () {
                            dataRFID();
                          }),
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: RoundedButton(
                          colour: const Color(0xFF586F6C),
                          boxTitle: widget.loadData == null
                              ? 'Waiting ..'
                              : 'Load Value: ${widget.loadData}',
                          onPressed: () {
                            dataTotalLoad();
                          }),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: RoundedButton(
                    colour: const Color(0xFF1D3434),
                    boxTitle: 'Exit to Main-Menu',
                    onPressed: () {
                      try {
                        widget.cartDevice.disconnect();
                      } catch (e) {
                        print(e);
                      }
                      Navigator.pushNamed(context, WelcomeScreen.id);
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
