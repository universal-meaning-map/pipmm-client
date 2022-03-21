import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ipfoam_client/navigation.dart';
import 'package:ipfoam_client/repo.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';
import 'package:provider/provider.dart';

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
