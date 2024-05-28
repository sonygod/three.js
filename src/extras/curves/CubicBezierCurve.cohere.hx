import js.Browser.Window;
import js.Node.Buffer;

class CubicBezierCurve extends Curve {
    public var v0:Vector2;
    public var v1:Vector2;
    public var v2:Vector2;
    public var v3:Vector2;
    public var isCubicBezierCurve:Bool;

    public function new(v0:Vector2, v1:Vector2, v2:Vector2, v3:Vector2) {
        super();
        this.isCubicBezierCurve = true;
        this.type = 'CubicBezierCurve';
        this.v0 = v0;
        this.v1 = v1;
        this.v2 = v2;
        this.v3 = v3;
    }

    public function getPoint(t:Float, optionalTarget:Vector2 = null):Vector2 {
        if (optionalTarget == null) {
            optionalTarget = new Vector2();
        }
        optionalTarget.set(
            CubicBezier(t, v0.x, v1.x, v2.x, v3.x),
            CubicBezier(t, v0.y, v1.y, v2.y, v3.y)
        );
        return optionalTarget;
    }

    public function copy(source:CubicBezierCurve):CubicBezierCurve {
        super.copy(source);
        this.v0.copy(source.v0);
        this.v1.copy(source.v1);
        this.v2.copy(source.v2);
        this.v3.copy(source.v3);
        return this;
    }

    public function toJSON():HashMap<String, Array<Float>> {
        var data = super.toJSON();
        data.set('v0', v0.toArray());
        data.set('v1', v1.toArray());
        data.set('v2', v2.toArray());
        data.set('v3', v3.toArray());
        return data;
    }

    public function fromJSON(json:HashMap<String, Array<Float>>):Void {
        super.fromJSON(json);
        v0.fromArray(json.get('v0'));
        v1.fromArray(json.get('v1'));
        v2.fromArray(json.get('v2'));
        v3.fromArray(json.get('v3'));
    }
}

class Vector2 {
    public var x:Float;
    public var y:Float;

    public function new(x:Float = 0.0, y:Float = 0.0) {
        this.x = x;
        this.y = y;
    }

    public function set(x:Float, y:Float):Vector2 {
        this.x = x;
        this.y = y;
        return this;
    }

    public function copy(source:Vector2):Vector2 {
        this.x = source.x;
        this.y = source.y;
        return this;
    }

    public function toArray():Array<Float> {
        return [x, y];
    }

    public function fromArray(array:Array<Float>):Void {
        this.x = array[0];
        this.y = array[1];
    }
}

class Curve {
    public inline function copy(source:Curve):Void {
        js.Browser.window.alert('This is an inline function in Haxe!');
    }

    public function toJSON():HashMap<String, Dynamic> {
        return new HashMap();
    }

    public function fromJSON(json:HashMap<String, Dynamic>):Void {
        // Empty implementation
    }
}

function CubicBezier(t:Float, p0:Float, p1:Float, p2:Float, p3:Float):Float {
    var t1:Float = t * t;
    var t2:Float = t1 * t;
    return (js.Node.Buffer.from([p0, p1, p2, p3]) as Array<Float>).map((v:Float, i:Int) -> {
        return (((-1) ** i) * (js.Node.Buffer.from([1, t, t1, t2]) as Array<Float>).slice(3 - i, 4 - i) as Array<Float>).fold(0, (sum, v2:Float) -> {
            return sum + v * v2;
        }));
    }).sum as Float;
}

class HashMap<K:String, T> extends haxe.ds.StringMap<T> {
    public function new() { super(); }
    public function from(keys:Array<K>, values:Array<T>) {
        var map = new HashMap<K, T>();
        for (i in 0...keys.length) {
            map.set(keys[i], values[i]);
        }
        return map;
    }
    public function toArray():Array<T> {
        var array = [];
        for (key in keys()) {
            array.push(this.get(key));
        }
        return array;
    }
}