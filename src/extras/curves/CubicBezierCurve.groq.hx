package three.js.src.extras.curves;

import three.js.src.core.Curve;
import three.js.src.core.Interpolations.CubicBezier;
import three.js.src.math.Vector2;

class CubicBezierCurve extends Curve {

    public var isCubicBezierCurve:Bool = true;

    public var type:String = 'CubicBezierCurve';

    public var v0:Vector2;
    public var v1:Vector2;
    public var v2:Vector2;
    public var v3:Vector2;

    public function new(v0:Vector2 = null, v1:Vector2 = null, v2:Vector2 = null, v3:Vector2 = null) {
        super();

        if (v0 == null) v0 = new Vector2();
        if (v1 == null) v1 = new Vector2();
        if (v2 == null) v2 = new Vector2();
        if (v3 == null) v3 = new Vector2();

        this.v0 = v0;
        this.v1 = v1;
        this.v2 = v2;
        this.v3 = v3;
    }

    public function getPoint(t:Float, ?optionalTarget:Vector2):Vector2 {
        var point:Vector2 = optionalTarget != null ? optionalTarget : new Vector2();
        point.set(
            CubicBezier.interpolate(t, v0.x, v1.x, v2.x, v3.x),
            CubicBezier.interpolate(t, v0.y, v1.y, v2.y, v3.y)
        );
        return point;
    }

    public function copy(source:CubicBezierCurve):CubicBezierCurve {
        super.copy(source);

        v0.copy(source.v0);
        v1.copy(source.v1);
        v2.copy(source.v2);
        v3.copy(source.v3);

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

    public function fromJSON(json:Dynamic):CubicBezierCurve {
        super.fromJSON(json);

        v0.fromArray(json.v0);
        v1.fromArray(json.v1);
        v2.fromArray(json.v2);
        v3.fromArray(json.v3);

        return this;
    }
}