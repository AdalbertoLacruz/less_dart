part of transformer.less;

class HtmlTransformer extends BaseTransformer{
  List<ContentElement> elements;
  List<Future> runners = [];

  List<String> imports = []; // aggregate dependencies

  HtmlTransformer(String inputContent, String inputFile, Function modifyOptions): super(
      inputContent.replaceAll(new RegExp(r'\r\n'), '\n'),
      inputFile, inputFile, null, modifyOptions
  );

  ///
  /// Transforms the html contents replacing(or keeping also)all <less> tags by <style> tags
  /// with the less code converted to css.
  ///
  /// <less> tags could be remoded using attribute replace as <less replace>.
  /// If not replace attribute is used <less> get a new attribute style="display:none".
  ///
  /// All other attributes are copied to <style>.
  /// Alternatively <style type="text/less"> is similar to <less replace>
  ///
  /// Example: <less no-shim> => <less no-shim style="display:none">  <style no-shim>
  ///
  Future<HtmlTransformer> transform(List<String> args) {
    Completer task = new Completer();
    timerStart();

    flags = args.sublist(0);
    args.add('-');

    elements = parse(inputContent);
    elements.forEach((element){
      if (element.hasLessCode) runners.add(execute(element, args));
    });

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
    List<ContentElement> result = [];

    result.addAll(LessElement.parse(content));
    result.addAll(StyleElement.parse(content));
    result.sort((x, y) => x.openTagStart.compareTo(y.openTagStart));
    result = FragmentElement.parse(content, result);

    return result;
  }

