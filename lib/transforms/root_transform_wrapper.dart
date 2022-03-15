import 'package:flutter/material.dart';
import 'package:ipfoam_client/navigation.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/dynamic_transclusion_run.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';
import 'package:ipfoam_client/transforms/page_navigator.dart';
import 'package:provider/provider.dart';

class RootTransformWrapper extends StatefulWidget {
  RootTransformWrapper({
    Key? key,
  }) : super(key: key);

  @override
  State<RootTransformWrapper> createState() => RootTransformWrapperState();
}

class RootTransformWrapperState extends State<RootTransformWrapper> {
  @override
  initState() {
    super.initState();
    print("init root");
  }

  @override
  Widget build(BuildContext context) {
    final navigation = Provider.of<Navigation>(context);
    var expr = navigation.history.last;
    var iptRun = IPTFactory.makeIptRunFromExpr(expr, IptRoot.defaultOnTap);

    return IPTFactory.getRootTransform(expr, IptRoot.defaultOnTap);
    var dynamicRun = iptRun as DynamicTransclusionRun;
    return PageNavigator(
      arguments: dynamicRun.arguments,
      key: ValueKey("pageNavigator"),
    );
  }
}
