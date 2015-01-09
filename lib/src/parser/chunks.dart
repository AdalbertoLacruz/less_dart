// source: less/parser.js

part of parser.less;

class Chunks {
  Env env;

  List<String> chunks = [];
  int currentChunkStartIndex;
  int emitFrom = 0;
  int parserCurrentIndex;

  Chunks(this.env);

  /**
   * throw Parse error
   */
  // less/parser.js 1.7.5 lines 381-388
  fail(String msg, [int index]) {
    LessError error = new LessError(
        index: (index != null)? index : parserCurrentIndex,
        type: 'Parse',
        message: msg,
        filename: env.currentFileInfo.filename,
        env: env);
    throw new LessExceptionError(error);
  }

  // less/parser.js 1.7.5 lines 390-397
  void emitChunk([bool force=false]) {
    int len = parserCurrentIndex - emitFrom;
    if (((len < 512) && !force) || len == 0) return;
    chunks.add(env.input.substring(emitFrom, parserCurrentIndex + 1));
    emitFrom = parserCurrentIndex + 1;
  }

  /**
   * Split the input into chunks.
   */
  // less/parser.js 1.7.5 lines 375-480
  List<String> analyzeInput(String input){
    int cc;  //character
    int cc2; //character
    int lastMultiComment = 0;
    int lastMultiCommentEndBrace = 0;
    int lastOpening = 0;
    int lastOpeningParen = 0;
    int len = input.length;
    int level = 0;
    bool matched;
    int parenLevel = 0;

    env.input = input;

    for (parserCurrentIndex = 0; parserCurrentIndex < len; parserCurrentIndex++) {
      cc = input.codeUnitAt(parserCurrentIndex);
      if (((cc >= 97) && (cc <= 122)) || (cc < 34)) {
        // a-z or whitespace
        continue;
      }

      switch (cc) {
        case 40:                            // (
          parenLevel++;
          lastOpeningParen = parserCurrentIndex;
          continue;
        case 41:                            // )
          if (--parenLevel < 0) return fail("missing opening `(`");
          continue;
        case 59:                            // ;
          if (parenLevel == 0) emitChunk();
          continue;
        case 123:                           // {
          level++;
          lastOpening = parserCurrentIndex;
          continue;
        case 125:                           // }
          if (--level < 0) return fail("missing opening `{`");
          if (level == 0 && parenLevel == 0) emitChunk();
          continue;
        case 92:                            // \
          if (parserCurrentIndex < len - 1) {
            parserCurrentIndex++;
            continue;
          }
          return fail("unescaped `\\`");
        case 34:
        case 39:
        case 96:                            // ", ' and `
          matched = false;
          currentChunkStartIndex = parserCurrentIndex;
          for (parserCurrentIndex = parserCurrentIndex + 1; parserCurrentIndex < len; parserCurrentIndex++){
            cc2 = input.codeUnitAt(parserCurrentIndex);
            if (cc2 > 96) continue;
            if (cc2 == cc) {
              matched = true;
              break;
            }
            if (cc2 == 92) {                 // \
              if (parserCurrentIndex == len - 1) return fail("unescaped `\\`");
              parserCurrentIndex++;
            }
          }
          if (matched) continue;
          return fail('unmatched `${input[currentChunkStartIndex]}`', currentChunkStartIndex);
        case 47:                             // /, check for comment
          if ((parenLevel != 0) || (parserCurrentIndex == len - 1 )) continue;
          cc2 = input.codeUnitAt(parserCurrentIndex + 1);
          if (cc2 == 47) {
            // //, find lnfeed
            for (parserCurrentIndex = parserCurrentIndex + 2; parserCurrentIndex < len; parserCurrentIndex++) {
              cc2 = input.codeUnitAt(parserCurrentIndex);
              if ((cc2 <= 13) && ((cc2 == 10) || (cc2 == 13))) break;
            }
          } else if (cc2 == 42) {
            // /*, find */
            lastMultiComment = currentChunkStartIndex = parserCurrentIndex;
            for (parserCurrentIndex = parserCurrentIndex + 2; parserCurrentIndex < len - 1; parserCurrentIndex++) {
              cc2 = input.codeUnitAt(parserCurrentIndex);
              if (cc2 == 125) lastMultiCommentEndBrace = parserCurrentIndex;
              if (cc2 != 42) continue;
              if (input.codeUnitAt(parserCurrentIndex + 1) == 47) break;
            }
            if (parserCurrentIndex == len - 1) return fail("missing closing `*/`", currentChunkStartIndex);
            parserCurrentIndex++;
          }
          continue;
        case 42:                              // *, check for unmatched */
          if ((parserCurrentIndex < len - 1) && (input.codeUnitAt(parserCurrentIndex + 1) == 47)) return fail("unmatched `/*`");
          continue;
      }
    }

    parserCurrentIndex = len - 1; // for exit value is len
    if (level != 0) {
      if ((lastMultiComment > lastOpening) && (lastMultiCommentEndBrace > lastMultiComment)) {
        return fail("missing closing `}` or `*/`", lastOpening);
      } else {
        return fail("missing closing `}`", lastOpening);
      }
    } else if (parenLevel != 0){
        return fail("missing closing `)`", lastOpeningParen);
    }

    emitChunk(true);
    return chunks;
  }
}