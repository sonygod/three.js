class CubicBezierCurve3 extends Curve {
    public var v0:Vector3;
    public var v1:Vector3;
    public var v2:Vector3;
    public var v3:Vector3;
    public var isCubicBezierCurve3:Bool;

    public function new(v0:Vector3 = Vector3_Impl.create(), v1:Vector3 = Vector3_Impl.create(), v2:Vector3 = Vector3_Impl.create(), v3:Vector3 = Vector3_Impl.create()) {
        super();
        this.isCubicBezierCurve3 = true;
        this.type = 'CubicBezierCurve3';
        this.v0 = v0;
        this.v1 = v1;
        this.v2 = v2;
        this.v3 = v3;
    }

    public function getPoint(t:Float, optionalTarget:Vector3 = Vector3_Impl.create()):Vector3 {
        var point:Vector3 = optionalTarget;
        var v0:Vector3 = this.v0;
        var v1:Vector3 = this.v1;
        var v2:Vector3 = this.v2;
        var v3:Vector3 = this.v3;
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

    public function toJSON():HashMap<String, Dynamic, String> {
        var data:HashMap<String, Dynamic, String> = super.toJSON();
        data.set('v0', this.v0.toArray());
        data.set('v1', this.v1.toArray());
        data.set('v2', this.v2.toArray());
        data.set('v3', this.v3.toArray());
        return data;
    }

    public function fromJSON(json:HashMap<String, Dynamic, String>):Void {
        super.fromJSON(json);
        this.v0.fromArray(json.get('v0'));
        this.v1.fromArray(json.get('v1'));
        this.v2.fromArray(json.get('v2'));
        this.v3.fromArray(json.get('v3'));
    }
}