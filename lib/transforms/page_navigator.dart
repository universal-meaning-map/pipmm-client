import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/navigation.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';
import 'package:provider/provider.dart';
import 'dart:html' as Html;

class PageNavigator extends StatefulWidget {
  // [[column1, column2], pref] or [[[column1 render, column1 note], [column2 render, column2 note]],pref]
  List<dynamic> arguments;
  int prevColumnsAmount = 0;

  PageNavigator({
    required this.arguments,
    Key? key,
  }) : super(key: key);

  @override
  State<PageNavigator> createState() => PageNavigatorState();
}

class PageNavigatorState extends State<PageNavigator> {
  Widget _build(BuildContext context) {
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

  Widget build(BuildContext context) {
    final navigation = Provider.of<Navigation>(context);
    List<dynamic> columnsExpr = widget.arguments[0];

    PageController pageController;

    return LayoutBuilder(builder: (context, constrains) {
      var w = 600;
      var f = w / constrains.maxWidth;
      pageController =
          PageController(viewportFraction: f, keepPage: false);

      animate() {
        final navigation = Provider.of<Navigation>(context);
        List<dynamic> columnsExpr = widget.arguments[0];
        print("Going to " + (columnsExpr[columnsExpr.length - 1]).toString());
        //pageController.jumpTo(columnsExpr.length.toDouble()-1);
        pageController.animateToPage(columnsExpr.length - 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutQuad);
      }

      if (widget.prevColumnsAmount != null &&
          widget.prevColumnsAmount != columnsExpr.length) {
            Timer(Duration(milliseconds: 10), animate);
      }

      return PageView.builder(
        controller: pageController,
        itemCount: columnsExpr.length,
        itemBuilder: (context, index) {
          void onTap(AbstractionReference aref) {
            var newColumns = columnsExpr;
            if (newColumns.length > index + 1) {
              newColumns.removeRange(index + 1, newColumns.length);
            }
            newColumns.add(Navigation.makeNoteViewerExpr(aref));
            var expr = Navigation.makeColumnExpr(newColumns);
            navigation.pushExpr(expr);

            // Timer(Duration(milliseconds: 1000), animate);
          }

          widget.prevColumnsAmount = columnsExpr.length;

          return Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 20, 0),
              child: ListView(
                //shrinkWrap: true,
                children: [
                  //buildMenuBar(navigation, i),
                  IPTFactory.getRootTransform(columnsExpr[index], onTap)
                ],
              ));
        },
      );
    });
  }
}




 /*Container(
          margin: EdgeInsets.all(10.0),
          color: Colors.amber[600],
          width: 300,
          //height: 48.0,
        )
        */