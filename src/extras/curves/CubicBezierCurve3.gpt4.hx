import three.core.Curve;
import three.core.Interpolations.CubicBezier;
import three.math.Vector3;

class CubicBezierCurve3 extends Curve {
    
    public var isCubicBezierCurve3:Bool;
    public var type:String;
    public var v0:Vector3;
    public var v1:Vector3;
    public var v2:Vector3;
    public var v3:Vector3;

    public function new(?v0:Vector3 = null, ?v1:Vector3 = null, ?v2:Vector3 = null, ?v3:Vector3 = null) {
        super();
        this.isCubicBezierCurve3 = true;
        this.type = 'CubicBezierCurve3';
        this.v0 = if (v0 != null) v0 else new Vector3();
        this.v1 = if (v1 != null) v1 else new Vector3();
        this.v2 = if (v2 != null) v2 else new Vector3();
        this.v3 = if (v3 != null) v3 else new Vector3();
    }

    public function getPoint(t:Float, ?optionalTarget:Vector3 = null):Vector3 {
        var point = if (optionalTarget != null) optionalTarget else new Vector3();
        var v0 = this.v0;
        var v1 = this.v1;
        var v2 = this.v2;
        var v3 = this.v3;
        point.set(
            CubicBezier(t, v0.x, v1.x, v2.x, v3.x),
            CubicBezier(t, v0.y, v1.y, v2.y, v3.y),
            CubicBezier(t, v0.z, v1.z, v2.z, v3.z)
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
        var data = super.toJSON();
        data.v0 = this.v0.toArray();
        data.v1 = this.v1.toArray();
        data.v2 = this.v2.toArray();
        data.v3 = this.v3.toArray();
        return data;
    }

    public function fromJSON(json:Dynamic):CubicBezierCurve3 {
        super.fromJSON(json);
        this.v0.fromArray(json.v0);
        this.v1.fromArray(json.v1);
        this.v2.fromArray(json.v2);
        this.v3.fromArray(json.v3);
        return this;
    }
}