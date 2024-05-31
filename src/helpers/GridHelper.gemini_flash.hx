import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Color;

class GridHelper extends LineSegments {

	public function new(size:Float = 10, divisions:Int = 10, color1:Color = new Color(0x444444), color2:Color = new Color(0x888888)) {
		super(null, null);

		var center = divisions / 2;
		var step = size / divisions;
		var halfSize = size / 2;

		var vertices:Array<Float> = [];
		var colors:Array<Float> = [];

		for (i in 0...divisions + 1) {
			var k = -halfSize + i * step;
			vertices.push(-halfSize, 0, k);
			vertices.push(halfSize, 0, k);
			vertices.push(k, 0, -halfSize);
			vertices.push(k, 0, halfSize);

			var color = i == center ? color1 : color2;

			colors.push(color.r, color.g, color.b);
			colors.push(color.r, color.g, color.b);
			colors.push(color.r, color.g, color.b);
			colors.push(color.r, color.g, color.b);
		}

		var geometry = new BufferGeometry();
		geometry.setAttribute("position", new Float32BufferAttribute(vertices, 3));
		geometry.setAttribute("color", new Float32BufferAttribute(colors, 3));

		var material = new LineBasicMaterial({vertexColors: true, toneMapped: false});

		this.geometry = geometry;
		this.material = material;

		this.type = "GridHelper";
	}

	public function dispose() {
		geometry.dispose();
		material.dispose();
	}
}