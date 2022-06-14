import 'dart:convert';
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
  StaticTransclusionConfig config = StaticTransclusionConfig();

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

    // Leaf of Interplanetary text (link)
    if (ipt.length <= 1) {
      text = ipt[0];
      if (assumedTransclusionProperty) {
        text = "* " + text;
      }
      if (config.showTransclusionLinks && shouldShowLink()) {
        return TextSpan(
            text: text,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                onTap(aref);
              },
            style: arefStyle());
      } else {
        return TextSpan(text: text
            // style: plainStyle()
            );
      }
    }

    //Interplanetary text (block of text)
    else {
      List<TextSpan> elements = [];
      elements.add(IPTFactory.renderDot(aref, onTap));
      for (var ipte in iptRuns) {
        if (ipte.isStaticTransclusion()) {
          var staticRun = ipte as StaticTransclusionRun;
          staticRun.config = config;
        }
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

  bool shouldShowLink() {
    return true;
    var note = Utils.getNote(aref);
    if (note == null) return false;

    //This is a hack to prevent confusing rendering to the website visitors. It should be passed down as a filter
    if (note.block[Note.iidPropertyPir] != null &&
        note.block[Note.iidPropertyPir] > 0.6) {
      if (note.block[Note.iidPropertyView] != null ||
          note.block[Note.iidPropertyRef] != null) {
        return true;
      }
    }

    return false;
  }

  TextStyle arefStyle() {
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

  TextStyle plainStyle() {
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

class StaticTransclusionConfig {
  bool showTransclusionLinks = true;

  StaticTransclusionConfig();

  StaticTransclusionConfig.fromJSON(String jsonStr) {
    try {
      var jsonObj = json.decode(jsonStr) as Map<String, dynamic>;

      showTransclusionLinks = jsonObj["showTransclusionLinks"] as bool;
    } catch (e) {
      print("Exception parsing StaticTransclusionConfig:\n\n" +
          e.toString() +
          "\n\nfor:\n" +
          jsonStr);
    }
  }
  StaticTransclusionConfig.fromJSONObj(Map<String, dynamic> jsonObj) {
    try {
      showTransclusionLinks = jsonObj["showTransclusionLinks"] as bool;
    } catch (e) {
      print("Exception parsing StaticTransclusionConfig:\n\n" +
          e.toString() +
          "\n\nfor:\n" +
          jsonObj.toString());
    }
  }
}
