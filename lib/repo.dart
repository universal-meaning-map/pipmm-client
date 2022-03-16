import 'package:flutter/foundation.dart';
import 'package:ipfoam_client/note.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ipfoam_client/utils.dart';

class Repo with ChangeNotifier {
  static Map<String, CidWrap> cids = {};
  static Map<String, IidWrap> iids = {};
  static Map<String, List<Function>> subscriptors = {};
  static String localServerPort = "";
  static String remoteServer = "";

  Repo();

  static void addNoteForCid(String cid, Note? note) {
    //log("addNoteForCid");
    if (Utils.cidIsValid(cid) == false) {
      throw ("Empty cid can't arrive here");
    }
    cids[cid] ??= CidWrap(cid);
    cids[cid]?.note = note;
    var oldStatus = cids[cid]?.status;
    if (note == null) {
      cids[cid]?.status = RequestStatus.missing;
    } else {
      cids[cid]?.status = RequestStatus.loaded;
    }
    if (oldStatus != cids[cid]?.status) {
      notifySubscriptors(cid);
    }
    //log("Server. CID:" + cid + " Status: " + cids[cid]!.status.toString());
  }

  static void addCidForIid(String iid, String cid) {
    iids[iid] ??= IidWrap(iid);
    iids[iid]?.cid = cid;
    var oldStatus = iids[iid]?.status;

    if (Utils.cidIsValid(cid) == false) {
      iids[iid]?.status = RequestStatus.missing;
    } else {
      iids[iid]?.status = RequestStatus.loaded;
    }

    if (oldStatus != iids[iid]?.status) {
      notifySubscriptors(iid);
    }
    //log("Added iid " +iid +"CID: " +cid +" Status: " +iids[iid]!.status.toString());
  }

  static addSubscriptor(String cidOrIid, Function? onNotifyUpdate) {
    if (onNotifyUpdate == null) {
      return;
    }
    if (subscriptors[cidOrIid] == null) {
      subscriptors[cidOrIid] = [];
    }
    subscriptors[cidOrIid]!.add(onNotifyUpdate);
  }

  static CidWrap getNoteWrapByCid(String cid, Function notifyUpdate) {
    addSubscriptor(cid, notifyUpdate);
    if (Utils.cidIsValid(cid) == false) {
      return CidWrap.invalid(cid);
    }

    cids[cid] ??= CidWrap(cid);
    //log("Transform. CID:" + cid + " Status: " + cids[cid]!.status.toString());
    if (cids[cid]!.status == RequestStatus.undefined) {
      cids[cid]!.status = RequestStatus.needed;
    }

    return cids[cid]!;
  }

  static IidWrap getCidWrapByIid(String iid, Function? notifyUpdate) {
    addSubscriptor(iid, notifyUpdate);
    if (Utils.iidIsValid(iid) == false) {
      return IidWrap.invalid(iid);
    }

    iids[iid] ??= IidWrap(iid);

    //log("Transform start. IID: " +iid +" Status: " + iids[iid]!.status.toString());
    if (iids[iid]!.status == RequestStatus.undefined) {
      iids[iid]!.status = RequestStatus.needed;
    }

    //log("Transform end. IID: " +iid +" Status: " +iids[iid]!.status.toString());
    // TODO this does not belong here
    if (iids[iid]!.status == RequestStatus.needed) fetchIIds();

    return iids[iid]!;
  }

  static IidWrap forceRequest(String iid) {
    var wrap = getCidWrapByIid(iid, null); //ensure is created first
    print("current status for: " + iid + wrap.status.toString());
    iids[iid]!.status = RequestStatus.needed;
    return wrap;
  }

  static Future<void> fetchIIds() async {
    List<String> iidsToLoad = [];

    Repo.iids.forEach((iid, entry) {
      if (entry.status == RequestStatus.needed) {
        iidsToLoad.add(iid);
        entry.lastRequest = DateTime.now();
        entry.status = RequestStatus.requested;
      }
    });

    //print("Server requesting " + iidsToLoad.toString());

    if (iidsToLoad.isEmpty) {
      print("Nothing to fetch");
      return;
    }

    //var remoteServer = "https://ipfoam-server-dc89h.ondigitalocean.app/iids/";
    var localServer = "http://localhost:" + localServerPort + "/iids/";
    var iidsEndPoint = localServer + iidsToLoad.join(",");

    if (localServerPort == "") {
      print("No local server specified, using remote:" + remoteServer);
      iidsEndPoint = remoteServer + iidsToLoad.join(",");
      if (remoteServer == "") {
        print("No remote server specified. Can't work");
        return;
      }
    }

    var uri = Uri.parse(iidsEndPoint);
    try {
      var result = await http.get(uri);

      Map<String, dynamic> body = json.decode(result.body);
      //log(body.toString());
      Map<String, dynamic> cids = body["data"]["cids"];
      Map<String, dynamic> blocks = body["data"]["blocks"];
      cids.forEach((iid, cid) {
        addCidForIid(iid, cid);
        if (Utils.cidIsValid(cid)) {
          if (Utils.blockIsValid(blocks[cid])) {
            Map<String, dynamic> block = blocks[cid];
            Note note = Note(cid: cid, block: block);
            addNoteForCid(cid, note);

            //List<String> dependencies = [];
            // dependencies.addAll(Utils.getIddTypesForBlock(block));
          }
        }
      });
    } catch (e) {
      print("Failed to connect to server: " +
          uri.toString() +
          "Error: " +
          e.toString());
    }
  }

  static notifySubscriptors(String cidOrIid) {
    if (subscriptors[cidOrIid] != null) {
      for (var s in subscriptors[cidOrIid]!) {
        s();
      }
    }
    print(subscriptors.length);
  }
}

//undefined: default state. Is only in this state if no action has been done
//needed: A Transform manifested it wants it. But no attempt of getting it  has been done
//requested: It has been requested to an outside source but have not response yet
//missing: The outside source has returned an emptty request , regardless of the reason. Should not expect the source to have it under the same conditions
//loaded: Its loaded and stred in Repo
//failed: The request failed (ex: connectivity issues).
//invalid: The item requested or the content returned is invalid
enum RequestStatus {
  undefined,
  needed,
  requested,
  missing,
  loaded,
  failed,
  invalid
}

class CidWrap {
  DateTime? lastRequest;
  RequestStatus status = RequestStatus.undefined;
  String cid;
  Note? note;

  CidWrap(this.cid);
  CidWrap.invalid(this.cid) {
    status = RequestStatus.invalid;
  }
}

class IidWrap {
  DateTime? lastRequest;
  RequestStatus status = RequestStatus.undefined;
  String iid;
  String? cid;

  IidWrap(this.iid);
  IidWrap.invalid(this.iid) {
    status = RequestStatus.invalid;
  }
}
