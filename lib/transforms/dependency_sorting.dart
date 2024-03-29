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
  int maxLevel = 15;
  Function onTap;
  Map<String, Dependency> dependencies = {};

  @override
  String transformIid = Note.iidDependencySorting;
  @override
  List<dynamic> arguments;
  String? dependencyType;

  DependencySorting(this.arguments, this.onTap) {
    processArguments();
  }

  void processArguments() {
    //Note to transclude
    if (arguments.isEmpty) {
      aref = AbstractionReference.fromText("");
    }

    aref = AbstractionReference.fromText(arguments[0]);
    if (arguments.length >= 2) {
      dependencyType = arguments[1];
    }
  }

  processSelf(Note note, AbstractionReference selfAref, Function subscribeChild,
      int level) {
    if (level > maxLevel) {
      return;
    }
    dependencies[selfAref.iid!] ??= Dependency();
    // pir
    if (level == 0) {
      dependencies[selfAref.iid!]!.levels.add(0);
    }
    if (note.block[Note.iidPropertyPir] != null) {
      dependencies[selfAref.iid]!.pir =
          note.block[Note.iidPropertyPir] as double;
    }
    //missing pointer
    if (note.block[Note.iidPropertyName] != null) {
      dependencies[selfAref.iid]!.hasPointer = 1;
      dependencies[selfAref.iid]!.name = note.block[Note.iidPropertyName];
    }

    dependencies[selfAref.iid]!.selfProcessed = true;

    //each property
    if (dependencyType != null) {
      //only process explicit type
      if (note.block[dependencyType] != null) {
        processDependency(selfAref, dependencyType!, note.block[dependencyType],
            level, subscribeChild);
      }
    } else {
      // process all interplanetary text types
      note.block.forEach((tiid, value) {
        processDependency(selfAref, tiid, value, level, subscribeChild);
      });
    }

    //childrenWithPointer
  }

  processDependency(AbstractionReference selfAref, String tiid, dynamic value,
      int level, Function subscribeChild) {
    subscribeChild(tiid);
    // List<String> dependencies = [];

    var typeNote = Utils.getNote(AbstractionReference.fromText(tiid));
    if (typeNote == null) {
      return;
    }

    if (Utils.getBasicType(typeNote) == Note.basicTypeInterplanetaryText) {
      for (var run in value) {
        var iptRun = IPTFactory.makeIptRun(run, onTap);
        if (iptRun.isStaticTransclusion()) {
          var depAref = (iptRun as StaticTransclusionRun).aref;

          dependencies[selfAref.iid]!.dependenciesIIds.add(depAref.iid!);
          //first time dependency
          if (dependencies[depAref.iid] == null) {
            if (depAref.isIid()) {
              subscribeChild(depAref.iid);

              var depNote = Utils.getNote(depAref);
              if (depNote != null) {
                processSelf(depNote, depAref, subscribeChild, level + 1);
              }
            }
          }
          //ref to itself are not dependencies
          if (depAref.iid != selfAref.iid) {
            //total dependencies
            dependencies[selfAref.iid]!.totalDependencies =
                dependencies[selfAref.iid]!.totalDependencies + 1;
            if (dependencies[depAref.iid] != null) {
              //level
              dependencies[depAref.iid]!.levels.add(level);
            }
          }
        } else if (iptRun.isDynamicTransclusion()) {
          // print( "Dependency sorting for dynamic transclusion not implemented");
        }
      }
    }
  }

  void compileDependencies() {
    dependencies.forEach((parentIid, dep) {
      if (dependencies[parentIid] != null &&
          dependencies[parentIid]!.dependenciesWithPointer == 0) {
        for (var dependentIiid in dependencies[parentIid]!.dependenciesIIds) {
          if (dependencies[dependentIiid] != null) {
            dependencies[parentIid]!.dependenciesWithPointer =
                dependencies[parentIid]!.dependenciesWithPointer +
                    dependencies[dependentIiid]!.hasPointer;
          }
        }
      }
    });
  }

  String spaceForLevel(int level) {
    var t = "";
    for (var i = 0; i <= level; i++) {
      t = t + "  ";
    }
    return t;
  }

  double getDependenciesWithPointerPercentage(Dependency d) {
    double dependenciesPointerPercentage = d.totalDependencies == 0
        ? 1
        : d.dependenciesWithPointer / d.totalDependencies;

    return dependenciesPointerPercentage;
  }

  double getCompletnessScore(Dependency d) {
    var cs = d.hasPointer * getDependenciesWithPointerPercentage(d) * d.pir;
    return cs;
  }

  double getRequiredCareScore(Dependency d) {
    var cs = getCompletnessScore(d);
    var dilution = 0.2;
    double total = 0; //level 0

    for (var l in d.levels) {
      if (l <= maxLevel) {
        if (l == 0) {
          total = total + 1 - cs;
        } else {
          total = total + (pow(dilution, l) * (1 - cs));
        }
      }
    }

    return total;
  }

  double round(r, decimals) {
    if (decimals == 1)
      return (r * 100).round() / 100;
    else
      return (r * 10).round() / 10;
  }

  String addPad(String str, int max) {
    var blank = "";
    for (var i = str.length; i < max; i++) {
      blank = blank + " ";
    }
    return blank;
  }

  String withPad(String str, int max) {
    return str + addPad(str, max);
  }

  List<dynamic> makeRow(String iid, Dependency dep) {
    var iptRuns = [];
    var crs = round(getRequiredCareScore(dep), 2).toString();
    //var crs="0,4rs";
    iptRuns.add(PlainTextRun(withPad(crs, 5)));

    iptRuns
        .add(StaticTransclusionRun([iid + "/" + Note.iidPropertyName], onTap));
    var namePad = dep.name == ""
        ? 35 - 8
        : 35; //for the ones missing name we pad the liid
    iptRuns.add(PlainTextRun(addPad(dep.name, namePad) +
        withPad(round(getCompletnessScore(dep), 1).toString(), 5) +
        withPad(dep.pir.toString(), 5) +
        withPad(dep.totalDependencies.toString(), 4) +
        withPad(
            round(getDependenciesWithPointerPercentage(dep), 1).toString(), 4) +
        "\n"));

    return iptRuns;
  }

  TextSpan renderAsSortedList(Function subscribeChild) {
    var mapEntries = dependencies.entries.toList()
      ..sort((a, b) {
        var aScore = getRequiredCareScore(a.value);
        var bScore = getRequiredCareScore(b.value);
        return bScore.compareTo(aScore);
      });

    var iptRuns = [];
    iptRuns.add(PlainTextRun("Required care for "));
    iptRuns.add(
        StaticTransclusionRun([aref.iid! + "/" + Note.iidPropertyName], onTap));
    iptRuns.add(PlainTextRun("\n\n" +
        withPad("RC", 5) +
        withPad("Note", 35) +
        withPad("C", 5) +
        withPad("PIR", 5) +
        withPad("Dep", 4) +
        withPad("DWP", 4) +
        "\n"));

    for (var i = 0; i <= mapEntries.length; i++) {
      iptRuns.addAll(makeRow(mapEntries[i].key, mapEntries[i].value));

      var listCut = 0.05;
      if (getRequiredCareScore(mapEntries[i].value) < listCut) {
        iptRuns.add(PlainTextRun("+" +
            (mapEntries.length - i).toString() +
            " with RC > " +
            listCut.toString() +
            " and maxLevel " +
            maxLevel.toString() +
            "\n\nRC: Required care (Σ level ((1-C) * DilutionFactor^Level )\nC: Completness (PIR * HasPointer *DWP)\nPIR: Projection to intent ratio\nDep: Number of dependencies\nDWP: % of dependencies with pointer"));
        break;
      }
    }

    List<TextSpan> elements = [];
    for (var ipte in iptRuns) {
      elements.add(ipte.renderTransclusion(subscribeChild));
    }

    return TextSpan(
      children: elements,
    );
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
      compileDependencies();
    }

    return renderAsSortedList(subscribeChild);
  }
}

class Dependency {
  String name = "";
  double pir = 0;
  int hasPointer = 0;
  int totalDependencies = 0;
  List<String> dependenciesIIds = [];
  int dependenciesWithPointer = 0;
  List<int> levels = [];
  bool selfProcessed = false;
  //children pir?
}
