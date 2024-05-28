import js.Browser.window;

class ShapeUtils {

	// calculate area of the contour polygon

	static public function area(contour:Array<Point>):Float {
		var n = contour.length;
		var a = 0.0;
		var p = n - 1;
		var q = 0;
		while (q < n) {
			a += contour[p].x * contour[q].y - contour[q].x * contour[p].y;
			p = q++;
		}
		return a * 0.5;
	}

	static public function isClockWise(pts:Array<Point>):Bool {
		return ShapeUtils.area(pts) < 0;
	}

	static public function triangulateShape(contour:Array<Point>, holes:Array<Array<Point>>):Array<Array<Int>> {
		var vertices = []; // flat array of vertices like [ x0,y0, x1,y1, x2,y2, ... ]
		var holeIndices = []; // array of hole indices
		var faces = []; // final array of vertex indices like [ [ a,b,d ], [ b,c,d ] ]

		removeDupEndPts(contour);
		addContour(vertices, contour);

		//

		var holeIndex = contour.length;

		for (hole in holes) {
			holeIndices.push(holeIndex);
			holeIndex += hole.length;
			removeDupEndPts(hole);
			addContour(vertices, hole);
		}

		//

		var triangles = Earcut.triangulate(vertices, holeIndices);

		//

		var i = 0;
		while (i < triangles.length) {
			faces.push(triangles.slice(i, i + 3));
			i += 3;
		}

		return faces;
	}

}

function removeDupEndPts(points:Array<Point>) {
	var l = points.length;
	if (l > 2 && points[l - 1].equals(points[0])) {
		points.pop();
	}
}

function addContour(vertices:Array<Float>, contour:Array<Point>) {
	for (i in 0...contour.length) {
		vertices.push(contour[i].x);
		vertices.push(contour[i].y);
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

@:jsRequire("earcut.js")
extern class Earcut {
	public static function triangulate(data:Array<Float>, holeIndices:Array<Int>, dimensions:Int=2):Array<Int>;
}