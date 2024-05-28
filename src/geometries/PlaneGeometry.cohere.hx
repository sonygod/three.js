package openfl.geom;

import openfl.geom.PlaneGeometry;
import openfl.geom.BufferGeometry;
import openfl.geom.Float32BufferAttribute;

class PlaneGeometry extends BufferGeometry {

	public function new ( width:Float = 1, height:Float = 1, widthSegments:Int = 1, heightSegments:Int = 1 ) {

		super ();

		this.type = 'PlaneGeometry';

		this.parameters = {
			'width' => width,
			'height' => height,
			'widthSegments' => widthSegments,
			'heightSegments' => heightSegments
		};

		var width_half = width / 2;
		var height_half = height / 2;

		var gridX = Std.int ( widthSegments );
		var gridY = Std.int ( heightSegments );

		var gridX1 = gridX + 1;
		var gridY1 = gridY + 1;

		var segment_width = width / gridX;
		var segment_height = height / gridY;

		//

		var indices = [];
		var vertices = [];
		var normals = [];
		var uvs = [];

		var iy:Int;
		var y:Float;

		for (iy = 0, y = 0; iy < gridY1; iy++, y += segment_height) {

			var ix:Int;
			var x:Float;

			for (ix = 0, x = 0; ix < gridX1; ix++, x += segment_width) {

				vertices.push (x - width_half);
				vertices.push (-y + height_half);
				vertices.push (0);

				normals.push (0);
				normals.push (0);
				normals.push (1);

				uvs.push (ix / gridX);
				uvs.push (1 - (iy / gridY));

			}

		}

		var a:Int, b:Int, c:Int, d:Int;

		for (iy = 0; iy < gridY; iy++) {

			for (ix = 0; ix < gridX; ix++) {

				a = ix + gridX1 * iy;
				b = ix + gridX1 * (iy + 1);
				c = (ix + 1) + gridX1 * (iy + 1);
				d = (ix + 1) + gridX1 * iy;

				indices.push (a);
				indices.push (b);
				indices.push (d);

				indices.push (b);
				indices.push (c);
				indices.push (d);

			}

		}

		this.setIndex (indices);
		this.setAttribute ('position', new Float32BufferAttribute (vertices, 3));
		this.setAttribute ('normal', new Float32BufferAttribute (normals, 3));
		this.setAttribute ('uv', new Float32BufferAttribute (uvs, 2));

	}

	public function copy (source:PlaneGeometry):PlaneGeometry {

		super.copy (source);

		this.parameters = source.parameters;

		return this;

	}

	public static function fromJSON (data:Dynamic):PlaneGeometry {

		return new PlaneGeometry (data.width, data.height, data.widthSegments, data.heightSegments);

	}

}