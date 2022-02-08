import 'package:flutter/material.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/repo.dart';
import 'package:ipfoam_client/note.dart';
import 'package:provider/provider.dart';

class AbstractionReferenceLink extends StatelessWidget {
  final AbstractionReference aref;

  AbstractionReferenceLink({required this.aref});

  Widget buildText(String str) {
    return Text(str,
        textAlign: TextAlign.left,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            fontWeight: FontWeight.normal, color: Colors.black, fontSize: 20));
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<Repo>(context);

    IidWrap? iidWrap;
    CidWrap? cidWrap;
    String str;

    if (aref.isIid()) {
      iidWrap = repo.getCidWrapByIid(aref.iid!);
      str = aref.iid!;
      if (iidWrap.cid != null) {
        str = iidWrap.cid!;
        cidWrap = repo.getNoteWrapByCid(iidWrap.cid!);
      }
    } else if (aref.isCid()) {
      cidWrap = repo.getNoteWrapByCid(aref.cid!);
      str = aref.cid!;
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
