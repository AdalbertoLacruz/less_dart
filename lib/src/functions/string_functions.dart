// source: lib/less/functions/string.js 2.5.0

part of functions.less;

///
class StringFunctions extends FunctionBase {
  ///
  /// CSS escaping, replaced with ~"value" syntax.
  /// It expects string as a parameter and return its content as is, but without quotes.
  /// Parameters:
  ///   string - a string to escape.
  ///   Returns: string - the escaped string, without quotes.
  /// Example:
  ///   filter: e("ms:alwaysHasItsOwnSyntax.For.Stuff()");
  ///   Output: filter: ms:alwaysHasItsOwnSyntax.For.Stuff();
  /// Note: The function accepts also ~"" escaped values and numbers as parameters.
  /// Anything else returns an error.
  ///
  //str.evaluated == null. JavaScript not supported
  Anonymous e(Node str) => new Anonymous(str is JavaScript ? null : str.value);

//    e: function (str) {
//        return new Anonymous(str instanceof JavaScript ? str.evaluated : str.value);
//    }

  ///
  /// Applies URL-encoding to special characters found in the input string.
  /// These characters are not encoded: ,, /, ?, @, &, +, ', ~, ! and $.
  /// Most common encoded characters are: \<space\>, #, ^, (, ), {, }, |, :, >, <, ;, ], [ and =.
  ///
  /// Parameters:
  ///   string: a string to escape.
  ///   Returns: escaped string content without quotes.
  /// Example:
  ///   escape('a=1')
  ///   Output: a%3D1
  /// Note: if the parameter is not a string, output is not defined.
  /// The current implementation returns undefined on color and unchanged input
  /// on any other kind of argument. This behavior should not be relied on and may change in the future.
  ///
  Anonymous escape(Node str) =>  new Anonymous(Uri.encodeFull(str.value)
      ..replaceAll(new RegExp(r'='), '%3D')
      ..replaceAll(new RegExp(r':'), '%3A')
      ..replaceAll(new RegExp(r'#'), '%23')
      ..replaceAll(new RegExp(r';'), '%3B')
      ..replaceAll(new RegExp(r'\('), '%28')
      ..replaceAll(new RegExp(r'\)'), '%29'));

//    escape: function (str) {
//        return new Anonymous(encodeURI(str.value).replace(/=/g, "%3D").replace(/:/g, "%3A").replace(/#/g, "%23").replace(/;/g, "%3B").replace(/\(/g, "%28").replace(/\)/g, "%29"));
//    }

  ///
  /// Replaces a text within a string.
  //
  /// Parameters:
  ///   string: The string to search and replace in.
  ///   pattern: A string or regular expression pattern to search for.
  ///   replacement: The string to replace the matched pattern with.
  ///   flags: (Optional) regular expression flags.
  ///   Returns: a string with the replaced values.
  /// Example:
  ///   replace("Hello, Mars?", "Mars\?", "Earth!");
  ///   replace("One + one = 4", "one", "2", "gi");
  ///   replace('This is a string.', "(string)\.$", "new $1.");
  ///   replace(~"bar-1", '1', '2');
  ///   Result:
  ///     "Hello, Earth!";
  ///     "2 + 2 = 4";
  ///     'This is a new string.';
  ///     bar-2;
  ///
  Quoted replace(Node string, Quoted pattern, Node replacement, [Node flags]) {
    //string, replacement, flags is Quoted ('value') or Keyword (value)

    final String flagsValue = flags != null ? flags.value : '';
    final MoreRegExp re = new MoreRegExp(pattern.value, flagsValue);

    final String replacementStr = (replacement is Quoted)
        ? replacement.value
        : replacement.toCSS(null);
    final String result = re.replace(string.value, replacementStr);

    final String quote = (string is Quoted) ? string.quote : '';
    final bool escaped = (string is Quoted) ? string.escaped : false;
    return new Quoted(quote, result, escaped: escaped);

//2.4.0 20150331
//  replace: function (string, pattern, replacement, flags) {
//      var result = string.value;
//      replacement = (replacement.type === "Quoted") ?
//          replacement.value : replacement.toCSS();
//      result = result.replace(new RegExp(pattern.value, flags ? flags.value : ''), replacement);
//      return new Quoted(string.quote || '', result, string.escaped);
//  },
  }

  ///
  /// % format
  /// The function %(string, arguments ...) formats a string.
  ///
  /// The first argument is string with placeholders. All placeholders start
  /// with percentage symbol % followed by letter s,S,d,D,a, or A.
  /// Remaining arguments contain expressions to replace placeholders.
  ///
  /// Placeholders:
  ///   d, D, a, A - can be replaced by any kind of argument
  ///     (color, number, escaped value, expression, ...). If you use them in
  ///     combination with string, the whole string will be used - including its
  ///     quotes. However, the quotes are placed into the string as they are,
  ///     they are not escaped by "/" nor anything similar.
  ///   s, S - can be replaced by any kind of argument except color. If you use
  ///     them in combination with string, only the string value will be used
  ///     - string quotes are omitted.
  /// Parameters:
  ///   string: format string with placeholders,
  ///   anything* : values to replace placeholders.
  /// Returns: formatted string.
  /// Example:
  ///   format-a-d: %("repetitions: %a file: %d", 1 + 2, "directory/file.less");
  ///   Output:
  ///     format-a-d: "repetitions: 3 file: "directory/file.less"";
  ///
  @DefineMethod(name: '%', listArguments: true)
  Quoted format(List<Node> args) {
    final Node qstr = args[0];
    String result = qstr.value;
    final MoreRegExp sda = new MoreRegExp(r'%[sda]', 'i');
    final RegExp az = new RegExp(r'[A-Z]$', caseSensitive: true);

    String value;
    for (int i = 1; i < args.length; i++) {
      result = sda.replaceMap(result, (Match m) {
        value =  (args[i] is Quoted &&  m[0].toLowerCase() == '%s')
            ? args[i].value
            : args[i].toCSS(context);
        return az.hasMatch(m[0]) ? Uri.encodeComponent(value) : value;
      });
    }

    result.replaceAll(new RegExp(r'%%'), '%');
    if (qstr is Quoted) {
      //return new Quoted(getValueOrDefault(qstr.quote, ''), result, qstr.escaped, qstr.index, currentFileInfo);
      return new Quoted((qstr.quote ?? ''), result,
        escaped: qstr.escaped,
        index: qstr.index,
        currentFileInfo: currentFileInfo);
    } else {
      return new Quoted('', result, escaped: null);
    }

//2.4.0 20150331
//  '%': function (string /* arg, arg, ...*/) {
//      var args = Array.prototype.slice.call(arguments, 1),
//          result = string.value;
//
//      for (var i = 0; i < args.length; i++) {
//          /*jshint loopfunc:true */
//          result = result.replace(/%[sda]/i, function(token) {
//              var value = ((args[i].type === "Quoted") &&
//                  token.match(/s/i)) ? args[i].value : args[i].toCSS();
//              return token.match(/[A-Z]$/) ? encodeURIComponent(value) : value;
//          });
//      }
//      result = result.replace(/%%/g, '%');
//      return new Quoted(string.quote || '', result, string.escaped);
//  }
  }
}
