package three.extras.core;

import three.math.Vector2;
import three.extras.core.CurvePath;
import three.curves.EllipseCurve;
import three.curves.SplineCurve;
import three.curves.CubicBezierCurve;
import three.curves.QuadraticBezierCurve;
import three.curves.LineCurve;

class Path extends CurvePath {
    public var type:String;
    public var currentPoint:Vector2;
    public var curves:Array<Dynamic>;

    public function new(points:Array<Vector2> = null) {
        super();
        type = 'Path';
        currentPoint = new Vector2();

        if (points != null) {
            setFromPoints(points);
        }
    }

    public function setFromPoints(points:Array<Vector2>):Path {
        moveTo(points[0].x, points[0].y);

        for (i in 1...points.length) {
            lineTo(points[i].x, points[i].y);
        }

        return this;
    }

    public function moveTo(x:Float, y:Float):Path {
        currentPoint.set(x, y);
        return this;
    }

    public function lineTo(x:Float, y:Float):Path {
        var curve = new LineCurve(currentPoint.clone(), new Vector2(x, y));
        curves.push(curve);
        currentPoint.set(x, y);
        return this;
    }

    public function quadraticCurveTo(aCPx:Float, aCPy:Float, aX:Float, aY:Float):Path {
        var curve = new QuadraticBezierCurve(currentPoint.clone(), new Vector2(aCPx, aCPy), new Vector2(aX, aY));
        curves.push(curve);
        currentPoint.set(aX, aY);
        return this;
    }

    public function bezierCurveTo(aCP1x:Float, aCP1y:Float, aCP2x:Float, aCP2y:Float, aX:Float, aY:Float):Path {
        var curve = new CubicBezierCurve(currentPoint.clone(), new Vector2(aCP1x, aCP1y), new Vector2(aCP2x, aCP2y), new Vector2(aX, aY));
        curves.push(curve);
        currentPoint.set(aX, aY);
        return this;
    }

    public function splineThru(pts:Array<Vector2>):Path {
        var npts = [currentPoint.clone()].concat(pts);
        var curve = new SplineCurve(npts);
        curves.push(curve);
        currentPoint.copy(pts[pts.length - 1]);
        return this;
    }

    public function arc(aX:Float, aY:Float, aRadius:Float, aStartAngle:Float, aEndAngle:Float, aClockwise:Bool):Path {
        var x0 = currentPoint.x;
        var y0 = currentPoint.y;
        absarc(aX + x0, aY + y0, aRadius, aStartAngle, aEndAngle, aClockwise);
        return this;
    }

    public function absarc(aX:Float, aY:Float, aRadius:Float, aStartAngle:Float, aEndAngle:Float, aClockwise:Bool):Path {
        absellipse(aX, aY, aRadius, aRadius, aStartAngle, aEndAngle, aClockwise);
        return this;
    }

    public function ellipse(aX:Float, aY:Float, xRadius:Float, yRadius:Float, aStartAngle:Float, aEndAngle:Float, aClockwise:Bool, aRotation:Float):Path {
        var x0 = currentPoint.x;
        var y0 = currentPoint.y;
        absellipse(aX + x0, aY + y0, xRadius, yRadius, aStartAngle, aEndAngle, aClockwise, aRotation);
        return this;
    }

    public function absellipse(aX:Float, aY:Float, xRadius:Float, yRadius:Float, aStartAngle:Float, aEndAngle:Float, aClockwise:Bool, aRotation:Float):Path {
        var curve = new EllipseCurve(aX, aY, xRadius, yRadius, aStartAngle, aEndAngle, aClockwise, aRotation);

        if (curves.length > 0) {
            var firstPoint = curve.getPoint(0);

            if (!firstPoint.equals(currentPoint)) {
                lineTo(firstPoint.x, firstPoint.y);
            }
        }

        curves.push(curve);

        var lastPoint = curve.getPoint(1);
        currentPoint.copy(lastPoint);

        return this;
    }

    public function copy(source:Path):Path {
        super.copy(source);
        currentPoint.copy(source.currentPoint);
        return this;
    }

    public function toJSON():Dynamic {
        var data = super.toJSON();
        data.currentPoint = currentPoint.toArray();
        return data;
    }

    public function fromJSON(json:Dynamic):Path {
        super.fromJSON(json);
        currentPoint.fromArray(json.currentPoint);
        return this;
    }
}