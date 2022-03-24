import 'package:flutter/material.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/note.dart';

class Navigation with ChangeNotifier {
  static List<List<dynamic>> history = [[]];
  static Function onExprPushed = (List<dynamic> expr) {}; //set by Square
  static Function onExprChanged  = (List<dynamic> expr) {};  //set by rootTransformWrapper
  static void pushExpr(List<dynamic> expr) {
    onExprPushed(expr);
  }

  static void setExpr(List<dynamic> expr) {
    history.add(expr);
   // notifyListeners();
   onExprChanged(expr);
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

  static List<dynamic> makeTransformExpr(String transformIid, AbstractionReference aref) {
    return [transformIid, aref.iid];
  }


  static void defaultOnTap(AbstractionReference aref) {
    print("Default tap:" + aref.origin);

    pushExpr(Navigation.makeNoteViewerExpr(aref));
  }
}
