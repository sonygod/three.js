package;

import js.html.Window;
import js.Browser;
import js.lib.Array;
import js.lib.Object;
import js.lib.String;
import js.lib.Math;
import js.lib.Function;
import js.lib.Error;

class TypeParser {
  public var pos:Int;
  public var spec:String;
  public var base:Dynamic;
  public var forceNew:Bool;

  public function new(spec:String, start:Int = 0, base:Dynamic = null, forceNew:Bool = false) {
    this.pos = start;
    this.spec = spec;
    this.base = base;
    this.forceNew = forceNew;
  }

  public function eat(str:String):Bool {
    if (str.length == 1) {
      return this.spec.charCodeAt(this.pos) == str.charCodeAt(0);
    } else {
      return this.spec.indexOf(str, this.pos) == this.pos;
    }
  }

  public function word(re:EReg):String {
    var word = "";
    var ch;
    while ((ch = this.spec.charCodeAt(this.pos)) != 0 && re.match(String.fromCharCode(ch))) {
      word += String.fromCharCode(ch);
      ++this.pos;
    }
    return word;
  }

  public function error() {
    throw new Error("Unrecognized type spec: " + this.spec + " (at " + this.pos + ")");
  }

  public function parseFnType(comp:Bool, name:String, top:Bool):Dynamic {
    var args = new Array<Dynamic>();
    var names = new Array<String>();
    var computed = false;
    if (!this.eat(")")) {
      for (var i = 0; ; ++i) {
        var colon = this.spec.indexOf(": ", this.pos);
        var argname:String;
        if (colon != -1) {
          argname = this.spec.substring(this.pos, colon);
          if (argname.match(new EReg("^[$\w?]+$", ""))) {
            this.pos = colon + 2;
          } else {
            argname = null;
          }
        }
        names.push(argname);
        var argType = this.parseType(comp);
        if (js.Boot.isFunction(argType)) {
          computed = true;
        }
        args.push(argType);
        if (!this.eat(", ")) {
          if (!this.eat(")")) {
            this.error();
          }
          break;
        }
      }
    }
    var retType:Dynamic;
    var computeRet:Dynamic;
    var computeRetStart:Int;
    var fn:Dynamic;
    if (this.eat(" -> ")) {
      var retStart = this.pos;
      retType = this.parseType(true);
      if (js.Boot.isFunction(retType)) {
        if (top) {
          computeRet = retType;
          retType = null;
          computeRetStart = retStart;
        } else {
          computed = true;
        }
      }
    } else {
      retType = null;
    }
    if (computed) {
      return function(self:Dynamic, cArgs:Array<Dynamic>):Dynamic {
        var realArgs = new Array<Dynamic>();
        for (var i = 0; i < args.length; i++) {
          realArgs.push(unwrapType(args[i], self, cArgs));
        }
        return new infer.Fn(name, null, realArgs, unwrapType(retType, self, cArgs));
      };
    }

    if (top && (fn = this.base)) {
      infer.Fn.call(this.base, name, null, args, names, retType);
    } else {
      fn = new infer.Fn(name, null, args, names, retType);
    }
    if (computeRet != null) {
      fn.computeRet = computeRet;
    }
    if (computeRetStart != null) {
      fn.computeRetSource = this.spec.substring(computeRetStart, this.pos);
    }
    return fn;
  }

  public function parseType(comp:Bool, name:String = null, top:Bool = false):Dynamic {
    var main = this.parseTypeMaybeProp(comp, name, top);
    if (!this.eat("|")) {
      return main;
    }
    var types = new Array<Dynamic>();
    types.push(main);
    var computed = js.Boot.isFunction(main);
    while (true) {
      var next = this.parseTypeMaybeProp(comp, name, top);
      types.push(next);
      if (js.Boot.isFunction(next)) {
        computed = true;
      }
      if (!this.eat("|")) {
        break;
      }
    }
    if (computed) {
      return function(self:Dynamic, args:Array<Dynamic>):Dynamic {
        var union = new infer.AVal();
        for (var i = 0; i < types.length; i++) {
          unwrapType(types[i], self, args).propagate(union);
        }
        return union;
      };
    }
    var union = new infer.AVal();
    for (var i = 0; i < types.length; i++) {
      types[i].propagate(union);
    }
    return union;
  }

  public function parseTypeMaybeProp(comp:Bool, name:String = null, top:Bool = false):Dynamic {
    var result = this.parseTypeInner(comp, name, top);
    while (comp && this.eat(".")) {
      result = this.extendWithProp(result);
    }
    return result;
  }

