import three.BufferGeometry;
import three.Float32BufferAttribute;
import math.ConvexHull;

class ConvexGeometry extends BufferGeometry {

	public function new(points:Array<Dynamic> = []) {

		super();

		// buffers

		var vertices:Array<Float> = [];
		var normals:Array<Float> = [];

		var convexHull:ConvexHull = new ConvexHull().setFromPoints(points);

		// generate vertices and normals

		var faces:Array<Dynamic> = convexHull.faces;

		for (i in 0...faces.length) {

			var face:Dynamic = faces[i];
			var edge:Dynamic = face.edge;

			// we move along a doubly-connected edge list to access all face points (see HalfEdge docs)

			while (edge != face.edge) {

				var point:Dynamic = edge.head().point;

				vertices.push(point.x, point.y, point.z);
				normals.push(face.normal.x, face.normal.y, face.normal.z);

				edge = edge.next;

			}

		}

		// build geometry

		this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
		this.setAttribute('normal', new Float32BufferAttribute(normals, 3));

	}

}

export.module(ConvexGeometry);