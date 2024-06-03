import Earcut;

class ShapeUtils {

	public static function area(contour:Array<Vector2>):Float {
		var n = contour.length;
		var a = 0.0;
		for (var p = n - 1, q = 0; q < n; p = q++) {
			a += contour[p].x * contour[q].y - contour[q].x * contour[p].y;
		}
		return a * 0.5;
	}

	public static function isClockWise(pts:Array<Vector2>):Bool {
		return ShapeUtils.area(pts) < 0;
	}

	public static function triangulateShape(contour:Array<Vector2>, holes:Array<Array<Vector2>>):Array<Array<Int>> {
		var vertices:Array<Float> = [];
		var holeIndices:Array<Int> = [];
		var faces:Array<Array<Int>> = [];

		removeDupEndPts(contour);
		addContour(vertices, contour);

		var holeIndex = contour.length;
		for (i in 0...holes.length) {
			removeDupEndPts(holes[i]);
			holeIndices.push(holeIndex);
			holeIndex += holes[i].length;
			addContour(vertices, holes[i]);
		}

		var triangles = Earcut.triangulate(vertices, holeIndices);

		for (i in 0...triangles.length) {
			faces.push(triangles.slice(i, i + 3));
			i += 2;
		}

		return faces;
	}
}

function removeDupEndPts(points:Array<Vector2>):Void {
	var l = points.length;
	if (l > 2 && points[l - 1].equals(points[0])) {
		points.pop();
	}
}

function addContour(vertices:Array<Float>, contour:Array<Vector2>):Void {
	for (i in 0...contour.length) {
		vertices.push(contour[i].x);
		vertices.push(contour[i].y);
	}
}

class Vector2 {
	public var x:Float;
	public var y:Float;

	public function new(x:Float, y:Float) {
		this.x = x;
		this.y = y;
	}

	public function equals(other:Vector2):Bool {
		return this.x == other.x && this.y == other.y;
	}
}