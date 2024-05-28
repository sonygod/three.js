import Vector2 from js.Math.Vector2;
import Curve from js.Curve;

class LineCurve extends Curve {
    public var v1:Vector2;
    public var v2:Vector2;
    public var isLineCurve:Bool;
    public var type:String;

    public function new(v1:Vector2 = new Vector2(), v2:Vector2 = new Vector2()) {
        super();
        this.isLineCurve = true;
        this.type = 'LineCurve';
        this.v1 = v1;
        this.v2 = v2;
    }

    public function getPoint(t:Float, optionalTarget:Vector2 = new Vector2()):Vector2 {
        var point = optionalTarget;
        if (t == 1) {
            point.copy(v2);
        } else {
            point.copy(v2).sub(v1);
            point.multiplyScalar(t).add(v1);
        }
        return point;
    }

    public function getPointAt(u:Float, optionalTarget:Vector2):Vector2 {
        return getPoint(u, optionalTarget);
    }

    public function getTangent(t:Float, optionalTarget:Vector2 = new Vector2()):Vector2 {
        return optionalTarget.subVectors(v2, v1).normalize();
    }

    public function getTangentAt(u:Float, optionalTarget:Vector2):Vector2 {
        return getTangent(u, optionalTarget);
    }

    public function copy(source:LineCurve):LineCurve {
        super.copy(source);
        v1.copy(source.v1);
        v2.copy(source.v2);
        return this;
    }

    public function toJSON():Object {
        var data = super.toJSON();
        data.v1 = v1.toArray();
        data.v2 = v2.toArray();
        return data;
    }

    public function fromJSON(json:Object):Void {
        super.fromJSON(json);
        v1.fromArray(json.v1);
        v2.fromArray(json.v2);
    }
}