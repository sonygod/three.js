import js.Curve;
import js.QuadraticBezier;
import js.Vector2;

class QuadraticBezierCurve extends Curve {
    public var v0:Vector2 = new Vector2();
    public var v1:Vector2 = new Vector2();
    public var v2:Vector2 = new Vector2();
    public var isQuadraticBezierCurve:Bool = true;
    public var type:String = "QuadraticBezierCurve";

    public function new(?v0:Vector2, ?v1:Vector2, ?v2:Vector2) {
        super();
        this.v0 = v0 ?? new Vector2();
        this.v1 = v1 ?? new Vector2();
        this.v2 = v2 ?? new Vector2();
    }

    public function getPoint(t:Float, optionalTarget:Vector2 = new Vector2()):Vector2 {
        var point:Vector2 = optionalTarget;
        var v0:Vector2 = this.v0;
        var v1:Vector2 = this.v1;
        var v2:Vector2 = this.v2;

        point.set(
            QuadraticBezier.get(t, v0.x, v1.x, v2.x),
            QuadraticBezier.get(t, v0.y, v1.y, v2.y)
        );

        return point;
    }

    public function copy(source:QuadraticBezierCurve):QuadraticBezierCurve {
        super.copy(source);
        this.v0.copy(source.v0);
        this.v1.copy(source.v1);
        this.v2.copy(source.v2);
        return this;
    }

    public function toJSON():HashMap {
        var data:HashMap = super.toJSON();
        data.set("v0", this.v0.toArray());
        data.set("v1", this.v1.toArray());
        data.set("v2", this.v2.toArray());
        return data;
    }

    public function fromJSON(json:HashMap):Void {
        super.fromJSON(json);
        this.v0.fromArray(json.get("v0"));
        this.v1.fromArray(json.get("v1"));
        this.v2.fromArray(json.get("v2"));
    }
}

class js.QuadraticBezierCurve = QuadraticBezierCurve;