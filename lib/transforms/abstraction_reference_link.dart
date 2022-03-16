import 'package:flutter/material.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/repo.dart';
import 'package:ipfoam_client/note.dart';

class AbstractionReferenceLink extends StatefulWidget {
  final AbstractionReference aref;

  AbstractionReferenceLink({required this.aref});

  @override
  State<AbstractionReferenceLink> createState() =>
      _AbstractionReferenceLinkState();
}

class _AbstractionReferenceLinkState extends State<AbstractionReferenceLink> {
  initState() {
    super.initState();
  }

  onRepoUpdate() {
    setState(() {});
  }

  Widget buildText(String str) {
    return Text(str,
        textAlign: TextAlign.left,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            fontWeight: FontWeight.normal, color: Colors.black, fontSize: 20));
  }

  @override
  Widget build(BuildContext context) {
    IidWrap? iidWrap;
    CidWrap? cidWrap;
    String str = "";

    if (widget.aref.isIid()) {
      iidWrap = Repo.getCidWrapByIid(widget.aref.iid!, onRepoUpdate);
      str = widget.aref.iid!;
      if (iidWrap.cid != null) {
        str = iidWrap.cid!;
        cidWrap = Repo.getNoteWrapByCid(iidWrap.cid!, onRepoUpdate);
      }
    } else if (widget.aref.isCid()) {
      cidWrap = Repo.getNoteWrapByCid(widget.aref.cid!, onRepoUpdate);
      str = widget.aref.cid!;
    } else {
      str = "Null";
    }

    if (cidWrap != null &&
        cidWrap.note != null &&
        cidWrap.note!.block[Note.iidPropertyName] != null) {
      str = cidWrap.note!.block[Note.iidPropertyName];
    }

    return buildText(str);
  }
}
