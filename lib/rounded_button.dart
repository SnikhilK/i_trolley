import 'package:flutter/material.dart';
import 'package:i_trolley/constants.dart';

class RoundedButton extends StatelessWidget {
  RoundedButton(
      {required this.colour, required this.boxTitle, required this.onPressed});
  final Color colour;
  final String boxTitle;
  final Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.0),
      child: Material(
        elevation: 5.0,
        color: colour,
        borderRadius: BorderRadius.circular(10.0),
        child: MaterialButton(
          elevation: 5.0,
          onPressed: onPressed,
          minWidth: 200.0,
          height: 40.0,
          child: Text(
            boxTitle,
            style: kText4button,
          ),
        ),
      ),
    );
  }
}
