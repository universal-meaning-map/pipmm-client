import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ipfoam_client/bridge.dart';
import 'package:ipfoam_client/config.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/navigation.dart';
import 'package:ipfoam_client/repo.dart';
import 'dart:html' as Html;

class Square {
  Bridge bridge;
  Repo repo;
  Navigation navigation;
  BuildContext context;
  Config config;

  Square(this.context, this.repo, this.navigation, this.bridge, this.config) {
    navigation.onExprPushed = onExprPushed;

    Html.window.onHashChange.listen((e) {
      processRoute();
    });

    config.loadConfig(() {
      repo.remoteServer = config.remoteServer;
      processRoute();

    });
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
    var runEncoded = uri.queryParameters['expr'];
    runEncoded ??= config.defaultExpr;

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
      route = route + "websocketsPort=" + bridge.websocketsPort + "&";
    }

    if (repo.localServerPort != "") {
      route = route + "localServerPort=" + repo.localServerPort + "&";
    }

    route = route + "expr=" + json.encode(expr);
    Html.window.location.hash = route;
  }
}