  public function extendWithProp(base:Dynamic):Dynamic {
    var propName = this.word(new EReg("[\w<>$!]", ""));
    if (propName == "") {
      this.error();
    }
    if (js.Boot.isFunction(base)) {
      return function(self:Dynamic, args:Array<Dynamic>):Dynamic {
        return extractProp(base(self, args), propName);
      };
    }
    return extractProp(base, propName);
  }

  public function parseTypeInner(comp:Bool, name:String = null, top:Bool = false):Dynamic {
    if (this.eat("fn(")) {
      return this.parseFnType(comp, name, top);
    } else if (this.eat("[")) {
      var inner = this.parseType(comp);
      if (!this.eat("]")) {
        this.error();
      }
      if (js.Boot.isFunction(inner)) {
        return function(self:Dynamic, args:Array<Dynamic>):Dynamic {
          return new infer.Arr(inner(self, args));
        };
      }
      if (top && this.base != null) {
        infer.Arr.call(this.base, inner);
        return this.base;
      }
      return new infer.Arr(inner);
    } else if (this.eat("+")) {
      var path = this.word(new EReg("[\w$<>\.!]", ""));
      var base = parsePath(path + ".prototype");
      if (!(base is infer.Obj)) {
        base = parsePath(path);
      }
      if (!(base is infer.Obj)) {
        return base;
      }
      if (comp && this.eat("[")) {
        return this.parsePoly(base);
      }
      if (top && this.forceNew) {
        return new infer.Obj(base);
      }
      return infer.getInstance(base);
    } else if (comp && this.eat("!")) {
      var arg = this.word(new EReg("\\d", ""));
      if (arg != "") {
        arg = Std.parseInt(arg);
        return function(_self:Dynamic, args:Array<Dynamic>):Dynamic {
          return args[arg] != null ? args[arg] : null;
        };
      } else if (this.eat("this")) {
        return function(self:Dynamic):Dynamic {
          return self;
        };
      } else if (this.eat("custom:")) {
        var fname = this.word(new EReg("[\w$]", ""));
        return customFunctions[fname] != null ? customFunctions[fname] : function():Dynamic { return null; };
      } else {
        return this.fromWord("!" + this.word(new EReg("[\w$<>\.!]", "")));
      }
    } else if (this.eat("?")) {
      return null;
    } else {
      return this.fromWord(this.word(new EReg("[\w$<>\.!`]", "")));
    }
  }

  public function fromWord(spec:String):Dynamic {
    var cx = infer.cx();
    switch (spec) {
      case "number": return cx.num;
      case "string": return cx.str;
      case "bool": return cx.bool;
      case "<top>": return cx.topScope;
    }
    if (cx.localDefs != null && cx.localDefs.hasOwnProperty(spec)) {
      return cx.localDefs[spec];
    }
    return parsePath(spec);
  }

  public function parsePoly(base:Dynamic):Dynamic {
    var propName = "<i>";
    var match = this.spec.substring(this.pos).match(new EReg("^\\s*(\\w+)\\s*=\\s*", ""));
    if (match != null) {
      propName = match[1];
      this.pos += match[0].length;
    }
    var value = this.parseType(true);
    if (!this.eat("]")) {
      this.error();
    }
    if (js.Boot.isFunction(value)) {
      return function(self:Dynamic, args:Array<Dynamic>):Dynamic {
        var instance = infer.getInstance(base);
        value(self, args).propagate(instance.defProp(propName));
        return instance;
      };
    }
    var instance = infer.getInstance(base);
    value.propagate(instance.defProp(propName));
    return instance;
  }
}

function unwrapType(type:Dynamic, self:Dynamic, args:Array<Dynamic>):Dynamic {
  if (js.Boot.isFunction(type)) {
    return type(self, args);
  } else {
    return type;
  }
}

function extractProp(type:Dynamic, prop:String):Dynamic {
  if (prop == "!ret") {
    if (type.retval != null) {
      return type.retval;
    }
    var rv = new infer.AVal();
    type.propagate(new infer.IsCallee(infer.ANull, new Array<Dynamic>(), null, rv));
    return rv;
  } else {
    return type.getProp(prop);
  }
}

function computedFunc(args:Array<Dynamic>, retType:Dynamic):Dynamic {
  return function(self:Dynamic, cArgs:Array<Dynamic>):Dynamic {
    var realArgs = new Array<Dynamic>();
    for (var i = 0; i < args.length; i++) {
      realArgs.push(unwrapType(args[i], self, cArgs));
    }
    return new infer.Fn(name, null, realArgs, unwrapType(retType, self, cArgs));
  };
}

