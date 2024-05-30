import threejs.extras.core.Curve;
import threejs.extras.core.Interpolations.QuadraticBezier;
import threejs.math.Vector3;

class QuadraticBezierCurve3 extends Curve {

	public var v0:Vector3;
	public var v1:Vector3;
	public var v2:Vector3;

	public function new(?v0:Vector3 = null, ?v1:Vector3 = null, ?v2:Vector3 = null) {
		super();
		this.isQuadraticBezierCurve3 = true;
		this.type = 'QuadraticBezierCurve3';

		this.v0 = v0 != null ? v0 : new Vector3();
		this.v1 = v1 != null ? v1 : new Vector3();
		this.v2 = v2 != null ? v2 : new Vector3();
	}

	public function getPoint(t:Float, ?optionalTarget:Vector3 = null):Vector3 {
		var point = if (optionalTarget != null) optionalTarget else new Vector3();
		point.set(
			QuadraticBezier(t, v0.x, v1.x, v2.x),
			QuadraticBezier(t, v0.y, v1.y, v2.y),
			QuadraticBezier(t, v0.z, v1.z, v2.z)
		);
		return point;
	}

	public override function copy(source:Curve):Curve {
		super.copy(source);
		var src = cast source;
		this.v0.copy(src.v0);
		this.v1.copy(src.v1);
		this.v2.copy(src.v2);
		return this;
	}

	public override function toJSON():Dynamic {
		var data = super.toJSON();
		data.v0 = this.v0.toArray();
		data.v1 = this.v1.toArray();
		data.v2 = this.v2.toArray();
		return data;
	}

	public override function fromJSON(json:Dynamic):Void {
		super.fromJSON(json);
		this.v0.fromArray(json.v0);
		this.v1.fromArray(json.v1);
		this.v2.fromArray(json.v2);
	}
}