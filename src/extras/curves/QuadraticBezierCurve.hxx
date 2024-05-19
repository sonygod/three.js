package three.js.src.extras.curves;

import three.js.src.core.Curve;
import three.js.src.core.Interpolations;
import three.js.math.Vector2;

class QuadraticBezierCurve extends Curve {

    public var v0:Vector2;
    public var v1:Vector2;
    public var v2:Vector2;

    public function new(v0:Vector2 = new Vector2(), v1:Vector2 = new Vector2(), v2:Vector2 = new Vector2()) {
        super();

        this.isQuadraticBezierCurve = true;
        this.type = 'QuadraticBezierCurve';

        this.v0 = v0;
        this.v1 = v1;
        this.v2 = v2;
    }

    public function getPoint(t:Float, optionalTarget:Vector2 = new Vector2()):Vector2 {
        var point = optionalTarget;

        point.set(
            Interpolations.QuadraticBezier(t, this.v0.x, this.v1.x, this.v2.x),
            Interpolations.QuadraticBezier(t, this.v0.y, this.v1.y, this.v2.y)
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

    public function toJSON():Dynamic {
        var data = super.toJSON();

        data.v0 = this.v0.toArray();
        data.v1 = this.v1.toArray();
        data.v2 = this.v2.toArray();

        return data;
    }

    public function fromJSON(json:Dynamic):QuadraticBezierCurve {
        super.fromJSON(json);

        this.v0.fromArray(json.v0);
        this.v1.fromArray(json.v1);
        this.v2.fromArray(json.v2);

        return this;
    }
}