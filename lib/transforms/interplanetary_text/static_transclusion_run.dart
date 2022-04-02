import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ipfoam_client/color_utils.dart';
import 'package:ipfoam_client/config.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/note.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';
import 'package:ipfoam_client/utils.dart';

class StaticTransclusionRun implements IptRun {
  late AbstractionReference aref;
  List<IptRun> iptRuns = [];
  Function onTap;
  bool assumedTransclusionProperty = false;
  bool notFoundNoteOrProperty = false;

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

  List<String> getTranscludedIpt(Function subscribeChild) {
    notFoundNoteOrProperty = false;
    assumedTransclusionProperty = false;
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

      if (Utils.isPrimitiveType(aref.tiid)) {
        return [note.block[aref.tiid]];
      }

      if (aref.tiid != null && note.block[aref.tiid] != null) {
        subscribeChild(aref.tiid);
        var typeNote = Utils.getNote(AbstractionReference.fromText(aref.tiid!));
        if (typeNote != null) {
          if (Utils.getBasicType(typeNote) == Note.basicTypeString) {
            return [note.block[aref.tiid]];
          } else if (Utils.getBasicType(typeNote) ==
              Note.basicTypeInterplanetaryText) {
            return note.block[aref.tiid];
          } else {}
        }
      }
    }
    notFoundNoteOrProperty = true;
    if (aref.liid != null) {
      return [aref.liid!];
    }
    return [aref.origin];
  }

  @override
  TextSpan renderTransclusion(Function subscribeChild) {
    subscribeChild(aref.iid);
    var ipt = getTranscludedIpt(subscribeChild);

    var iptRuns = IPTFactory.makeIptRuns(ipt, onTap);

    var text = "";

    // Plain text/ leaf of Interplanetary text
    if (ipt.length <= 1) {
      text = ipt[0];
      if (assumedTransclusionProperty) {
        text = "* " + text;
      }
      return TextSpan(
          text: text,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              onTap(aref);
            },
          style: getPlainStyle());
    }

    //Interplanetary text
    else {
      List<TextSpan> elements = [];
      elements.add(IPTFactory.renderDot(aref,onTap));
      for (var ipte in iptRuns) {
        elements.add(ipte.renderTransclusion(subscribeChild));
      }

      return TextSpan(
        text: text,
        children: elements,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            onTap(aref);
          },
      );
    }
  }

  TextStyle getPlainStyle() {
    return TextStyle(
        color: notFoundNoteOrProperty ? Colors.red : Colors.black,
        fontWeight: FontWeight.w400,
        //decoration: TextDecoration.underline,
        //decorationColor: getUnderlineColor(aref.origin),
        //decorationThickness: 2, //doesn't seem to have any effect
        background: Paint()
          // ..strokeWidth = 10.0
          //..strokeJoin = StrokeJoin.round
          ..color = getBackgroundColor(aref.origin)
          ..style = PaintingStyle.fill);
  }
}
