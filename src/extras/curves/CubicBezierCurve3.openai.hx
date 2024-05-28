package threejs.src.extras.curves;

import threejs.src.core.Curve;
import threejs.src.core.Interpolations.CubicBezier;
import threejs.src.math.Vector3;

class CubicBezierCurve3 extends Curve {
    public var v0:Vector3;
    public var v1:Vector3;
    public var v2:Vector3;
    public var v3:Vector3;

    public function new(v0:Vector3 = null, v1:Vector3 = null, v2:Vector3 = null, v3:Vector3 = null) {
        super();

        this.isCubicBezierCurve3 = true;
        this.type = 'CubicBezierCurve3';

        this.v0 = v0 != null ? v0 : new Vector3();
        this.v1 = v1 != null ? v1 : new Vector3();
        this.v2 = v2 != null ? v2 : new Vector3();
        this.v3 = v3 != null ? v3 : new Vector3();
    }

    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();

        point.set(
            CubicBezier.get(t, v0.x, v1.x, v2.x, v3.x),
            CubicBezier.get(t, v0.y, v1.y, v2.y, v3.y),
            CubicBezier.get(t, v0.z, v1.z, v2.z, v3.z)
        );

        return point;
    }

    public function copy(source:CubicBezierCurve3):CubicBezierCurve3 {
        super.copy(source);

        this.v0.copy(source.v0);
        this.v1.copy(source.v1);
        this.v2.copy(source.v2);
        this.v3.copy(source.v3);

        return this;
    }

    public function toJSON():Dynamic {
        var data:Dynamic = super.toJSON();

        data.v0 = v0.toArray();
        data.v1 = v1.toArray();
        data.v2 = v2.toArray();
        data.v3 = v3.toArray();

        return data;
    }

    public function fromJSON(json:Dynamic):CubicBezierCurve3 {
        super.fromJSON(json);

        v0.fromArray(json.v0);
        v1.fromArray(json.v1);
        v2.fromArray(json.v2);
        v3.fromArray(json.v3);

        return this;
    }
}