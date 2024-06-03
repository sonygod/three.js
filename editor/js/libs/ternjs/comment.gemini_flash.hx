class Comment {
  public static function isSpace(ch:Int):Bool {
    return (ch < 14 && ch > 8) || ch == 32 || ch == 160;
  }

  public static function onOwnLine(text:String, pos:Int):Bool {
    for (pos in 0...pos) {
      var ch = text.charCodeAt(pos - 1);
      if (ch == 10) return true;
      if (!isSpace(ch)) return false;
    }
    return true;
  }

  public static function commentsBefore(text:String, pos:Int):Array<String> {
    var found:Array<String> = null;
    var emptyLines:Int = 0;
    var topIsLineComment:Bool = false;
    while (pos > 0) {
      var prev = text.charCodeAt(pos - 1);
      if (prev == 10) {
        for (var scan = pos - 1; scan > 0; --scan) {
          prev = text.charCodeAt(scan - 1);
          if (prev == 47 && text.charCodeAt(scan - 2) == 47) {
            if (!onOwnLine(text, scan - 2)) break;
            var content = text.substring(scan, pos);
            if (!emptyLines && topIsLineComment) found[0] = content + "\n" + found[0];
            else found = found == null ? [content] : [content, ...found];
            topIsLineComment = true;
            emptyLines = 0;
            pos = scan - 2;
            break;
          } else if (prev == 10) {
            if (emptyLines++ > 1) break;
            break;
          } else if (!isSpace(prev)) {
            break;
          }
        }
      } else if (prev == 47 && text.charCodeAt(pos - 2) == 42) {
        for (var scan = pos - 2; scan > 1; --scan) {
          if (text.charCodeAt(scan - 1) == 42 && text.charCodeAt(scan - 2) == 47) {
            if (!onOwnLine(text, scan - 2)) break;
            found = found == null ? [text.substring(scan, pos - 2)] : [text.substring(scan, pos - 2), ...found];
            topIsLineComment = false;
            emptyLines = 0;
            break;
          }
        }
        pos = scan - 2;
      } else if (isSpace(prev)) {
        --pos;
      } else {
        break;
      }
    }
    return found;
  }

  public static function commentAfter(text:String, pos:Int):String {
    while (pos < text.length) {
      var next = text.charCodeAt(pos);
      if (next == 47) {
        var after = text.charCodeAt(pos + 1);
        var end:Int;
        if (after == 47) {
          end = text.indexOf("\n", pos + 2);
        } else if (after == 42) {
          end = text.indexOf("*/", pos + 2);
        } else {
          return null;
        }
        return text.substring(pos + 2, end < 0 ? text.length : end);
      } else if (isSpace(next)) {
        ++pos;
      }
    }
    return null;
  }

  public static function ensureCommentsBefore(text:String, node:Dynamic):Array<String> {
    if (Reflect.hasField(node, "commentsBefore")) return node.commentsBefore;
    return node.commentsBefore = commentsBefore(text, node.start);
  }
}


This Haxe code is equivalent to the JavaScript code you provided. Here's a breakdown of the changes:

- **Namespaces and Classes:** Haxe uses namespaces and classes to organize code. Instead of a single global scope, we create a `Comment` class to hold the functions.
- **`Dynamic` type:** The `node` parameter in `ensureCommentsBefore` is declared as `Dynamic` because Haxe doesn't have a direct equivalent to JavaScript's loose typing. This allows the function to work with objects that may not have a predefined type.
- **`Reflect.hasField`:** This function is used to check if the `node` object has a field named "commentsBefore" in a type-safe way.
- **`Array` and `String`:** Haxe has built-in types for arrays and strings, so we use `Array<String>` for the comments and `String` for the text.
- **`for` loop:** Haxe uses a slightly different syntax for `for` loops.
- **`substring`:** Haxe uses `substring` instead of `slice` to extract substrings from strings.
- **`null`:** Haxe uses `null` instead of `undefined` to represent the absence of a value.

To use this code in your Haxe project, you can save it as a file named `Comment.hx` and import it into your main Haxe file:


import Comment;

class Main {
  static function main() {
    // Use the functions from the Comment class here
  }
}