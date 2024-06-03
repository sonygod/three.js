package;

import haxe.ds.IntMap;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.macro.ExprTools;

class Found {
  public var node: Expr;
  public var state: Array<Expr>;
  public function new(node: Expr, state: Array<Expr>) {
    this.node = node;
    this.state = state;
  }
}

class Walk {
  public static function simple(node: Expr, visitors: IntMap<Expr>, base: IntMap<Expr>, state: Expr = null): Void {
    if (base == null) base = Walk.base;
    var c = function(node: Expr, st: Expr, override: String): Void {
      var type = override != null ? override : node.expr.getField("type");
      var found = visitors.get(type);
      base.get(type)(node, st, c);
      if (found != null) found(node, st);
    };
    c(node, state, null);
  }

  public static function ancestor(node: Expr, visitors: IntMap<Expr>, base: IntMap<Expr>, state: Expr = null): Void {
    if (base == null) base = Walk.base;
    if (state == null) state = new Array<Expr>();
    var c = function(node: Expr, st: Expr, override: String): Void {
      var type = override != null ? override : node.expr.getField("type");
      var found = visitors.get(type);
      if (node != st.expr.get(st.expr.length - 1)) {
        st = st.expr.copy();
        st.expr.push(node);
      }
      base.get(type)(node, st, c);
      if (found != null) found(node, st);
    };
    c(node, state, null);
  }

  public static function recursive(node: Expr, state: Expr, funcs: IntMap<Expr>, base: IntMap<Expr> = null): Void {
    var visitor = funcs != null ? Walk.make(funcs, base) : base;
    var c = function(node: Expr, st: Expr, override: String): Void {
      visitor.get(override != null ? override : node.expr.getField("type"))(node, st, c);
    };
    c(node, state, null);
  }

  public static function makeTest(test: Expr): (String -> Bool) {
    if (test.expr.isString()) {
      return function(type: String): Bool {
        return type == test.expr.toString();
      };
    } else if (test == null) {
      return function(): Bool {
        return true;
      };
    } else {
      return function(type: String): Bool {
        return test(type);
      };
    }
  }

  public static function findNodeAt(node: Expr, start: Int = null, end: Int = null, test: Expr = null, base: IntMap<Expr> = null, state: Expr = null): Expr {
    test = Walk.makeTest(test);
    if (base == null) base = Walk.base;
    try {
      var c = function(node: Expr, st: Expr, override: String): Void {
        var type = override != null ? override : node.expr.getField("type");
        if ((start == null || node.expr.getField("start") <= start) && (end == null || node.expr.getField("end") >= end)) base.get(type)(node, st, c);
        if (test(type) && (start == null || node.expr.getField("start") == start) && (end == null || node.expr.getField("end") == end)) throw new Found(node, st);
      };
      c(node, state, null);
    } catch (e: Found) {
      return e.node;
    }
  }

  public static function findNodeAround(node: Expr, pos: Int, test: Expr = null, base: IntMap<Expr> = null, state: Expr = null): Expr {
    test = Walk.makeTest(test);
    if (base == null) base = Walk.base;
    try {
      var c = function(node: Expr, st: Expr, override: String): Void {
        var type = override != null ? override : node.expr.getField("type");
        if (node.expr.getField("start") > pos || node.expr.getField("end") < pos) {
          return;
        }
        base.get(type)(node, st, c);
        if (test(type)) throw new Found(node, st);
      };
      c(node, state, null);
    } catch (e: Found) {
      return e.node;
    }
  }

  public static function findNodeAfter(node: Expr, pos: Int, test: Expr = null, base: IntMap<Expr> = null, state: Expr = null): Expr {
    test = Walk.makeTest(test);
    if (base == null) base = Walk.base;
    try {
      var c = function(node: Expr, st: Expr, override: String): Void {
        if (node.expr.getField("end") < pos) {
          return;
        }
        var type = override != null ? override : node.expr.getField("type");
        if (node.expr.getField("start") >= pos && test(type)) throw new Found(node, st);
        base.get(type)(node, st, c);
      };
      c(node, state, null);
    } catch (e: Found) {
      return e.node;
    }
  }

  public static function findNodeBefore(node: Expr, pos: Int, test: Expr = null, base: IntMap<Expr> = null, state: Expr = null): Expr {
    test = Walk.makeTest(test);
    if (base == null) base = Walk.base;
    var max: Found = null;
    var c = function(node: Expr, st: Expr, override: String): Void {
      if (node.expr.getField("start") > pos) {
        return;
      }
      var type = override != null ? override : node.expr.getField("type");
      if (node.expr.getField("end") <= pos && (max == null || max.node.expr.getField("end") < node.expr.getField("end")) && test(type)) max = new Found(node, st);
      base.get(type)(node, st, c);
    };
    c(node, state, null);
    return max != null ? max.node : null;
  }

