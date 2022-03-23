import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ipfoam_client/note.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';
import 'dart:html' as html;

class IptHyperlink implements IptRender, IptTransform {
  String uri = "";
  String label = "";
  Function onTap;

  @override
  String transformIid = Note.iidIptHyperlink;
  @override
  List<dynamic> arguments;

  IptHyperlink(this.arguments, this.onTap) {
    processArguments();
  }

  void processArguments() {
    if (arguments[0] != null) {
      uri = arguments[0];
    }
    if (arguments[1] != null) {
      label = arguments[1];
    } else {
      label = arguments[0];
    }
  }

  void launchURL() async {
    html.window.open(uri, '_blank');
  }

  @override
  TextSpan renderTransclusion(Function subscribeChild) {
    return TextSpan(
        text: label,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            launchURL();
          },
        style: const TextStyle(color: Colors.blue));
  }
}
