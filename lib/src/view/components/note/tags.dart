import "package:flutter/material.dart";

class Paragraph extends StatelessWidget {
  const Paragraph(
      {super.key,
      required this.isCenter,
      required this.isBold,
      required this.body});
  final bool isCenter;
  final bool isBold;
  final String body;

  Paragraph fromElement(Element element) {
    return Paragraph(
      isCenter: false,
      isBold: false,
      body: "",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      body,
      textAlign: isCenter ? TextAlign.center : TextAlign.left,
      style: TextStyle(
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

// arguments
//   - isBold: bool
//   - isStrong: bool
//   - body: str
class Span extends StatelessWidget {
  const Span(
      {super.key,
      required this.isBold,
      required this.isStrong,
      required this.body});
  final bool isBold;
  final bool isStrong;
  final String body;

  Span fromElement(Element element) {
    return Span(
      isBold: false,
      isStrong: false,
      body: "",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      body,
      style: TextStyle(
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: isStrong ? Colors.red : Colors.black,
      ),
    );
  }
}
