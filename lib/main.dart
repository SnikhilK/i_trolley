import 'package:flutter/material.dart';
import 'package:i_trolley/screens/my_cart.dart';
import 'package:i_trolley/services/blue.dart';
import 'package:i_trolley/services/qr_scanning.dart';
import 'package:i_trolley/screens/welcome_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), //id made static
      initialRoute: WelcomeScreen.id,
      // initialRoute: MyCart.id,
      // initialRoute: Blue.id,
      routes: {
        WelcomeScreen.id: (context) => WelcomeScreen(),
        QRScan.id: (context) => QRScan(),
        Blue.id: (context) => Blue(),
        MyCart.id: (context) => MyCart()
      },
    );
  }
}
