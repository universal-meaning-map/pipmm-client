import 'package:flutter/material.dart';
import 'package:ipfoam_client/navigation.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';
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
  Widget build(BuildContext context) {
    final navigation = Provider.of<Navigation>(context);
    var expr = navigation.history.last;
    return IPTFactory.getRootTransform(expr, IptRoot.defaultOnTap);
  }
}
