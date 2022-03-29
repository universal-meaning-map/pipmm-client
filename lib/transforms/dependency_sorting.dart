import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/note.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/plain_text_run.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/static_transclusion_run.dart';
import 'package:ipfoam_client/utils.dart';

class DependencySorting implements IptRender, IptTransform {
  AbstractionReference aref = AbstractionReference.fromText("");
  int level = 0;
  Function onTap;
  Map<String, Dependency> dependencies = {};

  @override
  String transformIid = Note.iidDependencySorting;
  @override
  List<dynamic> arguments;

  DependencySorting(this.arguments, this.onTap) {
    processArguments();
  }

  void processArguments() {
    //Note to transclude
    if (arguments.length == 0) {
      aref = AbstractionReference.fromText("");
    }

    aref = AbstractionReference.fromText(arguments[0]);
  }

  processSelf(Note note, AbstractionReference selfAref, Function subscribeChild,
      int level) {
    dependencies[selfAref.iid!] ??= Dependency();
    // pir
    if (note.block[Note.iidPropertyPir] != null) {
      dependencies[selfAref.iid]!.pir =
          note.block[Note.iidPropertyPir] as double;
    }
    //missing pointer
    if (note.block[Note.iidPropertyName] != null) {
      dependencies[selfAref.iid]!.hasPointer = 1;
      dependencies[selfAref.iid]!.name = note.block[Note.iidPropertyName];
    }

    //each property
    note.block.forEach((tiid, value) {
      subscribeChild(tiid);
      // List<String> dependencies = [];
      var typeNote = Utils.getNote(AbstractionReference.fromText(tiid));
      if (typeNote == null) {
        return;
      }

      if (Utils.getBasicType(typeNote) == Note.basicTypeInterplanetaryText) {
        //print(typeNote.block["defaultName"]);

        for (var run in value) {
          var iptRun = IPTFactory.makeIptRun(run, onTap);
          if (iptRun.isStaticTransclusion()) {
            var depAref = (iptRun as StaticTransclusionRun).aref;

            //first time dependency
            if (dependencies[depAref.iid] == null) {
              if (depAref.isIid()) {
                subscribeChild(depAref.iid);

                var depNote = Utils.getNote(depAref);
                if (depNote != null) {
                  processSelf(depNote, depAref, subscribeChild, level + 1);
                  //children pointers
                }
              }
            }
            //ref to itself are not dependencies
            if (depAref.iid != selfAref.iid) {
              //total dependencies
              dependencies[selfAref.iid]!.totalDependencies =
                  dependencies[selfAref.iid]!.totalDependencies + 1;
              //level

              if (dependencies[depAref.iid] != null) {
                dependencies[depAref.iid]!.levels.add(level);
                dependencies[selfAref.iid]!.childrenWithPointer +=
                    dependencies[depAref.iid]!.hasPointer;
              }
            }
          } else if (iptRun.isDynamicTransclusion()) {
            print("Dependency sorting ignoring dynamic transclusion");
          }
        }
      }
    });
    if (dependencies[selfAref.iid] != null) {
    /*  print(spaceForLevel(level) +
          dependencies[selfAref.iid]!.name +
          ", " +
          dependencies[selfAref.iid]!.hasPointer.toString() + 
          ", " +
          dependencies[selfAref.iid]!.childrenWithPointer.toString() +
          ", " +
          dependencies[selfAref.iid]!.pir.toString());
    */
    }
  }

  String spaceForLevel(int level) {
    var t = "";
    for (var i = 0; i <= level; i++) {
      t = t + "  ";
    }
    return t;
  }

  @override
  TextSpan renderTransclusion(Function subscribeChild) {
    dependencies = {};

    if (aref.isIid()) {
      subscribeChild(aref.iid);
    } else {
      if (aref.isCid()) {
        subscribeChild(aref.cid);
      }
    }
    var note = Utils.getNote(aref);
    if (note != null) {
      processSelf(note, aref, subscribeChild, 0);
    }

    print("\n\n\n");

    return renderAsSortedList(subscribeChild);
  }

  double getCompletnessScore(Dependency d) {
    var childrenPointerPercentage = d.totalDependencies == 0
        ? 1
        : d.childrenWithPointer / d.totalDependencies;

    var cs = d.hasPointer * childrenPointerPercentage * d.pir;
    var dilution = 0.95;

    double total = 0;

    for (var l in d.levels) {
      total = total + (pow( dilution, l) * (1 - cs));
    }

    return total;
  }

  TextSpan renderAsSortedList(Function subscribeChild) {
    var iptRuns = [];
    var mapEntries = dependencies.entries.toList()
      ..sort((a, b) {
        var aScore = getCompletnessScore(a.value);
        var bScore = getCompletnessScore(b.value);
        return bScore.compareTo(aScore);
      });

    mapEntries.forEach((e) {
      var prefix =
          ((getCompletnessScore(e.value) * 10).round() / 10).toString() + "\t";

      iptRuns.add(PlainTextRun(prefix));
      iptRuns.add(
          StaticTransclusionRun([e.key + "/" + Note.iidPropertyName], onTap));
      iptRuns.add(PlainTextRun("\n"));
      getCompletnessScore(e.value).toString() +
          " - " +
          e.value.name +
          " " +
          e.value.totalDependencies.toString() +
          "\n";
    });

    List<TextSpan> elements = [];
    for (var ipte in iptRuns) {
      elements.add(ipte.renderTransclusion(subscribeChild));
    }

    return TextSpan(
        children: elements,
        style: TextStyle(
            // fontWeight: FontWeight.w300,
            ));
  }
}

class Dependency {
  String name = "";
  double pir = 1;
  int hasPointer = 0;
  int totalDependencies = 0;
  int childrenWithPointer = 0;
  List<int> levels = [];
  //children pir?
}
