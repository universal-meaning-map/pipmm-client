import 'dart:collection';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/repo.dart';
import 'package:ipfoam_client/note.dart';
import 'package:ipfoam_client/transforms/abstraction_reference_link.dart';
import 'package:ipfoam_client/transforms/hyperlink.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';
import 'package:ipfoam_client/utils.dart';
import 'package:provider/provider.dart';

class NoteViewer extends StatelessWidget implements RootTransform {
  late String iid;
  List<dynamic> arguments;
  Function onTap;

  NoteViewer({
    required this.arguments,
    required this.onTap,
    Key? key,
  }) : super(key: key) {
    iid = arguments[0];
  }

  String getStatusText(String? iid, String? cid, Note? note) {
    return "IID: " +
        iid.toString() +
        "\nCID: " +
        cid.toString() +
        "\nNOTE: " +
        note.toString();
  }

  Widget buildPropertyRow(String typeIid, dynamic content, Repo repo) {
    Note? typeNote;
    String propertyName = typeIid;
    String? cid = repo.getCidWrapByIid(typeIid).cid;
    if (cid != null) {
      typeNote = repo.getNoteWrapByCid(cid).note;
      if (typeNote != null) {
        propertyName = typeNote.block[Note.primitiveDefaultName];
      }
    } else {}

    return Container(
        child: Column(
      children: [
        buildPropertyText(propertyName),
        buildSpacing(2),
        buildContentByType(typeNote, content, repo),
        buildSpacing(10),
      ],
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
    ));
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

  Widget buildContentByType(Note? typeNote, dynamic content, Repo repo) {
    if (typeNote != null) {
      if (Utils.typeIsStruct(typeNote)) {
        return buildStruct(typeNote, content, repo);
      } else if (typeNote.block[Note.primitiveConstrains] != null) {
        //STRING
        if (Utils.getBasicType(typeNote) == Note.basicTypeString) {
        }
        //Abstraction reference link
        else if (Utils.getBasicType(typeNote) ==
            Note.basicTypeAbstractionReference) {
          return AbstractionReferenceLink(
              aref: AbstractionReference.fromText(content.toString()));
        }

        // List of Abstraction reference links
        else if (Utils.getBasicType(typeNote) ==
            Note.basicTypeAbstractionReferenceList) {
          List<AbstractionReferenceLink> items = [];
          content.forEach((element) {
            items.add(AbstractionReferenceLink(
                aref: AbstractionReference.fromText(element.toString())));
          });

          return ListView(
            children: items,
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
          );
        } else if (Utils.getBasicType(typeNote) == Note.basicTypeUrl) {
          return Hyperlink(url: content.toString());
        } else if (Utils.getBasicType(typeNote) == Note.basicTypeBoolean) {
          return buildContentRaw(typeNote, content.toString());
        } else if (Utils.getBasicType(typeNote) == Note.basicTypeDate) {
          return buildContentRaw(typeNote, content.toString());
        } else if (Utils.getBasicType(typeNote) ==
            Note.basicTypeInterplanetaryText) {
          List<String> ipt = [];

          for (var run in content) {
            log(run);
            ipt.add(run as String);
          }
          return IptRoot(ipt, onTap);
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
    final repo = Provider.of<Repo>(context);

    IidWrap iidWrap = repo.getCidWrapByIid(iid);

    if (iidWrap.cid == null) {
      return Text(getStatusText(iid, iidWrap.cid, null));
    }
    CidWrap cidWrap = repo.getNoteWrapByCid(iidWrap.cid!);

    if (cidWrap.note == null) {
      return Text(getStatusText(iid, iidWrap.cid, cidWrap.note));
    }

    var properties = cidWrap.note!.block;

// Sorting the properties based on how long the content is
    var sortedKeys = properties.keys.toList(growable: false)
      ..sort((k1, k2) => properties[k1]
          .toString()
          .length
          .compareTo(properties[k2].toString().length))
      ..reversed;
    LinkedHashMap sortedMap = LinkedHashMap.fromIterable(sortedKeys,
        key: (k) => k, value: (k) => properties[k]);

    List<Widget> items = [];

    sortedMap.forEach((key, value) {
      items.add(buildPropertyRow(key, value, repo));
    });

    return ListView(
        padding: const EdgeInsets.all(8),
        physics: ClampingScrollPhysics(),
        children: items,
        shrinkWrap: true,
        scrollDirection: Axis.vertical);
  }

  buildStruct(Note? typeNote, dynamic content, Repo repo) {
    List<Widget> items = [];

    content!.forEach((key, value) {
      items.add(buildPropertyRow(key, value, repo));
    });
    //return Text("Struct");
    return ListView(
      //shrinkWrap: true,
      scrollDirection: Axis.vertical,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      children: items,
    );
  }
}
