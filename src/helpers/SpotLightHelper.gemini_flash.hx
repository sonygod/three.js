import three.math.Vector3;
import three.core.Object3D;
import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.core.BufferAttribute;
import three.core.BufferGeometry;

class SpotLightHelper extends Object3D {
	public var light:Dynamic;
	public var color:Dynamic;

	public function new(light:Dynamic, color:Dynamic) {
		super();
		this.light = light;
		this.matrixAutoUpdate = false;
		this.color = color;
		this.type = "SpotLightHelper";

		var geometry = new BufferGeometry();

		var positions = [
			0, 0, 0, 	0, 0, 1,
			0, 0, 0, 	1, 0, 1,
			0, 0, 0,	- 1, 0, 1,
			0, 0, 0, 	0, 1, 1,
			0, 0, 0, 	0, - 1, 1
		];

		for (var i = 0; i < 32; i++) {
			var p1 = (i / 32) * Math.PI * 2;
			var p2 = ((i + 1) / 32) * Math.PI * 2;

			positions.push(
				Math.cos(p1), Math.sin(p1), 1,
				Math.cos(p2), Math.sin(p2), 1
			);
		}

		geometry.setAttribute("position", new Float32BufferAttribute(positions, 3));

		var material = new LineBasicMaterial({fog: false, toneMapped: false});
		this.cone = new LineSegments(geometry, material);
		this.add(this.cone);

		this.update();
	}

	public function dispose() {
		this.cone.geometry.dispose();
		this.cone.material.dispose();
	}

	public function update() {
		this.light.updateWorldMatrix(true, false);
		this.light.target.updateWorldMatrix(true, false);

		if (this.parent != null) {
			this.parent.updateWorldMatrix(true);

			this.matrix
				.copy(this.parent.matrixWorld)
				.invert()
				.multiply(this.light.matrixWorld);
		}
		else {
			this.matrix.copy(this.light.matrixWorld);
		}

		this.matrixWorld.copy(this.light.matrixWorld);

		var coneLength = this.light.distance != null ? this.light.distance : 1000;
		var coneWidth = coneLength * Math.tan(this.light.angle);

		this.cone.scale.set(coneWidth, coneWidth, coneLength);

		var _vector = new Vector3();
		_vector.setFromMatrixPosition(this.light.target.matrixWorld);

		this.cone.lookAt(_vector);

		if (this.color != null) {
			this.cone.material.color.set(this.color);
		}
		else {
			this.cone.material.color.copy(this.light.color);
		}
	}
}