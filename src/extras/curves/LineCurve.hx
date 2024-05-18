package three.extras.curves;

import three.math.Vector2;
import three.core.Curve;

class LineCurve extends Curve {
    public var v1:Vector2;
    public var v2:Vector2;

    public function new(v1:Vector2 = new Vector2(), v2:Vector2 = new Vector2()) {
        super();

        isLineCurve = true;
        type = 'LineCurve';

        this.v1 = v1;
        this.v2 = v2;
    }

    public function getPoint(t:Float, ?optionalTarget:Vector2):Vector2 {
        var point:Vector2 = optionalTarget != null ? optionalTarget : new Vector2();

        if (t == 1) {
            point.copy(v2);
        } else {
            point.copy(v2).sub(v1);
            point.multiplyScalar(t).add(v1);
        }

        return point;
    }

    public function getPointAt(u:Float, ?optionalTarget:Vector2):Vector2 {
        return getPoint(u, optionalTarget);
    }

    public function getTangent(t:Float, ?optionalTarget:Vector2):Vector2 {
        return optionalTarget != null ? optionalTarget.subVectors(v2, v1).normalize() : new Vector2(v2.x - v1.x, v2.y - v1.y).normalize();
    }

    public function getTangentAt(u:Float, ?optionalTarget:Vector2):Vector2 {
        return getTangent(u, optionalTarget);
    }

    public function copy(source:LineCurve):LineCurve {
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

    public function fromJSON(json:Dynamic):LineCurve {
        super.fromJSON(json);

        v1.fromArray(json.v1);
        v2.fromArray(json.v2);

        return this;
    }
}