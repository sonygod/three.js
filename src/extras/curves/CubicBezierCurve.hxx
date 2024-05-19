import three.js.src.extras.curves.core.Curve;
import three.js.src.extras.curves.core.Interpolations;
import three.js.math.Vector2;

class CubicBezierCurve extends Curve {

    public var v0:Vector2;
    public var v1:Vector2;
    public var v2:Vector2;
    public var v3:Vector2;

    public function new(v0:Vector2 = new Vector2(), v1:Vector2 = new Vector2(), v2:Vector2 = new Vector2(), v3:Vector2 = new Vector2()) {
        super();

        this.isCubicBezierCurve = true;
        this.type = 'CubicBezierCurve';

        this.v0 = v0;
        this.v1 = v1;
        this.v2 = v2;
        this.v3 = v3;
    }

    public function getPoint(t:Float, optionalTarget:Vector2 = new Vector2()):Vector2 {
        var point = optionalTarget;

        var v0 = this.v0;
        var v1 = this.v1;
        var v2 = this.v2;
        var v3 = this.v3;

        point.set(
            Interpolations.CubicBezier(t, v0.x, v1.x, v2.x, v3.x),
            Interpolations.CubicBezier(t, v0.y, v1.y, v2.y, v3.y)
        );

        return point;
    }

    public function copy(source:CubicBezierCurve):CubicBezierCurve {
        super.copy(source);

        this.v0.copy(source.v0);
        this.v1.copy(source.v1);
        this.v2.copy(source.v2);
        this.v3.copy(source.v3);

        return this;
    }

    public function toJSON():Dynamic {
        var data = super.toJSON();

        data.v0 = this.v0.toArray();
        data.v1 = this.v1.toArray();
        data.v2 = this.v2.toArray();
        data.v3 = this.v3.toArray();

        return data;
    }

    public function fromJSON(json:Dynamic):CubicBezierCurve {
        super.fromJSON(json);

        this.v0.fromArray(json.v0);
        this.v1.fromArray(json.v1);
        this.v2.fromArray(json.v2);
        this.v3.fromArray(json.v3);

        return this;
    }
}