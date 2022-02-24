import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ipfoam_client/bridge.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/repo.dart';
import 'package:ipfoam_client/transforms/colum_navigator.dart';
import 'dart:html' as Html;

class Square {
  Bridge bridge;
  Repo repo;
  Navigation navigation;
  BuildContext context;

  Square(this.context, this.repo, this.navigation, this.bridge) {
    navigation.onExprPushed = onExprPushed;

    Html.window.onHashChange.listen((e) {
      processRoute();
    });

    processRoute();
  }

  void onBridgeIid(String iid) {
    print("Pushing IID:" + iid + " from bridge");
    repo.forceRequest(iid);

    navigation.pushExpr(Navigation.makeColumnExpr(
        [Navigation.makeNoteViewerExpr(AbstractionReference.fromText(iid))]));
  }

  void processRoute() {
    var uri = Uri.dataFromString(Html.window.location.href);

    final localServerPort = uri.queryParameters['localServerPort'];

    if (localServerPort != null && localServerPort != repo.localServerPort) {
      repo.localServerPort = localServerPort;
    }

    final websocketsPort = uri.queryParameters['websocketsPort'];
    if (websocketsPort != null && websocketsPort != bridge.websocketsPort) {
      bridge.startWs(onIid: onBridgeIid, port: websocketsPort);
    }
    final runEncoded = uri.queryParameters['expr'];

    if (runEncoded == null) {
      return;
    }

    var run = Uri.decodeFull(runEncoded);

    try {
      List<dynamic> expr = json.decode(run);
      navigation.setExpr(expr);
    } catch (e) {
      print("Unable to decode expr:" + run);
    }
  }

  void onExprPushed(List<dynamic> expr) {
    pushRoute(expr);
  }

  void pushRoute(List<dynamic> expr) {
    var route = "#?";
    if (bridge.websocketsPort != "") {
      route = route + "websocketsPort=" + bridge.websocketsPort +"&";
    }

    if (repo.localServerPort != "") {
      route = route + "localServerPort=" + repo.localServerPort+"&";
    }

    route = route + "expr=" + json.encode(expr);

    // Html.window.history.replaceState(null, "Interplanetary mind-map", route);
    Html.window.location.hash = route;
  }
}
