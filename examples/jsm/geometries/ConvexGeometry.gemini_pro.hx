import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.ConvexHull;

class ConvexGeometry extends BufferGeometry {

	public function new(points:Array<Vector3> = []) {
		super();

		// buffers
		var vertices:Array<Float> = [];
		var normals:Array<Float> = [];

		var convexHull = new ConvexHull().setFromPoints(points);

		// generate vertices and normals
		var faces = convexHull.faces;

		for (i in 0...faces.length) {
			var face = faces[i];
			var edge = face.edge;

			// we move along a doubly-connected edge list to access all face points (see HalfEdge docs)
			do {
				var point = edge.head().point;

				vertices.push(point.x, point.y, point.z);
				normals.push(face.normal.x, face.normal.y, face.normal.z);

				edge = edge.next;
			} while (edge != face.edge);
		}

		// build geometry
		this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
		this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
	}
}