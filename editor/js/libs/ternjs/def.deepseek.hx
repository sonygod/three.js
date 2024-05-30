// Type description parser
//
// Type description JSON files (such as ecma5.json and browser.json)
// are used to
//
// A) describe types that come from native code
//
// B) to cheaply load the types for big libraries, or libraries that
//    can't be inferred well

class TypeParser {
  var pos:Int;
  var spec:String;
  var base:Dynamic;
  var forceNew:Bool;

  public function new(spec:String, start:Int, base:Dynamic, forceNew:Bool) {
    this.pos = start;
    this.spec = spec;
    this.base = base;
    this.forceNew = forceNew;
  }

  private function hop(obj:Dynamic, prop:String):Bool {
    return Reflect.hasField(obj, prop);
  }

  private function eat(str:String):Bool {
    if (str.length == 1 && this.spec.charAt(this.pos) == str) {
      this.pos++;
      return true;
    }
    return false;
  }

  private function word(re:EReg):String {
    var word = "";
    while (this.pos < this.spec.length && re.match(this.spec.charAt(this.pos))) {
      word += this.spec.charAt(this.pos);
      this.pos++;
    }
    return word;
  }

  private function error():Void {
    throw "Unrecognized type spec: " + this.spec + " (at " + this.pos + ")";
  }

  private function parseFnType(comp:Bool, name:String, top:Bool):Dynamic {
    var args = [];
    var names = [];
    var computed = false;
    if (!this.eat(")")) {
      while (true) {
        var colon = this.spec.indexOf(": ", this.pos);
        var argname:String = null;
        if (colon != -1) {
          argname = this.spec.substr(this.pos, colon);
          if (/^[\w$]+$/.test(argname)) {
            this.pos = colon + 2;
          } else {
            argname = null;
          }
        }
        names.push(argname);
        var argType = this.parseType(comp);
        if (argType.call) {
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
    var retType:Dynamic = infer.ANull;
    var computeRet:Dynamic = null;
    var computeRetStart:Int = -1;
    var fn:Dynamic = null;
    if (this.eat(" -> ")) {
      computeRetStart = this.pos;
      retType = this.parseType(true);
      if (retType.call) {
        if (top) {
          computeRet = retType;
          retType = infer.ANull;
        } else {
          computed = true;
        }
      }
    }
    if (computed) {
      return computedFunc(args, retType);
    }
    if (top && this.base) {
      fn = this.base;
      infer.Fn.call(this.base, name, infer.ANull, args, names, retType);
    } else {
      fn = new infer.Fn(name, infer.ANull, args, names, retType);
    }
    if (computeRet) {
      fn.computeRet = computeRet;
    }
    if (computeRetStart != -1) {
      fn.computeRetSource = this.spec.substr(computeRetStart, this.pos);
    }
    return fn;
  }

  private function parseType(comp:Bool, name:String = null, top:Bool = false):Dynamic {
    var main = this.parseTypeMaybeProp(comp, name, top);
    if (!this.eat("|")) {
      return main;
    }
    var types = [main];
    var computed = main.call;
    while (true) {
      var next = this.parseTypeMaybeProp(comp, name, top);
      types.push(next);
      if (next.call) {
        computed = true;
      }
      if (!this.eat("|")) {
        break;
      }
    }
    if (computed) {
      return computedUnion(types);
    }
    var union = new infer.AVal();
    for (i in types) {
      types[i].propagate(union);
    }
    return union;
  }

  private function parseTypeMaybeProp(comp:Bool, name:String = null, top:Bool = false):Dynamic {
    var result = this.parseTypeInner(comp, name, top);
    while (comp && this.eat(".")) {
      result = this.extendWithProp(result);
    }
    return result;
  }

  private function extendWithProp(base:Dynamic):Dynamic {
    var propName = this.word(/[\w<>$!]/);
    if (propName == "") {
      this.error();
    }
    return function(self:Dynamic, args:Array<Dynamic>):Dynamic {
      return extractProp(base(self, args), propName);
    };
  }

  private function parseTypeInner(comp:Bool, name:String = null, top:Bool = false):Dynamic {
    if (this.eat("fn(")) {
      return this.parseFnType(comp, name, top);
    } else if (this.eat("[")) {
      var inner = this.parseType(comp);
      if (!this.eat("]")) {
        this.error();
      }
      if (inner.call) {
        return computedArray(inner);
      }
      if (top && this.base) {
        infer.Arr.call(this.base, inner);
        return this.base;
      }
      return new infer.Arr(inner);
    } else if (this.eat("+")) {
      var path = this.word(/[\w$<>\.!]/);
      var base = parsePath(path + ".prototype");
      if (!(base instanceof infer.Obj)) {
        base = parsePath(path);
      }
      if (!(base instanceof infer.Obj)) {
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
      var arg = this.word(/\d/);
      if (arg != "") {
        arg = parseInt(arg);
        return function(_self:Dynamic, args:Array<Dynamic>):Dynamic {
          return args[arg] || infer.ANull;
        };
      } else if (this.eat("this")) {
        return function(self:Dynamic):Dynamic {
          return self;
        };
      } else if (this.eat("custom:")) {
        var fname = this.word(/[\w$]/);
        return customFunctions[fname] || function():Dynamic {
          return infer.ANull;
        };
      } else {
        return this.fromWord("!" + this.word(/[\w$<>\.!]/));
      }
    } else if (this.eat("?")) {
      return infer.ANull;
    } else {
      return this.fromWord(this.word(/[\w$<>\.!`]/));
    }
  }

  private function fromWord(spec:String):Dynamic {
    var cx = infer.cx();
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
    if (cx.localDefs && spec in cx.localDefs) {
      return cx.localDefs[spec];
    }
    return parsePath(spec);
  }

  private function parsePoly(base:Dynamic):Dynamic {
    var propName = "<i>";
    var match = this.spec.substr(this.pos).match(/^\s*(\w+)\s*=\s*/);
    if (match) {
      propName = match[1];
      this.pos += match[0].length;
    }
    var value = this.parseType(true);
    if (!this.eat("]")) {
      this.error();
    }
    return function(self:Dynamic, args:Array<Dynamic>):Dynamic {
      var instance = infer.getInstance(base);
      value(self, args).propagate(instance.defProp(propName));
      return instance;
    };
  }
}

// ... 其他函数和类定义 ...