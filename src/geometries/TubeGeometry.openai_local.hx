import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.extras.curves.Curves;
import three.math.Vector2;
import three.math.Vector3;

class TubeGeometry extends BufferGeometry {
	public var tangents:Array<Vector3>;
	public var normals:Array<Vector3>;
	public var binormals:Array<Vector3>;
	public var parameters:{path:Dynamic, tubularSegments:Int, radius:Float, radialSegments:Int, closed:Bool};

	public function new(path:Dynamic = new Curves.QuadraticBezierCurve3(new Vector3(-1, -1, 0), new Vector3(-1, 1, 0), new Vector3(1, 1, 0)), tubularSegments:Int = 64, radius:Float = 1, radialSegments:Int = 8, closed:Bool = false) {
		super();

		this.type = 'TubeGeometry';

		this.parameters = {
			path: path,
			tubularSegments: tubularSegments,
			radius: radius,
			radialSegments: radialSegments,
			closed: closed
		};

		var frames = path.computeFrenetFrames(tubularSegments, closed);

		// expose internals

		this.tangents = frames.tangents;
		this.normals = frames.normals;
		this.binormals = frames.binormals;

		// helper variables

		var vertex = new Vector3();
		var normal = new Vector3();
		var uv = new Vector2();
		var P = new Vector3();

		// buffer

		var vertices = [];
		var normals = [];
		var uvs = [];
		var indices = [];

		// create buffer data

		generateBufferData();

		// build geometry

		this.setIndex(indices);
		this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
		this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
		this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));

		// functions

		function generateBufferData() {
			for (i in 0...tubularSegments) {
				generateSegment(i);
			}

			// if the geometry is not closed, generate the last row of vertices and normals
			// at the regular position on the given path
			//
			// if the geometry is closed, duplicate the first row of vertices and normals (uvs will differ)

			generateSegment(closed == false ? tubularSegments : 0);

			// uvs are generated in a separate function.
			// this makes it easy compute correct values for closed geometries

			generateUVs();

			// finally create faces

			generateIndices();
		}

		function generateSegment(i:Int) {
			// we use getPointAt to sample evenly distributed points from the given path
			P = path.getPointAt(i / tubularSegments, P);

			// retrieve corresponding normal and binormal
			var N = frames.normals[i];
			var B = frames.binormals[i];

			// generate normals and vertices for the current segment
			for (j in 0...radialSegments + 1) {
				var v = j / radialSegments * Math.PI * 2;
				var sin = Math.sin(v);
				var cos = -Math.cos(v);

				// normal
				normal.set(cos * N.x + sin * B.x, cos * N.y + sin * B.y, cos * N.z + sin * B.z);
				normal.normalize();

				normals.push(normal.x, normal.y, normal.z);

				// vertex
				vertex.set(P.x + radius * normal.x, P.y + radius * normal.y, P.z + radius * normal.z);
				vertices.push(vertex.x, vertex.y, vertex.z);
			}
		}

		function generateIndices() {
			for (j in 1...tubularSegments + 1) {
				for (i in 1...radialSegments + 1) {
					var a = (radialSegments + 1) * (j - 1) + (i - 1);
					var b = (radialSegments + 1) * j + (i - 1);
					var c = (radialSegments + 1) * j + i;
					var d = (radialSegments + 1) * (j - 1) + i;

					// faces
					indices.push(a, b, d);
					indices.push(b, c, d);
				}
			}
		}

		function generateUVs() {
			for (i in 0...tubularSegments + 1) {
				for (j in 0...radialSegments + 1) {
					uv.set(i / tubularSegments, j / radialSegments);
					uvs.push(uv.x, uv.y);
				}
			}
		}
	}

	public function copy(source:TubeGeometry):TubeGeometry {
		super.copy(source);
		this.parameters = {
			path: source.parameters.path,
			tubularSegments: source.parameters.tubularSegments,
			radius: source.parameters.radius,
			radialSegments: source.parameters.radialSegments,
			closed: source.parameters.closed
		};
		return this;
	}

	public function toJSON():Dynamic {
		var data = super.toJSON();
		data.path = this.parameters.path.toJSON();
		return data;
	}

	public static function fromJSON(data:Dynamic):TubeGeometry {
		// This only works for built-in curves (e.g. CatmullRomCurve3).
		// User defined curves or instances of CurvePath will not be deserialized.
		return new TubeGeometry(
			Type.createInstance(Type.resolveClass("three.extras.curves." + data.path.type), []).fromJSON(data.path),
			data.tubularSegments,
			data.radius,
			data.radialSegments,
			data.closed
		);
	}
}