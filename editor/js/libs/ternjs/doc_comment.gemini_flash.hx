package;

import infer.Infer;
import tern.Tern;
import tern.Comment;
import acorn.Acorn;
import acorn.Walk;

class DocComment {

  static function register(server:Tern, options:Dynamic):Dynamic {
    server.jsdocTypedefs = new haxe.ds.StringMap();
    server.on("reset", function() {
      server.jsdocTypedefs = new haxe.ds.StringMap();
    });
    server._docComment = {
      weight: if (options != null && options.strong == true) WG_STRONG else null,
      fullDocs: if (options != null && options.fullDocs == true) true else null
    };

    return {
      passes: {
        postParse: postParse,
        postInfer: postInfer,
        postLoadDef: postLoadDef
      }
    };
  }

  static function postParse(ast:Dynamic, text:String):Void {
    function attachComments(node:Dynamic) {
      Comment.ensureCommentsBefore(text, node);
    }

    Walk.simple(ast, {
      VariableDeclaration: attachComments,
      FunctionDeclaration: attachComments,
      AssignmentExpression: function(node:Dynamic) {
        if (node.operator == "=") attachComments(node);
      },
      ObjectExpression: function(node:Dynamic) {
        for (i in 0...node.properties.length) {
          attachComments(node.properties[i]);
        }
      },
      CallExpression: function(node:Dynamic) {
        if (isDefinePropertyCall(node)) attachComments(node);
      }
    });
  }

  static function isDefinePropertyCall(node:Dynamic):Bool {
    return node.callee.type == "MemberExpression" &&
      node.callee.object.name == "Object" &&
      node.callee.property.name == "defineProperty" &&
      node.arguments.length >= 3 &&
      Std.typeof(node.arguments[1].value) == "string";
  }

  static function postInfer(ast:Dynamic, scope:Dynamic):Void {
    jsdocParseTypedefs(ast.sourceFile.text, scope);

    Walk.simple(ast, {
      VariableDeclaration: function(node:Dynamic, scope:Dynamic) {
        if (node.commentsBefore != null)
          interpretComments(node, node.commentsBefore, scope,
                            scope.getProp(node.declarations[0].id.name));
      },
      FunctionDeclaration: function(node:Dynamic, scope:Dynamic) {
        if (node.commentsBefore != null)
          interpretComments(node, node.commentsBefore, scope,
                            scope.getProp(node.id.name),
                            node.body.scope.fnType);
      },
      AssignmentExpression: function(node:Dynamic, scope:Dynamic) {
        if (node.commentsBefore != null)
          interpretComments(node, node.commentsBefore, scope,
                            Infer.expressionType({node: node.left, state: scope}));
      },
      ObjectExpression: function(node:Dynamic, scope:Dynamic) {
        for (i in 0...node.properties.length) {
          var prop = node.properties[i];
          if (prop.commentsBefore != null)
            interpretComments(prop, prop.commentsBefore, scope,
                              node.objType.getProp(prop.key.name));
        }
      },
      CallExpression: function(node:Dynamic, scope:Dynamic) {
        if (node.commentsBefore != null && isDefinePropertyCall(node)) {
          var type = Infer.expressionType({node: node.arguments[0], state: scope}).getObjType();
          if (type != null && Std.is(type, Infer.Obj)) {
            var prop = type.props[node.arguments[1].value];
            if (prop != null) interpretComments(node, node.commentsBefore, scope, prop);
          }
        }
      }
    }, Infer.searchVisitor, scope);
  }

  static function postLoadDef(data:Dynamic):Void {
    var defs = data["!typedef"];
    var cx = Infer.cx();
    var orig = data["!name"];
    if (defs != null) {
      for (name in defs) {
        cx.parent.jsdocTypedefs[name] =
          maybeInstance(Infer.def.parse(defs[name], orig, name), name);
      }
    }
  }

