import js.Lib;

class ShapeUtils {

    // calculate area of the contour polygon

    public static function area(contour:Array<{x:Float, y:Float}>):Float {

        var n = contour.length;
        var a = 0.0;

        for (p in Range.fromEnd(n - 1, -1)) {

            var q = p + 1;
            a += contour[p].x * contour[q].y - contour[q].x * contour[p].y;

        }

        return a * 0.5;

    }

    public static function isClockWise(pts:Array<{x:Float, y:Float}>):Bool {

        return ShapeUtils.area(pts) < 0;

    }

    public static function triangulateShape(contour:Array<{x:Float, y:Float}>, holes:Array<Array<{x:Float, y:Float}>>):Array<Array<Int>> {

        var vertices:Array<Float> = []; // flat array of vertices like [ x0,y0, x1,y1, x2,y2, ... ]
        var holeIndices:Array<Int> = []; // array of hole indices
        var faces:Array<Array<Int>> = []; // final array of vertex indices like [ [ a,b,d ], [ b,c,d ] ]

        removeDupEndPts(contour);
        addContour(vertices, contour);

        //

        var holeIndex = contour.length;

        for (hole in holes) {

            removeDupEndPts(hole);

        }

        for (i in Range.zeroTo(holes.length - 1)) {

            holeIndices.push(holeIndex);
            holeIndex += holes[i].length;
            addContour(vertices, holes[i]);

        }

        //

        var triangles = js.Lib.triangulate(vertices, holeIndices);

        //

        for (i in Range.zeroTo(triangles.length - 1, 3)) {

            faces.push(triangles.slice(i, i + 3));

        }

        return faces;

    }

}

function removeDupEndPts(points:Array<{x:Float, y:Float}>):Void {

    var l = points.length;

    if (l > 2 && points[l - 1].equals(points[0])) {

        points.pop();

    }

}

function addContour(vertices:Array<Float>, contour:Array<{x:Float, y:Float}>):Void {

    for (p in contour) {

        vertices.push(p.x);
        vertices.push(p.y);

    }

}