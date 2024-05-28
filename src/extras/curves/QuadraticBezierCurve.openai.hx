package three.js.src.extras.curves;

import three.js.src.core.Curve;
import three.js.src.core.Interpolations;
import three.math.Vector2;

class QuadraticBezierCurve extends Curve {
    public var v0:Vector2;
    public var v1:Vector2;
    public var v2:Vector2;

    public function new(v0:Vector2 = null, v1:Vector2 = null, v2:Vector2 = null) {
        super();
        this.isQuadraticBezierCurve = true;
        this.type = 'QuadraticBezierCurve';

        v0 = v0 != null ? v0 : new Vector2();
        v1 = v1 != null ? v1 : new Vector2();
        v2 = v2 != null ? v2 : new Vector2();

        this.v0 = v0;
        this.v1 = v1;
        this.v2 = v2;
    }

    public function getPoint(t:Float, optionalTarget:Vector2 = null):Vector2 {
        var point:Vector2 = optionalTarget != null ? optionalTarget : new Vector2();

        point.set(
            Interpolations.quadraticBezier(t, v0.x, v1.x, v2.x),
            Interpolations.quadraticBezier(t, v0.y, v1.y, v2.y)
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
        var data:Dynamic = super.toJSON();

        data.v0 = v0.toArray();
        data.v1 = v1.toArray();
        data.v2 = v2.toArray();

        return data;
    }

    public function fromJSON(json:Dynamic):QuadraticBezierCurve {
        super.fromJSON(json);

        v0.fromArray(json.v0);
        v1.fromArray(json.v1);
        v2.fromArray(json.v2);

        return this;
    }
}