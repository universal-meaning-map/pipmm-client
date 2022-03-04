import 'package:flutter/material.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/navigation.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';
import 'package:provider/provider.dart';
import 'dart:html' as Html;

class PageNavigator extends StatefulWidget {
  // [[column1, column2], pref] or [[[column1 render, column1 note], [column2 render, column2 note]],pref]
  List<dynamic> arguments;
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
      double columWidth = 600;
      double viewPortFractionOnMobile = 0.9;

      var f = columWidth / constrains.maxWidth; //expands the viewportFraction lienearly
      if (constrains.maxWidth < columWidth+columWidth*(1-viewPortFractionOnMobile)) {
        f = viewPortFractionOnMobile;
        columWidth = f * columWidth;
      }

      var pageController = PageController(
          keepPage: false, viewportFraction: f, initialPage: widget.pos);

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
