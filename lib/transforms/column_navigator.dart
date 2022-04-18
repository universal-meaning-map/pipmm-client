import 'package:flutter/material.dart';
import 'package:ipfoam_client/config.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/navigation.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';

class ColumnNavigator extends StatefulWidget implements RootTransform {
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
  Widget build(BuildContext context) {
    if (widget.arguments.isEmpty) {
      return const Text('(╯°□°)╯︵ ┻━┻');
    }
    List<dynamic> columnsExpr = widget.arguments[0];

    return LayoutBuilder(builder: (context, constrains) {
      double fullColumWidth = 600;
      double viewPortFractionOnMobile = 0.9;
      double columnWidth = fullColumWidth;
      double columnRightSidePadding = 30;
      double firstColumnRightSidePadding = 30;

      var f = fullColumWidth /
          constrains.maxWidth; //expands the viewportFraction lienearly
      //Mobile
      bool isMobile = constrains.maxWidth <
          fullColumWidth + fullColumWidth * (1 - viewPortFractionOnMobile);
      if (isMobile) {
        f = viewPortFractionOnMobile;
        columnWidth = f * fullColumWidth;
        columnRightSidePadding = 5;
        firstColumnRightSidePadding = 5;
      }

      var pageController = PageController(keepPage: true, viewportFraction: f);

      return PageView.builder(
        padEnds: false,
        controller: pageController,
        itemCount: columnsExpr.length,
        itemBuilder: (context, index) {
          void onTap(AbstractionReference aref) {
            var newColumns = columnsExpr;
            if (newColumns.length > index + 1) {
              newColumns.removeRange(index + 1, newColumns.length);
            }
            newColumns.add(Navigation.makeTransformExpr(
                Config.openAbstractionsInTransform, aref));
            var expr = Navigation.makeColumnExpr(newColumns);
            Navigation.pushExpr(expr);

            double newOffset = 0;

            if (constrains.maxWidth < newColumns.length * columnWidth) {
              var c = columnWidth;
              if(isMobile){
                c = constrains.maxWidth*f;
              }
              newOffset = newColumns.length * c - constrains.maxWidth;
            }

            pageController.animateTo(newOffset,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutQuad);
          }

          double columnLeftSidePadding = 0;
          if (index == 0) {
            columnLeftSidePadding = firstColumnRightSidePadding;
          }

          return Padding(
            key: Key(index.toString()),
            padding: EdgeInsets.fromLTRB(
                columnLeftSidePadding, 0, columnRightSidePadding, 0),
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 30, 0, 30),
                  child: IPTFactory.getRootTransform(columnsExpr[index], onTap),
                )
              ],
            ),
          );
        },
      );
    });
  }
}
