import js.Node;
import js.NodeProps;
import js.Token;
import js.TokenTypes;
import js.TokenUtils;
import js.ast.Exp;
import js.ast.Name;
import js.tools.CodeTools;
import js.tools.NodeTools;
import js.tools.TokenTools;
import js.tools.TypeTools;
import js.tools.TypeUtils;
import js.tools.Types;
import js.tools.TypesList;
import js.tools.TypesMap;

class DocComment {
  var weight: Null<Int> = null;
  var fullDocs: Bool;

  public function new(weight: Null<Int>, fullDocs: Bool) {
    this.weight = weight;
    this.fullDocs = fullDocs;
  }
}

class JSDocInterpretResult {
  var self: Null<Types.Type> = null;
  var args: Null<TypesMap<Types.Type>> = null;
  var ret: Null<Types.Type> = null;
  var type: Null<Types.Type> = null;

  public function new(
    self: Null<Types.Type>,
    args: Null<TypesMap<Types.Type>>,
    ret: Null<Types.Type>,
    type: Null<Types.Type>
  ) {
    this.self = self;
    this.args = args;
    this.ret = ret;
    this.type = type;
  }
}

class JSDocInterpretCommentsResult {
  var result: Null<JSDocInterpretResult> = null;
  var foundOne: Bool;

  public function new(result: Null<JSDocInterpretResult>, foundOne: Bool) {
    this.result = result;
    this.foundOne = foundOne;
  }
}

class JSDocParseTypeResult {
  var type: Types.Type;
  var end: Int;
  var isOptional: Bool;
  var madeUp: Bool;

  public function new(
    type: Types.Type,
    end: Int,
    isOptional: Bool,
    madeUp: Bool
  ) {
    this.type = type;
    this.end = end;
    this.isOptional = isOptional;
    this.madeUp = madeUp;
  }
}

class JSDocParseTypeInnerResult {
  var type: Types.Type;
  var end: Int;
  var madeUp: Bool;

  public function new(type: Types.Type, end: Int, madeUp: Bool) {
    this.type = type;
    this.end = end;
    this.madeUp = madeUp;
  }
}

class JSDocParseLabelListResult {
  var labels: Array<String>;
  var types: Array<Types.Type>;
  var end: Int;
  var madeUp: Bool;

  public function new(
    labels: Array<String>,
    types: Array<Types.Type>,
    end: Int,
    madeUp: Bool
  ) {
    this.labels = labels;
    this.types = types;
    this.end = end;
    this.madeUp = madeUp;
  }
}

class JSDocParseTypeDefResult {
  var name: String;
  var type: Types.Type;

  public function new(name: String, type: Types.Type) {
    this.name = name;
    this.type = type;
  }
}

class JSDocInterpretComments {
  static function applyType(
    type: Null<Types.Type>,
    self: Null<Types.Type>,
    args: Null<TypesMap<Types.Type>>,
    ret: Null<Types.Type>,
    node: js.Node,
    aval: Types.AVal
  ): Void {
    var fn: Null<Types.Fn> = null;
    if (node.isKindOf(js.NodeKind.VariableDeclaration)) {
      var decl = node.asVariableDeclaration().declarations[0];
      if (decl.init != null && decl.init.isKindOf(js.NodeKind.FunctionExpression)) {
        fn = decl.init.asFunctionExpression().body.scope.fnType;
      }
    } else if (node.isKindOf(js.NodeKind.FunctionDeclaration)) {
      fn = node.asFunctionDeclaration().body.scope.fnType;
    } else if (node.isKindOf(js.NodeKind.AssignmentExpression)) {
      if (node.asAssignmentExpression().right != null && node.asAssignmentExpression().right.isKindOf(js.NodeKind.FunctionExpression)) {
        fn = node.asAssignmentExpression().right.asFunctionExpression().body.scope.fnType;
      }
    } else if (node.isKindOf(js.NodeKind.CallExpression)) {
    } else {
      // An object property
      if (node.isKindOf(js.NodeKind.ObjectProperty)) {
        var value = node.asObjectProperty().value;
        if (value != null && value.isKindOf(js.NodeKind.FunctionExpression)) {
          fn = value.asFunctionExpression().body.scope.fnType;
        }
      }
    }

    if (fn != null) {
      if (args != null) {
        for (i in 0...fn.argNames.length) {
          var name = fn.argNames[i];
          var known = args.get(name);
          if (known == null && (known = args.get(name + "?"))) {
            fn.argNames[i] += "?";
          }
          if (known != null) {
            JSDocInterpretComments.propagateWithWeight(known, fn.args[i]);
          }
        }
      }
      if (ret != null) {
        JSDocInterpretComments.propagateWithWeight(ret, fn.retval);
      }
      if (self != null) {
        JSDocInterpretComments.propagateWithWeight(self, fn.self);
      }
    } else if (type != null) {
      JSDocInterpretComments.propagateWithWeight(type, aval);
    }
  }

