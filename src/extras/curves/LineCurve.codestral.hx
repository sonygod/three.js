import three.math.Vector2;
import three.extras.core.Curve;

class LineCurve extends Curve {

    public var isLineCurve:Bool = true;
    public var type:String = 'LineCurve';
    public var v1:Vector2;
    public var v2:Vector2;

    public function new(v1:Vector2 = null, v2:Vector2 = null) {
        super();
        this.v1 = v1 != null ? v1 : new Vector2();
        this.v2 = v2 != null ? v2 : new Vector2();
    }

    public function getPoint(t:Float, optionalTarget:Vector2 = null):Vector2 {
        var point = optionalTarget != null ? optionalTarget : new Vector2();

        if (t == 1) {
            point.copy(this.v2);
        } else {
            point.copy(this.v2).sub(this.v1);
            point.multiplyScalar(t).add(this.v1);
        }

        return point;
    }

    override public function getPointAt(u:Float, optionalTarget:Vector2 = null):Vector2 {
        return this.getPoint(u, optionalTarget);
    }

    public function getTangent(t:Float, optionalTarget:Vector2 = null):Vector2 {
        if (optionalTarget == null) {
            optionalTarget = new Vector2();
        }
        return optionalTarget.subVectors(this.v2, this.v1).normalize();
    }

    override public function getTangentAt(u:Float, optionalTarget:Vector2 = null):Vector2 {
        return this.getTangent(u, optionalTarget);
    }

    override public function copy(source:LineCurve):Curve {
        super.copy(source);
        this.v1.copy(source.v1);
        this.v2.copy(source.v2);
        return this;
    }

    override public function toJSON():Dynamic {
        var data = super.toJSON();
        data.v1 = this.v1.toArray();
        data.v2 = this.v2.toArray();
        return data;
    }

    override public function fromJSON(json:Dynamic):Curve {
        super.fromJSON(json);
        this.v1.fromArray(json.v1);
        this.v2.fromArray(json.v2);
        return this;
    }
}