import infer.*;

class TypeParser {
    public var pos:Int;
    public var spec:String;
    public var base:Type;
    public var forceNew:Bool;

    public function new(spec:String, start:Int = 0, base:Type = null, forceNew:Bool = false) {
        this.pos = start;
        this.spec = spec;
        this.base = base;
        this.forceNew = forceNew;
    }

    public function eat(str:String):Bool {
        if (str.length == 1 ? this.spec.charAt(this.pos) == str[0] : this.spec.indexOf(str, this.pos) == this.pos) {
            this.pos += str.length;
            return true;
        }
        return false;
    }

    public function word(re:EReg = ~/[\w$]/):String {
        var word = "";
        var ch:String;
        while ((ch = this.spec.charAt(this.pos)) != "" && re.match(ch)) {
            word += ch;
            ++this.pos;
        }
        return word;
    }

    public function error():Void {
        throw "Unrecognized type spec: " + this.spec + " (at " + this.pos + ")";
    }

    public function parseFnType(comp:Bool, name:String, top:Bool):Type {
        // ... rest of the function ...
    }

    public function parseType(comp:Bool, name:String = null, top:Bool = false):Type {
        // ... rest of the function ...
    }

    public function parseTypeMaybeProp(comp:Bool, name:String = null, top:Bool = false):Type {
        // ... rest of the function ...
    }

    public function extendWithProp(base:Type):Type {
        // ... rest of the function ...
    }

    public function parseTypeInner(comp:Bool, name:String = null, top:Bool = false):Type {
        // ... rest of the function ...
    }

    public function fromWord(spec:String):Type {
        // ... rest of the function ...
    }

    public function parsePoly(base:Obj):Type {
        // ... rest of the function ...
    }
}

function parseType(spec:String, name:String = null, base:Type = null, forceNew:Bool = false):Type {
    // ... rest of the function ...
}

function addEffect(fn:Fn, handler:Dynamic -> Type, replaceRet:Bool = false):Void {
    // ... rest of the function ...
}

function parseEffect(effect:String, fn:Fn):Void {
    // ... rest of the function ...
}

var currentTopScope:Obj;

function parsePath(path:String, scope:Obj = null):Type {
    // ... rest of the function ...
}

function emptyObj(ctor:Class<Type>):Obj {
    // ... rest of the function ...
}

function isSimpleAnnotation(spec:Dynamic):Bool {
    // ... rest of the function ...
}

function passOne(base:Obj, spec:Dynamic, path:String = null):Obj {
    // ... rest of the function ...
}

function passTwo(base:Obj, spec:Dynamic, path:String = null):Obj {
    // ... rest of the function ...
}

function copyInfo(spec:Dynamic, type:Type):Void {
    // ... rest of the function ...
}

function runPasses(type:String, arg:Dynamic):Void {
    // ... rest of the function ...
}

function doLoadEnvironment(data:Dynamic, scope:Obj):Void {
    // ... rest of the function ...
}

function load(data:Dynamic, scope:Obj = null):Void {
    // ... rest of the function ...
}

function parse(data:Dynamic, origin:String = null, path:String = null):Type {
    // ... rest of the function ...
}

var customFunctions = new haxe.ds.StringMap<Dynamic -> Type>();

function registerFunction(name:String, f:Dynamic -> Type):Void {
    customFunctions.set(name, f);
}

class IsCreated extends Constraint {
    // ... rest of the class ...
}

registerFunction("Object_create", function(self:Type, args:Array<Type>, argNodes:Array<Dynamic> = null):Type {
    // ... rest of the function ...
});

class PropSpec extends Constraint {
    // ... rest of the class ...
}

registerFunction("Object_defineProperty", function(self:Type, args:Array<Type>, argNodes:Array<Dynamic> = null):Type {
    // ... rest of the function ...
});

registerFunction("Object_defineProperties", function(self:Type, args:Array<Type>, argNodes:Array<Dynamic> = null):Type {
    // ... rest of the function ...
});

class IsBound extends Constraint {
    // ... rest of the class ...
}

registerFunction("Function_bind", function(self:Type, args:Array<Type>):Type {
    // ... rest of the function ...
});

registerFunction("Array_ctor", function(self:Type, args:Array<Type>):Type {
    // ... rest of the function ...
});

registerFunction("Promise_ctor", function(self:Type, args:Array<Type>, argNodes:Array<Dynamic> = null):Type {
    // ... rest of the function ...
});