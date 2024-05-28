import js.Browser.Window;
import js.Node.Js;
import js.html.ArrayBuffer;
import js.html.Float32Array;
import js.html.DataView;

import openfl.geom.Vector3_Impl_;
import openfl.geom.Vector2_Impl_;

class CircleGeometry extends openfl.geom.BufferGeometry {

	public var radius:Float = 1.0;
	public var segments:Int = 32;
	public var thetaStart:Float = 0.0;
	public var thetaLength:Float = Std.int(Math.PI) * 2;

	public function new () {
		super();

		this.type = 'CircleGeometry';

		segments = Math.max(3, segments);

		var indices:Array<Int> = [];
		var vertices:Array<Float> = [];
		var normals:Array<Float> = [];
		var uvs:Array<Float> = [];

		var vertex:openfl.geom.Vector3 = new openfl.geom.Vector3();
		var uv:openfl.geom.Vector2 = new openfl.geom.Vector2();

		// center point

		vertices.push(0, 0, 0);
		normals.push(0, 0, 1);
		uvs.push(0.5, 0.5);

		var i:Int = 3;
		for (var s:Int = 0; s <= segments; s++) {

			var segment:Float = thetaStart + (s / segments) * thetaLength;

			// vertex

			vertex.x = radius * Math.cos(segment);
			vertex.y = radius * Math.sin(segment);

			vertices.push(vertex.x, vertex.y, vertex.z);

			// normal

			normals.push(0, 0, 1);

			// uvs

			uv.x = (vertices[i] / radius + 1) / 2;
			uv.y = (vertices[i + 1] / radius + 1) / 2;

			uvs.push(uv.x, uv.y);

			i += 3;

		}

		// indices

		var index:Int = 1;
		while (index <= segments) {

			indices.push(index, index + 1, 0);

			index++;

		}

		// build geometry

		this.setIndex(indices);
		this.setAttribute('position', new openfl.geom.Float32BufferAttribute(vertices, 3));
		this.setAttribute('normal', new openfl.geom.Float32BufferAttribute(normals, 3));
		this.setAttribute('uv', new openfl.geom.Float32BufferAttribute(uvs, 2));

	}

	public function copy(source:CircleGeometry):Void {

		super.copy(source);

		this.radius = source.radius;
		this.segments = source.segments;
		this.thetaStart = source.thetaStart;
		this.thetaLength = source.thetaLength;

		return;

	}

	public static function fromJSON(data:Dynamic):CircleGeometry {

		return new CircleGeometry(data.radius, data.segments, data.thetaStart, data.thetaLength);

	}

}

class Export {

	public static inline function get_CircleGeometry():Class<openfl.geom.CircleGeometry> {

		return openfl.geom.CircleGeometry;

	}

}