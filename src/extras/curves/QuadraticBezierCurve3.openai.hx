package three.js.src.extras.curves;

import three.js.src.core.Curve;
import three.js.src.core.Interpolations;
import three.js.src.math.Vector3;

class QuadraticBezierCurve3 extends Curve {
    public var v0:Vector3;
    public var v1:Vector3;
    public var v2:Vector3;

    public function new(v0:Vector3 = null, v1:Vector3 = null, v2:Vector3 = null) {
        super();

        this.isQuadraticBezierCurve3 = true;

        this.type = 'QuadraticBezierCurve3';

        this.v0 = v0 != null ? v0 : new Vector3();
        this.v1 = v1 != null ? v1 : new Vector3();
        this.v2 = v2 != null ? v2 : new Vector3();
    }

    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();

        point.x = Interpolations.QuadraticBezier(t, v0.x, v1.x, v2.x);
        point.y = Interpolations.QuadraticBezier(t, v0.y, v1.y, v2.y);
        point.z = Interpolations.QuadraticBezier(t, v0.z, v1.z, v2.z);

        return point;
    }

    public function copy(source:QuadraticBezierCurve3):QuadraticBezierCurve3 {
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

    public function fromJSON(json:Dynamic):QuadraticBezierCurve3 {
        super.fromJSON(json);

        v0.fromArray(json.v0);
        v1.fromArray(json.v1);
        v2.fromArray(json.v2);

        return this;
    }
}