part of transformer.less;

class LessTransformer extends BaseTransformer {

  LessTransformer(String inputContent, String inputFile, String outputFile, String buildMode)
      :super(inputContent, inputFile, outputFile, buildMode);

  Future<LessTransformer> transform(List<String> args) {
    timerStart();

    Completer task = new Completer();

    flags = args.sublist(0);
    switch (buildMode) {
      case BUILD_MODE_DART:
        args.add('-');
        break;
      case BUILD_MODE_MIXED:
        args.add(inputFile);
        break;
      case BUILD_MODE_LESS:
      default:
        args.add(inputFile);
        args.add(outputFile);
    }

    deliverToPipe = isBuildModeMixed || isBuildModeDart;

    runZoned((){
      Less less = new Less();
      less.stdin.write(inputContent);
      less.transform(args).then((exitCode){
        timerStop();
        if (exitCode == 0) {
          outputContent = less.stdout.toString();
          BaseTransformer.register[inputFile] = new RegisterItem(inputFile, less.imports, inputContent.hashCode);
        } else {
          outputContent = less.stderr.toString();
          errorMessage = less.stderr.toString();
          isError = true;
        }
        getMessage();
        task.complete(this);
      });
    },
    zoneValues: {#id: new Random().nextInt(10000)});

    return task.future;
  }
}