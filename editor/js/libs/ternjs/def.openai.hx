package three.js.editor.js.libs.ternjs;

import haxe.ds.ObjectMap;

class Def {
    private var pos:Int;
    private var spec:String;
    private var base:Dynamic;
    private var forceNew:Bool;

    public function new(spec:String, start:Int, base:Dynamic, forceNew:Bool) {
        this.pos = start;
        this.spec = spec;
        this.base = base;
        this.forceNew = forceNew;
    }

    private function hop(obj:Dynamic, prop:String):Bool {
        return Reflect.hasField(obj, prop);
    }

    private function unwrapType(type:Dynamic, self:Dynamic, args:Array<Dynamic>):Dynamic {
        return if (Reflect.isFunction(type)) type(self, args) else type;
    }

    private function extractProp(type:Dynamic, prop:String):Dynamic {
        if (prop == "!ret") {
            if (type.retval != null) return type.retval;
            var rv = new infer.AVal();
            type.propagate(new infer.IsCallee(infer.ANull, [], null, rv));
            return rv;
        } else {
            return type.getProp(prop);
        }
    }

    private function computedFunc(args:Array<Dynamic>, retType:Dynamic):Dynamic {
        return function(self:Dynamic, cArgs:Array<Dynamic>):Dynamic {
            var realArgs:Array<Dynamic> = [];
            for (i in 0...args.length) realArgs.push(unwrapType(args[i], self, cArgs));
            return new infer.Fn("", infer.ANull, realArgs, infer.ANull);
        };
    }

    private function computedUnion(types:Array<Dynamic>):Dynamic {
        return function(self:Dynamic, args:Array<Dynamic>):Dynamic {
            var union:infer.AVal = new infer.AVal();
            for (i in 0...types.length) unwrapType(types[i], self, args).propagate(union);
            return union;
        };
    }

    private function computedArray(inner:Dynamic):Dynamic {
        return function(self:Dynamic, args:Array<Dynamic>):Dynamic {
            return new infer.Arr(inner(self, args));
        };
    }

    public function eat(str:String):Bool {
        var start:Int = pos;
        if (str.length == 1 ? spec.charAt(pos) == str : spec.indexOf(str, pos) == pos) {
            pos += str.length;
            return true;
        }
        pos = start;
        return false;
    }

    public function word(re:EReg):String {
        var ch:String, word:String = "";
        while ((ch = spec.charAt(pos)) != null && re.match(ch)) {
            word += ch;
            pos++;
        }
        return word;
    }

    public function error():Void {
        throw new Error("Unrecognized type spec: " + spec + " (at " + pos + ")");
    }

    public function parseFnType(comp:Bool, name:String, top:Bool):Dynamic {
        var args:Array<Dynamic> = [], names:Array<String> = [];
        if (!eat(")")) {
            for (i in 0...100) {
                var colon:Int = spec.indexOf(": ", pos);
                var argName:String;
                if (colon != -1) {
                    argName = spec.substring(pos, colon);
                    if (/^[$\w?]+$/.test(argName)) {
                        pos = colon + 2;
                    } else {
                        argName = null;
                    }
                }
                names.push(argName);
                var argType:Dynamic = parseType(comp);
                if (argType.isFunction()) {
                    computed = true;
                }
                args.push(argType);
                if (!eat(", ")) {
                    eat(")") || error();
                    break;
                }
            }
        }
        var retType:Dynamic;
        if (eat(" -> ")) {
            var retStart:Int = pos;
            retType = parseType(true);
            if (retType.isFunction()) {
                if (top) {
                    computeRet = retType;
                    retType = infer.ANull;
                    computeRetStart = retStart;
                } else {
                    computed = true;
                }
            }
        } else {
            retType = infer.ANull;
        }
        if (computed) return computedFunc(args, retType);

        if (top && (fn = base)) {
            infer.Fn.call(base, name, infer.ANull, args, names, retType);
        } else {
            fn = new infer.Fn(name, infer.ANull, args, names, retType);
        }
        if (computeRet) fn.computeRet = computeRet;
        if (computeRetStart != null) fn.computeRetSource = spec.substring(computeRetStart, pos);
        return fn;
    }

