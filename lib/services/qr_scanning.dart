import 'package:flutter/material.dart';
import 'package:i_trolley/rounded_button.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScan extends StatelessWidget {
  static const String id = 'qrscan_screen';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan Trolley QR to Connect !',
              style: TextStyle(fontSize: 20.0, fontStyle: FontStyle.italic)),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RoundedButton(
              colour: Colors.black45,
              onPressed: () {
                Navigator.pop(context);
              },
              boxTitle: 'Back',
            ),
            Flexible(
              child: MobileScanner(
                allowDuplicates: false,
                onDetect: (barcode, args) {
                  if (barcode.rawValue == null) {
                    debugPrint('Failed to scan Barcode');
                  } else {
                    final String readQRcode = barcode.rawValue!;
                    debugPrint('Barcode found! $readQRcode');
                    Navigator.pop(context, readQRcode);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
