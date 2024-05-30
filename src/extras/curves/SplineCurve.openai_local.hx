import three.core.Curve;
import three.core.Interpolations.CatmullRom;
import three.math.Vector2;

class SplineCurve extends Curve {
    
    public var points:Array<Vector2>;

    public function new(points:Array<Vector2> = []) {
        super();
        this.isSplineCurve = true;
        this.type = 'SplineCurve';
        this.points = points;
    }

    public function getPoint(t:Float, ?optionalTarget:Vector2):Vector2 {
        var point = optionalTarget != null ? optionalTarget : new Vector2();
        var points = this.points;
        var p = (points.length - 1) * t;
        var intPoint = Math.floor(p);
        var weight = p - intPoint;

        var p0 = points[intPoint == 0 ? intPoint : intPoint - 1];
        var p1 = points[intPoint];
        var p2 = points[intPoint > points.length - 2 ? points.length - 1 : intPoint + 1];
        var p3 = points[intPoint > points.length - 3 ? points.length - 1 : intPoint + 2];

        point.set(
            CatmullRom(weight, p0.x, p1.x, p2.x, p3.x),
            CatmullRom(weight, p0.y, p1.y, p2.y, p3.y)
        );

        return point;
    }

    public override function copy(source:Curve):Curve {
        super.copy(source);
        var src: SplineCurve = cast(source, SplineCurve);
        this.points = [];
        for (i in 0...src.points.length) {
            var point = src.points[i];
            this.points.push(point.clone());
        }
        return this;
    }

    public override function toJSON():Dynamic {
        var data = super.toJSON();
        data.points = [];
        for (i in 0...this.points.length) {
            var point = this.points[i];
            data.points.push(point.toArray());
        }
        return data;
    }

    public override function fromJSON(json:Dynamic):Curve {
        super.fromJSON(json);
        this.points = [];
        for (i in 0...json.points.length) {
            var point = json.points[i];
            this.points.push(new Vector2().fromArray(point));
        }
        return this;
    }

}