    public function parseType(comp:Bool, name:String, top:Bool):Dynamic {
        var main:Dynamic = parseTypeMaybeProp(comp, name, top);
        if (!eat("|")) return main;
        var types:Array<Dynamic> = [main], computed:Bool = main.isFunction();
        for (;;) {
            var next:Dynamic = parseTypeMaybeProp(comp, name, top);
            types.push(next);
            if (next.isFunction()) computed = true;
            if (!eat("|")) break;
        }
        if (computed) return computedUnion(types);
        var union:infer.AVal = new infer.AVal();
        for (i in 0...types.length) types[i].propagate(union);
        return union;
    }

    public function parseTypeMaybeProp(comp:Bool, name:String, top:Bool):Dynamic {
        var result:Dynamic = parseTypeInner(comp, name, top);
        while (comp && eat(".")) result = extendWithProp(result);
        return result;
    }

    public function extendWithProp(base:Dynamic):Dynamic {
        var propName:String = word ~/[\w$<>!.]*/;
        if (base.isFunction()) return function(self:Dynamic, args:Array<Dynamic>):Dynamic {
            return extractProp(base(self, args), propName);
        };
        return extractProp(base, propName);
    }

    public function parseTypeInner(comp:Bool, name:String, top:Bool):Dynamic {
        if (eat("fn(")) {
            return parseFnType(comp, name, top);
        } else if (eat("[")) {
            var inner:Dynamic = parseType(comp);
            eat("]") || error();
            if (inner.isFunction()) return computedArray(inner);
            if (top && base) {
                infer.Arr.call(base, inner);
                return base;
            }
            return new infer.Arr(inner);
        } else if (eat("+")) {
            var path:String = word ~/[\w$<>\.!]*/;
            var base:Dynamic = parsePath(path + ".prototype");
            if (!(base instanceof infer.Obj)) base = parsePath(path);
            if (!(base instanceof infer.Obj)) return base;
            if (comp && eat("[")) return parsePoly(base);
            if (top && forceNew) return new infer.Obj(base);
            return infer.getInstance(base);
        } else if (comp && eat("!")) {
            var arg:String;
            if ((arg = word ~/[\d+]*/) != null) {
                arg = Std.parseInt(arg);
                return function(_self:Dynamic, args:Array<Dynamic>):Dynamic {
                    return args[arg] || infer.ANull;
                };
            } else if (eat("this")) {
                return function(self:Dynamic):Dynamic {
                    return self;
                };
            } else if (eat("custom:")) {
                var fname:String = word ~/[\w$]/;
                return customFunctions[fname] || function():Dynamic {
                    return infer.ANull;
                };
            } else {
                return fromWord("!" + word ~/[\w$<>\.!]/);
            }
        } else if (eat("?")) {
            return infer.ANull;
        } else {
            return fromWord(word ~/[\w$<>\.!]/);
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
        if (cx.localDefs && spec in cx.localDefs) return cx.localDefs[spec];
        return parsePath(spec);
    }
}

class Infer {
    public static var cx:InferCx;
    public static var definitions:ObjectMap<Dynamic>;
    public static var protos:ObjectMap<Dynamic>;

    public static function getInstance(base:Dynamic):Dynamic {
        return base.getInstance();
    }

    public static function registerFunction(name:String, f:Dynamic):Void {
        customFunctions[name] = f;
    }

    public static function load(data:Dynamic, scope:Dynamic):Void {
        doLoadEnvironment(data, scope);
    }

    public static function parse(data:Dynamic, origin:String, path:String):Dynamic {
        var cx = Infer.cx;
        if (origin) {
            cx.origin = origin;
            cx.localDefs = definitions[origin];
        }
        try {
            if (Std.is(data, String)) {
                return parseType(data, path);
            } else {
                return passTwo(passOne(null, data, path), data, path);
            }
        } finally {
            if (origin) {
                cx.origin = null;
                cx.localDefs = null;
            }
        }
    }

    // ... other functions ...
}