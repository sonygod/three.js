package three.js.src.extras.curves;

import three.js.src.core.Curve;
import three.js.src.core.Interpolations;
import three.math.Vector2;

class SplineCurve extends Curve {
    public var isSplineCurve:Bool = true;
    public var type:String = 'SplineCurve';
    public var points:Array<Vector2>;

    public function new(?points:Array<Vector2>) {
        super();
        this.points = points != null ? points : [];
    }

    public function getPoint(t:Float, ?optionalTarget:Vector2):Vector2 {
        var point:Vector2 = optionalTarget != null ? optionalTarget : new Vector2();
        var points:Array<Vector2> = this.points;
        var p:Float = (points.length - 1) * t;
        var intPoint:Int = Math.floor(p);
        var weight:Float = p - intPoint;

        var p0:Vector2 = intPoint == 0 ? points[intPoint] : points[intPoint - 1];
        var p1:Vector2 = points[intPoint];
        var p2:Vector2 = intPoint > points.length - 2 ? points[points.length - 1] : points[intPoint + 1];
        var p3:Vector2 = intPoint > points.length - 3 ? points[points.length - 1] : points[intPoint + 2];

        point.set(
            Interpolations.CatmullRom(weight, p0.x, p1.x, p2.x, p3.x),
            Interpolations.CatmullRom(weight, p0.y, p1.y, p2.y, p3.y)
        );
        return point;
    }

    public function copy(source:SplineCurve):SplineCurve {
        super.copy(source);
        this.points = [];
        for (i in 0...source.points.length) {
            var point:Vector2 = source.points[i];
            this.points.push(point.clone());
        }
        return this;
    }

    public function toJSON():Dynamic {
        var data:Dynamic = super.toJSON();
        data.points = [];
        for (i in 0...this.points.length) {
            var point:Vector2 = this.points[i];
            data.points.push(point.toArray());
        }
        return data;
    }

    public function fromJSON(json:Dynamic):SplineCurve {
        super.fromJSON(json);
        this.points = [];
        for (i in 0...json.points.length) {
            var point:Array<Float> = json.points[i];
            this.points.push(new Vector2().fromArray(point));
        }
        return this;
    }
}