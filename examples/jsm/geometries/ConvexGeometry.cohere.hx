import js.three.BufferGeometry;
import js.three.BufferAttribute;

class ConvexGeometry extends BufferGeometry {
	public function new(points:Array<Float>) {
		super();
		var vertices = [];
		var normals = [];
		var convexHull = new ConvexHull().setFromPoints(points);
		var faces = convexHull.faces;
		for (face in faces) {
			var edge = face.edge;
			while (true) {
				var point = edge.head().point;
				vertices.push(point.x, point.y, point.z);
				normals.push(face.normal.x, face.normal.y, face.normal.z);
				if (edge == face.edge) {
					break;
				}
				edge = edge.next;
			}
		}
		setAttribute('position', new Float32BufferAttribute(vertices, 3));
		setAttribute('normal', new Float32BufferAttribute(normals, 3));
	}
}

class ConvexHull {
	public var faces:Array<Dynamic>;
	public function setFromPoints(points:Array<Float>) {
		// ...
	}
}

class HalfEdge {
	public var head:Dynamic;
	public var next:Dynamic;
}

class Face {
	public var edge:Dynamic;
	public var normal:Dynamic;
}

class Point {
	public var x:Float;
	public var y:Float;
	public var z:Float;
}