part of transformer.less;

class HtmlTransformer extends BaseTransformer{
  List elements;
  List<Future> runners = [];

  List<String> imports = []; // aggregate dependencies

  HtmlTransformer(String inputContent, String inputFile): super(
      inputContent.replaceAll(new RegExp(r'\r\n'), '\n'),
      inputFile, inputFile, null
  );

  ///
  /// Transforms the html contents replacing(or keeping also)all <less> tags by <style> tags
  /// with the less code converted to css.
  ///
  /// <less> tags could be remoded using attribute replace as <less replace>.
  /// If not replace attribute is used <less> get a new attribute style="display:none".
  ///
  /// All other attributes are copied to <style>.
  ///
  /// Example: <less no-shim> => <less no-shim style="display:none">  <style no-shim>
  ///
  Future<HtmlTransformer> transform(List<String> args) {
    timerStart();

    Completer task = new Completer();
    var element;

    flags = args.sublist(0);
    args.add('-');

    elements = parse(inputContent);

    for(int i = 0; i < elements.length; i++) {
      element = elements[i];
      if (element is LessElement) {
        runners.add(execute(element, args));
      }
    }

    Future.wait(runners).whenComplete((){
      outputContent = toString();
      timerStop();
      getMessage();

      if(!isError) {
        BaseTransformer.register[inputFile] = new RegisterItem(inputFile, imports, inputContent.hashCode);
      }

      task.complete(this);
    });
    return task.future;
  }

  ///
  /// Split content into html and less fragments
  ///
  /// [content] is the html file content
  ///
  List parse(String content) {
    RegExp lessTagReg = new RegExp(r'<less[^>]*>(.|\n)*?<\/less>');
    List result = [];
    LessElement element;
    int index = 0;

    Iterable<Match> fragments = lessTagReg.allMatches(content);
    if (fragments != null) {
      for(int i = 0; i < fragments.length; i++) {
        element = new LessElement(fragments.elementAt(i));
        if (element.openTagStart > index) {
          result.add(new FragmentElement(content, index, element.openTagStart));
          index = element.closeTagEnd;
        }
        result.add(element);
      }
      if (index < content.length) {
        result.add(new FragmentElement(content, index, content.length));
      }
    } else {
      result.add(new FragmentElement(content, index, content.length));
    }
    return result;
  }

  ///
  /// Transform less to css inside the [element]
  ///
  Future execute(LessElement element, List<String> args) {
    Completer task = new Completer();

    runZoned((){
      Less less = new Less();
      less.stdin.write(element.inner);
      less.transform(args).then((exitCode){
        if (exitCode == 0) {
          element.css = less.stdout.toString();
          imports.addAll(less.imports);
        } else {
          element.css = less.stderr.toString();
          errorMessage += element.css + '\n';
          isError = true;
        }
        task.complete();
      });
    },
    zoneValues: {#id: new Random().nextInt(10000)});
    return task.future;
  }

  ///
  /// Converts elements to html string
  ///
  String toString() {
    StringBuffer output = new StringBuffer();
    var element;

    if (elements.length == 1) deliverToPipe = false;

    for (int i = 0; i < elements.length; i++) {
      element = elements[i];
      if (element is FragmentElement) {
        output.write(element.toString());
      } else if (element is LessElement) {
        if (!element.isReplace) output.write(element.lessToString());
        output.write(element.cssToString());
      }
    }
    return output.toString();
  }
}

class LessElement {
  bool isReplace = false;
  String openTag;   // <less...>
  int openTagStart; // '<'  - absolute position to content file
  int openTagEnd;   // next to '>'

  String closeTag;  // </less>
  int closeTagStart;
  int closeTagEnd;

  String outer;      // <less...>...</less>
  String get inner => outer.substring(openTagEnd - openTagStart, closeTagStart - openTagStart);

  String cssOpenTag; // <style...>
  String css;  // result of less process

  String tabStr;  // '   '<less...  - distance to line start
  String tabStr2; // '     '        - distance to line start + 2

  RegExp openTagReg = new RegExp(r'<less[^>]*>');
  RegExp closeTagReg = new RegExp(r'<\/less>');

  LessElement(Match fragment) {
    openTagStart = fragment.start;
    closeTagEnd = fragment.end;
    outer = fragment[0];

    Match match = openTagReg.firstMatch(outer); //<less...>
    openTag = match[0];
    openTagEnd = openTagStart + match.end;

    match = closeTagReg.firstMatch(outer);  //</less>
    closeTag = match[0];
    closeTagStart = openTagStart + match.start;

    tabStr = getTabStr(fragment.input);
    tabStr2 = tabStr + '  ';

    //attributes
    cssOpenTag = openTag;
    cssOpenTag = cssOpenTag.replaceFirst('less', 'style');

    if (openTag.contains('replace')) {
      isReplace = true;
      cssOpenTag = cssOpenTag.replaceFirst('replace', '');
    }

    openTag = openTag.substring(0, openTag.length - 1) + ' style="display:none"' + '>';

    openTag = trimSpaces(openTag);
    cssOpenTag = trimSpaces(cssOpenTag);
  }

  ///
  /// Build the tab separator to tag
  ///
  String getTabStr(String content) {
    int tab = 0;

    for (int i = openTagStart - 1; i >= 0; i--) {
      if (content[i] != '\n') tab++; else break;
    }

    return ' ' * tab;
  }

  ///
  /// Removes inner double spaces
  ///
  String trimSpaces(content) {
    String result = content;
    while (result.indexOf('  ') != -1) {
      result = result.replaceAll('  ', ' ');
    }
    result = result.replaceFirst(' >', '>');
    return result;
  }

  ///
  /// Build the <less> element as string
  ///
  String lessToString() {
    return openTag + inner + '</less>';
  }

  ///
  /// Build the inner <style> element string, with the line tabs
  ///
  String tabCss(){
    StringBuffer resultBuffer = new StringBuffer();
    List<String> lines = css.split('\n');

    for(int i = 0; i < lines.length - 1; i++) {
      resultBuffer.writeln(tabStr2 + lines[i]);
    }

    return resultBuffer.toString();
  }

  ///
  /// Build the <style> element as string
  ///
  String cssToString() {
    String prefix = isReplace ? '' : '\n${tabStr}';

    return '${prefix}${cssOpenTag}\n${tabCss()}${tabStr}</style>';
  }
}

class FragmentElement {
  int start;
  int end;
  String outer;

  FragmentElement(String content, int this.start, int this.end) {
    outer = content.substring(start, end);
  }

  ///
  /// The fragment between <less> tags is delivered
  ///
  String toString() => outer;
}