  static function interpretComments(node:Dynamic, comments:Array<String>, scope:Dynamic, aval:Dynamic, type:Dynamic):Void {
    jsdocInterpretComments(node, scope, aval, comments);
    var cx = Infer.cx();

    if (type == null && Std.is(aval, Infer.AVal) && aval.types.length > 0) {
      type = aval.types[aval.types.length - 1];
      if (!(Std.is(type, Infer.Obj)) || type.origin != cx.curOrigin || type.doc != null)
        type = null;
    }

    var result = comments[comments.length - 1];
    if (cx.parent._docComment.fullDocs == true) {
      result = result.trim().replace(RegExp.quote("\n[ \t]*\* ?"), "\n");
    } else {
      var dot = result.indexOf(RegExp.quote(". "));
      if (dot > 5) result = result.substring(0, dot + 1);
      result = result.trim().replace(RegExp.quote("\s*\n\s*\*\s*|\s{1,}") , " ");
    }
    result = result.replace(RegExp.quote("^\s*\*+\s*"), "");

    if (Std.is(aval, Infer.AVal)) aval.doc = result;
    if (type != null) type.doc = result;
  }

  static function skipSpace(str:String, pos:Int):Int {
    while (RegExp.quote("\\s").test(str.charAt(pos))) ++pos;
    return pos;
  }

  static function isIdentifier(string:String):Bool {
    if (!Acorn.isIdentifierStart(string.charCodeAt(0))) return false;
    for (i in 1...string.length) {
      if (!Acorn.isIdentifierChar(string.charCodeAt(i))) return false;
    }
    return true;
  }

  static function parseLabelList(scope:Dynamic, str:String, pos:Int, close:String):Dynamic {
    var labels = new Array<String>();
    var types = new Array<Dynamic>();
    var madeUp = false;
    var first = true;
    while (true) {
      pos = skipSpace(str, pos);
      if (first == true && str.charAt(pos) == close) break;
      var colon = str.indexOf(":", pos);
      if (colon < 0) return null;
      var label = str.substring(pos, colon);
      if (!isIdentifier(label)) return null;
      labels.push(label);
      pos = colon + 1;
      var type = parseType(scope, str, pos);
      if (type == null) return null;
      pos = type.end;
      madeUp = madeUp || type.madeUp;
      types.push(type.type);
      pos = skipSpace(str, pos);
      var next = str.charAt(pos);
      ++pos;
      if (next == close) break;
      if (next != ",") return null;
      first = false;
    }
    return {labels: labels, types: types, end: pos, madeUp: madeUp};
  }

  static function parseType(scope:Dynamic, str:String, pos:Int):Dynamic {
    var type;
    var union = false;
    var madeUp = false;
    while (true) {
      var inner = parseTypeInner(scope, str, pos);
      if (inner == null) return null;
      madeUp = madeUp || inner.madeUp;
      if (union == true) inner.type.propagate(union);
      else type = inner.type;
      pos = skipSpace(str, inner.end);
      if (str.charAt(pos) != "|") break;
      pos++;
      if (union == false) {
        union = new Infer.AVal();
        type.propagate(union);
        type = union;
      }
    }
    var isOptional = false;
    if (str.charAt(pos) == "=") {
      ++pos;
      isOptional = true;
    }
    return {type: type, end: pos, isOptional: isOptional, madeUp: madeUp};
  }

