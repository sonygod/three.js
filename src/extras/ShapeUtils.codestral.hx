import Earcut;

class ShapeUtils {

    static function area(contour:Array<Point>):Float {
        var n:Int = contour.length;
        var a:Float = 0.0;

        for (var p:Int = n - 1, q:Int = 0; q < n; p = q ++) {
            a += contour[p].x * contour[q].y - contour[q].x * contour[p].y;
        }

        return a * 0.5;
    }

    static function isClockWise(pts:Array<Point>):Bool {
        return ShapeUtils.area(pts) < 0;
    }

    static function triangulateShape(contour:Array<Point>, holes:Array<Array<Point>>):Array<Array<Int>> {
        var vertices:Array<Float> = [];
        var holeIndices:Array<Int> = [];
        var faces:Array<Array<Int>> = [];

        removeDupEndPts(contour);
        addContour(vertices, contour);

        var holeIndex:Int = contour.length;

        for (var i in 0...holes.length) {
            removeDupEndPts(holes[i]);
            holeIndices.push(holeIndex);
            holeIndex += holes[i].length;
            addContour(vertices, holes[i]);
        }

        var triangles:Array<Int> = Earcut.triangulate(vertices, holeIndices);

        for (var i:Int = 0; i < triangles.length; i += 3) {
            faces.push(triangles.slice(i, i + 3));
        }

        return faces;
    }

    static function removeDupEndPts(points:Array<Point>) {
        var l:Int = points.length;

        if (l > 2 && points[l - 1].equals(points[0])) {
            points.pop();
        }
    }

    static function addContour(vertices:Array<Float>, contour:Array<Point>) {
        for (var i in 0...contour.length) {
            vertices.push(contour[i].x);
            vertices.push(contour[i].y);
        }
    }
}

class Point {
    public var x:Float;
    public var y:Float;

    public function new(x:Float, y:Float) {
        this.x = x;
        this.y = y;
    }

    public function equals(other:Point):Bool {
        return this.x == other.x && this.y == other.y;
    }
}