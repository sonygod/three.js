package three.js.src.extras.curves;

import three.math.Vector2;
import three.core.Curve;

class LineCurve extends Curve {

    public var v1: Vector2;
    public var v2: Vector2;

    public function new(?v1: Vector2 = null, ?v2: Vector2 = null) {
        super();
        this.isLineCurve = true;
        this.type = 'LineCurve';
        this.v1 = if (v1 == null) new Vector2() else v1;
        this.v2 = if (v2 == null) new Vector2() else v2;
    }

    public function getPoint(t: Float, ?optionalTarget: Vector2 = null): Vector2 {
        var point: Vector2 = if (optionalTarget == null) new Vector2() else optionalTarget;
        if (t == 1) {
            point.copy(this.v2);
        } else {
            point.copy(this.v2).sub(this.v1);
            point.multiplyScalar(t).add(this.v1);
        }
        return point;
    }

    public function getPointAt(u: Float, ?optionalTarget: Vector2 = null): Vector2 {
        return this.getPoint(u, optionalTarget);
    }

    public function getTangent(t: Float, ?optionalTarget: Vector2 = null): Vector2 {
        var tangent: Vector2 = if (optionalTarget == null) new Vector2() else optionalTarget;
        return tangent.subVectors(this.v2, this.v1).normalize();
    }

    public function getTangentAt(u: Float, ?optionalTarget: Vector2 = null): Vector2 {
        return this.getTangent(u, optionalTarget);
    }

    override public function copy(source: LineCurve): LineCurve {
        super.copy(source);
        this.v1.copy(source.v1);
        this.v2.copy(source.v2);
        return this;
    }

    override public function toJSON(): Dynamic {
        var data: Dynamic = super.toJSON();
        data.v1 = this.v1.toArray();
        data.v2 = this.v2.toArray();
        return data;
    }

    override public function fromJSON(json: Dynamic): LineCurve {
        super.fromJSON(json);
        this.v1.fromArray(json.v1);
        this.v2.fromArray(json.v2);
        return this;
    }
}