import 'dart:io';
import 'dart:math' as Math;
import 'package:less_dart/less.dart';
import 'package:path/path.dart' as path;
import 'vm_common.dart';

main() async{
  Less less = new Less();
  var sampleFile1 = "benchmark/big1.less";
  var content = readSampleFile(sampleFile1);
//  for (var i = 0; i < 10 ; i++)
  {
    DateTime start = new DateTime.now();
    await less.parseLessFile(content);
    String newContent = less.stdout.toString();
      print("Time:${new DateTime.now().difference(start).inMilliseconds}");
//    print("new content: $newContent");
    print("error: ${less.stderr.toString()}");
      print("----------------------");
  }
//  mainJs();
}

// Less 2.7.1
mainJs() async{
  var file =  "benchmark/benchmark.less";
  Less less = new Less();
  var data = readSampleFile(file);
  print("Benchmarking...\n${path.basename(file)} (${data.length / 1024} KB)");

  var benchMarkData = <int>[];

  var totalruns = 100;
  var ignoreruns = 30;

  for(var i = 0; i < totalruns; i++) {
    var start = new DateTime.now();
    await less.parseLessFile(data);
    var end = new DateTime.now();
    benchMarkData.add(end.difference(start).inMilliseconds);
//    if (err) {
//      less.writeError(err);
//      exit(3);
//    }
  }

  var totalTime = 0;
  num mintime = 9999999;
  num maxtime = 0;
  for(var i = ignoreruns; i < totalruns; i++) {
    totalTime += benchMarkData[i];
    mintime = Math.min(mintime, benchMarkData[i]);
    maxtime = Math.max(maxtime, benchMarkData[i]);
  }
  var avgtime = totalTime / (totalruns - ignoreruns);
  var variation = maxtime - mintime;
  var variationperc = (variation / avgtime) * 100;

  print("Min. Time: $mintime ms");
  print("Max. Time: $maxtime ms");
  print("Total Average Time: $avgtime ms (${1000 / avgtime *
          data.length / 1024} KB\/s)");
  print("+/- $variationperc%");
}