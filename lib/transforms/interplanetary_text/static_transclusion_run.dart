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

    // Leaf of Interplanetary text (link)
    if (ipt.length <= 1) {
      text = ipt[0];
      if (assumedTransclusionProperty) {
        text = "* " + text;
      }
    
      if (Config.filterTransclusionLinks && !passesFilterToDisplayLink()) {
        return TextSpan(text: text
            // style: plainStyle()
            );
      } else {
        return TextSpan(
            text: text,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                onTap(aref);
              },
            style: arefStyle());
      }
    }

    //Interplanetary text (block of text)
    else {
      List<TextSpan> elements = [];
      elements.add(IPTFactory.renderDot(aref, onTap));
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

  bool passesFilterToDisplayLink() {
    var note = Utils.getNote(aref);
    if (note == null) return false;

    //This is a hack to prevent confusing rendering to the website visitors. It should be passed down as a filter
    if (note.block[Note.iidPropertyPir] != null &&
        note.block[Note.iidPropertyPir] > 0.75) {
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
