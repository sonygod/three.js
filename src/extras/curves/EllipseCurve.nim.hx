import Curve from '../core/Curve.hx';
import Vector2 from '../../math/Vector2.hx';

class EllipseCurve extends Curve {
    public var isEllipseCurve:Bool = true;
    public var type:String = 'EllipseCurve';
    public var aX:Float = 0;
    public var aY:Float = 0;
    public var xRadius:Float = 1;
    public var yRadius:Float = 1;
    public var aStartAngle:Float = 0;
    public var aEndAngle:Float = Math.PI * 2;
    public var aClockwise:Bool = false;
    public var aRotation:Float = 0;

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
        var point:Vector2 = optionalTarget;
        var twoPi:Float = Math.PI * 2;
        var deltaAngle:Float = this.aEndAngle - this.aStartAngle;
        var samePoints:Bool = Math.abs(deltaAngle) < Number.EPSILON;

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

export EllipseCurve;