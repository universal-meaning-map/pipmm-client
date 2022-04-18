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
  BuildContext context;
  Config config;

  String prevUrl = "";

  Square(this.context, this.repo, this.bridge, this.config,
      Function onConfigLoaded) {
    Navigation.onExprPushed = onExprPushed;

    Html.window.onHashChange.listen((e) {
      String newUrl = Uri.dataFromString(Html.window.location.href).toString();

      //something is triggering false events
      if (newUrl != prevUrl) {
        processRoute();
        prevUrl = newUrl;
      }
    });

    Config.loadConfig(() {
      Repo.remoteServer = Config.remoteServer;
      onConfigLoaded();
      processRoute();
    });
  }

  void onBridgeIid(String iid) {
    print("Pushing IID:" + iid + " from bridge");
    Repo.forceRequest(iid);
    Navigation.pushExpr(Navigation.makeColumnExpr(
        [Navigation.makeNoteViewerExpr(AbstractionReference.fromText(iid))]));
  }

  void processRoute() {
    var uri = Uri.dataFromString(Html.window.location.hash);

    final localServerPort = uri.queryParameters['localServerPort'];

    if (localServerPort != null && localServerPort != Repo.localServerPort) {
      Repo.localServerPort = localServerPort;
    }

    final websocketsPort = uri.queryParameters['websocketsPort'];
    if (websocketsPort != null && websocketsPort != bridge.websocketsPort) {
      bridge.startWs(onIid: onBridgeIid, port: websocketsPort);
    }
    var runEncoded = uri.queryParameters['expr'];
    runEncoded ??= Config.defaultExpr;

    var run = Uri.decodeFull(runEncoded);

    try {
      List<dynamic> expr = json.decode(run);
      Navigation.setExpr(expr);
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

    if (Repo.localServerPort != "") {
      route = route + "localServerPort=" + Repo.localServerPort + "&";
    }

    route = route + "expr=" + json.encode(expr) + "&";
    Html.window.location.hash = route;
  }
}
