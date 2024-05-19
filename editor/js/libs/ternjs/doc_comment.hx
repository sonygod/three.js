package three.js.editor.js.libs.ternjs.doc_comment;

import haxe.ds.ObjectMap;
import infer.AVal;
import infer.Cx;
import infer.Fn;
import infer.Obj;
import tern.Comment;
import tern.Infer;
import tern.Server;

class DocComment {
  static var WG_MADEUP = 1;
  static var WG_STRONG = 101;

  static function registerPlugin(server:Server, options:Dynamic) {
    server.jsdocTypedefs = new ObjectMap();
    server.on("reset", function() {
      server.jsdocTypedefs = new ObjectMap();
    });
    server._docComment = {
      weight: options && options.strong ? WG_STRONG : null,
      fullDocs: options && options.fullDocs
    };

    return {
      passes: {
        postParse: postParse,
        postInfer: postInfer,
        postLoadDef: postLoadDef
      }
    };
  }

  static function postParse(ast:Dynamic, text:String) {
    function attachComments(node:Dynamic) {
      Comment.ensureCommentsBefore(text, node);
    }

    walk.simple(ast, {
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

  static function isDefinePropertyCall(node:Dynamic) {
    return node.callee.type == "MemberExpression" &&
      node.callee.object.name == "Object" &&
      node.callee.property.name == "defineProperty" &&
      node.arguments.length >= 3 &&
      Std.is(node.arguments[1].value, String);
  }

  static function postInfer(ast:Dynamic, scope:Dynamic) {
    jsdocParseTypedefs(ast.sourceFile.text, scope);

    walk.simple(ast, {
      VariableDeclaration: function(node:Dynamic, scope:Dynamic) {
        if (node.commentsBefore) {
          interpretComments(node, node.commentsBefore, scope,
                            scope.getProp(node.declarations[0].id.name));
        }
      },
      FunctionDeclaration: function(node:Dynamic, scope:Dynamic) {
        if (node.commentsBefore) {
          interpretComments(node, node.commentsBefore, scope,
                            scope.getProp(node.id.name), node.body.scope.fnType);
        }
      },
      AssignmentExpression: function(node:Dynamic, scope:Dynamic) {
        if (node.commentsBefore) {
          interpretComments(node, node.commentsBefore, scope,
                            Infer.expressionType({node: node.left, state: scope}));
        }
      },
      ObjectExpression: function(node:Dynamic, scope:Dynamic) {
        for (i in 0...node.properties.length) {
          var prop = node.properties[i];
          if (prop.commentsBefore) {
            interpretComments(prop, prop.commentsBefore, scope,
                               node.objType.getProp(prop.key.name));
          }
        }
      },
      CallExpression: function(node:Dynamic, scope:Dynamic) {
        if (node.commentsBefore && isDefinePropertyCall(node)) {
          var type = Infer.expressionType({node: node.arguments[0], state: scope}).getObjType();
          if (type && Std.is(type, infer.Obj)) {
            var prop = type.props[node.arguments[1].value];
            if (prop) interpretComments(node, node.commentsBefore, scope, prop);
          }
        }
      }
    }, Infer.searchVisitor, scope);
  }

  static function postLoadDef(data:Dynamic) {
    var defs = data["!typedef"];
    var cx = Infer.cx();
    var orig = data["!name"];
    if (defs) for (name in defs) {
      cx.parent.jsdocTypedefs[name] =
        maybeInstance(Infer.def.parse(defs[name], orig, name), name);
    }
  }

  static function interpretComments(node:Dynamic, comments:Array<String>, scope:Dynamic, aval:AVal, type:Dynamic) {
    jsdocInterpretComments(node, scope, aval, comments);
    var cx = Infer.cx();

    if (!type && aval instanceof AVal && aval.types.length > 0) {
      type = aval.types[aval.types.length - 1];
      if (!(type instanceof Obj) || type.origin != cx.curOrigin || type.doc)
        type = null;
    }

    var result = comments[comments.length - 1];
    if (cx.parent._docComment.fullDocs) {
      result = result.trim().replace(~/\n[ \t]*\* ?/g, "\n");
    } else {
      var dot = result.indexOf(". ");
      if (dot > 5) result = result.substring(0, dot + 1);
      result = result.trim().replace(~/\s*\n\s*\*\s*|\s{1,}/g, " ");
    }
    result = result.replace(~/^\s*\*+/g, "");

    if (aval instanceof AVal) aval.doc = result;
    if (type) type.doc = result;
  }

  static function skipSpace(str:String, pos:Int) {
    while (~/\s/.test(str.charAt(pos))) ++pos;
    return pos;
  }

  static function isIdentifier(string:String) {
    if (!~/[a-zA-Z_$]/.test(string.charCodeAt(0))) return false;
    for (i in 1...string.length) {
      if (!~/[a-zA-Z_$0-9]/.test(string.charCodeAt(i))) return false;
    }
    return true;
  }

  static function parseLabelList(scope:Dynamic, str:String, pos:Int, close:String) {
    var labels:Array<String> = [], types:Array<Dynamic> = [], madeUp = false;
    while (true) {
      pos = skipSpace(str, pos);
      if (str.charAt(pos) == close) break;
      var colon = str.indexOf(":", pos);
      if (colon < 0) return null;
      var label = str.substring(pos, colon);
      if (!isIdentifier(label)) return null;
      labels.push(label);
      pos = colon + 1;
      var type = parseType(scope, str, pos);
      if (!type) return null;
      pos = type.end;
      madeUp = madeUp || type.madeUp;
      types.push(type.type);
      pos = skipSpace(str, pos);
      if (str.charAt(pos) == close) break;
      if (str.charAt(pos++) != ",") return null;
    }
    return {labels: labels, types: types, end: pos, madeUp: madeUp};
  }

  static function parseType(scope:Dynamic, str:String, pos:Int) {
    var type:Dynamic, union = false, madeUp = false;
    while (true) {
      var inner = parseTypeInner(scope, str, pos);
      if (!inner) return null;
      madeUp = madeUp || inner.madeUp;
      if (union) inner.type.propagate(union);
      else type = inner.type;
      pos = skipSpace(str, inner.end);
      if (str.charAt(pos) != "|") break;
      pos++;
      if (!union) {
        union = new AVal();
        type.propagate(union);
        type = union;
      }
    }
    var isOptional = false;
    if (str.charAt(pos) == "=") {
      pos++;
      isOptional = true;
    }
    return {type: type, end: pos, isOptional: isOptional, madeUp: madeUp};
  }

  static function parseTypeInner(scope:Dynamic, str:String, pos:Int) {
    pos = skipSpace(str, pos);
    var type:Dynamic, madeUp = false;

    if (str.indexOf("function(", pos) == pos) {
      var args = parseLabelList(scope, str, pos + 9, ")");
      if (!args) return null;
      pos = skipSpace(str, args.end);
      if (str.charAt(pos) == ":") {
        pos++;
        var retType = parseType(scope, str, pos + 1);
        if (!retType) return null;
        pos = skipSpace(str, retType.end);
        madeUp = retType.madeUp;
      }
      type = new Fn(null, Infer.ANull, args.types, args.labels, retType.type);
    } else if (str.charAt(pos) == "[") {
      var inner = parseType(scope, str, pos + 1);
      if (!inner) return null;
      pos = skipSpace(str, inner.end);
      madeUp = inner.madeUp;
      if (str.charAt(pos) != "]") return null;
      pos++;
      type = new Arr(inner.type);
    } else if (str.charAt(pos) == "{") {
      var fields = parseLabelList(scope, str, pos + 1, "}");
      if (!fields) return null;
      type = new Obj(true);
      for (i in 0...fields.types.length) {
        var field = type.defProp(fields.labels[i]);
        field.initializer = true;
        fields.types[i].propagate(field);
      }
      pos = fields.end;
      madeUp = fields.madeUp;
    } else if (str.charAt(pos) == "(") {
      var inner = parseType(scope, str, pos + 1);
      if (!inner) return null;
      pos = skipSpace(str, inner.end);
      if (str.charAt(pos) != ")") return null;
      pos++;
      type = inner.type;
    } else {
      var start = pos;
      if (!~/[a-zA-Z_$]/.test(str.charCodeAt(pos))) return null;
      while (~/[a-zA-Z_$0-9]/.test(str.charCodeAt(pos))) ++pos;
      if (start == pos) return null;
      var word = str.substring(start, pos);
      if (~/(number|integer)$/i.test(word)) type = Infer.cx().num;
      else if (~/(bool(ean)?$/i.test(word)) type = Infer.cx().bool;
      else if (~/string$/i.test(word)) type = Infer.cx().str;
      else if (~/(null|undefined)$/i.test(word)) type = Infer.ANull;
      else if (~/(array$/i.test(word))) {
        var inner = null;
        if (str.charAt(pos) == "." && str.charAt(pos + 1) == "<") {
          var inAngles = parseType(scope, str, pos + 2);
          if (!inAngles) return null;
          pos = skipSpace(str, inAngles.end);
          madeUp = inAngles.madeUp;
          if (str.charAt(pos++) != ">") return null;
          inner = inAngles.type;
        }
        type = new Arr(inner);
      } else if (~/(object$/i.test(word))) {
        type = new Obj(true);
        if (str.charAt(pos) == "." && str.charAt(pos + 1) == "<") {
          var key = parseType(scope, str, pos + 2);
          if (!key) return null;
          pos = skipSpace(str, key.end);
          if (str.charAt(pos++) != ">") return null;
          key.type.propagate(type.defProp("<i>"));
        }
      } else {
        while (~/[.a-zA-Z_$0-9]/.test(str.charCodeAt(pos))) ++pos;
        var path = str.substring(start, pos);
        var cx = Infer.cx();
        var defs = cx.parent.jsdocTypedefs;
        var found;
        if (defs && (path in defs)) {
          type = defs[path];
        } else if ((found = Infer.def.parsePath(path, scope).getObjType())) {
          type = maybeInstance(found, path);
        } else {
          if (!cx.jsdocPlaceholders) cx.jsdocPlaceholders = new ObjectMap();
          if (!(path in cx.jsdocPlaceholders))
            type = cx.jsdocPlaceholders[path] = new Obj(null, path);
          else
            type = cx.jsdocPlaceholders[path];
          madeUp = true;
        }
      }
    }

    return {type: type, end: pos, madeUp: madeUp};
  }

  static function maybeInstance(type:Dynamic, path:String) {
    if (type instanceof Fn && ~/^[A-Z]/.test(path)) {
      var proto = type.getProp("prototype").getObjType();
      if (proto instanceof Obj) return Infer.getInstance(proto);
    }
    return type;
  }

  static function parseTypeOuter(scope:Dynamic, str:String, pos:Int) {
    pos = skipSpace(str, pos || 0);
    if (str.charAt(pos) != "{") return null;
    var result = parseType(scope, str, pos + 1);
    if (!result) return null;
    var end = skipSpace(str, result.end);
    if (str.charAt(end) != "}") return null;
    result.end = end + 1;
    return result;
  }

  static function jsdocInterpretComments(node:Dynamic, scope:Dynamic, aval:AVal, comments:Array<String>) {
    var type:Dynamic, args:Dynamic, ret:Dynamic, foundOne = false, self:Dynamic, parsed:Dynamic;

    for (i in 0...comments.length) {
      var comment = comments[i];
      var decl = ~/^(?:\n|\$|\*)\s*@(type|param|arg(?:ument)?|returns?|this)\s+(.*)/g;
      while (decl.match(comment)) {
        if (decl.matched(1) == "this" && (parsed = parseType(scope, decl.matched(2), 0))) {
          self = parsed;
          foundOne = true;
          continue;
        }

        if (!(parsed = parseTypeOuter(scope, decl.matched(2)))) continue;
        foundOne = true;

        switch(decl.matched(1)) {
          case "returns", "return":
            ret = parsed;
          case "type":
            type = parsed;
          case "param", "arg", "argument":
            var name = decl.matched(2).match(~/^([^=]+)(?:=([^=]+))?$/);
            if (!name) continue;
            var argname = name[1] + (name[2] ? "?" : "");
            (args || (args = new ObjectMap()))[argname] = parsed;
            break;
        }
      }
    }

    if (foundOne) applyType(type, self, args, ret, node, aval);
  };

  static function applyType(type:Dynamic, self:Dynamic, args:Dynamic, ret:Dynamic, node:Dynamic, aval:AVal) {
    var fn:Fn;
    if (node.type == "VariableDeclaration") {
      var decl = node.declarations[0];
      if (decl.init && decl.init.type == "FunctionExpression") fn = decl.init.body.scope.fnType;
    } else if (node.type == "FunctionDeclaration") {
      fn = node.body.scope.fnType;
    } else if (node.type == "AssignmentExpression") {
      if (node.right.type == "FunctionExpression") fn = node.right.body.scope.fnType;
    } else { // An object property
      if (node.value.type == "FunctionExpression") fn = node.value.body.scope.fnType;
    }

    if (fn && (args || ret || self)) {
      if (args) for (i in 0...fn.argNames.length) {
        var name = fn.argNames[i], known = args[name];
        if (!known && (known = args[name + "?"]))
          fn.argNames[i] += "?";
        if (known) propagateWithWeight(known, fn.args[i]);
      }
      if (ret) propagateWithWeight(ret, fn.retval);
      if (self) propagateWithWeight(self, fn.self);
    } else if (type) {
      propagateWithWeight(type, aval);
    }
  }

  static function propagateWithWeight(type:Dynamic, target:Dynamic) {
    var weight = Infer.cx().parent._docComment.weight;
    type.type.propagate(target, weight || (type.madeUp ? WG_MADEUP : undefined));
  }
}