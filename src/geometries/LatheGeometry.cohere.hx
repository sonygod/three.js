package openfl.geom;

import openfl.utils.Float32BufferAttribute;
import openfl.utils.BufferGeometry;
import openfl.utils.Vector3;
import openfl.utils.Vector2;
import openfl.utils.MathUtils;

class LatheGeometry extends BufferGeometry {

	public function new (points:Array<Vector2> = [Vector2.create(-0.5, 0), Vector2.create(0.5, 0), Vector2.create(0, 0.5)], segments:Int = 12, phiStart:Float = 0, phiLength:Float = Math.PI * 2) {

		super();

		this.type = 'LatheGeometry';

		this.parameters = {
			points: points,
			segments: segments,
			phiStart: phiStart,
			phiLength: phiLength
		};

		segments = Math.floor( segments );

		// clamp phiLength so it's in range of [ 0, 2PI ]

		phiLength = MathUtils.clamp( phiLength, 0, Math.PI * 2 );

		// buffers

		var indices = [];
		var vertices = [];
		var uvs = [];
		var initNormals = [];
		var normals = [];

		// helper variables

		var inverseSegments = 1.0 / segments;
		var vertex = Vector3.create();
		var uv = Vector2.create();
		var normal = Vector3.create();
		var curNormal = Vector3.create();
		var prevNormal = Vector3.create();
		var dx = 0;
		var dy = 0;

		// pre-compute normals for initial "meridian"

		for (i in 0...points.length) {

			switch (i) {

				case 0:				// special handling for 1st vertex on path

					dx = points[i + 1].x - points[i].x;
					dy = points[i + 1].y - points[i].y;

					normal.x = dy * 1.0;
					normal.y = - dx;
					normal.z = dy * 0.0;

					prevNormal = normal.clone();

					normal.normalize();

					initNormals.push(normal.x, normal.y, normal.z);

					break;

				case (points.length - 1):	// special handling for last Vertex on path

					initNormals.push(prevNormal.x, prevNormal.y, prevNormal.z);

					break;

				default:			// default handling for all vertices in between

					dx = points[i + 1].x - points[i].x;
					dy = points[i + 1].y - points[i].y;

					normal.x = dy * 1.0;
					normal.y = - dx;
					normal.z = dy * 0.0;

					curNormal = normal.clone();

					normal.x += prevNormal.x;
					normal.y += prevNormal.y;
					normal.z += prevNormal.z;

					normal.normalize();

					initNormals.push(normal.x, normal.y, normal.z);

					prevNormal = curNormal;

			}

		}

		// generate vertices, uvs and normals

		for (i in 0...(segments + 1)) {

			var phi = phiStart + i * inverseSegments * phiLength;

			var sin = Math.sin( phi );
			var cos = Math.cos( phi );

			for (j in 0...points.length) {

				// vertex

				vertex.x = points[j].x * sin;
				vertex.y = points[j].y;
				vertex.z = points[j].x * cos;

				vertices.push( vertex.x, vertex.y, vertex.z );

				// uv

				uv.x = i / segments;
				uv.y = j / ( points.length - 1 );

				uvs.push( uv.x, uv.y );

				// normal

				var x = initNormals[ 3 * j + 0 ] * sin;
				var y = initNormals[ 3 * j + 1 ];
				var z = initNormals[ 3 * j + 0 ] * cos;

				normals.push( x, y, z );

			}

		}

		// indices

		for (i in 0...segments) {

			for (j in 0...(points.length - 1)) {

				var base = j + i * points.length;

				var a = base;
				var b = base + points.length;
				var c = base + points.length + 1;
				var d = base + 1;

				// faces

				indices.push( a, b, d );
				indices.push( c, d, b );

			}

		}

		// build geometry

		this.setIndex( indices );
		this.setAttribute( 'position', Float32BufferAttribute.fromArray( vertices, 3 ) );
		this.setAttribute( 'uv', Float32BufferAttribute.fromArray( uvs, 2 ) );
		this.setAttribute( 'normal', Float32BufferAttribute.fromArray( normals, 3 ) );

	}

	public function copy (source:LatheGeometry):LatheGeometry {

		super.copy( source );

		this.parameters = source.parameters;

		return this;

	}

	public static function fromJSON (data:Dynamic):LatheGeometry {

		return LatheGeometry.create(data.points, data.segments, data.phiStart, data.phiLength);

	}

}