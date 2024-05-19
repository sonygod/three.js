import three.core.BufferGeometry;
import three.core.BufferAttribute;

class PlaneGeometry extends BufferGeometry {

	public function new(width:Float = 1, height:Float = 1, widthSegments:Int = 1, heightSegments:Int = 1) {
		super();

		this.type = 'PlaneGeometry';

		this.parameters = {
			width: width,
			height: height,
			widthSegments: widthSegments,
			heightSegments: heightSegments
		};

		var width_half = width / 2;
		var height_half = height / 2;

		var gridX = Std.int(widthSegments);
		var gridY = Std.int(heightSegments);

		var gridX1 = gridX + 1;
		var gridY1 = gridY + 1;

		var segment_width = width / gridX;
		var segment_height = height / gridY;

		var indices = [];
		var vertices = [];
		var normals = [];
		var uvs = [];

		for (iy in 0...gridY1) {

			var y = iy * segment_height - height_half;

			for (ix in 0...gridX1) {

				var x = ix * segment_width - width_half;

				vertices.push(x);
				vertices.push(-y);
				vertices.push(0);

				normals.push(0);
				normals.push(0);
				normals.push(1);

				uvs.push(ix / gridX);
				uvs.push(1 - (iy / gridY));

			}

		}

		for (iy in 0...gridY) {

			for (ix in 0...gridX) {

				var a = ix + gridX1 * iy;
				var b = ix + gridX1 * (iy + 1);
				var c = (ix + 1) + gridX1 * (iy + 1);
				var d = (ix + 1) + gridX1 * iy;

				indices.push(a);
				indices.push(b);
				indices.push(d);

				indices.push(b);
				indices.push(c);
				indices.push(d);

			}

		}

		this.setIndex(indices);
		this.setAttribute('position', new BufferAttribute(vertices, 3));
		this.setAttribute('normal', new BufferAttribute(normals, 3));
		this.setAttribute('uv', new BufferAttribute(uvs, 2));

	}

	public function copy(source:PlaneGeometry):PlaneGeometry {

		super.copy(source);

		this.parameters = Std.clone(source.parameters);

		return this;

	}

	public static function fromJSON(data:Dynamic):PlaneGeometry {

		return new PlaneGeometry(data.width, data.height, data.widthSegments, data.heightSegments);

	}

}