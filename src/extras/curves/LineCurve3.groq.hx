package three.js.src.extras.curves;

import three.math.Vector3;
import three.core.Curve;

class LineCurve3 extends Curve {
    public var v1:Vector3;
    public var v2:Vector3;

    public function new(v1:Vector3 = new Vector3(), v2:Vector3 = new Vector3()) {
        super();
        this.isLineCurve3 = true;
        this.type = 'LineCurve3';
        this.v1 = v1;
        this.v2 = v2;
    }

    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();
        if (t == 1) {
            point.copy(v2);
        } else {
            point.copy(v2).sub(v1);
            point.multiplyScalar(t).add(v1);
        }
        return point;
    }

    public function getPointAt(u:Float, ?optionalTarget:Vector3):Vector3 {
        return getPoint(u, optionalTarget);
    }

    public function getTangent(t:Float, ?optionalTarget:Vector3):Vector3 {
        return optionalTarget != null ? optionalTarget.subVectors(v2, v1).normalize() : new Vector3().subVectors(v2, v1).normalize();
    }

    public function getTangentAt(u:Float, ?optionalTarget:Vector3):Vector3 {
        return getTangent(u, optionalTarget);
    }

    public function copy(source:LineCurve3):LineCurve3 {
        super.copy(source);
        v1.copy(source.v1);
        v2.copy(source.v2);
        return this;
    }

    public function toJSON():Dynamic {
        var data:Dynamic = super.toJSON();
        data.v1 = v1.toArray();
        data.v2 = v2.toArray();
        return data;
    }

    public function fromJSON(json:Dynamic):LineCurve3 {
        super.fromJSON(json);
        v1.fromArray(json.v1);
        v2.fromArray(json.v2);
        return this;
    }
}