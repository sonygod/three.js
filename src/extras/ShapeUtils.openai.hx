package three.js.src.extras;

import Earcut;

class ShapeUtils {

    // calculate area of the contour polygon
    public static function area(contour:Array<{x:Float, y:Float}>):Float {
        var n = contour.length;
        var a:Float = 0.0;

        for (p in n - 1...0) {
            a += contour[p].x * contour[(p + 1) % n].y - contour[(p + 1) % n].x * contour[p].y;
        }

        return a * 0.5;
    }

    public static function isClockWise(pts:Array<{x:Float, y:Float}>):Bool {
        return area(pts) < 0;
    }

    public static function triangulateShape(contour:Array<{x:Float, y:Float}>, holes:Array<Array<{x:Float, y:Float}>>):Array<Array<Int>> {
        var vertices:Array<Float> = [];
        var holeIndices:Array<Int> = [];
        var faces:Array<Array<Int>> = [];

        removeDupEndPts(contour);
        addContour(vertices, contour);

        var holeIndex:Int = contour.length;

        for (hole in holes) {
            removeDupEndPts(hole);
        }

        for (i in 0...holes.length) {
            holeIndices.push(holeIndex);
            holeIndex += holes[i].length;
            addContour(vertices, holes[i]);
        }

        var triangles:Array<Int> = Earcut.triangulate(vertices, holeIndices);

        for (i in 0...(triangles.length - 2)) {
            faces.push(triangles.slice(i, i + 3));
        }

        return faces;
    }
}

function removeDupEndPts(points:Array<{x:Float, y:Float}>):Void {
    if (points.length > 2 && points[points.length - 1].equals(points[0])) {
        points.pop();
    }
}

function addContour(vertices:Array<Float>, contour:Array<{x:Float, y:Float}>):Void {
    for (point in contour) {
        vertices.push(point.x);
        vertices.push(point.y);
    }
}