import three.math.Vector2;
import three.extras.core.Curve;

class LineCurve extends Curve {

	public var v1:Vector2;
	public var v2:Vector2;

	public function new(v1:Vector2 = new Vector2(), v2:Vector2 = new Vector2()) {
		super();
		this.v1 = v1;
		this.v2 = v2;
	}

	public function getPoint(t:Float, optionalTarget:Vector2 = new Vector2()):Vector2 {
		if (t == 1) {
			optionalTarget.copy(this.v2);
		} else {
			optionalTarget.copy(this.v2).sub(this.v1).multiplyScalar(t).add(this.v1);
		}
		return optionalTarget;
	}

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
		var data = super.toJSON();
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