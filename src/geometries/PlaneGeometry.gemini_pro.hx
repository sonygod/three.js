import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;

class PlaneGeometry extends BufferGeometry {

	public var width:Float;
	public var height:Float;
	public var widthSegments:Int;
	public var heightSegments:Int;

	public function new(width:Float = 1, height:Float = 1, widthSegments:Int = 1, heightSegments:Int = 1) {
		super();

		this.type = "PlaneGeometry";

		this.width = width;
		this.height = height;
		this.widthSegments = widthSegments;
		this.heightSegments = heightSegments;

		var width_half = width / 2;
		var height_half = height / 2;

		var gridX = Math.floor(widthSegments);
		var gridY = Math.floor(heightSegments);

		var gridX1 = gridX + 1;
		var gridY1 = gridY + 1;

		var segment_width = width / gridX;
		var segment_height = height / gridY;

		//

		var indices:Array<Int> = [];
		var vertices:Array<Float> = [];
		var normals:Array<Float> = [];
		var uvs:Array<Float> = [];

		for (iy in 0...gridY1) {
			var y = iy * segment_height - height_half;

			for (ix in 0...gridX1) {
				var x = ix * segment_width - width_half;

				vertices.push(x, -y, 0);

				normals.push(0, 0, 1);

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

				indices.push(a, b, d);
				indices.push(b, c, d);
			}
		}

		this.setIndex(new IntBufferAttribute(indices, 1));
		this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
		this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
		this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
	}

	public function copy(source:PlaneGeometry):PlaneGeometry {
		super.copy(source);

		this.width = source.width;
		this.height = source.height;
		this.widthSegments = source.widthSegments;
		this.heightSegments = source.heightSegments;

		return this;
	}

	public static function fromJSON(data:Dynamic):PlaneGeometry {
		return new PlaneGeometry(data.width, data.height, data.widthSegments, data.heightSegments);
	}
}