//import 'dart:io';
import 'dart:async';
import 'dart:math' as Math;
import 'package:less_dart/less.dart';
import 'package:path/path.dart' as path;
import 'vm_common.dart';

Future<Null> main(List<String> args) async{
  if (args.isNotEmpty) return mainJs();
  
  final Less less = new Less();
  final String sampleFile1 = "benchmark/big1.less";
  final String content = readSampleFile(sampleFile1);

  const int N = 1;
  for (int i = 0; i < N; i++) {
    final Stopwatch stopwatch = new Stopwatch()..start();
    await less.parseLessFile(content);
    print("Time: ${stopwatch.elapsedMilliseconds}");
    if (less.stderr.isNotEmpty){
      print("error: ${less.stderr}");
      print("----------------------");
    }
  }

//  mainJs();
}

// Less 2.7.1
Future<Null> mainJs() async{
  String file =  "benchmark/benchmark.less";
  Less less = new Less();
  String data = readSampleFile(file);
  print("Benchmarking...\n${path.basename(file)} (${data.length / 1024} KB)");

  List<int> benchMarkData = <int>[];

  int totalruns = 100;
  int ignoreruns = 30;

  for (int i = 0; i < totalruns; i++) {
    DateTime start = new DateTime.now();
    await less.parseLessFile(data);
    DateTime end = new DateTime.now();
    benchMarkData.add(end.difference(start).inMilliseconds);
//    if (err) {
//      less.writeError(err);
//      exit(3);
//    }
  }

  num totalTime = 0;
  num mintime = 9999999;
  num maxtime = 0;
  for(int i = ignoreruns; i < totalruns; i++) {
    totalTime += benchMarkData[i];
    mintime = Math.min(mintime, benchMarkData[i]);
    maxtime = Math.max(maxtime, benchMarkData[i]);
  }
  double avgtime = totalTime / (totalruns - ignoreruns);
  num variation = maxtime - mintime;
  double variationperc = (variation / avgtime) * 100;

  print("Min. Time: $mintime ms");
  print("Max. Time: $maxtime ms");
  print("Total Average Time: $avgtime ms (${1000 / avgtime *
          data.length / 1024} KB\/s)");
  print("+/- $variationperc%");
}
