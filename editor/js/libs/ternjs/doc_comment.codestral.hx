import js.Browser.document;
import js.lib.JsTools;
import tern.Tern;
import tern.infer.Infer;
import tern.infer.Type;
import tern.def.Def;
import acorn.Acorn;
import acorn.walk.Walk;

class DocComment {
  private static var WG_MADEUP:Int = 1;
  private static var WG_STRONG:Int = 101;

  public static function registerPlugin(server:Tern, options:Dynamic) {
    server.jsdocTypedefs = js.Boot.createEmptyObject();
    server.on("reset", () -> {
      server.jsdocTypedefs = js.Boot.createEmptyObject();
    });
    server._docComment = {
      weight: (options && options.strong) ? WG_STRONG : null,
      fullDocs: (options && options.fullDocs)
    };

    return {
      passes: {
        postParse: postParse,
        postInfer: postInfer,
        postLoadDef: postLoadDef
      }
    };
  }

  private static function postParse(ast:Dynamic, text:String) {
    function attachComments(node:Dynamic) {
      Tern.comment.ensureCommentsBefore(text, node);
    }

    Walk.simple(ast, {
      VariableDeclaration: attachComments,
      FunctionDeclaration: attachComments,
      AssignmentExpression: function(node:Dynamic) {
        if (node.operator == "=") attachComments(node);
      },
      ObjectExpression: function(node:Dynamic) {
        for (i in 0...node.properties.length)
          attachComments(node.properties[i]);
      },
      CallExpression: function(node:Dynamic) {
        if (isDefinePropertyCall(node)) attachComments(node);
      }
    });
  }

  private static function isDefinePropertyCall(node:Dynamic):Bool {
    return node.callee.type == "MemberExpression" &&
      node.callee.object.name == "Object" &&
      node.callee.property.name == "defineProperty" &&
      node.arguments.length >= 3 &&
      js.Boot.isOfType(node.arguments[1].value, String);
  }

  private static function postInfer(ast:Dynamic, scope:Dynamic) {
    jsdocParseTypedefs(ast.sourceFile.text, scope);

    Walk.simple(ast, {
      VariableDeclaration: function(node:Dynamic, scope:Dynamic) {
        if (node.commentsBefore)
          interpretComments(node, node.commentsBefore, scope,
                            scope.getProp(node.declarations[0].id.name));
      },
      FunctionDeclaration: function(node:Dynamic, scope:Dynamic) {
        if (node.commentsBefore)
          interpretComments(node, node.commentsBefore, scope,
                            scope.getProp(node.id.name),
                            node.body.scope.fnType);
      },
      AssignmentExpression: function(node:Dynamic, scope:Dynamic) {
        if (node.commentsBefore)
          interpretComments(node, node.commentsBefore, scope,
                            Infer.expressionType({node: node.left, state: scope}));
      },
      ObjectExpression: function(node:Dynamic, scope:Dynamic) {
        for (i in 0...node.properties.length) {
          var prop:Dynamic = node.properties[i];
          if (prop.commentsBefore)
            interpretComments(prop, prop.commentsBefore, scope,
                              node.objType.getProp(prop.key.name));
        }
      },
      CallExpression: function(node:Dynamic, scope:Dynamic) {
        if (node.commentsBefore && isDefinePropertyCall(node)) {
          var type:Type = Infer.expressionType({node: node.arguments[0], state: scope}).getObjType();
          if (type && type is Infer.Obj) {
            var prop:Dynamic = type.props[node.arguments[1].value];
            if (prop) interpretComments(node, node.commentsBefore, scope, prop);
          }
        }
      }
    }, Infer.searchVisitor, scope);
  }

  private static function postLoadDef(data:Dynamic) {
    var defs:Dynamic = data["!typedef"];
    var cx:Infer = Infer.cx();
    var orig:String = data["!name"];
    if (defs != null) {
      for (name in Reflect.fields(defs))
        cx.parent.jsdocTypedefs[name] =
          maybeInstance(Def.parse(defs[name], orig, name), name);
    }
  }

