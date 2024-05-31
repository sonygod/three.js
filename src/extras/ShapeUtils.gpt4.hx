import Earcut;

class ShapeUtils {

    // calculate area of the contour polygon
    public static function area(contour:Array<{x:Float, y:Float}>):Float {
        var n = contour.length;
        var a = 0.0;
        for (p in 0...n) {
            var q = (p + 1) % n;
            a += contour[p].x * contour[q].y - contour[q].x * contour[p].y;
        }
        return a * 0.5;
    }

    public static function isClockWise(pts:Array<{x:Float, y:Float}>):Bool {
        return ShapeUtils.area(pts) < 0;
    }

    public static function triangulateShape(contour:Array<{x:Float, y:Float}>, holes:Array<Array<{x:Float, y:Float}>>):Array<Array<Int>> {
        var vertices = []; // flat array of vertices like [ x0,y0, x1,y1, x2,y2, ... ]
        var holeIndices = []; // array of hole indices
        var faces = []; // final array of vertex indices like [ [ a,b,d ], [ b,c,d ] ]

        removeDupEndPts(contour);
        addContour(vertices, contour);

        var holeIndex = contour.length;
        for (hole in holes) {
            removeDupEndPts(hole);
            holeIndices.push(holeIndex);
            holeIndex += hole.length;
            addContour(vertices, hole);
        }

        var triangles = Earcut.triangulate(vertices, holeIndices);

        for (i in 0...triangles.length / 3) {
            faces.push([triangles[i * 3], triangles[i * 3 + 1], triangles[i * 3 + 2]]);
        }

        return faces;
    }

    static function removeDupEndPts(points:Array<{x:Float, y:Float}>):Void {
        var l = points.length;
        if (l > 2 && points[l - 1] == points[0]) {
            points.pop();
        }
    }

    static function addContour(vertices:Array<Float>, contour:Array<{x:Float, y:Float}>):Void {
        for (point in contour) {
            vertices.push(point.x);
            vertices.push(point.y);
        }
    }
}