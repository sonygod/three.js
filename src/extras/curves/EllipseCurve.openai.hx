package extras.curves;
import core.Curve;
import math.Vector2;

class EllipseCurve extends Curve {

	public var aX(default, null):Float;
	public var aY(default, null):Float;
	public var xRadius(default, null):Float;
	public var yRadius(default, null):Float;
	public var aStartAngle(default, null):Float;
	public var aEndAngle(default, null):Float;
	public var aClockwise(default, null):Bool;
	public var aRotation(default, null):Float;

	public function new(aX = 0, aY = 0, xRadius = 1, yRadius = 1, aStartAngle = 0, aEndAngle = Math.PI * 2, aClockwise = false, aRotation = 0) {
		super();
		this.isEllipseCurve = true;
		this.type = 'EllipseCurve';
		this.aX = aX;
		this.aY = aY;
		this.xRadius = xRadius;
		this.yRadius = yRadius;
		this.aStartAngle = aStartAngle;
		this.aEndAngle = aEndAngle;
		this.aClockwise = aClockwise;
		this.aRotation = aRotation;
	}

	public function getPoint(t:Float, ?optionalTarget:Vector2 = null):Vector2 {
		var point:Vector2 = (optionalTarget != null) ? optionalTarget : new Vector2();
		var twoPi:Float = Math.PI * 2;
		var deltaAngle:Float = this.aEndAngle - this.aStartAngle;
		var samePoints:Bool = Math.abs(deltaAngle) < Math.EPSILON;
		while (deltaAngle < 0) deltaAngle += twoPi;
		while (deltaAngle > twoPi) deltaAngle -= twoPi;
		if (deltaAngle < Math.EPSILON) {
			if (samePoints){
				deltaAngle = 0;
			} else {
				deltaAngle = twoPi;
			}
		}
		if (this.aClockwise === true && !samePoints) {
			if (deltaAngle === twoPi) {
				deltaAngle = -twoPi;
			} else {
				deltaAngle = deltaAngle - twoPi;
			}
		}
		var angle:Float = this.aStartAngle + t * deltaAngle;
		var x:Float = this.aX + this.xRadius * Math.cos(angle);
		var y:Float = this.aY + this.yRadius * Math.sin(angle);
		if (this.aRotation !== 0) {
			var cos:Float = Math.cos(this.aRotation);
			var sin:Float = Math.sin(this.aRotation);
			var tx:Float = x - this.aX;
			var ty:Float = y - this.aY;
			x = tx * cos - ty * sin + this.aX;
			y = tx * sin + ty * cos + this.aY;
		}
		return point.set(x, y);
	}

	public function copy(source):EllipseCurve {
		super.copy(source);
		this.aX = source.aX;
		this.aY = source.aY;
		this.xRadius = source.xRadius;
		this.yRadius = source.yRadius;
		this.aStartAngle = source.aStartAngle;
		this.aEndAngle = source.aEndAngle;
		this.aClockwise = source.aClockwise;
		this.aRotation = source.aRotation;
		return this;
	}

	public function toJSON():Dynamic {
		var data:Dynamic = super.toJSON();
		data.aX = this.aX;
		data.aY = this.aY;
		data.xRadius = this.xRadius;
		data.yRadius = this.yRadius;
		data.aStartAngle = this.aStartAngle;
		data.aEndAngle = this.aEndAngle;
		data.aClockwise = this.aClockwise;
		data.aRotation = this.aRotation;
		return data;
	}

	public function fromJSON(json):EllipseCurve {
		super.fromJSON(json);
		this.aX = json.aX;
		this.aY = json.aY;
		this.xRadius = json.xRadius;
		this.yRadius = json.yRadius;
		this.aStartAngle = json.aStartAngle;
		this.aEndAngle = json.aEndAngle;
		this.aClockwise = json.aClockwise;
		this.aRotation = json.aRotation;
		return this;
	}
}