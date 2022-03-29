import 'package:flutter/material.dart';
import 'package:ipfoam_client/main.dart';
import 'package:ipfoam_client/note.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';
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
    //if (level > 2) return;
    if (note == null) {
      return;
    }
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
      print(spaceForLevel(level) +
          dependencies[selfAref.iid]!.name +
          ", " +
          dependencies[selfAref.iid]!.levels.toString());
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

    return renderAsSortedList();
  }

  double getCompletnessScore(Dependency d) {
    var childrenPointerPercentage = d.totalDependencies == 0
        ? 1
        : d.childrenWithPointer / d.totalDependencies;

    /* print(d.hasPointer.toString() +
        " * (" +
        childrenPointerPercentage.toString() +
        " / " +
        d.totalDependencies.toString() +
        ") * " +
        d.pir.toString());
*/
    return d.hasPointer * childrenPointerPercentage * d.pir;
  }

  TextSpan renderAsSortedList() {
    var mapEntries = dependencies.entries.toList()
      ..sort((a, b) {
        var aScore = getCompletnessScore(a.value);
        var bScore = getCompletnessScore(b.value);
        return aScore.compareTo(bScore);
      });

    var t = "";
    mapEntries.forEach((e) {
      t = t +
          getCompletnessScore(e.value).toString() +
          " - " +
          e.value.name +
          " " +
          e.value.totalDependencies.toString() +
          "\n";
    });

    return TextSpan(
        text: t,
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
