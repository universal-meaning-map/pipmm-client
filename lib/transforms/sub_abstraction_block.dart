import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/note.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/dynamic_transclusion_run.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/static_transclusion_run.dart';
import 'package:ipfoam_client/utils.dart';

class SubAbstractionBlock implements IptRender, IptTransform {
  AbstractionReference aref = AbstractionReference.fromText("");
  Function onTap;
  SubAbstractionBlockConfig config = SubAbstractionBlockConfig();

  @override
  String transformIid = Note.iidSubAbstractionBlock;
  @override
  List<dynamic> arguments;

  int level = 0;

  SubAbstractionBlock(this.arguments, this.onTap) {
    processArguments();
  }

  void processArguments() {
    //Note to transclude
    if (arguments.isEmpty) {
      aref = AbstractionReference.fromText("");
    } else {
      aref = AbstractionReference.fromText(arguments[0]);
    }

    /*if (arguments.length == 1) {
      level = -1;

    //Level of indentation
    level = getLevelFromArgument(arguments[1]);
    if (level == -1) level = 0;
    }*/
  }

  /* int getLevelFromArgument(String value) {
    var l = int.tryParse(value);
    if (l == null) {
      return -1;
    }
    return l;
  }*/

  SubAbstractionBlockConfig getConfig(String iid, Function subscribeChild) {
    subscribeChild(iid);
    var configIid = AbstractionReference.fromText(iid);
    var configNote = Utils.getNote(configIid);
    if (configNote != null && configNote.block[Note.iidJsonConfig]) {
      return SubAbstractionBlockConfig.fromJSON(
          configNote.block[Note.iidJsonConfig]);
    }
    print("Note " +
        iid +
        " does not seem to include a JsonConfig property " +
        Note.iidJsonConfig);
    return SubAbstractionBlockConfig();
  }

  @override
  TextSpan renderTransclusion(Function subscribeChild) {
    if (aref.isIid()) {
      subscribeChild(aref.iid);
    } else {
      if (aref.isCid()) {
        subscribeChild(aref.cid);
      }
    }

    if (arguments[1] != null) {
      config = getConfig(arguments[1], subscribeChild);
    } else {
      //config has been overriten by parent SAB
    }

    var note = Utils.getNote(aref);

    List<TextSpan> blocks = [];

    if (note != null) {
      if (note.block[Note.iidPropertyName]) {
        blocks
            .add(renderTitle(note.block[Note.iidPropertyName], subscribeChild));
        blocks.add(renderLineJump());
      }

      /*if (note.block[Note.iidPropertyAbstract]) {
        blocks.add(renderAbstract(
            note.block[Note.iidPropertyAbstract], subscribeChild));
        blocks.add(renderLineJump());
      }*/

      if (note.block[Note.iidPropertyView]) {
        blocks
            .add(renderView(note.block[Note.iidPropertyView], subscribeChild));
        blocks.add(renderLineJump());
      }
      return TextSpan(children: blocks);
    }

    return TextSpan(
        text: "<Sub-abstraction block. Failed to load " + aref.origin + ">",
        style: TextStyle(
            // fontWeight: FontWeight.w300,
            ));
  }

  TextSpan renderLineJump() {
    return const TextSpan(text: "\n\n");
  }

  double titleFontSizeByLevel() {
    double rootSize = 36;
    double decrease = 8;
    double size = rootSize - (decrease * level);
    if (size < 16) {
      size = 16;
    }
    return size;
  }

  FontWeight titleFontWeightByLevel() {
    return FontWeight.w600;
  }

  TextStyle titleStyleByLevel() {
    return TextStyle(
        fontWeight: titleFontWeightByLevel(),
        fontSize: titleFontSizeByLevel(),
        color: const Color.fromRGBO(50, 50, 50, 1),
        height: 1.2);
  }

  TextSpan renderTitle(String str, Function subscribeChild) {
    return TextSpan(
        children: [IPTFactory.renderDot(aref, onTap), TextSpan(text: str)],
        style: titleStyleByLevel());
  }

  TextSpan renderAbstract(List<String> ipt, Function subscribeChild) {
    // var a = IptRoot(ipt, onTap));
    var iptRuns = IPTFactory.makeIptRuns(ipt, onTap);

    List<TextSpan> elements = [];
    for (var ipte in iptRuns) {
      elements.add(ipte.renderTransclusion(subscribeChild));
    }

    return TextSpan(
        children: elements,
        style: const TextStyle(
            //fontWeight: FontWeight.w300,
            fontStyle: FontStyle.italic,
            color: Colors.grey));
  }

  TextSpan renderView(List<String> ipt, Function subscribeChild) {
    var iptRuns = IPTFactory.makeIptRuns(ipt, onTap);

    List<TextSpan> elements = [];
    for (var i = 0; i < iptRuns.length; i++) {
      var run = iptRuns[i];

      if (run.isDynamicTransclusion()) {
        var dynamicRun = run as DynamicTransclusionRun;
        if (dynamicRun.transformAref.iid == Note.iidSubAbstractionBlock) {
          var sabChild =
              SubAbstractionBlock(dynamicRun.arguments, dynamicRun.onTap);
          sabChild.level = level + 1;
          if (run.arguments[1] != null) {
            var childConfig = getConfig(run.arguments[1], subscribeChild);
            sabChild.config = childConfig;
          } else {
            sabChild.config = config;
          }
          elements.add(sabChild.renderTransclusion(subscribeChild));
        } else {
          elements.add(run.renderTransclusion(subscribeChild));
        }
      } else if (run.isStaticTransclusion()) {
        var staticRun = run as StaticTransclusionRun;

        elements.add(staticRun.renderTransclusion(subscribeChild));
      } else {
        elements.add(run.renderTransclusion(subscribeChild));
      }
    }

    return TextSpan(
      children: elements,
    );
  }
}

class SubAbstractionBlockConfig {
  List<String> titleProperties = [Note.iidPropertyName];
  List<String> abstractProperties = [];
  List<String> bodyProperties = [Note.iidPropertyView];

  SubAbstractionBlockConfig();

  SubAbstractionBlockConfig.fromJSON(String jsonStr) {
    try {
      var jsonObj = json.decode(jsonStr) as Map<String, dynamic>;

      List.castFrom<dynamic, String>(jsonObj["titleProperties"]);
      abstractProperties =
          List.castFrom<dynamic, String>(jsonObj["abstractProperties"]);
      bodyProperties =
          List.castFrom<dynamic, String>(jsonObj["bodyProperties"]);
    } catch (e) {
      print("Exception parsing SubAbstractionBlockConfig:\n\n" +
          e.toString() +
          "\n\nfor:\n" +
          jsonStr);
    }
  }
}
