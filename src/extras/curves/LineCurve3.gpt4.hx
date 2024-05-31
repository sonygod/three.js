import three.math.Vector3;
import three.extras.core.Curve;

class LineCurve3 extends Curve {
	
	public var v1:Vector3;
	public var v2:Vector3;

	public function new(v1:Vector3 = null, v2:Vector3 = null) {
		super();
		
		this.v1 = if (v1 != null) v1 else new Vector3();
		this.v2 = if (v2 != null) v2 else new Vector3();

		this.isLineCurve3 = true;
		this.type = "LineCurve3";
	}

	public function getPoint(t:Float, optionalTarget:Vector3 = null):Vector3 {
		var point = if (optionalTarget != null) optionalTarget else new Vector3();

		if (t == 1) {
			point.copy(this.v2);
		} else {
			point.copy(this.v2).sub(this.v1);
			point.multiplyScalar(t).add(this.v1);
		}

		return point;
	}

	public function getPointAt(u:Float, optionalTarget:Vector3 = null):Vector3 {
		return this.getPoint(u, optionalTarget);
	}

	public function getTangent(t:Float, optionalTarget:Vector3 = null):Vector3 {
		var result = if (optionalTarget != null) optionalTarget else new Vector3();
		return result.subVectors(this.v2, this.v1).normalize();
	}

	public function getTangentAt(u:Float, optionalTarget:Vector3 = null):Vector3 {
		return this.getTangent(u, optionalTarget);
	}

	public override function copy(source:Curve):Curve {
		super.copy(source);
		var src:LineCurve3 = cast source;
		this.v1.copy(src.v1);
		this.v2.copy(src.v2);
		return this;
	}

	public override function toJSON():Dynamic {
		var data = super.toJSON();
		data.v1 = this.v1.toArray();
		data.v2 = this.v2.toArray();
		return data;
	}

	public override function fromJSON(json:Dynamic):Void {
		super.fromJSON(json);
		this.v1.fromArray(json.v1);
		this.v2.fromArray(json.v2);
	}
}