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
 // var pageController = PageController(viewportFraction: 1, keepPage: true);
  double prevF = 0;
  int pos = 0;
  double offset = 0;

  PageNavigator({
    required this.arguments,
    Key? key,
  }) : super(key: key);

  @override
  State<PageNavigator> createState() => PageNavigatorState();
}

class PageNavigatorState extends State<PageNavigator> {
  Widget build(BuildContext context) {
    final navigation = Provider.of<Navigation>(context);
    List<dynamic> columnsExpr = widget.arguments[0];

    return LayoutBuilder(builder: (context, constrains) {
      var w = 600;

      var f = w / constrains.maxWidth;
      if (constrains.maxWidth < 667) {
        f = 1;
      }

      if (f != widget.prevF) {
      }
      var pageController = PageController(keepPage: false, viewportFraction: f, initialPage: widget.pos);

      animate() {
        List<dynamic> columnsExpr = widget.arguments[0];
        if (columnsExpr.isNotEmpty) {
        }
      }
      

      if (widget.prevColumnsAmount != columnsExpr.length) {
        // Timer(Duration(milliseconds: 500), animate);
       // animate();
      }

      widget.prevF = f;
      widget.prevColumnsAmount = columnsExpr.length;
      var fullColumnsDisplayed =(columnsExpr.length*w/ constrains.maxWidth).floor();
      return PageView.builder(
        padEnds: false,
        
        onPageChanged: (_pos) {
          widget.pos = _pos;
        },
      
        controller: pageController,
        itemCount: columnsExpr.length,
        itemBuilder: (context, index) {
          void onTap(AbstractionReference aref) {
            widget.offset = pageController.position.pixels;
            var newColumns = columnsExpr;
            if (newColumns.length > index + 1) {
              newColumns.removeRange(index + 1, newColumns.length);
            }
            newColumns.add(Navigation.makeNoteViewerExpr(aref));
            var expr = Navigation.makeColumnExpr(newColumns);
            navigation.pushExpr(expr);
            pageController.jumpTo(widget.offset);
           /* pageController.animateTo(columnsExpr.length*w-fullColumnsDisplayed.toDouble(),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.linear);*/

          }

          return Padding(
              key: Key(index.toString()),
              padding: const EdgeInsets.fromLTRB(20, 0, 10, 0),
              child: ListView(
                children: [
                  IPTFactory.getRootTransform(columnsExpr[index], onTap)
                ],
              ));
        },
      );
    });
  }
}
