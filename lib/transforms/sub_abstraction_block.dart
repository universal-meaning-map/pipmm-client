import 'package:flutter/material.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/repo.dart';
import 'package:ipfoam_client/note.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/dynamic_transclusion_run.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';
import 'package:ipfoam_client/utils.dart';

class SubAbstractionBlock implements IptRender, IptTransform {
  AbstractionReference aref = AbstractionReference.fromText("");
  int level = 0;
  final Repo repo;
  Function onTap;

  @override
  String transformIid =Note.iidSubAbstractionBlock;
  @override
  List<dynamic> arguments;

  SubAbstractionBlock(this.arguments, this.repo, this.onTap) {
    processArguments();
  }

  void processArguments() {
    //Note to transclude
    if (arguments.length == 0) {
      aref = AbstractionReference.fromText("");
    }
    if (arguments.length == 1) {
      level = -1;
    }

    aref = AbstractionReference.fromText(arguments[0]);

    //Level of indentation
    level = getLevelFromArgument(arguments[1]);
    if (level == -1) level = 0;
  }

  int getLevelFromArgument(String value) {
    var l = int.tryParse(value);
    if (l == null) {
      return -1;
    }
    return l;
  }

  void updateChildren() {}

  @override
  TextSpan renderTransclusion(repo) {
    print("Render transclusion: subabstraction block");
    var note = Utils.getNote(aref, repo);

    List<TextSpan> blocks = [];

  
    if (note != null) {
      print(note.block);
      if (note.block[Note.iidPropertyName]) {
        blocks.add(renderTitle(note.block[Note.iidPropertyName]));
        blocks.add(renderLineJump());
      }
      if (note.block[Note.iidPropertyAbstract]) {
        blocks.add(renderAbstract(
            note.block[Note.iidPropertyAbstract], repo));
        blocks.add(renderLineJump());
      }
      if (note.block[Note.iidPropertyView]) {
        blocks.add(
            renderView(note.block[Note.iidPropertyView], repo));
        blocks.add(renderLineJump());
      }
      return TextSpan(children: blocks);
    }
    

    return TextSpan(
        text: "<Sub-abstraction block. Failed to load "+ aref.origin +">",
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
        color: const Color.fromRGBO(50,50,50,1),
        height: 1.2);
  }

  TextSpan renderTitle(String str) {
    return TextSpan(text: str, style: titleStyleByLevel());
  }

  TextSpan renderAbstract(List<String> ipt, repo) {
    var a = IptRoot(ipt, onTap);

    var text = a.renderIPT(repo);
    return TextSpan(
        children: text,
        style: const TextStyle(
            //fontWeight: FontWeight.w300,
            fontStyle: FontStyle.italic,
            color: Colors.grey));
  }

  TextSpan renderView(List<String> ipt, repo) {
    var iptRuns = IPTFactory.makeIptRuns(ipt, onTap);

    List<TextSpan> elements = [];
    for (var i = 0; i < iptRuns.length; i++) {
      var run = iptRuns[i];

      if (run.isDynamicTransclusion()) {
        var dynamicRun = run as DynamicTransclusionRun;
        if (dynamicRun.transformAref.iid == transformIid) {
          var childLevel = getLevelFromArgument(run.arguments[1]);
          if (childLevel == -1) {
            childLevel = level + 1;
          }
          var newArguments = run.arguments;
          newArguments[1] = childLevel.toString();
          (iptRuns[i] as DynamicTransclusionRun).arguments = newArguments;
        }
      }
      elements.add(run.renderTransclusion(repo));
    }

    return TextSpan(
      children: elements,
    );
  }
}