function computedUnion(types:Array<Dynamic>):Dynamic {
  return function(self:Dynamic, args:Array<Dynamic>):Dynamic {
    var union = new infer.AVal();
    for (var i = 0; i < types.length; i++) {
      unwrapType(types[i], self, args).propagate(union);
    }
    return union;
  };
}

function computedArray(inner:Dynamic):Dynamic {
  return function(self:Dynamic, args:Array<Dynamic>):Dynamic {
    return new infer.Arr(inner(self, args));
  };
}

class TypeParser_Impl_ {
  static public function parseType(spec:String, name:String = null, base:Dynamic = null, forceNew:Bool = false):Dynamic {
    var type = new TypeParser(spec, null, base, forceNew).parseType(false, name, true);
    if (spec.match(new EReg("^fn\\(", "")) != null) {
      for (var i = 0; i < type.args.length; ++i) {
        (function(i) {
          var arg = type.args[i];
          if (arg is infer.Fn && arg.args != null && arg.args.length > 0) {
            addEffect(type, function(_self:Dynamic, fArgs:Array<Dynamic>):Dynamic {
              var fArg = fArgs[i];
              if (fArg != null) {
                fArg.propagate(new infer.IsCallee(infer.cx().topScope, arg.args, null, null));
              }
            });
          }
        })(i);
      }
    }
    return type;
  }

  static public function parseEffect(effect:String, fn:Dynamic):Void {
    var m;
    if (effect.indexOf("propagate ") == 0) {
      var p = new TypeParser(effect, 10);
      var origin = p.parseType(true);
      if (!p.eat(" ")) {
        p.error();
      }
      var target = p.parseType(true);
      addEffect(fn, function(self:Dynamic, args:Array<Dynamic>):Dynamic {
        unwrapType(origin, self, args).propagate(unwrapType(target, self, args));
      });
    } else if (effect.indexOf("call ") == 0) {
      var andRet = effect.indexOf("and return ", 5) == 5;
      var p = new TypeParser(effect, andRet ? 16 : 5);
      var getCallee = p.parseType(true);
      var getSelf:Dynamic = null;
      var getArgs = new Array<Dynamic>();
      if (p.eat(" this=")) {
        getSelf = p.parseType(true);
      }
      while (p.eat(" ")) {
        getArgs.push(p.parseType(true));
      }
      addEffect(fn, function(self:Dynamic, args:Array<Dynamic>):Dynamic {
        var callee = unwrapType(getCallee, self, args);
        var slf = getSelf != null ? unwrapType(getSelf, self, args) : null;
        var as = new Array<Dynamic>();
        for (var i = 0; i < getArgs.length; ++i) {
          as.push(unwrapType(getArgs[i], self, args));
        }
        var result = andRet ? new infer.AVal() : null;
        callee.propagate(new infer.IsCallee(slf, as, null, result));
        return result;
      }, andRet);
    } else if ((m = effect.match(new EReg("^custom (\\S+)\\s*(.*)", ""))) != null) {
      var customFunc = customFunctions[m[1]];
      if (customFunc != null) {
        addEffect(fn, m[2] != null ? customFunc(m[2]) : customFunc);
      }
    } else if (effect.indexOf("copy ") == 0) {
      var p = new TypeParser(effect, 5);
      var getFrom = p.parseType(true);
      p.eat(" ");
      var getTo = p.parseType(true);
      addEffect(fn, function(self:Dynamic, args:Array<Dynamic>):Dynamic {
        var from = unwrapType(getFrom, self, args);
        var to = unwrapType(getTo, self, args);
        from.forAllProps(function(prop:String, val:Dynamic, local:Bool):Void {
          if (local && prop != "<i>") {
            to.propagate(new infer.PropHasSubset(prop, val));
          }
        });
      });
    } else {
      throw new Error("Unknown effect type: " + effect);
    }
  }

