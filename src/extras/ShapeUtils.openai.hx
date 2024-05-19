import threex.extras.Earcut;

class ShapeUtils {

    static function area(contour: Array<{x: Float, y: Float}>): Float {
        var n:Int = contour.length;
        var a:Float = 0.0;

        for (p in 0 ... n) {
            var q:Int = (p + 1) % n;
            a += contour[p].x * contour[q].y - contour[q].x * contour[p].y;
        }

        return a * 0.5;
    }

    static function isClockWise(pts: Array<{x: Float, y: Float}>): Bool {
        return ShapeUtils.area(pts) < 0;
    }

    static function triangulateShape(contour: Array<{x: Float, y: Float}>, holes: Array<Array<{x: Float, y: Float}>>): Array<Array<Int>> {
        var vertices:Array<Float> = [];
        var holeIndices:Array<Int> = [];
        var faces:Array<Array<Int>> = [];

        removeDupEndPts(contour);
        addContour(vertices, contour);

        var holeIndex:Int = contour.length;
        for (i in 0 ... holes.length) {
            removeDupEndPts(holes[i]);
            holeIndices.push(holeIndex);
            holeIndex += holes[i].length;
            addContour(vertices, holes[i]);
        }

        var triangles:Array<Int> = Earcut.triangulate(vertices, holeIndices);

        for (i in 0 ... (triangles.length / 3)) {
            faces.push(triangles.slice(i * 3, i * 3 + 3));
        }

        return faces;
    }

    static function removeDupEndPts(points: Array<{x: Float, y: Float}>): Void {
        var l:Int = points.length;

        if (l > 2 && points[l - 1].equals(points[0])) {
            points.pop();
        }
    }

    static function addContour(vertices: Array<Float>, contour: Array<{x: Float, y: Float}>): Void {
        for (point in contour) {
            vertices.push(point.x);
            vertices.push(point.y);
        }
    }

}

class Earcut {
    public static function triangulate(vertices: Array<Float>, holeIndices: Array<Int>): Array<Int> {
        // Add Earcut implementation here
        // ...
        return [];
    }
}