  private static function interpretComments(node:Dynamic, comments:Array<String>, scope:Dynamic, aval:Dynamic, type:Type = null) {
    jsdocInterpretComments(node, scope, aval, comments);
    var cx:Infer = Infer.cx();

    if (type == null && aval is Infer.AVal && aval.types.length > 0) {
      type = aval.types[aval.types.length - 1];
      if (!(type is Infer.Obj) || type.origin != cx.curOrigin || type.doc != null)
        type = null;
    }

    var result:String = comments[comments.length - 1];
    if (cx.parent._docComment.fullDocs) {
      result = result.trim().replace(/\n[ \t]*\* ?/g, "\n");
    } else {
      var dot:Int = result.search(/\.\s/);
      if (dot > 5) result = result.substring(0, dot + 1);
      result = result.trim().replace(/\s*\n\s*\*\s*|\s{1,}/g, " ");
    }
    result = result.replace(/^\s*\*+\s*/, "");

    if (aval is Infer.AVal) aval.doc = result;
    if (type != null) type.doc = result;
  }

  private static function skipSpace(str:String, pos:Int):Int {
    while (/\s/.test(str.charAt(pos))) ++pos;
    return pos;
  }

  private static function isIdentifier(string:String):Bool {
    if (!Acorn.isIdentifierStart(string.codePointAt(0))) return false;
    for (i in 1...string.length)
      if (!Acorn.isIdentifierChar(string.codePointAt(i))) return false;
    return true;
  }

  private static function parseLabelList(scope:Dynamic, str:String, pos:Int, close:String) {
    var labels:Array<String> = [];
    var types:Array<Type> = [];
    var madeUp:Bool = false;
    var first:Bool = true;
    while (true) {
      pos = skipSpace(str, pos);
      if (first && str.charAt(pos) == close) break;
      var colon:Int = str.indexOf(":", pos);
      if (colon < 0) return null;
      var label:String = str.substring(pos, colon);
      if (!isIdentifier(label)) return null;
      labels.push(label);
      pos = colon + 1;
      var type:Dynamic = parseType(scope, str, pos);
      if (type == null) return null;
      pos = type.end;
      madeUp = madeUp || type.madeUp;
      types.push(type.type);
      pos = skipSpace(str, pos);
      var next:String = str.charAt(pos);
      ++pos;
      if (next == close) break;
      if (next != ",") return null;
      first = false;
    }
    return {labels: labels, types: types, end: pos, madeUp: madeUp};
  }

  private static function parseType(scope:Dynamic, str:String, pos:Int) {
    var type:Type = null;
    var union:Bool = false;
    var madeUp:Bool = false;
    while (true) {
      var inner:Dynamic = parseTypeInner(scope, str, pos);
      if (inner == null) return null;
      madeUp = madeUp || inner.madeUp;
      if (union) inner.type.propagate(union);
      else type = inner.type;
      pos = skipSpace(str, inner.end);
      if (str.charAt(pos) != "|") break;
      pos++;
      if (!union) {
        union = new Infer.AVal();
        type.propagate(union);
        type = union;
      }
    }
    var isOptional:Bool = false;
    if (str.charAt(pos) == "=") {
      ++pos;
      isOptional = true;
    }
    return {type: type, end: pos, isOptional: isOptional, madeUp: madeUp};
  }

