import 'package:flutter/material.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/note.dart';

class Navigation with ChangeNotifier {
  List<List<dynamic>> history = [[]];
  Function onExprPushed = (List<dynamic> expr) {}; //set by Square 

  void pushExpr(List<dynamic> expr) {
    onExprPushed(expr);
  }

  void setExpr(List<dynamic> expr) {
    history.add(expr);
    notifyListeners();
  }

  static List<dynamic> makeSabExpr(AbstractionReference aref) {
    return [Note.iidSubAbstractionBlock, aref.iid];
  }

  static List<dynamic> makeColumnExpr(dynamic columnsExpr) {
    return [Note.iidColumnNavigator, columnsExpr];
  }

  static List<dynamic> makeNoteViewerExpr(AbstractionReference aref) {
    return [Note.iidNoteViewer, aref.iid];
  }
}
