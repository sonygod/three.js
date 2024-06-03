import three.math.Vector3;
import three.core.Curve;
import three.core.Interpolations;

class QuadraticBezierCurve3 extends Curve {
    public var v0:Vector3;
    public var v1:Vector3;
    public var v2:Vector3;

    public function new(Vector3? v0 = null, Vector3? v1 = null, Vector3? v2 = null) {
        super();

        this.isQuadraticBezierCurve3 = true;
        this.type = 'QuadraticBezierCurve3';
        this.v0 = v0 != null ? v0 : new Vector3();
        this.v1 = v1 != null ? v1 : new Vector3();
        this.v2 = v2 != null ? v2 : new Vector3();
    }

    public function getPoint(t:Float, Vector3? optionalTarget = null):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();
        point.set(
            Interpolations.QuadraticBezier(t, this.v0.x, this.v1.x, this.v2.x),
            Interpolations.QuadraticBezier(t, this.v0.y, this.v1.y, this.v2.y),
            Interpolations.QuadraticBezier(t, this.v0.z, this.v1.z, this.v2.z)
        );
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
        var data = super.toJSON();
        data.v0 = this.v0.toArray();
        data.v1 = this.v1.toArray();
        data.v2 = this.v2.toArray();
        return data;
    }

    public function fromJSON(json:Dynamic):QuadraticBezierCurve3 {
        super.fromJSON(json);
        this.v0.fromArray(json.v0);
        this.v1.fromArray(json.v1);
        this.v2.fromArray(json.v2);
        return this;
    }
}