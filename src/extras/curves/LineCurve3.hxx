package three.js.src.extras.curves;

import three.js.src.math.Vector3;
import three.js.src.core.Curve;

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

    public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        var point:Vector3 = optionalTarget;

        if (t == 1) {
            point.copy(this.v2);
        } else {
            point.copy(this.v2).sub(this.v1);
            point.multiplyScalar(t).add(this.v1);
        }

        return point;
    }

    public function getPointAt(u:Float, optionalTarget:Vector3):Vector3 {
        return this.getPoint(u, optionalTarget);
    }

    public function getTangent(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        return optionalTarget.subVectors(this.v2, this.v1).normalize();
    }

    public function getTangentAt(u:Float, optionalTarget:Vector3):Vector3 {
        return this.getTangent(u, optionalTarget);
    }

    public function copy(source:LineCurve3):LineCurve3 {
        super.copy(source);

        this.v1.copy(source.v1);
        this.v2.copy(source.v2);

        return this;
    }

    public function toJSON():Dynamic {
        var data:Dynamic = super.toJSON();

        data.v1 = this.v1.toArray();
        data.v2 = this.v2.toArray();

        return data;
    }

    public function fromJSON(json:Dynamic):LineCurve3 {
        super.fromJSON(json);

        this.v1.fromArray(json.v1);
        this.v2.fromArray(json.v2);

        return this;
    }
}