import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/navigation.dart';
import 'package:ipfoam_client/note.dart';
import 'package:ipfoam_client/repo.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/dynamic_transclusion_run.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/plain_text_run.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/static_transclusion_run.dart';
import 'package:ipfoam_client/transforms/note_viewer.dart';
import 'package:ipfoam_client/transforms/page_navigator.dart';
import 'package:provider/provider.dart';

//Run (JSON): `["is6hvlinq2lf4dbua","is6hvlinqxoswfrpq","2"]`
//Expr (Parsed JSON): [is6hvlinq2lf4dbua,is6hvlinqxoswfrpq,2]
//IptRun (object instance)
class IPTFactory {
  static bool isRunATransclusionExpression(String run) {
    if (run.length < 2) return false;
    return run.substring(0, 1) == "[" && run.substring(run.length - 1) == "]";
  }

  static IptRun makeIptRun(String run, Function onTap) {
    if (IPTFactory.isRunATransclusionExpression(run)) {
      List<String> expr = json.decode(run);

      if (expr.length == 1) {
        return StaticTransclusionRun(expr, onTap);
      }
      if (expr.length > 1) {
        return DynamicTransclusionRun(expr, onTap);
      }
    }
    return PlainTextRun(run);
  }

  static IptRun makeIptRunFromExpr(List<dynamic> expr, Function onTap) {
    if (expr.length == 1) {
      return StaticTransclusionRun(expr, onTap);
    }
    if (expr.length > 1) {
      return DynamicTransclusionRun(expr, onTap);
    }

    return PlainTextRun("empty");
  }

  static List<IptRun> makeIptRuns(List<String> ipt, Function onTap) {
    List<IptRun> iptRuns = [];
    for (var run in ipt) {
      iptRuns.add(IPTFactory.makeIptRun(run, onTap));
    }
    return iptRuns;
  }

  static RootTransform getRootTransform(List<dynamic> expr, Function onTap) {
    var iptRun = IPTFactory.makeIptRunFromExpr(expr, onTap);

    if (iptRun.isDynamicTransclusion()) {
      var dynamicRun = iptRun as DynamicTransclusionRun;

      if (dynamicRun.transformAref.iid == Note.iidColumnNavigator) {
        return PageNavigator(arguments: dynamicRun.arguments);
      }
      if (dynamicRun.transformAref.iid == Note.iidNoteViewer) {
        return NoteViewer(dynamicRun.arguments, onTap);
      }

      return IptRoot.fromExpr(expr, onTap);
    } else if (iptRun.isStaticTransclusion()) {
      var staticRun = iptRun as StaticTransclusionRun;

      return IptRoot.fromExpr(expr, onTap);
    }
    return IptRoot.fromExpr(expr, onTap);
  }
}

abstract class RootTransform implements Widget {
  void updateArguments(List<dynamic> expr, Function onTap);
}

abstract class IptRun implements IptRender {
  List<IptRun> iptRuns = [];
  bool isPlainText();
  bool isStaticTransclusion();
  bool isDynamicTransclusion();
}

abstract class IptRender {
  TextSpan renderTransclusion(Repo repo);
}

abstract class IptTransform {
  List<dynamic> arguments = [];
  String transformIid = "";
}

class IptRoot extends StatelessWidget implements RootTransform {
  List<String> ipt = [];
  List<IptRun> iptRuns = [];

  @override
  updateArguments(List<dynamic> args, onTap) {
    iptRuns = [IPTFactory.makeIptRunFromExpr(args, onTap)];
  }

  static void defaultOnTap(AbstractionReference aref) {
    print("Default tap:" + aref.origin);
  }

  IptRoot(this.ipt, onTap) {
    onTap ??= defaultOnTap;
    iptRuns = IPTFactory.makeIptRuns(ipt, onTap);
  }

  IptRoot.fromRun(String jsonStr, onTap) {
    onTap ??= defaultOnTap;

    List<String> expr = json.decode(jsonStr);

    iptRuns = [IPTFactory.makeIptRunFromExpr(expr, onTap)];
  }

  IptRoot.fromExpr(List<dynamic> expr, onTap) {
    iptRuns = [IPTFactory.makeIptRunFromExpr(expr, onTap)];
  }

  List<TextSpan> renderIPT(repo) {
    List<TextSpan> elements = [];
    for (var ipte in iptRuns) {
      elements.add(ipte.renderTransclusion(repo));
    }
    return elements;
  }

  @override
  Widget build(BuildContext context) {
    final navigation = Provider.of<Navigation>(context);
    final repo = Provider.of<Repo>(context);
    var text = SelectableText.rich(TextSpan(
      style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
          fontFamily: "OpenSans",
          fontWeight: FontWeight.w100,
          fontStyle: FontStyle.normal, //TODO: Use FontStyle.normal. Flutter bug
          height: 1.7),
      children: renderIPT(repo),
    ));

    return text;
  }
}
