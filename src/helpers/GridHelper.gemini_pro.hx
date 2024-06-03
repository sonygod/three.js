import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.materials.LineBasicMaterial;
import three.math.Color;
import three.objects.LineSegments;

class GridHelper extends LineSegments {

	public var size:Float;
	public var divisions:Int;
	public var color1:Color;
	public var color2:Color;

	public function new(size:Float = 10, divisions:Int = 10, color1:Int = 0x444444, color2:Int = 0x888888) {
		this.size = size;
		this.divisions = divisions;
		this.color1 = new Color(color1);
		this.color2 = new Color(color2);

		var center = divisions / 2;
		var step = size / divisions;
		var halfSize = size / 2;

		var vertices = new Array<Float>();
		var colors = new Array<Float>();

		for (i in 0...divisions + 1) {
			var k = -halfSize + i * step;
			vertices.push(-halfSize, 0, k);
			vertices.push(halfSize, 0, k);
			vertices.push(k, 0, -halfSize);
			vertices.push(k, 0, halfSize);

			var color = (i == center) ? color1 : color2;
			color.toArray(colors);
			color.toArray(colors);
			color.toArray(colors);
			color.toArray(colors);
		}

		var geometry = new BufferGeometry();
		geometry.setAttribute("position", new Float32BufferAttribute(vertices, 3));
		geometry.setAttribute("color", new Float32BufferAttribute(colors, 3));

		var material = new LineBasicMaterial({vertexColors: true, toneMapped: false});

		super(geometry, material);

		this.type = "GridHelper";
	}

	public function dispose() {
		this.geometry.dispose();
		this.material.dispose();
	}
}