  static function propagateWithWeight(type: Types.Type, target: Types.AVal): Void {
    var weight = TypeTools.cx().parent.docComment.weight;
    type.propagate(target, weight != null ? weight : (type.madeUp ? 1 : null));
  }

  static function jsdocInterpretComments(
    node: js.Node,
    scope: js.Scope,
    aval: Types.AVal,
    comments: Array<String>
  ): JSDocInterpretCommentsResult {
    var type: Null<Types.Type> = null;
    var args: Null<TypesMap<Types.Type>> = null;
    var ret: Null<Types.Type> = null;
    var self: Null<Types.Type> = null;
    var foundOne: Bool = false;

    for (i in 0...comments.length) {
      var comment = comments[i];
      var decl = ~/@(type|param|arg(?:ument)?|returns?|this)\s+(.*)/g.match(comment);
      while (decl != null) {
        var m = decl.matched(0);
        if (m[1] == "this" && (parsed = JSDocInterpretComments.parseType(scope, m[2], 0))) {
          self = parsed.type;
          foundOne = true;
        } else {
          var parsed = JSDocInterpretComments.parseTypeOuter(scope, m[2]);
          if (parsed == null) {
            continue;
          }
          foundOne = true;

          switch (m[1]) {
            case "returns":
            case "return":
              ret = parsed.type;
              break;
            case "type":
              type = parsed.type;
              break;
            case "param":
            case "arg":
            case "argument":
              var name = m[2].substr(parsed.end).match(/^(\[?)\s*([^\]\s=]+)\s*(?:=[^\]]+\s*)?(\]?)/);
              if (name == null) {
                continue;
              }
              var argname = name[2] + (parsed.isOptional || (name[1] == "[" && name[3] == "]") ? "?" : "");
              if (args == null) {
                args = new TypesMap();
              }
              args.set(argname, parsed.type);
              break;
          }
        }
        decl = decl.nextMatch();
      }
    }

    return new JSDocInterpretCommentsResult(new JSDocInterpretResult(self, args, ret, type), foundOne);
  }

  static function parseTypeOuter(scope: js.Scope, str: String): Null<JSDocParseTypeResult> {
    var pos = JSDocInterpretComments.skipSpace(str, 0);
    if (str.charCodeAt(pos) != "{".charCodeAt(0)) {
      return null;
    }
    var result = JSDocInterpretComments.parseType(scope, str, pos + 1);
    if (result == null) {
      return null;
    }
    var end = JSDocInterpretComments.skipSpace(str, result.end);
    if (str.charCodeAt(end) != "}".charCodeAt(0)) {
      return null;
    }
    result.end = end + 1;
    return result;
  }

  static function parseType(scope: js.Scope, str: String, pos: Int): Null<JSDocParseTypeResult> {
    var type: Types.Type;
    var union = false;
    var madeUp = false;

    while (true) {
      var inner = JSDocInterpretComments.parseTypeInner(scope, str, pos);
      if (inner == null) {
        return null;
      }
      madeUp = madeUp || inner.madeUp;
      if (union) {
        inner.type.propagate(union);
      } else {
        type = inner.type;
      }
      pos = JSDocInterpretComments.skipSpace(str, inner.end);
      if (str.charCodeAt(pos) != "|".charCodeAt(0)) {
        break;
      }
      pos++;
      if (!union) {
        union = new Types.AVal();
        type.propagate(union);
        type = union;
      }
    }
    var isOptional = false;
    if (str.charCodeAt(pos) == "=".charCodeAt(0)) {
      pos++;
      isOptional = true;
    }
    return new JSDocParseTypeResult(type, pos, isOptional, madeUp);
  }

  static function parseTypeInner(scope: js.Scope, str: String, pos: Int): Null<JSDocParseTypeInnerResult> {
    pos = JSDocInterpretComments.skipSpace(str, pos);
    var type: Types.Type;
    var madeUp = false;

    if (str.substr(pos, 9) == "function(") {
      var args = JSDocInterpretComments.parseLabelList(scope, str, pos + 9, ")");
      if (args == null) {
        return null;
      }
      pos = JSDocInterpretComments.skipSpace(str, args.end);
      if (str.charCodeAt(pos) == ":".charCodeAt(0)) {
        pos++;
        var retType = JSDocInterpretComments.parseType(scope, str, pos);
        if (retType == null) {
          return null;
        }
        pos = retType.end;
        madeUp = madeUp || retType.madeUp;
        type = new Types.Fn(null, new Types.ANull(), args.types, args.labels, retType.type);
      } else {
        type = new Types.Fn(null, new Types.ANull(), [], [], new Types.ANull());
      }
    } else if (str.charCodeAt(pos) == "[".charCodeAt(0)) {
      var inner = JSDocInterpretComments.parseType(scope, str, pos + 1);
      if (inner == null) {
        return null;
      }
      pos = JSDocInterpretComments.skipSpace(str, inner.end);
      madeUp = madeUp || inner.madeUp;
      if (str.charCodeAt(pos) != "]".charCodeAt(0)) {
        return null;
      }
      pos++;
      type = new Types.Arr(inner.type);
    } else if (str.charCodeAt(pos) == "{".charCodeAt(0)) {
      var fields = JSDocInterpretComments.parseLabelList(scope, str, pos + 1, "}");
      if (fields == null) {
        return null;
      }
      type = new Types.Obj(true);
      for (i in 0...fields.types.length) {
        var field = type.defProp(fields.labels[i]);
        field.initializer = true;
        fields.types[i].propagate(field);
      }
      pos = fields.end;
      madeUp = madeUp || fields.madeUp;
    } else if (str.charCodeAt(pos) == "(".charCodeAt(0)) {
      var inner = JSDocInterpretComments.parseType(scope, str, pos + 1);
      if (inner == null) {
        return null;
      }
      pos = JSDocInterpretComments.skipSpace(str, inner.end);
      if (str.charCodeAt(pos) != ")".charCodeAt(0)) {
        return null;
      }
      pos++;
      type = inner.type;
    } else {
      var start = pos;
      if (!TokenUtils.isIdentifierStart(str.charCodeAt(pos))) {
        return null;
      }
      while (TokenUtils.isIdentifierChar(str.charCodeAt(pos))) {
        pos++;
      }
      if (start == pos) {
        return null;
      }
      var word = str.substr(start, pos - start);
      if (word == "number" || word == "integer") {
        type = TypeTools.cx().num;
      } else if (word == "boolean" || word == "bool") {
        type = TypeTools.cx().bool;
      } else if (word == "string") {
        type = TypeTools.cx().str;
      } else if (word == "null" || word == "undefined") {
        type = new Types.ANull();
      } else if (word == "array") {
        var inner: Null<Types.Type> = null;
        if (str.charCodeAt(pos) == ".".charCodeAt(0) && str.charCodeAt(pos + 1) == "<".charCodeAt(0)) {
          var inAngles = JSDocInterpretComments.parseType(scope, str, pos + 2);
          if (inAngles == null) {
            return null;
          }
          pos = JSDocInterpretComments.skipSpace(str, inAngles.end);
          madeUp = madeUp || inAngles.madeUp;
          if (str.charCodeAt(pos++) != ">".charCodeAt(0)) {
            return null;
          }
          inner = inAngles.type;
        }
        type = new Types.Arr(inner);
      } else if (word == "object") {
        type = new Types.Obj(true);
        if (str.charCodeAt(pos) == ".".charCodeAt(0) && str.charCodeAt(pos + 1) == "<".charCodeAt(0)) {
          var key = JSDocInterpretComments.parseType(scope, str, pos + 2);
          if (key == null) {
            return null;
          }
          pos = JSDocInterpretComments.skipSpace(str, key.end);
          if (str.charCodeAt(pos++) != ",".charCodeAt(0)) {
            return null;
          }
          var val = JSDocInterpretComments.parseType(scope, str, pos);
          if (val == null) {
            return null;
          }
          pos = JSDocInterpretComments.skipSpace(str, val.end);
          madeUp = madeUp || key.madeUp || val.madeUp;
          if (str.charCodeAt(pos++) != ">".charCodeAt(0)) {
            return null;
          }
          val.type.propagate(type.defProp("<i>"));
        }
      } else {
        while (str.charCodeAt(pos) == ".".charCodeAt(0) || TokenUtils.isIdentifierChar(str.charCodeAt(pos))) {
          pos++;
        }
        var path = str.substr(start, pos - start);
        var cx = TypeTools.cx();
        var defs = cx.parent != null ? cx.parent.jsdocTypedefs : null;
        var found: Null<Types.Type> = null;
        if (defs != null && defs.exists(path)) {
          found = defs.get(path);
        } else if ((found = TypeUtils.parsePath(path, scope).getObjType()) != null) {
          found = TypeUtils.maybeInstance(found, path);
        } else {
          if (cx.jsdocPlaceholders == null) {
            cx.jsdocPlaceholders = new TypesMap();
          }
          if (!cx.jsdocPlaceholders.exists(path)) {
            cx.jsdocPlaceholders.set(path, new Types.Obj(null, path));
          }
          found = cx.jsdocPlaceholders.get(path);
          madeUp = true;
        }
        type = found;
      }
    }

    return new JSDocParseTypeInnerResult(type, pos, madeUp);
  }

  static function parseLabelList(scope: js.Scope, str: String, pos: Int, close: String): Null<JSDocParseLabelListResult> {
    var labels = [];
    var types = [];
    var madeUp = false;

    while (true) {
      pos = JSDocInterpretComments.skipSpace(str, pos);
      if (str.charCodeAt(pos) == close.charCodeAt(0)) {
        break;
      }
      var colon = str.indexOf(":", pos);
      if (colon < 0) {
        return null;
      }
      var label = str.substr(pos, colon - pos);
      if (!TokenUtils.isIdentifier(label)) {
        return null;
      }
      labels.push(label);
      pos = colon + 1;
      var type = JSDocInterpretComments.parseType(scope, str, pos);
      if (type == null) {
        return null;
      }
      pos = type.end;
      madeUp = madeUp || type.madeUp;
      types.push(type.type);
      pos = JSDocInterpretComments.skipSpace(str, pos);
      var next = str.charCodeAt(pos);
      pos++;
      if (next == close.charCodeAt(0)) {
        break;
      }
      if (next != ",".charCodeAt(0)) {
        return null;
      }
    }
    return new JSDocParseLabelListResult(labels, types, pos, madeUp);
  }

  static function skipSpace(str: String, pos: Int): Int {
    while (str.charCodeAt(pos) <= " ".charCodeAt(0)) {
      pos++;
    }
    return pos;
  }
}

