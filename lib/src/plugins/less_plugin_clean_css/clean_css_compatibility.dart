//source: clean-css\lib\utils\compatibility.js

part of less_plugin_clean_css.plugins.less;

///
class CleanCssCompatibility {
  ///
  String source;

  ///
  CleanCssColors colors = CleanCssColors();

  ///
  CleanCssProperties properties = CleanCssProperties();

  ///
  CleanCssSelectors selectors = CleanCssSelectors();

  ///
  CleanCssUnits units = CleanCssUnits();

  // --compatibility: 'ie8,+units.rem'

  ///
  CleanCssCompatibility(this.source) {
    bool isAdd;
    List<String> key;
    String group;
    String option;
    String part;

    final List<String> parts = source.split(',');
    final String nav = parts[0].trim();

    switch (nav) {
      case 'ie8':
        colors.opacity = false;
        properties.iePrefixHack = true;
        properties.ieSuffixHack = true;
        properties.merging = false;
        properties.spaceAfterClosingBrace = true;
        selectors.special = RegExp(
            r'(\-moz\-|\-ms\-|\-o\-|\-webkit\-|:root|:nth|:first\-of|:last|:only|:empty|:target|:checked|::selection|:enabled|:disabled|:not)');
        units.ch = false;
        units.rem = false;
        units.vh = false;
        units.vm = false;
        units.vmax = false;
        units.vmin = false;
        units.vw = false;
        break;
      case 'ie7':
        colors.opacity = false;
        properties.iePrefixHack = true;
        properties.ieSuffixHack = true;
        properties.merging = false;
        properties.spaceAfterClosingBrace = true;
        selectors.ie7Hack = true;
        selectors.special = RegExp(
            r'(\-moz\-|\-ms\-|\-o\-|\-webkit\-|:focus|:before|:after|:root|:nth|:first\-of|:last|:only|:empty|:target|:checked|::selection|:enabled|:disabled|:not)');
        units.ch = false;
        units.rem = false;
        units.vh = false;
        units.vm = false;
        units.vmax = false;
        units.vmin = false;
        units.vw = false;
        break;
    }

    // fine tuning
    if (parts.length > 1) {
      for (int i = 1; i < parts.length; i++) {
        part = parts[i].trim();
        isAdd = part[0] == '+';
        key = part.substring(1).split('.');
        group = key[0].trim();
        option = key[1].trim();
        setOption(group, option, isAdd: isAdd);
      }
    }
  }

  ///
  void setOption(String group, String option, {bool isAdd = false}) {
    switch (group) {
      case 'colors':
        colors.setOption(option, isAdd: isAdd);
        break;
      case 'properties':
        properties.setOption(option, isAdd: isAdd);
        break;
      case 'selectors':
        selectors.setOption(option, isAdd: isAdd);
        break;
      case 'units':
        units.setOption(option, isAdd: isAdd);
        break;
    }
  }
}

///
class CleanCssColors {
  /// rgba / hsla. Replace rgb(0,0,0,0) by transparent
  bool opacity = true;

  ///
  void setOption(String option, {bool isAdd = false}) {
    switch (option) {
      case 'opacity':
        opacity = isAdd;
        break;
    }
  }
}

///
class CleanCssProperties {
  /// background-size to shorthand
  bool backgroundSizeMerging = false;

  /// any kind of color transformations, like `#ff00ff` to `#f0f` or `#fff` into `red`
  /// Use the shorter color representation
  bool colors = true;

  /// underscore / asterisk prefix hacks on IE
  bool iePrefixHack = false;

  /// \9 suffix hacks on IE
  bool ieSuffixHack = false;

  /// merging properties into one
  bool merging = true;

  /// 'url() no-repeat' to 'url()no-repeat'
  bool spaceAfterClosingBrace = false;

  /// whether to wrap content of `url()` into quotes or not
  bool urlQuotes = false;

  /// 0unit -> 0
  bool zeroUnits = true;

  ///
  void setOption(String option, {bool isAdd = false}) {
    switch (option) {
      case 'backgroundSizeMerging':
        backgroundSizeMerging = isAdd;
        break;
      case 'colors':
        colors = isAdd;
        break;
      case 'iePrefixHack':
        iePrefixHack = isAdd;
        break;
      case 'ieSuffixHack':
        ieSuffixHack = isAdd;
        break;
      case 'merging':
        merging = isAdd;
        break;
      case 'spaceAfterClosingBrace':
        spaceAfterClosingBrace = isAdd;
        break;
      case 'urlQuotes':
        urlQuotes = isAdd;
        break;
      case 'zeroUnits':
        zeroUnits = isAdd;
        break;
    }
  }
}

///
class CleanCssSelectors {
  /// div+ nav Android stock browser hack
  bool adjacentSpace = false;

  /// *+html hack
  bool ie7Hack = false;

  /// special selectors which prevent merging
  RegExp special = RegExp(
      r'(\-moz\-|\-ms\-|\-o\-|\-webkit\-|:dir\([a-z-]*\)|:first(?![a-z-])|:fullscreen|:left|:read-only|:read-write|:right)');

  ///
  void setOption(String option, {bool isAdd = false}) {
    switch (option) {
      case 'adjacentSpace':
        adjacentSpace = isAdd;
        break;
      case 'ie7Hack':
        ie7Hack = isAdd;
        break;
    }
  }
}

///
class CleanCssUnits {
  ///
  bool ch = true;

  ///
  bool rem = true;

  ///
  bool vh = true;

  ///
  // vm is vmin on IE9+ see https://developer.mozilla.org/en-US/docs/Web/CSS/length
  bool vm = true;

  ///
  bool vmax = true;

  ///
  bool vmin = true;

  ///
  bool vw = true;

  ///
  void setOption(String option, {bool isAdd = false}) {
    switch (option) {
      case 'ch':
        ch = isAdd;
        break;
      case 'rem':
        rem = isAdd;
        break;
      case 'vh':
        vh = isAdd;
        break;
      case 'vm':
        vm = isAdd;
        break;
      case 'vmax':
        vmax = isAdd;
        break;
      case 'vmin':
        vmin = isAdd;
        break;
      case 'vw':
        vw = isAdd;
        break;
    }
  }
}
