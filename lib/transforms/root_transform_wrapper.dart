import 'package:flutter/material.dart';
import 'package:ipfoam_client/navigation.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';
import 'package:ipfoam_client/transforms/note_viewer.dart';

import 'package:provider/provider.dart';

class RootTransformWrapper extends StatefulWidget {
  RootTransformWrapper({
    Key? key,
  }) : super(key: key);

  RootTransform currentTransform = NoteViewer([],(){});
  String prevTransformIid = "";

  @override
  State<RootTransformWrapper> createState() => RootTransformWrapperState();
}

class RootTransformWrapperState extends State<RootTransformWrapper> {
  @override
  Widget getRootTransform(Navigation navigation) {
    var expr = navigation.history.last;

  //This is necessary for the ColumnViewer to not reset its position on every change
    if(expr[0] != widget.prevTransformIid ){
      widget.currentTransform = IPTFactory.getRootTransform(expr, IptRoot.defaultOnTap);
    }
    else{
     // widget.currentTransform.updateArguments(expr, IptRoot.defaultOnTap);
    }
    widget.prevTransformIid = expr[0];
    return widget.currentTransform;    
  }

  Widget build(BuildContext context) {
    final navigation = Provider.of<Navigation>(context);

    return getRootTransform(navigation);
  }
}
