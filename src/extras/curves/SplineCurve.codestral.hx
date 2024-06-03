import three.core.Curve;
import three.core.Interpolations;
import three.math.Vector2;

class SplineCurve extends Curve {

    public var points:Array<Vector2> = [];

    public function new(points:Array<Vector2> = null) {
        super();

        this.isSplineCurve = true;
        this.type = 'SplineCurve';

        if (points != null) {
            this.points = points;
        }
    }

    public function getPoint(t:Float, optionalTarget:Vector2 = null):Vector2 {
        var point:Vector2 = optionalTarget != null ? optionalTarget : new Vector2();

        var p:Float = (this.points.length - 1) * t;
        var intPoint:Int = Math.floor(p);
        var weight:Float = p - intPoint;

        var p0:Vector2 = this.points[intPoint == 0 ? intPoint : intPoint - 1];
        var p1:Vector2 = this.points[intPoint];
        var p2:Vector2 = this.points[intPoint > this.points.length - 2 ? this.points.length - 1 : intPoint + 1];
        var p3:Vector2 = this.points[intPoint > this.points.length - 3 ? this.points.length - 1 : intPoint + 2];

        point.set(
            Interpolations.CatmullRom(weight, p0.x, p1.x, p2.x, p3.x),
            Interpolations.CatmullRom(weight, p0.y, p1.y, p2.y, p3.y)
        );

        return point;
    }

    public function copy(source:SplineCurve):SplineCurve {
        super.copy(source);

        this.points = [];

        for (point in source.points) {
            this.points.push(point.clone());
        }

        return this;
    }

    public function toJSON():Dynamic {
        var data = super.toJSON();

        data.points = [];

        for (point in this.points) {
            data.points.push(point.toArray());
        }

        return data;
    }

    public function fromJSON(json:Dynamic):SplineCurve {
        super.fromJSON(json);

        this.points = [];

        for (point in json.points) {
            this.points.push(new Vector2().fromArray(point));
        }

        return this;
    }
}