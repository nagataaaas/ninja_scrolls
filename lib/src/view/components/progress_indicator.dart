import 'package:flutter/material.dart';

Widget createProgressIndicator() {
  return Container(
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        color: Colors.green,
      ));
}
