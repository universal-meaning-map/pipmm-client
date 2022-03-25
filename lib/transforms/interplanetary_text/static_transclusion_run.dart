import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ipfoam_client/color_utils.dart';
import 'package:ipfoam_client/config.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';
import 'package:ipfoam_client/utils.dart';

class StaticTransclusionRun implements IptRun {
  late AbstractionReference aref;
  List<IptRun> iptRuns = [];
  Function onTap;
  bool assumedTransclusionProperty = false;

  StaticTransclusionRun(List<dynamic> expr, this.onTap) {
    aref = AbstractionReference.fromText(expr[0]);
  }

  @override
  bool isStaticTransclusion() {
    return true;
  }

  @override
  bool isDynamicTransclusion() {
    return false;
  }

  @override
  bool isPlainText() {
    return false;
  }

  List<String> getTranscludedText() {
    var note = Utils.getNote(aref);

    if (note != null) {
      if (aref.tiid == null || note.block[aref.tiid] == null) {
        //If transclusion property is not defined we use the properties defined in the config
        for (var propertyToTransclude
            in Config.transclusionPropertiesPriority) {
          if (note.block[propertyToTransclude] != null) {
            aref.tiid = propertyToTransclude;
            assumedTransclusionProperty = true;
            break;
          }
        }
      }
      if (note.block[aref.tiid] != null) {
        //TODO verify what property type is it
        try {
          //Transcluded text
          return [note.block[aref.tiid] as String];
        } catch (e) {
          //Transcluded transclusion (ipt)
          return note.block[aref.tiid];
        }
      }
    }

    return [aref.origin];
  }

  @override
  TextSpan renderTransclusion(Function subscribeChild) {
    subscribeChild(aref.iid);
    var text = "";
    var t = getTranscludedText();
    List<TextSpan> elements = [];
    // Plain text/ leaf of Interplanetary text
    if (t.length <= 1) {
      text = t[0];
    }
    if(assumedTransclusionProperty){
      text = "*"+text;
    }
    //Interplanetary text
    else {
      for (var ipte in iptRuns) {
        elements.add(ipte.renderTransclusion(subscribeChild));
      }
    }
    var style = TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w400,
        //decoration: TextDecoration.underline,
        //decorationColor: getUnderlineColor(aref.origin),
        // decorationThickness: 2, //doesn't seem to have any effect
        background: Paint()
          // ..strokeWidth = 10.0
          //..strokeJoin = StrokeJoin.round
          ..color = getBackgroundColor(aref.origin)
          ..style = PaintingStyle.fill);

    return TextSpan(
        text: text,
        children: elements,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            onTap(aref);
          },
        style: style);
  }
}
