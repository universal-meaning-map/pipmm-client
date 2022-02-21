import 'package:flutter/material.dart';
import 'dart:html' as html;

class Hyperlink extends StatelessWidget {
  final String url;

  Hyperlink({required this.url});

  void launchURL() async {
    html.window.open(url, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
       launchURL();
      },
      child: Text(url,
          textAlign: TextAlign.left,
     
          style: const TextStyle(
              fontWeight: FontWeight.normal, color: Colors.blue)),
    );
  }
}
