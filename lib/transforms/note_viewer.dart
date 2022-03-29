import 'dart:collection';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:ipfoam_client/repo.dart';
import 'package:ipfoam_client/note.dart';
import 'package:ipfoam_client/transforms/hyperlink.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/ipt_root.dart';
import 'package:ipfoam_client/utils.dart';

class NoteViewer extends StatefulWidget implements RootTransform {
  late String iid;
  List<dynamic> arguments;
  Function onTap;
  bool propertiesSubscribed = false;

  NoteViewer({
    required this.arguments,
    required this.onTap,
    Key? key,
  }) : super(key: key) {
    iid = arguments[0];
  }

  @override
  State<NoteViewer> createState() => _NoteViewerState();
}

class _NoteViewerState extends State<NoteViewer> {
  @override
  initState() {
    super.initState();
    Repo.addSubscriptor(widget.iid, onRepoUpdate);
    subscribeToProperties();
  }

  onRepoUpdate() {
    if (widget.propertiesSubscribed == false) {
      subscribeToProperties();
    }
    setState(() {});
  }

  subscribeToProperties() {
    String? cid = Repo.getCidWrapByIid(widget.iid).cid;
    if (cid != null) {
      CidWrap cidWrap = Repo.getNoteWrapByCid(cid);
      if (cidWrap.note != null) {
        widget.propertiesSubscribed = true;
        var properties = cidWrap.note!.block;
        for (String tiid in properties.keys) {
          Repo.addSubscriptor(tiid, onRepoUpdate);
        }
      }
    }
  }

  List<String> children = [];

  subscribeChild(String cidOrIid) {
    if (children.contains(cidOrIid)) {
      return;
    }
    children.add(cidOrIid);
    Repo.addSubscriptor(cidOrIid, onRepoUpdate);
  }

  String getStatusText(String? iid, String? cid, Note? note) {
    return "IID: " +
        iid.toString() +
        "\nCID: " +
        cid.toString() +
        "\nNOTE: " +
        note.toString();
  }

  Widget buildPropertyRow(String typeIid, dynamic content) {
    Note? typeNote;
    String propertyName = typeIid;
    subscribeChild(typeIid);
    String? cid = Repo.getCidWrapByIid(typeIid).cid;
    if (cid != null) {
      typeNote = Repo.getNoteWrapByCid(cid).note;
      if (typeNote != null) {
        propertyName = typeNote.block[Note.primitiveDefaultName];
      }
    }

    if (typeNote == null) {
      return Column(
        children: [
          buildPropertyText(typeIid),
          buildSpacing(10),
        ],
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
      );
    }

    return Column(
      children: [
        buildPropertyText(propertyName),
        buildSpacing(2),
        buildContentByType(typeNote, content),
        buildSpacing(10),
      ],
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }

  Widget buildSpacing(double space) {
    return SizedBox(
      height: space,
    );
  }

  Widget buildPropertyText(String typeIid) {
    String str = typeIid;

    return Text(str,
        textAlign: TextAlign.left,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          fontSize: 14,
        ));
  }

  Widget buildContentByType(Note typeNote, dynamic content) {
    if (content != null) {
      if (Utils.typeIsStruct(typeNote)) {
        return buildStruct(typeNote, content);
      } else if (typeNote.block[Note.primitiveConstrains] != null) {
        //STRING
        if (Utils.getBasicType(typeNote) == Note.basicTypeString) {
          //WHY IS THIS EMPTY?
        }
        //Abstraction reference link
        else if (Utils.getBasicType(typeNote) ==
            Note.basicTypeAbstractionReference) {
          return IptRoot.fromExpr(
              [content.toString()], widget.onTap, ValueKey(content.toString()));
          //return AbstractionReferenceLink(aref: AbstractionReference.fromText(content.toString()));
        }

        // List of Abstraction reference links
        else if (Utils.getBasicType(typeNote) ==
            Note.basicTypeAbstractionReferenceList) {
          List<IptRoot> items = [];
          content.forEach((element) {
            items.add(IptRoot.fromExpr([element.toString()], widget.onTap,
                ValueKey(content.toString())));
          });

          return Column(
            children: items,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
          );
        } else if (Utils.getBasicType(typeNote) == Note.basicTypeUrl) {
          return Hyperlink(url: content.toString());
        } else if (Utils.getBasicType(typeNote) == Note.basicTypeBoolean) {
          return buildContentRaw(typeNote, content);
        } else if (Utils.getBasicType(typeNote) == Note.basicTypeDate) {
          return buildContentRaw(typeNote, content);
        } else if (Utils.getBasicType(typeNote) ==
            Note.basicTypeInterplanetaryText) {
          List<String> ipt = [];

          for (var run in content) {
            log(run);
            ipt.add(run as String);
          }
          return IptRoot(ipt, widget.onTap, ValueKey(ipt.toString()));
        }
      } else {
        return buildContentRaw(typeNote, content);
      }
    }
    return Text(content.toString());
  }

  Widget buildContentRaw(Note? typeNote, dynamic content) {
    return Text(content.toString(),
        textAlign: TextAlign.left,
        overflow: TextOverflow.visible,
        style: const TextStyle(
            fontWeight: FontWeight.normal, color: Colors.black));
  }

  @override
  Widget build(BuildContext context) {
    IidWrap iidWrap = Repo.getCidWrapByIid(widget.iid);

    if (iidWrap.cid == null) {
      return Text(getStatusText(widget.iid, iidWrap.cid, null));
    }
    CidWrap cidWrap = Repo.getNoteWrapByCid(iidWrap.cid!);

    if (cidWrap.note == null) {
      return Text(getStatusText(widget.iid, iidWrap.cid, cidWrap.note));
    }

    List<Widget> items = [];

/*
    cidWrap.note!.block.forEach((key, value) {
      items.add(buildPropertyRow(key, value));
    });
*/

// Sorting the properties based on how long the content is
    var properties = cidWrap.note!.block;
    var sortedKeys = properties.keys.toList(growable: false)
      ..sort((k1, k2) => properties[k1]
          .toString()
          .length
          .compareTo(properties[k2].toString().length))
      ..reversed;
    LinkedHashMap sortedMap = LinkedHashMap.fromIterable(sortedKeys,
        key: (k) => k, value: (k) => properties[k]);

    sortedMap.forEach((key, value) {
      items.add(buildPropertyRow(key, value));
    });

    return ListView(
        padding: const EdgeInsets.all(8),
        physics: const ClampingScrollPhysics(),
        children: items,
        shrinkWrap: true,
        scrollDirection: Axis.vertical);
  }

  Widget buildStruct(Note? typeNote, dynamic content) {
    List<Widget> items = [];
    content!.forEach((key, value) {
      items.add(buildPropertyRow(key, value));
    });

    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
            children: items,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start));
  }
}
