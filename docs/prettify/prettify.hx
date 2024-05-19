package ;

class Prettify {
  static var q : Null<Int> = null;
  static var PR_SHOULD_USE_CONTINUATION : Bool = true;

  static function L(a : Array<Dynamic>) : Void {
    // ...
  }

  static function M(a : Dynamic) : Dynamic {
    // ...
  }

  static function B(a : Dynamic, m : Dynamic, e : Dynamic, h : Array<Dynamic>) : Void {
    // ...
  }

  static function x(a : Array<Dynamic>, m : Array<Dynamic>) : Void {
    // ...
  }

  static function u(a : Dynamic) : Dynamic {
    // ...
  }

  static function D(a : Dynamic, m : Int) : Void {
    // ...
  }

  static function k(a : Dynamic, m : Dynamic) : Void {
    // ...
  }

  static function C(a : Dynamic, m : Dynamic) : Dynamic {
    // ...
  }

  static function E(a : Dynamic) : Void {
    // ...
  }

  static var v : Array<Dynamic> = [
    "break", "continue", "do", "else", "for", "if", "return", "while"
  ];

  static var w : Array<Dynamic> = [
    ["auto", "case", "char", "const", "default", "double", "enum", "extern", "float", "goto", "int", "long", "register", "short", "signed", "sizeof", "static", "struct", "switch", "typedef", "union", "unsigned", "void", "volatile"],
    ["catch", "class", "delete", "false", "import", "new", "operator", "private", "protected", "public", "this", "throw", "true", "try", "typeof"]
  ];

  // ...

  static function prettyPrintOne(a : String, m : Dynamic, e : Int) : String {
    var h : Dynamic = document.createElement("PRE");
    h.innerHTML = a;
    e != null && D(h, e);
    E({ g: m, i: e, h: h });
    return h.innerHTML;
  }

  static function prettyPrint(a : Void -> Void) : Void {
    // ...
  }
}