class JSDocParseTypedefs {
  static function jsdocParseTypedefs(text: String, scope: js.Scope): Void {
    var cx = TypeTools.cx();
    var re = ~/@typedef\s+(.*)/g;
    while (re.match(text) != null) {
      var parsed = JSDocInterpretComments.parseTypeOuter(scope, re.matched(1));
      if (parsed == null) {
        continue;
      }
      var name = parsed.type.toString().match(/^(\S+)/);
      if (name != null) {
        cx.parent.jsdocTypedefs.set(name[1], parsed.type);
      }
    }
  }
}

class PostInfer {
  static function postInfer(ast: js.Node, scope: js.Scope): Void {
    JSDocParseTypedefs.jsdocParseTypedefs(ast.sourceFile.text, scope);

    var visitor = new js.NodeVisitor();
    visitor.VariableDeclaration = function(node: js.Node, scope: js.Scope): Bool {
      if (node.commentsBefore != null) {
        var comments = node.commentsBefore;
        var decl = node.asVariableDeclaration();
        var name = decl.declarations[0].id.name;
        var aval = scope.getProp(name);
        JSDocInterpretComments.interpretComments(node, scope, aval, comments);
      }
      return true;
    };
    visitor.FunctionDeclaration = function(node: js.Node, scope: js.Scope): Bool {
      if (node.commentsBefore != null) {
        var comments = node.commentsBefore;
        var decl = node.asFunctionDeclaration();
        var name = decl.id.name;
        var aval = scope.getProp(name);
        var fnType = decl.body.scope.fnType;
        JSDocInterpretComments.interpretComments(node, scope, aval, comments);
      }
      return true;
    };
    visitor.AssignmentExpression = function(node: js.Node, scope: js.Scope): Bool {
      if (node.commentsBefore != null) {
        var comments = node.commentsBefore;
        var expr = node.asAssignmentExpression();
        var left = expr.left;
        var aval = TypeUtils.expressionType({ node: left, state: scope });
        JSDocInterpretComments.interpretComments(node, scope, aval, comments);
      }
      return true;
    };
    visitor.ObjectExpression = function(node: js.Node, scope: js.Scope): Bool {
      var expr = node.asObjectExpression();
      for (i in 0...expr.properties.length) {
        var prop = expr.properties[i];
        if (prop.commentsBefore != null) {
          var comments = prop.commentsBefore;
          var objType = expr.objType;
          var key = prop.key.name;
          var aval = objType.getProp(key);
          JSDocInterpretComments.interpretComments(prop, scope, aval, comments);
        }
      }
      return true;
    };
    visitor.CallExpression = function(node: js.Node, scope: js.Scope): Bool {
      if (node.commentsBefore != null && JSDocInterpretComments.isDefinePropertyCall(node)) {
        var expr = node.asCallExpression();
        var type = TypeUtils.expressionType({ node: expr.arguments[0], state: scope }).getObjType();
        if (type != null) {
          var prop = type.props.get(expr.arguments[1].value);
          if (prop != null) {
            var comments = node.commentsBefore;
            JSDocInterpretComments.interpretComments(node, scope, prop, comments);
          }
        }
      }
      return true;
    };
    visitor.visit(ast, scope, infer.searchVisitor, scope);
  }

