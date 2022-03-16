import 'package:flutter/material.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/note.dart';
import 'package:ipfoam_client/repo.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/plain_text_run.dart';
import 'package:ipfoam_client/transforms/sub_abstraction_block.dart';
import 'package:ipfoam_client/utils.dart';

class DynamicTransclusionRun implements IptRun {
  @override
  List<IptRun> iptRuns = []; //TODO unused?
  late AbstractionReference transformAref;
  List<dynamic> arguments = [];
  Function onTap;
  Function onRepoUpdate;

  DynamicTransclusionRun(List<dynamic> expr, this.onTap, this.onRepoUpdate) {
    transformAref = AbstractionReference.fromText(expr[0]);
    arguments = expr.sublist(1, expr.length);
  }

  @override
  bool isStaticTransclusion() {
    return false;
  }

  @override
  bool isDynamicTransclusion() {
    return true;
  }

  @override
  bool isPlainText() {
    return false;
  }

  @override
  TextSpan renderTransclusion(Repo repo) {
    var transformNote = Utils.getNote(transformAref, null);
    var text = "<Dynamic transclusion not found: " + transformAref.origin + ">";
    if (transformNote != null) {
      if (transformNote.block[Note.iidPropertyTransform]) {
        return applyTransform(
            transformNote.block[Note.iidPropertyTransform], repo);
      } else {
        text = "<dynamic transclusion with unkown transform: " +
            transformAref.origin +
            ">";
      }
    }

    return TextSpan(
        text: text,
        style: const TextStyle(
          fontWeight: FontWeight.w300,
        ));
  }

  TextSpan applyTransform(String transformId, Repo repo) {
    IptRender transform = PlainTextRun("<" + transformId + " not implemented>");
    if (transformId == Note.transFilter) {
      //TODO
    } else if (transformId == Note.transSubAbstractionBlock) {
      transform = SubAbstractionBlock(arguments, repo, onTap, onRepoUpdate);
    }

    return transform.renderTransclusion(repo);
  }
}
