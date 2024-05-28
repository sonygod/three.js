package ;

import js.Curve;
import js.Interpolations.catmullRom;
import js.Vector2;

class SplineCurve extends Curve {
    public var isSplineCurve:Bool;
    public var type:String;
    public var points:Array<Vector2>;

    public function new(points:Array<Vector2> = []) {
        super();
        isSplineCurve = true;
        type = "SplineCurve";
        this.points = points;
    }

    public function getPoint(t:Float, optionalTarget:Vector2 = new Vector2()):Vector2 {
        var point:Vector2 = optionalTarget;
        var p:Int = (points.length - 1) * t;
        var intPoint:Int = Std.int(p);
        var weight:Float = p - intPoint;

        var p0:Vector2 = if (intPoint == 0) points[intPoint] else points[intPoint - 1];
        var p1:Vector2 = points[intPoint];
        var p2:Vector2 = if (intPoint > points.length - 2) points[points.length - 1] else points[intPoint + 1];
        var p3:Vector2 = if (intPoint > points.length - 3) points[points.length - 1] else points[intPoint + 2];

        point.set(
            catmullRom(weight, p0.x, p1.x, p2.x, p3.x),
            catmullRom(weight, p0.y, p1.y, p2.y, p3.y)
        );

        return point;
    }

    public function copy(source:SplineCurve):SplineCurve {
        super.copy(source);
        points = [];
        for (i in 0...source.points.length) {
            var point:Vector2 = source.points[i];
            points.push(point.clone());
        }
        return this;
    }

    public function toJSON():Object {
        var data:Object = super.toJSON();
        data.points = [];
        for (i in 0...points.length) {
            var point:Vector2 = points[i];
            data.points.push(point.toArray());
        }
        return data;
    }

    public function fromJSON(json:Object):SplineCurve {
        super.fromJSON(json);
        points = [];
        for (i in 0...json.points.length) {
            var point:Vector2 = new Vector2();
            var jsonPoint:Array<Dynamic> = json.points[i];
            point.fromArray(jsonPoint);
            points.push(point);
        }
        return this;
    }
}