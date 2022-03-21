import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ipfoam_client/navigation.dart';
import 'package:ipfoam_client/note.dart';
import 'package:ipfoam_client/repo.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/dynamic_transclusion_run.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/plain_text_run.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/static_transclusion_run.dart';
import 'package:ipfoam_client/transforms/note_viewer.dart';
import 'package:ipfoam_client/transforms/column_navigator.dart';
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
        return ColumnNavigator(
            arguments: dynamicRun.arguments,
            key: const ValueKey("PageNavigator"));
      }
      if (dynamicRun.transformAref.iid == Note.iidNoteViewer) {
        return NoteViewer(
            arguments: dynamicRun.arguments,
            onTap: onTap,
            key: ValueKey(dynamicRun.arguments));
      }

      return IptRoot.fromExpr(expr, onTap, ValueKey(expr.toString()));
    } else if (iptRun.isStaticTransclusion()) {
      var staticRun = iptRun as StaticTransclusionRun;

      return IptRoot.fromExpr(expr, onTap, ValueKey(expr.toString()));
    }
    return IptRoot.fromExpr(expr, onTap, ValueKey(expr.toString()));
  }
}

abstract class RootTransform implements Widget {}

abstract class IptRun implements IptRender {
  bool isPlainText();
  bool isStaticTransclusion();
  bool isDynamicTransclusion();
}

abstract class IptRender {
  TextSpan renderTransclusion(Function subscribeChild);
}

abstract class IptTransform {
  List<dynamic> arguments = [];
  String transformIid = "";
}

class IptRoot extends StatefulWidget implements RootTransform {
  List<String> ipt = [];
  List<IptRun> iptRuns = [];

  IptRoot(this.ipt, onTap, Key? key) : super(key: key) {
    onTap ??= Navigation.defaultOnTap;
    iptRuns = IPTFactory.makeIptRuns(ipt, onTap);
  }

  IptRoot.fromRun(String jsonStr, onTap, Key? key) : super(key: key) {
    onTap ??= Navigation.defaultOnTap;

    List<String> expr = json.decode(jsonStr);

    iptRuns = [IPTFactory.makeIptRunFromExpr(expr, onTap)];
  }

  IptRoot.fromExpr(List<dynamic> expr, onTap, Key? key) : super(key: key) {
    iptRuns = [IPTFactory.makeIptRunFromExpr(expr, onTap)];
  }

  List<TextSpan> renderIPT(subscribeChild) {
    List<TextSpan> elements = [];
    for (var ipte in iptRuns) {
      elements.add(ipte.renderTransclusion(subscribeChild));
    }
    return elements;
  }

  @override
  State<IptRoot> createState() => _IptRootState();
}

class _IptRootState extends State<IptRoot> {
  List<String> children = [];

   @override
  initState() {
    super.initState();
  }

  subscribeChild(String cidOrIid) {
    if (children.contains(cidOrIid)) {
      return;
    }
    print("Child " + cidOrIid);
    children.add(cidOrIid);
    Repo.addSubscriptor(cidOrIid, onRepoUpdate);
  }

  onRepoUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<Repo>(context);
    var text = SelectableText.rich(TextSpan(
      style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
          fontFamily: "FiraCode",
          letterSpacing: -0.5,
          fontWeight: FontWeight.w100,
          fontStyle: FontStyle.normal, //TODO: Use FontStyle.normal. Flutter bug
          height: 1.7),
      children: widget.renderIPT(subscribeChild),
    ));

    return text;
  }
}
