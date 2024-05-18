package three.extras;

import Earcut;

class ShapeUtils {
  // calculate area of the contour polygon
  public static function area(contour:Array<{x:Float, y:Float}>):Float {
    var n = contour.length;
    var a:Float = 0.0;

    for (p in n - 1...0, q in 0...n) {
      a += contour[p].x * contour[q].y - contour[q].x * contour[p].y;
    }

    return a * 0.5;
  }

  public static function isClockWise(pts:Array<{x:Float, y:Float}>):Bool {
    return area(pts) < 0;
  }

  public static function triangulateShape(contour:Array<{x:Float, y:Float}>, holes:Array<Array<{x:Float, y:Float}>>):Array<Array<Int>> {
    var vertices:Array<Float> = []; // flat array of vertices like [ x0,y0, x1,y1, x2,y2, ... ]
    var holeIndices:Array<Int> = []; // array of hole indices
    var faces:Array<Array<Int>> = []; // final array of vertex indices like [ [ a,b,d ], [ b,c,d ] ]

    removeDupEndPts(contour);
    addContour(vertices, contour);

    var holeIndex:Int = contour.length;

    for (hole in holes) {
      removeDupEndPts(hole);
      holeIndices.push(holeIndex);
      holeIndex += hole.length;
      addContour(vertices, hole);
    }

    var triangles:Array<Int> = Earcut.triangulate(vertices, holeIndices);

    for (i in 0...triangles.length) {
      faces.push(triangles.slice(i, i + 3));
      i += 2;
    }

    return faces;
  }
}

function removeDupEndPts(points:Array<{x:Float, y:Float}>) {
  var l:Int = points.length;

  if (l > 2 && points[l - 1].equals(points[0])) {
    points.pop();
  }
}

function addContour(vertices:Array<Float>, contour:Array<{x:Float, y:Float}>) {
  for (point in contour) {
    vertices.push(point.x);
    vertices.push(point.y);
  }
}