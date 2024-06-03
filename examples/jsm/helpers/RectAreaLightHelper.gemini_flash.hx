import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.objects.Line;
import three.materials.LineBasicMaterial;
import three.objects.Mesh;
import three.materials.MeshBasicMaterial;
import three.math.Color;
import three.core.Object3D;
import three.scenes.Fog;
import three.core.Raycaster;
import three.objects.LineSegments;

class RectAreaLightHelper extends Line {

	public var light:Dynamic;
	public var color:Color;

	public function new(light:Dynamic, color:Color) {
		super(new BufferGeometry(), new LineBasicMaterial({fog: false}));

		this.light = light;
		this.color = color;

		var positions = [1, 1, 0, -1, 1, 0, -1, -1, 0, 1, -1, 0, 1, 1, 0];
		this.geometry.setAttribute("position", new Float32BufferAttribute(positions, 3));
		this.geometry.computeBoundingSphere();

		var positions2 = [1, 1, 0, -1, 1, 0, -1, -1, 0, 1, 1, 0, -1, -1, 0, 1, -1, 0];
		var geometry2 = new BufferGeometry();
		geometry2.setAttribute("position", new Float32BufferAttribute(positions2, 3));
		geometry2.computeBoundingSphere();
		this.add(new Mesh(geometry2, new MeshBasicMaterial({side: BackSide, fog: false})));
		this.type = "RectAreaLightHelper";
	}

	override function updateMatrixWorld() {
		this.scale.set(this.light.width * 0.5, this.light.height * 0.5, 1);

		if (this.color != null) {
			this.material.color = this.color;
			this.children[0].material.color = this.color;
		} else {
			this.material.color = this.light.color.clone().multiplyScalar(this.light.intensity);
			var c = this.material.color;
			var max = Math.max(c.r, c.g, c.b);
			if (max > 1) c.multiplyScalar(1 / max);
			this.children[0].material.color = this.material.color;
		}

		this.matrixWorld.extractRotation(this.light.matrixWorld).scale(this.scale).copyPosition(this.light.matrixWorld);
		this.children[0].matrixWorld = this.matrixWorld;
	}

	public function dispose() {
		this.geometry.dispose();
		this.material.dispose();
		this.children[0].geometry.dispose();
		this.children[0].material.dispose();
	}

}