  static function isDefinePropertyCall(node: js.Node): Bool {
    if (!node.isKindOf(js.NodeKind.CallExpression)) {
      return false;
    }
    var expr = node.asCallExpression();
    if (!expr.callee.isKindOf(js.NodeKind.MemberExpression)) {
      return false;
    }
    var memberExpr = expr.callee.asMemberExpression();
    if (memberExpr.object.name != "Object" || memberExpr.property.name != "defineProperty") {
      return false;
    }
    if (expr.arguments.length < 3) {
      return false;
    }
    if (expr.arguments[1].value == null) {
      return false;
    }
    return true;
  }
}

class PostParse {
  static function postParse(ast: js.Node, text: String): Void {
    function attachComments(node: js.Node): Void {
      comment.ensureCommentsBefore(text, node);
    }

    var visitor = new js.NodeVisitor();
    visitor.VariableDeclaration = attachComments;
    visitor.FunctionDeclaration = attachComments;
    visitor.AssignmentExpression = function(node: js.Node): Bool {
      if (node.operator == "=") {
        attachComments(node);
      }
      return true;
    };
    visitor.ObjectExpression = function(node: js.Node): Bool {
      for (i in 0...node.asObjectExpression().properties.length) {
        attachComments(node.asObjectExpression().properties[i]);
      }
      return true;
    };
    visitor.CallExpression = function(node: js.Node): Bool {
      if (JSDocInterpretComments.isDefinePropertyCall(node)) {
        attachComments(node);
      }
      return true;
    };
    visitor.visit(ast, null, null, null);
  }
}

class Plugin {
  static function register(server: infer.Server, options: Null<Dynamic>): Void {
    server.jsdocTypedefs = new TypesMap();
    server.onReset = function(): Void {
      server.jsdocTypedefs = new TypesMap();
    };
    server._docComment = new DocComment(options != null ? options.strong : null, options != null ? options.fullDocs : false);

    var passes = new infer.Passes();
    passes.postParse = PostParse.postParse;
    passes.postInfer = PostInfer.postInfer;
    passes.postLoadDef = function(data: Dynamic): Void {
      var defs = data["!typedef"];
      if (defs != null) {
        var cx = TypeTools.cx();
        var orig = data["!name"];
        for (name in defs) {
          var def = TypeUtils.parse(defs[name], orig, name);
          var type = TypeUtils.maybeInstance(def, name);
          cx.parent.jsdocTypedefs.set(name, type);
        }
      }
    };
    return { passes: passes };
  }
}