  static public function parsePath(path:String, scope:Dynamic = null):Dynamic {
    var cx = infer.cx();
    var cached = cx.paths[path];
    var origPath = path;
    if (cached != null) {
      return cached;
    }
    cx.paths[path] = null;

    var base = scope != null ? scope : currentTopScope != null ? currentTopScope : cx.topScope;

    if (cx.localDefs != null) {
      for (var name in cx.localDefs) {
        if (path.indexOf(name) == 0) {
          if (path == name) {
            return cx.paths[path] = cx.localDefs[name];
          }
          if (path.charCodeAt(name.length) == 46) {
            base = cx.localDefs[name];
            path = path.substring(name.length + 1);
            break;
          }
        }
      }
    }

    var parts = path.split(".");
    for (var i = 0; i < parts.length && base != null; ++i) {
      var prop = parts[i];
      if (prop.charCodeAt(0) == 33) {
        if (prop == "!proto") {
          base = (base is infer.Obj && base.proto != null) ? base.proto : null;
        } else {
          var fn = base.getFunctionType();
          if (fn == null) {
            base = null;
          } else if (prop == "!ret") {
            base = fn.retval != null && fn.retval.getType(false) != null ? fn.retval.getType(false) : null;
          } else {
            var arg = fn.args != null && fn.args[Std.parseInt(prop.substring(1))] != null ? fn.args[Std.parseInt(prop.substring(1))] : null;
            base = (arg != null && arg.getType(false) != null) ? arg.getType(false) : null;
          }
        }
      } else if (base is infer.Obj) {
        var propVal = (prop == "prototype" && base is infer.Fn) ? base.getProp(prop) : base.props[prop];
        if (propVal == null || propVal.isEmpty()) {
          base = null;
        } else {
          base = propVal.types[0];
        }
      }
    }
    // Uncomment this to get feedback on your poorly written .json files
    // if (base == infer.ANull) console.error("bad path: " + origPath + " (" + cx.curOrigin + ")");
    cx.paths[origPath] = base == null ? null : base;
    return base;
  }

  static public function emptyObj(ctor:Dynamic):Dynamic {
    var empty = Object.create(ctor.prototype);
    empty.props = Object.create(null);
    empty.isShell = true;
    return empty;
  }

  static public function isSimpleAnnotation(spec:Dynamic):Bool {
    if (spec["!type"] == null || spec["!type"].match(new EReg("^(fn\\(|\[)", "")) != null) {
      return false;
    }
    for (var prop in spec) {
      if (prop != "!type" && prop != "!doc" && prop != "!url" && prop != "!span" && prop != "!data") {
        return false;
      }
    }
    return true;
  }

  static public function passOne(base:Dynamic, spec:Dynamic, path:String):Dynamic {
    if (base == null) {
      var tp = spec["!type"];
      if (tp != null) {
        if (tp.match(new EReg("^fn\\(", "")) != null) {
          base = emptyObj(infer.Fn);
        } else if (tp.charCodeAt(0) == 91) {
          base = emptyObj(infer.Arr);
        } else {
          throw new Error("Invalid !type spec: " + tp);
        }
      } else if (spec["!stdProto"] != null) {
        base = infer.cx().protos[spec["!stdProto"]];
      } else {
        base = emptyObj(infer.Obj);
      }
      base.name = path;
    }

    for (var name in spec) {
      if (spec.hasOwnProperty(name) && name.charCodeAt(0) != 33) {
        var inner = spec[name];
        if (js.Boot.isString(inner) || isSimpleAnnotation(inner)) {
          continue;
        }
        var prop = base.defProp(name);
        passOne(prop.getObjType(), inner, path != null ? path + "." + name : name).propagate(prop);
      }
    }
    return base;
  }

  static public function passTwo(base:Dynamic, spec:Dynamic, path:String):Dynamic {
    if (base.isShell) {
      delete base.isShell;
      var tp = spec["!type"];
      if (tp != null) {
        parseType(tp, path, base);
      } else {
        var proto = spec["!proto"] != null ? parseType(spec["!proto"]) : null;
        infer.Obj.call(base, proto is infer.Obj ? proto : true, path);
      }
    }

    var effects = spec["!effects"];
    if (effects != null && base is infer.Fn) {
      for (var i = 0; i < effects.length; i++) {
        parseEffect(effects[i], base);
      }
    }
    copyInfo(spec, base);

    for (var name in spec) {
      if (spec.hasOwnProperty(name) && name.charCodeAt(0) != 33) {
        var inner = spec[name];
        var known = base.defProp(name);
        var innerPath = path != null ? path + "." + name : name;
        if (js.Boot.isString(inner)) {
          if (known.isEmpty()) {
            parseType(inner, innerPath).propagate(known);
          }
        } else {
          if (!isSimpleAnnotation(inner)) {
            passTwo(known.getObjType(), inner, innerPath);
          } else if (known.isEmpty()) {
            parseType(inner["!type"], innerPath, null, true).propagate(known);
          } else {
            continue;
          }
          if (inner["!doc"] != null) {
            known.doc = inner["!doc"];
          }
          if (inner["!url"] != null) {
            known.url = inner["!url"];
          }
          if (inner["!span"] != null) {
            known.span = inner["!span"];
          }
        }
      }
    }
    return base;
  }

