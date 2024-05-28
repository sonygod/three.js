package three.js.src.extras.curves;

import three.core.Curve;
import three.math.Vector2;

class EllipseCurve extends Curve {
    public var isEllipseCurve:Bool = true;
    public var type:String = 'EllipseCurve';

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

    public function getPoint(t:Float, optionalTarget:Vector2 = null):Vector2 {
        var point:Vector2 = optionalTarget == null ? new Vector2() : optionalTarget;
        var twoPi:Float = Math.PI * 2;
        var deltaAngle:Float = aEndAngle - aStartAngle;
        var samePoints:Bool = Math.abs(deltaAngle) < Math.pow(10, -10);

        // ensures that deltaAngle is 0 .. 2 PI
        while (deltaAngle < 0) deltaAngle += twoPi;
        while (deltaAngle > twoPi) deltaAngle -= twoPi;

        if (deltaAngle < Math.pow(10, -10)) {
            if (samePoints) {
                deltaAngle = 0;
            } else {
                deltaAngle = twoPi;
            }
        }

        if (aClockwise && !samePoints) {
            if (deltaAngle == twoPi) {
                deltaAngle = -twoPi;
            } else {
                deltaAngle = deltaAngle - twoPi;
            }
        }

        var angle:Float = aStartAngle + t * deltaAngle;
        var x:Float = aX + xRadius * Math.cos(angle);
        var y:Float = aY + yRadius * Math.sin(angle);

        if (aRotation != 0) {
            var cos:Float = Math.cos(aRotation);
            var sin:Float = Math.sin(aRotation);

            var tx:Float = x - aX;
            var ty:Float = y - aY;

            // Rotate the point about the center of the ellipse.
            x = tx * cos - ty * sin + aX;
            y = tx * sin + ty * cos + aY;
        }

        return point.set(x, y);
    }

    public function copy(source:EllipseCurve):EllipseCurve {
        super.copy(source);

        aX = source.aX;
        aY = source.aY;

        xRadius = source.xRadius;
        yRadius = source.yRadius;

        aStartAngle = source.aStartAngle;
        aEndAngle = source.aEndAngle;

        aClockwise = source.aClockwise;

        aRotation = source.aRotation;

        return this;
    }

    public function toJSON():Dynamic {
        var data:Dynamic = super.toJSON();

        data.aX = aX;
        data.aY = aY;

        data.xRadius = xRadius;
        data.yRadius = yRadius;

        data.aStartAngle = aStartAngle;
        data.aEndAngle = aEndAngle;

        data.aClockwise = aClockwise;

        data.aRotation = aRotation;

        return data;
    }

    public function fromJSON(json:Dynamic):EllipseCurve {
        super.fromJSON(json);

        aX = json.aX;
        aY = json.aY;

        xRadius = json.xRadius;
        yRadius = json.yRadius;

        aStartAngle = json.aStartAngle;
        aEndAngle = json.aEndAngle;

        aClockwise = json.aClockwise;

        aRotation = json.aRotation;

        return this;
    }
}