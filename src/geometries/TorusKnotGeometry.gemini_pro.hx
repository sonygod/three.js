import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.Vector3;

class TorusKnotGeometry extends BufferGeometry {

	public var radius:Float;
	public var tube:Float;
	public var tubularSegments:Int;
	public var radialSegments:Int;
	public var p:Int;
	public var q:Int;

	public function new(radius = 1, tube = 0.4, tubularSegments = 64, radialSegments = 8, p = 2, q = 3) {
		super();
		this.type = "TorusKnotGeometry";
		this.radius = radius;
		this.tube = tube;
		this.tubularSegments = Math.floor(tubularSegments);
		this.radialSegments = Math.floor(radialSegments);
		this.p = p;
		this.q = q;

		// buffers
		var indices = new Array<Int>();
		var vertices = new Array<Float>();
		var normals = new Array<Float>();
		var uvs = new Array<Float>();

		// helper variables
		var vertex = new Vector3();
		var normal = new Vector3();

		var P1 = new Vector3();
		var P2 = new Vector3();

		var B = new Vector3();
		var T = new Vector3();
		var N = new Vector3();

		// generate vertices, normals and uvs
		for (i in 0...tubularSegments + 1) {
			// the radian "u" is used to calculate the position on the torus curve of the current tubular segment
			var u = i / tubularSegments * p * Math.PI * 2;

			// now we calculate two points. P1 is our current position on the curve, P2 is a little farther ahead.
			// these points are used to create a special "coordinate space", which is necessary to calculate the correct vertex positions
			calculatePositionOnCurve(u, p, q, radius, P1);
			calculatePositionOnCurve(u + 0.01, p, q, radius, P2);

			// calculate orthonormal basis
			T.subVectors(P2, P1);
			N.addVectors(P2, P1);
			B.crossVectors(T, N);
			N.crossVectors(B, T);

			// normalize B, N. T can be ignored, we don't use it
			B.normalize();
			N.normalize();

			for (j in 0...radialSegments + 1) {
				// now calculate the vertices. they are nothing more than an extrusion of the torus curve.
				// because we extrude a shape in the xy-plane, there is no need to calculate a z-value.
				var v = j / radialSegments * Math.PI * 2;
				var cx = -tube * Math.cos(v);
				var cy = tube * Math.sin(v);

				// now calculate the final vertex position.
				// first we orient the extrusion with our basis vectors, then we add it to the current position on the curve
				vertex.x = P1.x + (cx * N.x + cy * B.x);
				vertex.y = P1.y + (cx * N.y + cy * B.y);
				vertex.z = P1.z + (cx * N.z + cy * B.z);

				vertices.push(vertex.x, vertex.y, vertex.z);

				// normal (P1 is always the center/origin of the extrusion, thus we can use it to calculate the normal)
				normal.subVectors(vertex, P1).normalize();
				normals.push(normal.x, normal.y, normal.z);

				// uv
				uvs.push(i / tubularSegments);
				uvs.push(j / radialSegments);
			}
		}

		// generate indices
		for (j in 1...tubularSegments + 1) {
			for (i in 1...radialSegments + 1) {
				// indices
				var a = (radialSegments + 1) * (j - 1) + (i - 1);
				var b = (radialSegments + 1) * j + (i - 1);
				var c = (radialSegments + 1) * j + i;
				var d = (radialSegments + 1) * (j - 1) + i;

				// faces
				indices.push(a, b, d);
				indices.push(b, c, d);
			}
		}

		// build geometry
		this.setIndex(indices);
		this.setAttribute("position", new Float32BufferAttribute(vertices, 3));
		this.setAttribute("normal", new Float32BufferAttribute(normals, 3));
		this.setAttribute("uv", new Float32BufferAttribute(uvs, 2));
	}

	public function calculatePositionOnCurve(u:Float, p:Int, q:Int, radius:Float, position:Vector3) {
		var cu = Math.cos(u);
		var su = Math.sin(u);
		var quOverP = q / p * u;
		var cs = Math.cos(quOverP);

		position.x = radius * (2 + cs) * 0.5 * cu;
		position.y = radius * (2 + cs) * su * 0.5;
		position.z = radius * Math.sin(quOverP) * 0.5;
	}

	public function copy(source:TorusKnotGeometry):TorusKnotGeometry {
		super.copy(source);
		this.radius = source.radius;
		this.tube = source.tube;
		this.tubularSegments = source.tubularSegments;
		this.radialSegments = source.radialSegments;
		this.p = source.p;
		this.q = source.q;
		return this;
	}

	public static function fromJSON(data:Dynamic):TorusKnotGeometry {
		return new TorusKnotGeometry(data.radius, data.tube, data.tubularSegments, data.radialSegments, data.p, data.q);
	}
}