  static function parseTypeInner(scope:Dynamic, str:String, pos:Int):Dynamic {
    pos = skipSpace(str, pos);
    var type;
    var madeUp = false;

    if (str.indexOf("function(", pos) == pos) {
      var args = parseLabelList(scope, str, pos + 9, ")");
      var ret = new Infer.ANull();
      if (args == null) return null;
      pos = skipSpace(str, args.end);
      if (str.charAt(pos) == ":") {
        ++pos;
        var retType = parseType(scope, str, pos + 1);
        if (retType == null) return null;
        pos = retType.end;
        ret = retType.type;
        madeUp = retType.madeUp;
      }
      type = new Infer.Fn(null, new Infer.ANull(), args.types, args.labels, ret);
    } else if (str.charAt(pos) == "[") {
      var inner = parseType(scope, str, pos + 1);
      if (inner == null) return null;
      pos = skipSpace(str, inner.end);
      madeUp = inner.madeUp;
      if (str.charAt(pos) != "]") return null;
      ++pos;
      type = new Infer.Arr(inner.type);
    } else if (str.charAt(pos) == "{") {
      var fields = parseLabelList(scope, str, pos + 1, "}");
      if (fields == null) return null;
      type = new Infer.Obj(true);
      for (i in 0...fields.types.length) {
        var field = type.defProp(fields.labels[i]);
        field.initializer = true;
        fields.types[i].propagate(field);
      }
      pos = fields.end;
      madeUp = fields.madeUp;
    } else if (str.charAt(pos) == "(") {
      var inner = parseType(scope, str, pos + 1);
      if (inner == null) return null;
      pos = skipSpace(str, inner.end);
      if (str.charAt(pos) != ")") return null;
      ++pos;
      type = inner.type;
    } else {
      var start = pos;
      if (!Acorn.isIdentifierStart(str.charCodeAt(pos))) return null;
      while (Acorn.isIdentifierChar(str.charCodeAt(pos))) ++pos;
      if (start == pos) return null;
      var word = str.substring(start, pos);
      if (RegExp.quote("^(number|integer)$").test(word)) type = Infer.cx().num;
      else if (RegExp.quote("^bool(ean)?$").test(word)) type = Infer.cx().bool;
      else if (RegExp.quote("^string$").test(word)) type = Infer.cx().str;
      else if (RegExp.quote("^(null|undefined)$").test(word)) type = new Infer.ANull();
      else if (RegExp.quote("^array$").test(word)) {
        var inner = null;
        if (str.charAt(pos) == "." && str.charAt(pos + 1) == "<") {
          var inAngles = parseType(scope, str, pos + 2);
          if (inAngles == null) return null;
          pos = skipSpace(str, inAngles.end);
          madeUp = inAngles.madeUp;
          if (str.charAt(pos++) != ">") return null;
          inner = inAngles.type;
        }
        type = new Infer.Arr(inner);
      } else if (RegExp.quote("^object$").test(word)) {
        type = new Infer.Obj(true);
        if (str.charAt(pos) == "." && str.charAt(pos + 1) == "<") {
          var key = parseType(scope, str, pos + 2);
          if (key == null) return null;
          pos = skipSpace(str, key.end);
          if (str.charAt(pos++) != ",") return null;
          var val = parseType(scope, str, pos);
          if (val == null) return null;
          pos = skipSpace(str, val.end);
          madeUp = key.madeUp || val.madeUp;
          if (str.charAt(pos++) != ">") return null;
          val.type.propagate(type.defProp("<i>"));
        }
      } else {
        while (str.charCodeAt(pos) == 46 ||
               Acorn.isIdentifierChar(str.charCodeAt(pos))) ++pos;
        var path = str.substring(start, pos);
        var cx = Infer.cx();
        var defs = cx.parent != null ? cx.parent.jsdocTypedefs : null;
        var found;
        if (defs != null && defs.exists(path)) {
          type = defs.get(path);
        } else if ((found = Infer.def.parsePath(path, scope).getObjType()) != null) {
          type = maybeInstance(found, path);
        } else {
          if (cx.jsdocPlaceholders == null) cx.jsdocPlaceholders = new haxe.ds.StringMap();
          if (!cx.jsdocPlaceholders.exists(path))
            type = cx.jsdocPlaceholders.set(path, new Infer.Obj(null, path));
          else
            type = cx.jsdocPlaceholders.get(path);
          madeUp = true;
        }
      }
    }

    return {type: type, end: pos, madeUp: madeUp};
  }

  static function maybeInstance(type:Dynamic, path:String):Dynamic {
    if (Std.is(type, Infer.Fn) && RegExp.quote("^[A-Z]").test(path)) {
      var proto = type.getProp("prototype").getObjType();
      if (Std.is(proto, Infer.Obj)) return Infer.getInstance(proto);
    }
    return type;
  }

