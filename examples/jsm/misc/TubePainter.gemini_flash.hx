import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.math.Color;
import three.math.Matrix4;
import three.math.Vector3;
import three.objects.Mesh;
import three.materials.MeshStandardMaterial;
import three.constants.DrawUsage;

class TubePainter {

	public static final BUFFER_SIZE:Int = 1000000 * 3;

	public var mesh:Mesh;
	private var positions:BufferAttribute;
	private var normals:BufferAttribute;
	private var colors:BufferAttribute;
	private var geometry:BufferGeometry;
	private var matrix1:Matrix4;
	private var matrix2:Matrix4;
	private var point1:Vector3;
	private var point2:Vector3;
	private var color:Color;
	private var size:Float;
	private var count:Int = 0;

	public function new() {

		positions = new BufferAttribute(new Float32Array(BUFFER_SIZE), 3);
		positions.usage = DrawUsage.DynamicDraw;

		normals = new BufferAttribute(new Float32Array(BUFFER_SIZE), 3);
		normals.usage = DrawUsage.DynamicDraw;

		colors = new BufferAttribute(new Float32Array(BUFFER_SIZE), 3);
		colors.usage = DrawUsage.DynamicDraw;

		geometry = new BufferGeometry();
		geometry.setAttribute('position', positions);
		geometry.setAttribute('normal', normals);
		geometry.setAttribute('color', colors);
		geometry.drawRange.count = 0;

		var material = new MeshStandardMaterial({
			vertexColors: true
		});

		mesh = new Mesh(geometry, material);
		mesh.frustumCulled = false;

		matrix1 = new Matrix4();
		matrix2 = new Matrix4();
		point1 = new Vector3();
		point2 = new Vector3();
		color = new Color(0xffffff);
		size = 1;

	}

	private function getPoints(size:Float):Array<Vector3> {

		var PI2 = Math.PI * 2;
		var sides = 10;
		var array:Array<Vector3> = [];
		var radius = 0.01 * size;

		for (i in 0...sides) {

			var angle = (i / sides) * PI2;
			array.push(new Vector3(Math.sin(angle) * radius, Math.cos(angle) * radius, 0));

		}

		return array;

	}

	public function stroke(position1:Vector3, position2:Vector3, matrix1:Matrix4, matrix2:Matrix4) {

		if (position1.distanceToSquared(position2) == 0) return;

		var count = geometry.drawRange.count;

		var points = getPoints(size);

		for (i in 0...points.length) {

			var vertex1 = points[i];
			var vertex2 = points[(i + 1) % points.length];

			// positions

			var vector1 = vertex1.clone().applyMatrix4(matrix2).add(position2);
			var vector2 = vertex2.clone().applyMatrix4(matrix2).add(position2);
			var vector3 = vertex2.clone().applyMatrix4(matrix1).add(position1);
			var vector4 = vertex1.clone().applyMatrix4(matrix1).add(position1);

			vector1.toArray(positions.array, (count + 0) * 3);
			vector2.toArray(positions.array, (count + 1) * 3);
			vector4.toArray(positions.array, (count + 2) * 3);

			vector2.toArray(positions.array, (count + 3) * 3);
			vector3.toArray(positions.array, (count + 4) * 3);
			vector4.toArray(positions.array, (count + 5) * 3);

			// normals

			vector1.copy(vertex1).applyMatrix4(matrix2).normalize();
			vector2.copy(vertex2).applyMatrix4(matrix2).normalize();
			vector3.copy(vertex2).applyMatrix4(matrix1).normalize();
			vector4.copy(vertex1).applyMatrix4(matrix1).normalize();

			vector1.toArray(normals.array, (count + 0) * 3);
			vector2.toArray(normals.array, (count + 1) * 3);
			vector4.toArray(normals.array, (count + 2) * 3);

			vector2.toArray(normals.array, (count + 3) * 3);
			vector3.toArray(normals.array, (count + 4) * 3);
			vector4.toArray(normals.array, (count + 5) * 3);

			// colors

			color.toArray(colors.array, (count + 0) * 3);
			color.toArray(colors.array, (count + 1) * 3);
			color.toArray(colors.array, (count + 2) * 3);

			color.toArray(colors.array, (count + 3) * 3);
			color.toArray(colors.array, (count + 4) * 3);
			color.toArray(colors.array, (count + 5) * 3);

			count += 6;

		}

		geometry.drawRange.count = count;

	}

	public function moveTo(position:Vector3) {

		point1.copy(position);
		matrix1.lookAt(point2, point1, new Vector3(0, 1, 0));

		point2.copy(position);
		matrix2.copy(matrix1);

	}

	public function lineTo(position:Vector3) {

		point1.copy(position);
		matrix1.lookAt(point2, point1, new Vector3(0, 1, 0));

		stroke(point1, point2, matrix1, matrix2);

		point2.copy(point1);
		matrix2.copy(matrix1);

	}

	public function setSize(value:Float) {

		size = value;

	}

	public function update() {

		var start = count;
		var end = geometry.drawRange.count;

		if (start == end) return;

		positions.addUpdateRange(start * 3, (end - start) * 3);
		positions.needsUpdate = true;

		normals.addUpdateRange(start * 3, (end - start) * 3);
		normals.needsUpdate = true;

		colors.addUpdateRange(start * 3, (end - start) * 3);
		colors.needsUpdate = true;

		count = geometry.drawRange.count;

	}

}