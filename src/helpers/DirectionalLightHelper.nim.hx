import Vector3.{v1, v2, v3};
import Object3D.{Object3D};
import Line.{Line};
import Float32BufferAttribute.{Float32BufferAttribute};
import BufferGeometry.{BufferGeometry};
import LineBasicMaterial.{LineBasicMaterial};

class DirectionalLightHelper extends Object3D {

	public var light:Dynamic;
	public var matrix:Dynamic;
	public var matrixAutoUpdate:Bool;
	public var color:Dynamic;
	public var type:String;
	public var lightPlane:Line;
	public var targetLine:Line;

	public function new(light:Dynamic, size:Float, color:Dynamic) {

		super();

		this.light = light;

		this.matrix = light.matrixWorld;
		this.matrixAutoUpdate = false;

		this.color = color;

		this.type = 'DirectionalLightHelper';

		if (size == null) size = 1;

		var geometry = new BufferGeometry();
		geometry.setAttribute('position', new Float32BufferAttribute([
			- size, size, 0,
			size, size, 0,
			size, - size, 0,
			- size, - size, 0,
			- size, size, 0
		], 3));

		var material = new LineBasicMaterial({ fog: false, toneMapped: false });

		this.lightPlane = new Line(geometry, material);
		this.add(this.lightPlane);

		geometry = new BufferGeometry();
		geometry.setAttribute('position', new Float32BufferAttribute([0, 0, 0, 0, 0, 1], 3));

		this.targetLine = new Line(geometry, material);
		this.add(this.targetLine);

		this.update();

	}

	public function dispose() {

		this.lightPlane.geometry.dispose();
		this.lightPlane.material.dispose();
		this.targetLine.geometry.dispose();
		this.targetLine.material.dispose();

	}

	public function update() {

		this.light.updateWorldMatrix(true, false);
		this.light.target.updateWorldMatrix(true, false);

		v1.setFromMatrixPosition(this.light.matrixWorld);
		v2.setFromMatrixPosition(this.light.target.matrixWorld);
		v3.subVectors(v2, v1);

		this.lightPlane.lookAt(v2);

		if (this.color != null) {

			this.lightPlane.material.color.set(this.color);
			this.targetLine.material.color.set(this.color);

		} else {

			this.lightPlane.material.color.copy(this.light.color);
			this.targetLine.material.color.copy(this.light.color);

		}

		this.targetLine.lookAt(v2);
		this.targetLine.scale.z = v3.length();

	}

}