import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ipfoam_client/navigation.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';

import 'package:provider/provider.dart';
import 'dart:html' as Html;

class RootTransformWrapper extends StatefulWidget {
  RootTransformWrapper({
    Key? key,
  }) : super(key: key);

  Widget currentTransform = Container(color: Colors.blueAccent,);
  String prevTransformIid = "";

  @override
  State<RootTransformWrapper> createState() => RootTransformWrapperState();
}

class RootTransformWrapperState extends State<RootTransformWrapper> {
  @override
  Widget getRootTransform(Navigation navigation) {
    var expr = navigation.history.last;
    if(expr[0] != widget.prevTransformIid ){
      widget.currentTransform = IPTFactory.getRootTransform(expr, IptRoot.defaultOnTap);
    }
    widget.prevTransformIid = expr[0];
    return widget.currentTransform;    
  }

  Widget build(BuildContext context) {
    final navigation = Provider.of<Navigation>(context);

    return getRootTransform(navigation);
  }
}
