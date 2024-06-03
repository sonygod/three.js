import three.objects.Mesh;
import three.materials.MeshBasicMaterial;
import three.geometries.SphereGeometry;

class PointLightHelper extends Mesh {

	public var light:Dynamic;
	public var color:Dynamic;

	public function new(light:Dynamic, sphereSize:Float, color:Dynamic) {
		var geometry = new SphereGeometry(sphereSize, 4, 2);
		var material = new MeshBasicMaterial({wireframe:true, fog:false, toneMapped:false});
		super(geometry, material);
		this.light = light;
		this.color = color;
		this.type = 'PointLightHelper';
		this.matrix = light.matrixWorld;
		this.matrixAutoUpdate = false;
		this.update();
	}

	public function dispose() {
		this.geometry.dispose();
		this.material.dispose();
	}

	public function update() {
		this.light.updateWorldMatrix(true, false);
		if (this.color != null) {
			this.material.color.set(this.color);
		} else {
			this.material.color.copy(this.light.color);
		}
	}
}