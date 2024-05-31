import three.extras.core.Curve;
import three.math.Vector2;

class EllipseCurve extends Curve {

	public var aX:Float;
	public var aY:Float;
	public var xRadius:Float;
	public var yRadius:Float;
	public var aStartAngle:Float;
	public var aEndAngle:Float;
	public var aClockwise:Bool;
	public var aRotation:Float;

	public function new(aX:Float = 0, aY:Float = 0, xRadius:Float = 1, yRadius:Float = 1, aStartAngle:Float = 0, aEndAngle:Float = Math.PI * 2, aClockwise:Bool = false, aRotation:Float = 0) {
		super();
		this.aX = aX;
		this.aY = aY;
		this.xRadius = xRadius;
		this.yRadius = yRadius;
		this.aStartAngle = aStartAngle;
		this.aEndAngle = aEndAngle;
		this.aClockwise = aClockwise;
		this.aRotation = aRotation;
	}

	public function getPoint(t:Float, optionalTarget:Vector2 = new Vector2()):Vector2 {
		var point = optionalTarget;
		var twoPi = Math.PI * 2;
		var deltaAngle = this.aEndAngle - this.aStartAngle;
		var samePoints = Math.abs(deltaAngle) < Number.EPSILON;

		// ensures that deltaAngle is 0 .. 2 PI
		while (deltaAngle < 0) deltaAngle += twoPi;
		while (deltaAngle > twoPi) deltaAngle -= twoPi;

		if (deltaAngle < Number.EPSILON) {
			if (samePoints) {
				deltaAngle = 0;
			} else {
				deltaAngle = twoPi;
			}
		}

		if (this.aClockwise && !samePoints) {
			if (deltaAngle == twoPi) {
				deltaAngle = -twoPi;
			} else {
				deltaAngle = deltaAngle - twoPi;
			}
		}

		var angle = this.aStartAngle + t * deltaAngle;
		var x = this.aX + this.xRadius * Math.cos(angle);
		var y = this.aY + this.yRadius * Math.sin(angle);

		if (this.aRotation != 0) {
			var cos = Math.cos(this.aRotation);
			var sin = Math.sin(this.aRotation);
			var tx = x - this.aX;
			var ty = y - this.aY;

			// Rotate the point about the center of the ellipse.
			x = tx * cos - ty * sin + this.aX;
			y = tx * sin + ty * cos + this.aY;
		}

		return point.set(x, y);
	}

	public function copy(source:EllipseCurve):EllipseCurve {
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
		var data = super.toJSON();
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

	public function fromJSON(json:Dynamic):EllipseCurve {
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