  private static function parseTypeInner(scope:Dynamic, str:String, pos:Int) {
    pos = skipSpace(str, pos);
    var type:Type = null;
    var madeUp:Bool = false;

    if (str.indexOf("function(", pos) == pos) {
      var args:Dynamic = parseLabelList(scope, str, pos + 9, ")");
      if (args == null) return null;
      pos = skipSpace(str, args.end);
      var ret:Type = Infer.ANull;
      if (str.charAt(pos) == ":") {
        ++pos;
        var retType:Dynamic = parseType(scope, str, pos + 1);
        if (retType == null) return null;
        pos = retType.end;
        ret = retType.type;
        madeUp = retType.madeUp;
      }
      type = new Infer.Fn(null, Infer.ANull, args.types, args.labels, ret);
    } else if (str.charAt(pos) == "[") {
      var inner:Dynamic = parseType(scope, str, pos + 1);
      if (inner == null) return null;
      pos = skipSpace(str, inner.end);
      madeUp = inner.madeUp;
      if (str.charAt(pos) != "]") return null;
      ++pos;
      type = new Infer.Arr(inner.type);
    } else if (str.charAt(pos) == "{") {
      var fields:Dynamic = parseLabelList(scope, str, pos + 1, "}");
      if (fields == null) return null;
      type = new Infer.Obj(true);
      for (i in 0...fields.types.length) {
        var field:Dynamic = type.defProp(fields.labels[i]);
        field.initializer = true;
        fields.types[i].propagate(field);
      }
      pos = fields.end;
      madeUp = fields.madeUp;
    } else if (str.charAt(pos) == "(") {
      var inner:Dynamic = parseType(scope, str, pos + 1);
      if (inner == null) return null;
      pos = skipSpace(str, inner.end);
      if (str.charAt(pos) != ")") return null;
      ++pos;
      type = inner.type;
    } else {
      var start:Int = pos;
      if (!Acorn.isIdentifierStart(str.codePointAt(pos))) return null;
      while (Acorn.isIdentifierChar(str.codePointAt(pos))) ++pos;
      if (start == pos) return null;
      var word:String = str.substring(start, pos);
      var cx:Infer = Infer.cx();
      if (/^(number|integer)$/i.test(word)) type = cx.num;
      else if (/^bool(ean)?$/i.test(word)) type = cx.bool;
      else if (/^string$/i.test(word)) type = cx.str;
      else if (/^(null|undefined)$/i.test(word)) type = Infer.ANull;
      else if (/^array$/i.test(word)) {
        var inner:Type = null;
        if (str.charAt(pos) == "." && str.charAt(pos + 1) == "<") {
          var inAngles:Dynamic = parseType(scope, str, pos + 2);
          if (inAngles == null) return null;
          pos = skipSpace(str, inAngles.end);
          madeUp = inAngles.madeUp;
          if (str.charAt(pos++) != ">") return null;
          inner = inAngles.type;
        }
        type = new Infer.Arr(inner);
      } else if (/^object$/i.test(word)) {
        type = new Infer.Obj(true);
        if (str.charAt(pos) == "." && str.charAt(pos + 1) == "<") {
          var key:Dynamic = parseType(scope, str, pos + 2);
          if (key == null) return null;
          pos = skipSpace(str, key.end);
          if (str.charAt(pos++) != ",") return null;
          var val:Dynamic = parseType(scope, str, pos);
          if (val == null) return null;
          pos = skipSpace(str, val.end);
          madeUp = key.madeUp || val.madeUp;
          if (str.charAt(pos++) != ">") return null;
          val.type.propagate(type.defProp("<i>"));
        }
      } else {
        while (str.codePointAt(pos) == 46 ||
               Acorn.isIdentifierChar(str.codePointAt(pos))) ++pos;
        var path:String = str.substring(start, pos);
        var cx:Infer = Infer.cx();
        var defs:Dynamic = cx.parent && cx.parent.jsdocTypedefs;
        var found:Type = null;
        if (defs != null && defs.hasOwnProperty(path)) {
          type = defs[path];
        } else if (found = Def.parsePath(path, scope).getObjType()) {
          type = maybeInstance(found, path);
        } else {
          if (cx.jsdocPlaceholders == null) cx.jsdocPlaceholders = js.Boot.createEmptyObject();
          if (!cx.jsdocPlaceholders.hasOwnProperty(path))
            type = cx.jsdocPlaceholders[path] = new Infer.Obj(null, path);
          else
            type = cx.jsdocPlaceholders[path];
          madeUp = true;
        }
      }
    }

    return {type: type, end: pos, madeUp: madeUp};
  }

  private static function maybeInstance(type:Type, path:String):Type {
    if (type is Infer.Fn && /^[A-Z]/.test(path)) {
      var proto:Type = type.getProp("prototype").getObjType();
      if (proto is Infer.Obj) return Infer.getInstance(proto);
    }
    return type;
  }