  static public function copyInfo(spec:Dynamic, type:Dynamic):Void {
    if (spec["!doc"] != null) {
      type.doc = spec["!doc"];
    }
    if (spec["!url"] != null) {
      type.url = spec["!url"];
    }
    if (spec["!span"] != null) {
      type.span = spec["!span"];
    }
    if (spec["!data"] != null) {
      type.metaData = spec["!data"];
    }
  }

  static public function runPasses(type:String, arg:Dynamic):Void {
    var parent = infer.cx().parent;
    var pass = parent != null && parent.passes != null && parent.passes[type] != null ? parent.passes[type] : null;
    if (pass != null) {
      for (var i = 0; i < pass.length; i++) {
        pass[i](arg);
      }
    }
  }

  static public function doLoadEnvironment(data:Dynamic, scope:Dynamic):Void {
    var cx = infer.cx();

    infer.addOrigin(cx.curOrigin = data["!name"] != null ? data["!name"] : "env#" + cx.origins.length);
    cx.localDefs = cx.definitions[cx.curOrigin] = Object.create(null);

    runPasses("preLoadDef", data);

    passOne(scope, data);

    var def = data["!define"];
    if (def != null) {
      for (var name in def) {
        var spec = def[name];
        cx.localDefs[name] = js.Boot.isString(spec) ? parsePath(spec) : passOne(null, spec, name);
      }
      for (var name in def) {
        var spec = def[name];
        if (!js.Boot.isString(spec)) {
          passTwo(cx.localDefs[name], def[name], name);
        }
      }
    }

    passTwo(scope, data);

    runPasses("postLoadDef", data);

    cx.curOrigin = cx.localDefs = null;
  }

  static public function load(data:Dynamic, scope:Dynamic = null):Void {
    if (scope == null) {
      scope = infer.cx().topScope;
    }
    var oldScope = currentTopScope;
    currentTopScope = scope;
    try {
      doLoadEnvironment(data, scope);
    } finally {
      currentTopScope = oldScope;
    }
  }

  static public function parse(data:Dynamic, origin:String = null, path:String = null):Dynamic {
    var cx = infer.cx();
    if (origin != null) {
      cx.origin = origin;
      cx.localDefs = cx.definitions[origin];
    }

    try {
      if (js.Boot.isString(data)) {
        return parseType(data, path);
      } else {
        return passTwo(passOne(null, data, path), data, path);
      }
    } finally {
      if (origin != null) {
        cx.origin = cx.localDefs = null;
      }
    }
  }
}

var customFunctions = Object.create(null);

function addEffect(fn:Dynamic, handler:Dynamic, replaceRet:Bool = false):Void {
  var oldCmp = fn.computeRet;
  var rv = fn.retval;
  fn.computeRet = function(self:Dynamic, args:Array<Dynamic>, argNodes:Array<Dynamic>):Dynamic {
    var handled = handler(self, args, argNodes);
    var old = oldCmp != null ? oldCmp(self, args, argNodes) : rv;
    return replaceRet ? handled : old;
  };
}

var currentTopScope:Dynamic;

class IsCreated extends infer.Constraint {
  public var created:Int;
  public var spec:Dynamic;

  public function new(created:Int, target:Dynamic, spec:Dynamic) {
    this.created = created;
    this.target = target;
    this.spec = spec;
    super(target);
  }

  override public function addType(tp:Dynamic):Void {
    if (tp is infer.Obj && this.created++ < 5) {
      var derived = new infer.Obj(tp);
      var spec = this.spec;
      if (spec is infer.AVal) {
        spec = spec.getObjType(false);
      }
      if (spec is infer.Obj) {
        for (var prop in spec.props) {
          var cur = spec.props[prop].types[0];
          var p = derived.defProp(prop);
          if (cur != null && cur is infer.Obj && cur.props.hasOwnProperty("value")) {
            var vtp = cur.props.value.getType(false);
            if (vtp != null) {
              p.addType(vtp);
            }
          }
        }
      }
      this.target.addType(derived);
    }
  }
}

class PropSpec extends infer.Constraint {
  public function new(target:Dynamic) {
    this.target = target;
    super(target);
  }

