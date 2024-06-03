import three.core.Curve;
import three.core.Interpolations;
import three.math.Vector2;

class CubicBezierCurve extends Curve {
    public var v0:Vector2;
    public var v1:Vector2;
    public var v2:Vector2;
    public var v3:Vector2;

    public function new(v0:Vector2 = null, v1:Vector2 = null, v2:Vector2 = null, v3:Vector2 = null) {
        super();

        this.isCubicBezierCurve = true;
        this.type = 'CubicBezierCurve';

        this.v0 = v0 != null ? v0 : new Vector2();
        this.v1 = v1 != null ? v1 : new Vector2();
        this.v2 = v2 != null ? v2 : new Vector2();
        this.v3 = v3 != null ? v3 : new Vector2();
    }

    public function getPoint(t:Float, optionalTarget:Vector2 = null):Vector2 {
        var point = optionalTarget != null ? optionalTarget : new Vector2();

        point.set(
            Interpolations.CubicBezier(t, this.v0.x, this.v1.x, this.v2.x, this.v3.x),
            Interpolations.CubicBezier(t, this.v0.y, this.v1.y, this.v2.y, this.v3.y)
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