  private static function parseTypeOuter(scope:Dynamic, str:String, pos:Int = 0) {
    pos = skipSpace(str, pos);
    if (str.charAt(pos) != "{") return null;
    var result:Dynamic = parseType(scope, str, pos + 1);
    if (result == null) return null;
    var end:Int = skipSpace(str, result.end);
    if (str.charAt(end) != "}") return null;
    result.end = end + 1;
    return result;
  }

  private static function jsdocInterpretComments(node:Dynamic, scope:Dynamic, aval:Dynamic, comments:Array<String>) {
    var type:Dynamic = null;
    var args:Dynamic = null;
    var ret:Dynamic = null;
    var foundOne:Bool = false;
    var self:Dynamic = null;
    var parsed:Dynamic = null;

    for (i in 0...comments.length) {
      var comment:String = comments[i];
      var decl:EReg = new EReg("(?:\\n|\\$|\\*)\\s*@(type|param|arg(?:ument)?|returns?|this)\\s+(.*)", "g");
      var m:Dynamic = null;
      while ((m = decl.exec(comment)) != null) {
        if (m[1] == "this" && (parsed = parseType(scope, m[2], 0))) {
          self = parsed;
          foundOne = true;
          continue;
        }

        if ((parsed = parseTypeOuter(scope, m[2])) == null) continue;
        foundOne = true;

        switch(m[1]) {
        case "returns": case "return":
          ret = parsed; break;
        case "type":
          type = parsed; break;
        case "param": case "arg": case "argument":
            var name:Array<String> = m[2].substring(parsed.end).match(/^\s*(\[?)\s*([^\]\s=]+)\s*(?:=[^\]]+\s*)?(\]?).*/);
            if (name == null) continue;
            var argname:String = name[2] + (parsed.isOptional || (name[1] === '[' && name[3] === ']') ? "?" : "");
          if (args == null) args = js.Boot.createEmptyObject();
          args[argname] = parsed;
          break;
        }
      }
    }

    if (foundOne) applyType(type, self, args, ret, node, aval);
  };

  private static function jsdocParseTypedefs(text:String, scope:Dynamic) {
    var cx:Infer = Infer.cx();

    var re:EReg = new EReg("\\s@typedef\\s+(.*)","g");
    var m:Dynamic = null;
    while ((m = re.exec(text)) != null) {
      var parsed:Dynamic = parseTypeOuter(scope, m[1]);
      var name:Array<String> = parsed != null ? m[1].substring(parsed.end).match(/^\s*(\S+)/) : null;
      if (name != null)
        cx.parent.jsdocTypedefs[name[1]] = parsed.type;
    }
  }

  private static function propagateWithWeight(type:Dynamic, target:Dynamic) {
    var weight:Int = Infer.cx().parent._docComment.weight;
    type.type.propagate(target, weight != null ? weight : (type.madeUp ? WG_MADEUP : null));
  }

  private static function applyType(type:Dynamic, self:Dynamic, args:Dynamic, ret:Dynamic, node:Dynamic, aval:Dynamic) {
    var fn:Infer.Fn = null;
    if (node.type == "VariableDeclaration") {
      var decl:Dynamic = node.declarations[0];
      if (decl.init != null && decl.init.type == "FunctionExpression") fn = decl.init.body.scope.fnType;
    } else if (node.type == "FunctionDeclaration") {
      fn = node.body.scope.fnType;
    } else if (node.type == "AssignmentExpression") {
      if (node.right.type == "FunctionExpression")
        fn = node.right.body.scope.fnType;
    } else if (node.type == "CallExpression") {
    } else { // An object property
      if (node.value.type == "FunctionExpression") fn = node.value.body.scope.fnType;
    }

    if (fn != null && (args != null || ret != null || self != null)) {
      if (args != null) {
        for (i in 0...fn.argNames.length) {
          var name:String = fn.argNames[i];
          var known:Dynamic = args[name];
          if (known == null && (known = args[name + "?"]))
            fn.argNames[i] += "?";
          if (known != null) propagateWithWeight(known, fn.args[i]);
        }
      }
      if (ret != null) propagateWithWeight(ret, fn.retval);
      if (self != null) propagateWithWeight(self, fn.self);
    } else if (type != null) {
      propagateWithWeight(type, aval);
    }
  };
}