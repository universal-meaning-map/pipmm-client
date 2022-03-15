import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class Config {
  String remoteServer = "";
  String defaultExpr = "";

  loadConfig(Function onLoaded) async {
    var data = await rootBundle.loadString('config.json');
    final jsonResult = jsonDecode(data);

    remoteServer = jsonResult["remoteServer"];
    defaultExpr = jsonResult["defaultExpr"];

    onLoaded();
  }
}
