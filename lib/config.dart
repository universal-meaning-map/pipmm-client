import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class Config {
  static String remoteServer = "";
  static String defaultExpr = "";
  static String title = "";
  static List<String> transclusionPropertiesPriority= [];
  static String openAbstractionsInTransform = "";
  static loadConfig(Function onLoaded) async {
    var data = await rootBundle.loadString('config.json');
    final jsonResult = jsonDecode(data);

    remoteServer = jsonResult["remoteServer"];
    defaultExpr = jsonResult["defaultExpr"];
    title = jsonResult["title"];
    transclusionPropertiesPriority = jsonResult["transclusionPropertiesPriority"];
    openAbstractionsInTransform = jsonResult["openAbstractionsInTransform"];

    onLoaded();
  }
}
