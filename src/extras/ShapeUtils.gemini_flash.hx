import Earcut from "./Earcut";

class ShapeUtils {

	static function area(contour:Array<Dynamic>):Float {
		var n = contour.length;
		var a = 0.0;
		for (var p = n - 1, q = 0; q < n; p = q++) {
			a += contour[p].x * contour[q].y - contour[q].x * contour[p].y;
		}
		return a * 0.5;
	}

	static function isClockWise(pts:Array<Dynamic>):Bool {
		return ShapeUtils.area(pts) < 0;
	}

	static function triangulateShape(contour:Array<Dynamic>, holes:Array<Array<Dynamic>>):Array<Array<Int>> {
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
			if (i % 3 == 0) {
				faces.push([triangles[i], triangles[i + 1], triangles[i + 2]]);
			}
		}
		return faces;
	}
}

function removeDupEndPts(points:Array<Dynamic>) {
	var l = points.length;
	if (l > 2 && points[l - 1].equals(points[0])) {
		points.pop();
	}
}

function addContour(vertices:Array<Float>, contour:Array<Dynamic>) {
	for (i in 0...contour.length) {
		vertices.push(contour[i].x);
		vertices.push(contour[i].y);
	}
}

class Dynamic {
	public var x:Float;
	public var y:Float;

	public function new(x:Float, y:Float) {
		this.x = x;
		this.y = y;
	}

	public function equals(other:Dynamic):Bool {
		return this.x == other.x && this.y == other.y;
	}
}