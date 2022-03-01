import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/navigation.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';
import 'package:provider/provider.dart';
import 'dart:html' as Html;

class ColumnNavigator extends StatefulWidget {
  // [[column1, column2], pref] or [[[column1 render, column1 note], [column2 render, column2 note]],pref]
  List<dynamic> arguments;

  ColumnNavigator({
    required this.arguments,
    Key? key,
  }) : super(key: key);

  @override
  State<ColumnNavigator> createState() => ColumnNavigatorState();
}

class ColumnNavigatorState extends State<ColumnNavigator> {
  /*Widget buildMenuBar(Navigation navigation, int column) {
    return Row(children: [
      TextButton(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontSize: 12),
        ),
        onPressed: () {
          navigation.close(column);
        },
        child: const Text('Close'),
      ),
    ], mainAxisAlignment: MainAxisAlignment.end);
  }
  */



  Widget build(BuildContext context) {
    final navigation = Provider.of<Navigation>(context);
    List<Widget> columns = [];

    List<dynamic> columnsExpr = widget.arguments[0];

    for (var i = 0; i < columnsExpr.length; i++) {
      void onTap(AbstractionReference aref) {
        var newColumns = columnsExpr;

        if (newColumns.length > i + 1) {
          newColumns.removeRange(i + 1, newColumns.length);
        }
        newColumns.add(Navigation.makeNoteViewerExpr(aref));
        var expr = Navigation.makeColumnExpr(newColumns);
        navigation.pushExpr(expr);
      }

      columns.add(
        ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 20, 0),
                child: ListView(
                  //shrinkWrap: true,
                  children: [
                    //buildMenuBar(navigation, i),
                    IPTFactory.getRootTransform(columnsExpr[i], onTap)
                  ],
                ))),
      );
    }

    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        Row(
          children: columns,
        )
      ],
    );
  }
}