  public static function make(funcs: IntMap<Expr>, base: IntMap<Expr>): IntMap<Expr> {
    if (base == null) base = Walk.base;
    var visitor = new IntMap<Expr>();
    for (i in base) visitor.set(i, base.get(i));
    for (i in funcs) visitor.set(i, funcs.get(i));
    return visitor;
  }

  public static function skipThrough(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
    c(node, st, null);
  }

  public static function ignore(_node: Expr, _st: Expr, _c: (Expr, Expr, String) -> Void): Void {
  }

  public static var base: IntMap<Expr> = new IntMap<Expr>();

  static function init() {
    base.set("Program", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      var body = node.expr.getField("body");
      for (i in 0...body.expr.length) {
        c(body.expr.get(i), st, "Statement");
      }
    });
    base.set("BlockStatement", base.get("Program"));
    base.set("Statement", skipThrough);
    base.set("EmptyStatement", ignore);
    base.set("ExpressionStatement", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node.expr.getField("expression"), st, "Expression");
    });
    base.set("ParenthesizedExpression", base.get("ExpressionStatement"));
    base.set("IfStatement", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node.expr.getField("test"), st, "Expression");
      c(node.expr.getField("consequent"), st, "Statement");
      if (node.expr.getField("alternate") != null) c(node.expr.getField("alternate"), st, "Statement");
    });
    base.set("LabeledStatement", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node.expr.getField("body"), st, "Statement");
    });
    base.set("BreakStatement", ignore);
    base.set("ContinueStatement", ignore);
    base.set("WithStatement", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node.expr.getField("object"), st, "Expression");
      c(node.expr.getField("body"), st, "Statement");
    });
    base.set("SwitchStatement", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node.expr.getField("discriminant"), st, "Expression");
      var cases = node.expr.getField("cases");
      for (i in 0...cases.expr.length) {
        var cs = cases.expr.get(i);
        if (cs.expr.getField("test") != null) c(cs.expr.getField("test"), st, "Expression");
        var consequent = cs.expr.getField("consequent");
        for (j in 0...consequent.expr.length) {
          c(consequent.expr.get(j), st, "Statement");
        }
      }
    });
    base.set("ReturnStatement", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      if (node.expr.getField("argument") != null) c(node.expr.getField("argument"), st, "Expression");
    });
    base.set("YieldExpression", base.get("ReturnStatement"));
    base.set("ThrowStatement", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node.expr.getField("argument"), st, "Expression");
    });
    base.set("SpreadElement", base.get("ThrowStatement"));
    base.set("RestElement", base.get("ThrowStatement"));
    base.set("TryStatement", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node.expr.getField("block"), st, "Statement");
      if (node.expr.getField("handler") != null) c(node.expr.getField("handler").expr.getField("body"), st, "ScopeBody");
      if (node.expr.getField("finalizer") != null) c(node.expr.getField("finalizer"), st, "Statement");
    });
    base.set("WhileStatement", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node.expr.getField("test"), st, "Expression");
      c(node.expr.getField("body"), st, "Statement");
    });
    base.set("DoWhileStatement", base.get("WhileStatement"));
    base.set("ForStatement", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      if (node.expr.getField("init") != null) c(node.expr.getField("init"), st, "ForInit");
      if (node.expr.getField("test") != null) c(node.expr.getField("test"), st, "Expression");
      if (node.expr.getField("update") != null) c(node.expr.getField("update"), st, "Expression");
      c(node.expr.getField("body"), st, "Statement");
    });
    base.set("ForInStatement", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node.expr.getField("left"), st, "ForInit");
      c(node.expr.getField("right"), st, "Expression");
      c(node.expr.getField("body"), st, "Statement");
    });
    base.set("ForOfStatement", base.get("ForInStatement"));
    base.set("ForInit", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      if (node.expr.getField("type") == "VariableDeclaration") c(node, st);
      else c(node, st, "Expression");
    });
    base.set("DebuggerStatement", ignore);
    base.set("FunctionDeclaration", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node, st, "Function");
    });
    base.set("VariableDeclaration", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      var declarations = node.expr.getField("declarations");
      for (i in 0...declarations.expr.length) {
        var decl = declarations.expr.get(i);
        if (decl.expr.getField("init") != null) c(decl.expr.getField("init"), st, "Expression");
      }
    });
    base.set("Function", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node.expr.getField("body"), st, "ScopeBody");
    });
    base.set("ScopeBody", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node, st, "Statement");
    });
    base.set("Expression", skipThrough);
    base.set("ThisExpression", ignore);
    base.set("Super", ignore);
    base.set("MetaProperty", ignore);
    base.set("ArrayExpression", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      var elements = node.expr.getField("elements");
      for (i in 0...elements.expr.length) {
        var elt = elements.expr.get(i);
        if (elt != null) c(elt, st, "Expression");
      }
    });
    base.set("ArrayPattern", base.get("ArrayExpression"));
    base.set("ObjectExpression", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      var properties = node.expr.getField("properties");
      for (i in 0...properties.expr.length) {
        c(properties.expr.get(i), st);
      }
    });
    base.set("ObjectPattern", base.get("ObjectExpression"));
    base.set("FunctionExpression", base.get("FunctionDeclaration"));
    base.set("ArrowFunctionExpression", base.get("FunctionDeclaration"));
    base.set("SequenceExpression", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      var expressions = node.expr.getField("expressions");
      for (i in 0...expressions.expr.length) {
        c(expressions.expr.get(i), st, "Expression");
      }
    });
    base.set("TemplateLiteral", base.get("SequenceExpression"));
    base.set("UnaryExpression", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node.expr.getField("argument"), st, "Expression");
    });
    base.set("UpdateExpression", base.get("UnaryExpression"));
    base.set("BinaryExpression", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node.expr.getField("left"), st, "Expression");
      c(node.expr.getField("right"), st, "Expression");
    });
    base.set("AssignmentExpression", base.get("BinaryExpression"));
    base.set("AssignmentPattern", base.get("BinaryExpression"));
    base.set("LogicalExpression", base.get("BinaryExpression"));
    base.set("ConditionalExpression", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node.expr.getField("test"), st, "Expression");
      c(node.expr.getField("consequent"), st, "Expression");
      c(node.expr.getField("alternate"), st, "Expression");
    });
    base.set("NewExpression", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node.expr.getField("callee"), st, "Expression");
      if (node.expr.getField("arguments") != null) {
        var arguments = node.expr.getField("arguments");
        for (i in 0...arguments.expr.length) {
          c(arguments.expr.get(i), st, "Expression");
        }
      }
    });
    base.set("CallExpression", base.get("NewExpression"));
    base.set("MemberExpression", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node.expr.getField("object"), st, "Expression");
      if (node.expr.getField("computed")) c(node.expr.getField("property"), st, "Expression");
    });
    base.set("ExportDeclaration", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node.expr.getField("declaration"), st);
    });
    base.set("ImportDeclaration", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      var specifiers = node.expr.getField("specifiers");
      for (i in 0...specifiers.expr.length) {
        c(specifiers.expr.get(i), st);
      }
    });
    base.set("ImportSpecifier", ignore);
    base.set("ImportBatchSpecifier", ignore);
    base.set("Identifier", ignore);
    base.set("Literal", ignore);
    base.set("TaggedTemplateExpression", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      c(node.expr.getField("tag"), st, "Expression");
      c(node.expr.getField("quasi"), st);
    });
    base.set("ClassDeclaration", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      if (node.expr.getField("superClass") != null) c(node.expr.getField("superClass"), st, "Expression");
      var body = node.expr.getField("body").expr.getField("body");
      for (i in 0...body.expr.length) {
        c(body.expr.get(i), st);
      }
    });
    base.set("ClassExpression", base.get("ClassDeclaration"));
    base.set("MethodDefinition", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      if (node.expr.getField("computed")) c(node.expr.getField("key"), st, "Expression");
      c(node.expr.getField("value"), st, "Expression");
    });
    base.set("Property", base.get("MethodDefinition"));
    base.set("ComprehensionExpression", function(node: Expr, st: Expr, c: (Expr, Expr, String) -> Void): Void {
      var blocks = node.expr.getField("blocks");
      for (i in 0...blocks.expr.length) {
        c(blocks.expr.get(i).expr.getField("right"), st, "Expression");
      }
      c(node.expr.getField("body"), st, "Expression");
    });
  }
}

class Main {
  static function main() {
    Walk.init();
  }
}

class Test {
  static function test(node: Expr) {
    var visitor = new IntMap<Expr>();
    visitor.set("Identifier", function(node: Expr, st: Expr) {
      Context.println(node);
    });
    Walk.simple(node, visitor, Walk.base);
  }
}