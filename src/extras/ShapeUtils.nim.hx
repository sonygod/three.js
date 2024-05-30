import Earcut.Earcut;

class ShapeUtils {

    // calculate area of the contour polygon

    static function area(contour:Array<{x:Float, y:Float}>):Float {

        var n = contour.length;
        var a = 0.0;

        for (p in 0...n) {

            var q = (p + 1) % n;

            a += contour[p].x * contour[q].y - contour[q].x * contour[p].y;

        }

        return a * 0.5;

    }

    static function isClockWise(pts:Array<{x:Float, y:Float}>):Bool {

        return ShapeUtils.area(pts) < 0;

    }

    static function triangulateShape(contour:Array<{x:Float, y:Float}>, holes:Array<Array<{x:Float, y:Float}>>):Array<Array<Int>> {

        var vertices:Array<Float> = []; // flat array of vertices like [ x0,y0, x1,y1, x2,y2, ... ]
        var holeIndices:Array<Int> = []; // array of hole indices
        var faces:Array<Array<Int>> = []; // final array of vertex indices like [ [ a,b,d ], [ b,c,d ] ]

        removeDupEndPts(contour);
        addContour(vertices, contour);

        //

        var holeIndex = contour.length;

        for (hole in holes) {
            removeDupEndPts(hole);
            holeIndices.push(holeIndex);
            holeIndex += hole.length;
            addContour(vertices, hole);
        }

        //

        var triangles = Earcut.triangulate(vertices, holeIndices);

        //

        for (i in 0...triangles.length by 3) {

            faces.push(triangles.slice(i, i + 3));

        }

        return faces;

    }

}

function removeDupEndPts(points:Array<{x:Float, y:Float}>) {

    var l = points.length;

    if (l > 2 && points[l - 1].x == points[0].x && points[l - 1].y == points[0].y) {

        points.pop();

    }

}

function addContour(vertices:Array<Float>, contour:Array<{x:Float, y:Float}>) {

    for (i in 0...contour.length) {

        vertices.push(contour[i].x);
        vertices.push(contour[i].y);

    }

}