import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;

class TorusKnotGeometry extends BufferGeometry {

	public var type:String = "TorusKnotGeometry";
	public var parameters:Dynamic;

	public function new(radius:Float = 1, tube:Float = 0.4, tubularSegments:Int = 64, radialSegments:Int = 8, p:Int = 2, q:Int = 3) {

		super();

		this.parameters = {
			radius: radius,
			tube: tube,
			tubularSegments: tubularSegments,
			radialSegments: radialSegments,
			p: p,
			q: q
		};

		tubularSegments = Std.int(tubularSegments);
		radialSegments = Std.int(radialSegments);

		// buffers

		var indices:Array<Int> = [];
		var vertices:Array<Float> = [];
		var normals:Array<Float> = [];
		var uvs:Array<Float> = [];

		// helper variables

		var vertex:Vector3 = new Vector3();
		var normal:Vector3 = new Vector3();

		var P1:Vector3 = new Vector3();
		var P2:Vector3 = new Vector3();

		var B:Vector3 = new Vector3();
		var T:Vector3 = new Vector3();
		var N:Vector3 = new Vector3();

		// generate vertices, normals and uvs

		for (i in 0...tubularSegments + 1) {

			// the radian "u" is used to calculate the position on the torus curve of the current tubular segment

			var u:Float = i / tubularSegments * p * Math.PI * 2;

			// now we calculate two points. P1 is our current position on the curve, P2 is a little farther ahead.
			// these points are used to create a special "coordinate space", which is necessary to calculate the correct vertex positions

			calculatePositionOnCurve(u, p, q, radius, P1);
			calculatePositionOnCurve(u + 0.01, p, q, radius, P2);

			// calculate orthonormal basis

			T.sub(P2, P1);
			N.add(P2, P1);
			B.cross(T, N);
			N.cross(B, T);

			// normalize B, N. T can be ignored, we don't use it

			B.normalize();
			N.normalize();

			for (j in 0...radialSegments + 1) {

				// now calculate the vertices. they are nothing more than an extrusion of the torus curve.
				// because we extrude a shape in the xy-plane, there is no need to calculate a z-value.

				var v:Float = j / radialSegments * Math.PI * 2;
				var cx:Float = -tube * Math.cos(v);
				var cy:Float = tube * Math.sin(v);

				// now calculate the final vertex position.
				// first we orient the extrusion with our basis vectors, then we add it to the current position on the curve

				vertex.x = P1.x + (cx * N.x + cy * B.x);
				vertex.y = P1.y + (cx * N.y + cy * B.y);
				vertex.z = P1.z + (cx * N.z + cy * B.z);

				vertices.push(vertex.x, vertex.y, vertex.z);

				// normal (P1 is always the center/origin of the extrusion, thus we can use it to calculate the normal)

				normal.sub(vertex, P1).normalize();

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

				var a:Int = (radialSegments + 1) * (j - 1) + (i - 1);
				var b:Int = (radialSegments + 1) * j + (i - 1);
				var c:Int = (radialSegments + 1) * j + i;
				var d:Int = (radialSegments + 1) * (j - 1) + i;

				// faces

				indices.push(a, b, d);
				indices.push(b, c, d);

			}

		}

		// build geometry

		this.setIndex(indices);
		this.setAttribute("position", new BufferAttribute(vertices, 3));
		this.setAttribute("normal", new BufferAttribute(normals, 3));
		this.setAttribute("uv", new BufferAttribute(uvs, 2));

		// this function calculates the current position on the torus curve

		function calculatePositionOnCurve(u:Float, p:Int, q:Int, radius:Float, position:Vector3) {

			var cu:Float = Math.cos(u);
			var su:Float = Math.sin(u);
			var quOverP:Float = q / p * u;
			var cs:Float = Math.cos(quOverP);

			position.x = radius * (2 + cs) * 0.5 * cu;
			position.y = radius * (2 + cs) * su * 0.5;
			position.z = radius * Math.sin(quOverP) * 0.5;

		}

	}

	public function copy(source:TorusKnotGeometry):TorusKnotGeometry {

		super.copy(source);

		this.parameters = Type.clone(source.parameters);

		return this;

	}

	public static function fromJSON(data:Dynamic):TorusKnotGeometry {

		return new TorusKnotGeometry(data.radius, data.tube, data.tubularSegments, data.radialSegments, data.p, data.q);

	}

}