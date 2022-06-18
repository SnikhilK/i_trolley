import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:i_trolley/rounded_button.dart';
import 'package:i_trolley/services/blue.dart';
import 'package:i_trolley/services/qr_scanning.dart';

class WelcomeScreen extends StatefulWidget {
  static const String id = 'welcome_screen';
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  var readQRcodeResult;
  Future<void> _navigateAndDisplaySelection(BuildContext context) async {
    // Navigator.push returns a Future that completes after calling Navigator.pop on the Selection Screen.
    final readQRcodeResult =
        await Navigator.pushNamed(context, QRScan.id); // Waiting for pop
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(
              'Connection to Cart is Initiating, Cart Address: $readQRcodeResult')));
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Blue(testIdAddress: readQRcodeResult),
        ));
  }

  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black26,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    'i - T r o l l e y',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontFamily: "SourceSansPro",
                        fontWeight: FontWeight.w300),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Expanded(
                  flex: 1,
                  child: Image(image: AssetImage('assets/playstore.png'))),
              RoundedButton(
                boxTitle: 'Scan QR to Start Shopping',
                colour: Color(0XFF212121),
                onPressed: () {
                  _navigateAndDisplaySelection(context);
                },
              ),
              SizedBox(
                height: 1,
              ),
              RoundedButton(
                boxTitle: 'Exit Companion App',
                colour: Color(0XFF212121),
                onPressed: () {
                  SystemNavigator.pop(animated: true);
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