  static function parseTypeOuter(scope:Dynamic, str:String, pos:Int):Dynamic {
    pos = skipSpace(str, pos);
    if (str.charAt(pos) != "{") return null;
    var result = parseType(scope, str, pos + 1);
    if (result == null) return null;
    var end = skipSpace(str, result.end);
    if (str.charAt(end) != "}") return null;
    result.end = end + 1;
    return result;
  }

  static function jsdocInterpretComments(node:Dynamic, scope:Dynamic, aval:Dynamic, comments:Array<String>):Void {
    var type;
    var args;
    var ret;
    var foundOne = false;
    var self;
    var parsed;

    for (i in 0...comments.length) {
      var comment = comments[i];
      var decl = RegExp.quote("(?:\n|\$|\*)\s*@(type|param|arg(?:ument)?|returns?|this)\s+(.*)");
      var m;
      while ((m = decl.exec(comment)) != null) {
        if (m[1] == "this" && (parsed = parseType(scope, m[2], 0)) != null) {
          self = parsed;
          foundOne = true;
          continue;
        }

        if ((parsed = parseTypeOuter(scope, m[2])) == null) continue;
        foundOne = true;

        switch(m[1]) {
        case "returns":
        case "return":
          ret = parsed;
          break;
        case "type":
          type = parsed;
          break;
        case "param":
        case "arg":
        case "argument":
          var name = m[2].substring(parsed.end).match(RegExp.quote("^\s*(\[?)\s*([^\]\s=]+)\s*(?:=[^\]]+\s*)?(\]?).*"));
          if (name == null) continue;
          var argname = name[2] + (parsed.isOptional || (name[1] === "[" && name[3] === "]") ? "?" : "");
          if (args == null) args = new haxe.ds.StringMap();
          args.set(argname, parsed);
          break;
        }
      }
    }

    if (foundOne == true) applyType(type, self, args, ret, node, aval);
  };

  static function jsdocParseTypedefs(text:String, scope:Dynamic):Void {
    var cx = Infer.cx();

    var re = RegExp.quote("\\s@typedef\\s+(.*)");
    var m;
    while ((m = re.exec(text)) != null) {
      var parsed = parseTypeOuter(scope, m[1]);
      var name = parsed != null ? m[1].substring(parsed.end).match(RegExp.quote("^\s*(\S+)")) : null;
      if (name != null)
        cx.parent.jsdocTypedefs.set(name[1], parsed.type);
    }
  }

  static function propagateWithWeight(type:Dynamic, target:Dynamic):Void {
    var cx = Infer.cx();
    var weight = cx.parent != null ? cx.parent._docComment.weight : null;
    type.type.propagate(target, weight != null ? weight : (type.madeUp == true ? WG_MADEUP : null));
  }

  static function applyType(type:Dynamic, self:Dynamic, args:Dynamic, ret:Dynamic, node:Dynamic, aval:Dynamic):Void {
    var fn;
    if (node.type == "VariableDeclaration") {
      var decl = node.declarations[0];
      if (decl.init != null && decl.init.type == "FunctionExpression") fn = decl.init.body.scope.fnType;
    } else if (node.type == "FunctionDeclaration") {
      fn = node.body.scope.fnType;
    } else if (node.type == "AssignmentExpression") {
      if (node.right.type == "FunctionExpression")
        fn = node.right.body.scope.fnType;
    } else if (node.type == "CallExpression") {
    } else {
      if (node.value.type == "FunctionExpression") fn = node.value.body.scope.fnType;
    }

    if (fn != null && (args != null || ret != null || self != null)) {
      if (args != null) {
        for (i in 0...fn.argNames.length) {
          var name = fn.argNames[i];
          var known = args.exists(name) ? args.get(name) : null;
          if (known == null && (known = args.exists(name + "?") ? args.get(name + "?") : null))
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

  static inline var WG_MADEUP:Int = 1;
  static inline var WG_STRONG:Int = 101;
}