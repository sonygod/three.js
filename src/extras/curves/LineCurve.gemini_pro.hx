import math.Vector2;
import three.core.Curve;

class LineCurve extends Curve {

	public var isLineCurve:Bool = true;
	public var type:String = "LineCurve";
	public var v1:Vector2;
	public var v2:Vector2;

	public function new(v1:Vector2 = new Vector2(), v2:Vector2 = new Vector2()) {
		super();
		this.v1 = v1;
		this.v2 = v2;
	}

	public function getPoint(t:Float, optionalTarget:Vector2 = new Vector2()):Vector2 {
		var point:Vector2 = optionalTarget;

		if (t == 1) {
			point.copy(this.v2);
		} else {
			point.copy(this.v2).sub(this.v1);
			point.multiplyScalar(t).add(this.v1);
		}

		return point;
	}

	// Line curve is linear, so we can overwrite default getPointAt
	public function getPointAt(u:Float, optionalTarget:Vector2):Vector2 {
		return this.getPoint(u, optionalTarget);
	}

	public function getTangent(t:Float, optionalTarget:Vector2 = new Vector2()):Vector2 {
		return optionalTarget.subVectors(this.v2, this.v1).normalize();
	}

	public function getTangentAt(u:Float, optionalTarget:Vector2):Vector2 {
		return this.getTangent(u, optionalTarget);
	}

	public function copy(source:LineCurve):LineCurve {
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

	public function fromJSON(json:Dynamic):LineCurve {
		super.fromJSON(json);

		this.v1.fromArray(json.v1);
		this.v2.fromArray(json.v2);

		return this;
	}

}