  override public function addType(tp:Dynamic):Void {
    if (!(tp is infer.Obj)) {
      return;
    }
    if (tp.hasProp("value")) {
      tp.getProp("value").propagate(this.target);
    } else if (tp.hasProp("get")) {
      tp.getProp("get").propagate(new infer.IsCallee(null, new Array<Dynamic>(), null, this.target));
    }
  }
}

class IsBound extends infer.Constraint {
  public var self:Dynamic;
  public var args:Array<Dynamic>;

  public function new(self:Dynamic, args:Array<Dynamic>, target:Dynamic) {
    this.self = self;
    this.args = args;
    this.target = target;
    super(target);
  }

  override public function addType(tp:Dynamic):Void {
    if (!(tp is infer.Fn)) {
      return;
    }
    this.target.addType(new infer.Fn(tp.name, null, tp.args.slice(this.args.length), tp.argNames.slice(this.args.length), tp.retval));
    this.self.propagate(tp.self);
    for (var i = 0; i < Math.min(tp.args.length, this.args.length); ++i) {
      this.args[i].propagate(tp.args[i]);
    }
  }
}

var exports = {
  TypeParser : TypeParser,
  parseType : TypeParser_Impl_.parseType,
  parseEffect : TypeParser_Impl_.parseEffect,
  parsePath : TypeParser_Impl_.parsePath,
  load : TypeParser_Impl_.load,
  parse : TypeParser_Impl_.parse,
  registerFunction : function(name:String, f:Dynamic):Void { customFunctions[name] = f; }
};

infer.registerFunction("Object_create", function(_self:Dynamic, args:Array<Dynamic>, argNodes:Array<Dynamic>):Dynamic {
  if (argNodes != null && argNodes.length > 0 && argNodes[0].type == "Literal" && argNodes[0].value == null) {
    return new infer.Obj();
  }

  var result = new infer.AVal();
  if (args[0] != null) {
    args[0].propagate(new IsCreated(0, result, args[1]));
  }
  return result;
});

infer.registerFunction("Object_defineProperty", function(_self:Dynamic, args:Array<Dynamic>, argNodes:Array<Dynamic>):Dynamic {
  if (argNodes != null && argNodes.length >= 3 && argNodes[1].type == "Literal" && js.Boot.isString(argNodes[1].value)) {
    var obj = args[0];
    var connect = new infer.AVal();
    obj.propagate(new infer.PropHasSubset(argNodes[1].value, connect, argNodes[1]));
    args[2].propagate(new PropSpec(connect));
  }
  return null;
});

infer.registerFunction("Object_defineProperties", function(_self:Dynamic, args:Array<Dynamic>, argNodes:Array<Dynamic>):Dynamic {
  if (args.length >= 2) {
    var obj = args[0];
    args[1].forAllProps(function(prop:String, val:Dynamic, local:Bool):Void {
      if (!local) {
        return;
      }
      var connect = new infer.AVal();
      obj.propagate(new infer.PropHasSubset(prop, connect, argNodes != null && argNodes[1] != null ? argNodes[1] : null));
      val.propagate(new PropSpec(connect));
    });
  }
  return null;
});

infer.registerFunction("Function_bind", function(self:Dynamic, args:Array<Dynamic>):Dynamic {
  if (args.length == 0) {
    return null;
  }
  var result = new infer.AVal();
  self.propagate(new IsBound(args[0], args.slice(1), result));
  return result;
});

infer.registerFunction("Array_ctor", function(_self:Dynamic, args:Array<Dynamic>):Dynamic {
  var arr = new infer.Arr();
  if (args.length != 1 || !args[0].hasType(infer.cx().num)) {
    var content = arr.getProp("<i>");
    for (var i = 0; i < args.length; ++i) {
      args[i].propagate(content);
    }
  }
  return arr;
});

infer.registerFunction("Promise_ctor", function(_self:Dynamic, args:Array<Dynamic>, argNodes:Array<Dynamic>):Dynamic {
  if (args.length < 1) {
    return null;
  }
  var self = new infer.Obj(infer.cx().definitions.ecma6["Promise.prototype"]);
  var valProp = self.defProp("value", argNodes != null && argNodes[0] != null ? argNodes[0] : null);
  var valArg = new infer.AVal();
  valArg.propagate(valProp);
  var exec = new infer.Fn("execute", null, new Array<Dynamic>(valArg), new Array<String>("value"), null);
  var reject = infer.cx().definitions.ecma6.promiseReject;
  args[0].propagate(new infer.IsCallee(null, new Array<Dynamic>(exec, reject), null, null));
  return self;
});