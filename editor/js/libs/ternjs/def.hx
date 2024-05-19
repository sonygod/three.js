Here is the converted Haxe code:
```
package three.js.editor.js.libs.ternjs;

import haxe.ds.StringMap;

class Def {
  static var cx:InferCx;

  static function init(mod:DefMod) {
    return new TypeParser(mod);
  }
}

class TypeParser {
  var pos:Int;
  var spec:String;
  var base:InferType;
  var forceNew:Bool;

  public function new(spec:String, ?start:Int, ?base:InferType, ?forceNew:Bool) {
    this.spec = spec;
    this.pos = start != null ? start : 0;
    this.base = base;
    this.forceNew = forceNew;
  }

  function hop(obj:Dynamic, prop:String):Bool {
    return Reflect.hasField(obj, prop);
  }

  function unwrapType(type:InferType, self:InferType, args:Array<InferType>):InferType {
    return type.call != null ? type.call(self, args) : type;
  }

  function extractProp(type:InferType, prop:String):InferType {
    if (prop == "!ret") {
      if (type.retval != null) return type.retval;
      var rv = new InferAVal();
      type.propagate(new InferIsCallee(InferNull, [], null, rv));
      return rv;
    } else {
      return type.getProp(prop);
    }
  }

  function computedFunc(args:Array<InferType>, retType:InferType):InferType {
    return function(self:InferType, cArgs:Array<InferType>):InferType {
      var realArgs:Array<InferType> = [];
      for (i in 0...args.length) realArgs.push(unwrapType(args[i], self, cArgs));
      return new InferFn("name", InferNull, realArgs, retType);
    };
  }

  function computedUnion(types:Array<InferType>):InferType {
    return function(self:InferType, args:Array<InferType>):InferType {
      var union = new InferAVal();
      for (i in 0...types.length) unwrapType(types[i], self, args).propagate(union);
      return union;
    };
  }

  function computedArray(inner:InferType):InferType {
    return function(self:InferType, args:Array<InferType>):InferType {
      return new InferArr(inner(self, args));
    };
  }

  public function eat(str:String):Bool {
    if (str.length == 1 ? spec.charAt(pos) == str : spec.indexOf(str, pos) == pos) {
      pos += str.length;
      return true;
    }
    return false;
  }

  public function word(?re:EReg):String {
    var word = "", ch:String;
    while ((ch = spec.charAt(pos)) != null && re.match(ch)) {
      word += ch;
      pos++;
    }
    return word;
  }

  public function error():Void {
    throw new Error("Unrecognized type spec: " + spec + " (at " + pos + ")");
  }

  public function parseFnType(?comp:Bool, ?name:String, ?top:Bool):InferType {
    var args:Array<InferType> = [], names:Array<String> = [], computed:Bool = false;
    if (!eat(")")) {
      for (var i = 0; ; i++) {
        var colon = spec.indexOf(": ", pos);
        var argname = spec.substring(pos, colon);
        if (/^[$\w?]+$/.test(argname)) {
          pos = colon + 2;
        } else {
          argname = null;
        }
        names.push(argname);
        var argType = parseType(comp);
        if (argType.call != null) computed = true;
        args.push(argType);
        if (!eat(", ")) break;
      }
    }
    var retType:InferType, computeRet:InferType, computeRetStart:Int;
    if (eat(" -> ")) {
      var retStart = pos;
      retType = parseType(true);
      if (retType.call != null) {
        if (top) {
          computeRet = retType;
          retType = InferNull;
          computeRetStart = retStart;
        } else {
          computed = true;
        }
      }
    } else {
      retType = InferNull;
    }
    if (computed) return computedFunc(args, retType);
    var fn = top && base != null ? InferFn.call(base, name, InferNull, args, names, retType) : new InferFn(name, InferNull, args, names, retType);
    if (computeRet != null) fn.computeRet = computeRet;
    if (computeRetStart != null) fn.computeRetSource = spec.substring(computeRetStart, pos);
    return fn;
  }

  public function parseType(?comp:Bool, ?name:String, ?top:Bool):InferType {
    var main = parseTypeMaybeProp(comp, name, top);
    if (!eat("|")) return main;
    var types:Array<InferType> = [main], computed:Bool = main.call != null;
    for (;;) {
      var next = parseTypeMaybeProp(comp, name, top);
      types.push(next);
      if (next.call != null) computed = true;
      if (!eat("|")) break;
    }
    if (computed) return computedUnion(types);
    var union = new InferAVal();
    for (i in 0...types.length) types[i].propagate(union);
    return union;
  }

  public function parseTypeMaybeProp(?comp:Bool, ?name:String, ?top:Bool):InferType {
    var result = parseTypeInner(comp, name, top);
    while (eat(".")) result = extendWithProp(result);
    return result;
  }

  public function extendWithProp(base:InferType):InferType {
    var propName = word(/[\w$<>!]/) || error();
    if (base.call != null) return function(self:InferType, args:Array<InferType>):InferType {
      return extractProp(base(self, args), propName);
    };
    return extractProp(base, propName);
  }

  public function parseTypeInner(?comp:Bool, ?name:String, ?top:Bool):InferType {
    if (eat("fn(")) return parseFnType(comp, name, top);
    if (eat("[")) {
      var inner = parseType(comp);
      eat("]") || error();
      if (inner.call != null) return computedArray(inner);
      if (top && base != null) {
        InferArr.call(base, inner);
        return base;
      }
      return new InferArr(inner);
    }
    if (eat("+")) {
      var path = word(/[\w$<>\.!]/);
      var base = parsePath(path + ".prototype");
      if (!(base instanceof InferObj)) base = parsePath(path);
      if (!(base instanceof InferObj)) return base;
      if (comp && eat("[")) return parsePoly(base);
      if (top && forceNew) return new InferObj(base);
      return Infer.getInstance(base);
    }
    if (comp && eat("!")) {
      var arg = word(/\d/);
      if (arg != null) {
        arg = Std.parseInt(arg);
        return function(_self:InferType, args:Array<InferType>):InferType {
          return args[arg] || InferNull;
        };
      } else if (eat("this")) {
        return function(self:InferType):InferType {
          return self;
        };
      } else if (eat("custom:")) {
        var fname = word(/[\w$]/);
        return customFunctions[fname] || function():InferType {
          return InferNull;
        };
      } else {
        return fromWord("!" + word(/[\w$<>\.!]/));
      }
    }
    if (eat("?")) return InferNull;
    return fromWord(word(/[\w$<>\.!`]/));
  }

  public function fromWord(spec:String):InferType {
    switch (spec) {
    case "number":
      return cx.num;
    case "string":
      return cx.str;
    case "bool":
      return cx.bool;
    case "<top>":
      return cx.topScope;
    }
    if (cx.localDefs != null && spec in cx.localDefs) return cx.localDefs[spec];
    return parsePath(spec);
  }

  public function parsePoly(base:InferType):InferType {
    var propName = "<i>";
    var match = ~/^(.+)\s*=\s*/.match(spec);
    if (match != null) {
      propName = match[1];
      pos += match[0].length;
    }
    var value = parseType(true);
    eat("]") || error();
    if (value.call != null) return function(self:InferType, args:Array<InferType>):InferType {
      var instance = Infer.getInstance(base);
      value(self, args).propagate(instance.defProp(propName));
      return instance;
    };
    value.propagate(instance.defProp(propName));
    return instance;
  }
}

class InferCx {
  public var paths:StringMap<InferType>;
  public var localDefs:StringMap<InferType>;
  public var topScope:InferType;
  public var protos:StringMap<InferType>;

  public function new() {
    paths = new StringMap<InferType>();
    localDefs = new StringMap<InferType>();
    topScope = new InferObj();
    protos = new StringMap<InferType>();
  }

  public function cx():InferCx {
    return this;
  }
}

class InferType {}

class InferAVal extends InferType {}

class InferArr extends InferType {}

class InferObj extends InferType {}

class InferFn extends InferType {}

class InferIsCallee extends InferConstraint {}

class InferConstraint {}

class InferPropHasSubset extends InferConstraint {}

class InferIsCreated extends InferConstraint {}

class DefMod {}