import js.three.BufferGeometry;
import js.three.BufferAttribute;
import js.three.BufferAttributeType.Float32;

class BoxLineGeometry extends BufferGeometry {
	public function new(width:Float = 1., height:Float = 1., depth:Float = 1., widthSegments:Int = 1, heightSegments:Int = 1, depthSegments:Int = 1) {
		super();

		widthSegments = min(widthSegments, Std.int(width));
		heightSegments = min(heightSegments, Std.int(height));
		depthSegments = min(depthSegments, Std.int(depth));

		var width_half:Float = width / 2;
		var height_half:Float = height / 2;
		var depth_half:Float = depth / 2;

		var segment_width:Float = width / widthSegments;
		var segment_height:Float = height / heightSegments;
		var segment_depth:Float = depth / depthSegments;

		var vertices:Array<Float> = [];

		var x:Float, y:Float, z:Float;
		var i:Int, j:Int, k:Int;

		for (i = 0; i <= widthSegments; i++) {
			x = i * segment_width - width_half;

			vertices.push(x, -height_half, -depth_half);
			vertices.push(x, height_half, -depth_half);

			vertices.push(x, height_half, depth_half);
			vertices.push(x, -height_half, depth_half);
		}

		for (j = 0; j <= heightSegments; j++) {
			y = j * segment_height - height_half;

			vertices.push(-width_half, y, -depth_half);
			vertices.push(width_half, y, -depth_half);

			vertices.push(width_half, y, depth_half);
			vertices.push(-width_half, y, depth_half);
		}

		for (k = 0; k <= depthSegments; k++) {
			z = k * segment_depth - depth_half;

			vertices.push(-width_half, -height_half, z);
			vertices.push(width_half, -height_half, z);

			vertices.push(width_half, height_half, z);
			vertices.push(-width_half, height_half, z);
		}

		setAttribute('position', BufferAttribute.ofFloat32(vertices, 3));
	}
}

class BoxLineGeometryTest {
	static public function main() {
		var geometry = new BoxLineGeometry(2, 3, 4, 2, 3, 4);
		trace(geometry);
	}
}