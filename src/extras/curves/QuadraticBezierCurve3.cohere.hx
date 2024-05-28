import js.Browser.console;

class QuadraticBezierCurve3 {
    public var v0:Vector3;
    public var v1:Vector3;
    public var v2:Vector3;

    public function new(v0:Vector3 = Vector3.create(), v1:Vector3 = Vector3.create(), v2:Vector3 = Vector3.create()) {
        this.v0 = v0;
        this.v1 = v1;
        this.v2 = v2;
    }

    public function getPoint(t:Float, optionalTarget:Vector3 = null):Vector3 {
        if (optionalTarget == null) {
            optionalTarget = new Vector3();
        }

        var point = optionalTarget;
        point.set(
            QuadraticBezier(t, v0.x, v1.x, v2.x),
            QuadraticBezier(t, v0.y, v1.y, v2.y),
            QuadraticBezier(t, v0.z, v1.z, v2.z)
        );

        return point;
    }

    public function copy(source:QuadraticBezierCurve3):QuadraticBezierCurve3 {
        this.v0.copy(source.v0);
        this.v1.copy(source.v1);
        this.v2.copy(source.v2);
        return this;
    }

    public function toJSON():HashMap {
        var data = HashMap.create();
        data.set("v0", v0.toArray());
        data.set("v1", v1.toArray());
        data.set("v2", v2.toArray());
        return data;
    }

    public function fromJSON(json:HashMap) {
        v0.fromArray(json.get("v0"));
        v1.fromArray(json.get("v1"));
        v2.fromArray(json.get("v2"));
        return this;
    }
}

class Vector3 {
    public var x:Float;
    public var y:Float;
    public var z:Float;

    public function new(x:Float = 0.0, y:Float = 0.0, z:Float = 0.0) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public static function create():Vector3 {
        return new Vector3();
    }

    public function set(x:Float, y:Float, z:Float):Vector3 {
        this.x = x;
        this.y = y;
        this.z = z;
        return this;
    }

    public function copy(source:Vector3):Vector3 {
        this.x = source.x;
        this.y = source.y;
        this.z = source.z;
        return this;
    }

    public function toArray():Array<Float> {
        return [x, y, z];
    }

    public function fromArray(array:Array<Float>):Vector3 {
        this.x = array[0];
        this.y = array[1];
        this.z = array[2];
        return this;
    }
}

function QuadraticBezier(t:Float, p0:Float, p1:Float, p2:Float):Float {
    var onet = 1.0 - t;
    return onet * (onet * p0 + 2.0 * t * p1) + t * t * p2;
}

class HashMap {
    public var data:Array<Dynamic>;

    public function new() {
        this.data = [];
    }

    public function create():HashMap {
        return new HashMap();
    }

    public function set(key:String, value:Dynamic) {
        this.data[key] = value;
    }

    public function get(key:String):Dynamic {
        return this.data[key];
    }
}

class Float {
    public static var NaN:Float = Std.NaN;
    public static var NEGATIVE_INFINITY:Float = Neg.infinity;
    public static var POSITIVE_INFINITY:Float = Infinity;

    public function new(v:Float) {
        this = v;
    }
}