  ///
  /// Transform less to css inside the [element]
  ///
  Future execute(ContentElement element, List<String> args) {
    Completer task = new Completer();

    runZoned((){
      Less less = new Less();
      less.stdin.write(element.inner);
      less.transform(args, modifyOptions: modifyOptions).then((exitCode){
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
    if (elements.length == 1) deliverToPipe = false;

    StringBuffer output = elements.fold(new StringBuffer(), (out, element) => out..write(element.toString()));
    return output.toString();
  }
}

// ------------------------ class ------

/// Base class for LessElement and StyleElement
class ContentElement {
  bool hasLessCode = false;
  String openTag;   // <tag...>
  int openTagStart; // '<'  - absolute position to content file. fragment start
  int openTagEnd;   // next to '>'

  String closeTag;  // </tag>
  int closeTagStart;
  int closeTagEnd;  // fragment end

  String outer;     // <tag...>...</tag>
  String get inner => outer.substring(openTagEnd - openTagStart, closeTagStart - openTagStart);

  String openTagResult;  // openTag transformed
  String closeTagResult; // closeTag transformed
  String css;       // result of less process

  String tabStr;    // '   '<tag...  - distance to line start. Source tag tabulation
  String tabStr2;   // '     '        - distance to line start + 2. Content tabulation

  ///
  /// Returns a list of elements match with [outerTagReg]
  /// List of '<tag>...</tag>' elements
  ///
  static List<Match> parse(String content, RegExp outerTagReg) {
    Iterable<Match> fragments = outerTagReg.allMatches(content);
    return (fragments == null)? fragments : fragments.toList();
  }

  /// get '<tag...>'
  static String getOpenTag(String content, RegExp openTagReg) {
    Match match = openTagReg.firstMatch(content);
    return match[0];
  }

  ///
  /// Analyze [fragment] to fill the fields
  ///
  void analyzeContent(Match fragment, RegExp openTagReg, RegExp closeTagReg) {
    openTagStart = fragment.start;
    closeTagEnd = fragment.end;
    outer = fragment[0];

    Match match = openTagReg.firstMatch(outer); //<tag...>
    openTag = match[0];
    openTagResult = openTag;
    openTagEnd = openTagStart + match.end;

    match = closeTagReg.firstMatch(outer);  //</tag>
    closeTag = match[0];
    closeTagResult = closeTag;
    closeTagStart = openTagStart + match.start;

    tabStr = getTabStr(fragment.input);
    tabStr2 = tabStr + '  ';
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
  /// Build the inner <style> result element string, with the line tabs
  ///
  String tabCss(){
    StringBuffer resultBuffer = new StringBuffer();
    List<String> lines = css.split('\n');

    for(int i = 0; i < lines.length - 1; i++) {
      resultBuffer.writeln(tabStr2 + lines[i]);
    }

    return resultBuffer.toString();
  }
}

///
/// <style type="text/less"> ... </style>
///
class StyleElement extends ContentElement {
  bool hasLessCode = true;
  static RegExp outerTagReg = new RegExp(r'<style[^>]*>(.|\n)*?<\/style>');
  static RegExp openTagReg = new RegExp(r'<style[^>]*>');
  static RegExp closeTagReg = new RegExp(r'<\/style>');
  static RegExp styleTypeReg = new RegExp(r'type="text\/less"');

  ///
  /// Build a list with the detected elements
  ///
  static List<StyleElement> parse(String content) {
    List<StyleElement> result = [];

    ContentElement.parse(content, outerTagReg).forEach((fragment) {
      String openTag = ContentElement.getOpenTag(fragment[0], openTagReg);
      if(styleTypeReg.hasMatch(openTag)) result.add(new StyleElement(fragment));
    });
    return result;
  }

  StyleElement(Match fragment) {
    analyzeContent(fragment, openTagReg, closeTagReg);
    openTagResult = openTagResult.replaceFirst(styleTypeReg, 'type="text/css"');
  }

  ///
  /// Build the <style> element as string
  ///
  String toString() => '${openTagResult}\n${tabCss()}${tabStr}${closeTagResult}';
}


///
/// <less...>...</less>
///
class LessElement extends ContentElement {
  bool hasLessCode = true;
  bool isReplace = false;
  String cssOpenTag; // <style...>
  String cssCloseTag = '</style>';

  static RegExp outerTagReg = new RegExp(r'<less[^>]*>(.|\n)*?<\/less>');
  static RegExp openTagReg = new RegExp(r'<less[^>]*>');
  static RegExp closeTagReg = new RegExp(r'<\/less>');

  static List<LessElement> parse(String content) {
    List<LessElement> result = [];

    ContentElement.parse(content, outerTagReg).forEach((fragment) {
      result.add(new LessElement(fragment));
    });
    return result;
  }

  LessElement(Match fragment) {
    analyzeContent(fragment, openTagReg, closeTagReg);

    cssOpenTag = openTag.replaceFirst('less', 'style');
    if (openTag.contains('replace')) {
      isReplace = true;
      cssOpenTag = trimSpaces(cssOpenTag.replaceFirst('replace', ''));
    }
    openTagResult = trimSpaces(openTag.substring(0, openTag.length - 1) + ' style="display:none"' + '>');
  }

  ///
  /// Build the <less> and <style> elements as string
  ///
  String toString() => lessToString() + cssToString();

  /// Build <less> string
  String lessToString() {
    if (isReplace) {
      return '';
    } else {
      return openTagResult + inner + closeTagResult;
    }
  }

  /// Build <style> string
  String cssToString() {
    String prefix = isReplace ? '' : '\n${tabStr}';
    return '${prefix}${cssOpenTag}\n${tabCss()}${tabStr}${cssCloseTag}';
  }
}

///
/// Html content between less tags
///
class FragmentElement extends ContentElement {
  ///
  /// Creates FragmentElement components between ContentElement not contiguous
  ///
  static List<ContentElement> parse(String content, List<ContentElement> source) {
    List<ContentElement> result = [];
    ContentElement element;
    int index = 0;

    for (int i = 0; i < source.length; i++) {
      element = source[i];
      if (element.openTagStart > index) {
        result.add(new FragmentElement(content, index, element.openTagStart));
        result.add(element);
        index = element.closeTagEnd;
      }
    }
    if (index < content.length) result.add(new FragmentElement(content, index, content.length));

    return result;
  }

  FragmentElement(String content, int openTagStart, int closeTagEnd) {
    this.openTagStart = openTagStart;
    this.openTagEnd = openTagStart;
    this.closeTagStart = closeTagEnd;
    this.closeTagEnd = closeTagEnd;

    outer = content.substring(openTagStart, closeTagEnd);
  }

  ///
  /// The fragment between <less> tags is delivered
  ///
  String toString() => outer;
}
