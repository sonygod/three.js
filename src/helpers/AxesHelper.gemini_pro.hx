import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.materials.LineBasicMaterial;
import three.math.Color;
import three.objects.LineSegments;

class AxesHelper extends LineSegments {

	public function new(size:Float = 1) {
		var vertices = [
			0, 0, 0,	size, 0, 0,
			0, 0, 0,	0, size, 0,
			0, 0, 0,	0, 0, size
		];

		var colors = [
			1, 0, 0,	1, 0.6, 0,
			0, 1, 0,	0.6, 1, 0,
			0, 0, 1,	0, 0.6, 1
		];

		var geometry = new BufferGeometry();
		geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
		geometry.setAttribute('color', new Float32BufferAttribute(colors, 3));

		var material = new LineBasicMaterial({vertexColors: true, toneMapped: false});

		super(geometry, material);

		this.type = 'AxesHelper';
	}

	public function setColors(xAxisColor:Color, yAxisColor:Color, zAxisColor:Color):AxesHelper {
		var color = new Color();
		var array = this.geometry.attributes.color.array;

		color.set(xAxisColor);
		color.toArray(array, 0);
		color.toArray(array, 3);

		color.set(yAxisColor);
		color.toArray(array, 6);
		color.toArray(array, 9);

		color.set(zAxisColor);
		color.toArray(array, 12);
		color.toArray(array, 15);

		this.geometry.attributes.color.needsUpdate = true;

		return this;
	}

	public function dispose() {
		this.geometry.dispose();
		this.material.dispose();
	}
}

class AxesHelper {
	public static function new(size:Float = 1):AxesHelper {
		return new AxesHelper(size);
	}
}