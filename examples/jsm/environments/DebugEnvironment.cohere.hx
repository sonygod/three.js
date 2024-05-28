import three.geom.BoxGeometry;
import three.materials.MeshLambertMaterial;
import three.materials.MeshStandardMaterial;
import three.materials.side.BackSide;
import three.objects.Mesh;
import three.objects.PointLight;
import three.scenes.Scene;

class DebugEnvironment extends Scene {

	public function new() {
		super();

		var geometry = new BoxGeometry();
		geometry.deleteAttribute('uv');
		var roomMaterial = new MeshStandardMaterial({ metalness: 0, side: BackSide });
		var room = new Mesh(geometry, roomMaterial);
		room.scale.setScalar(10);
		this.add(room);

		var mainLight = new PointLight(0xffffff, 50, 0, 2);
		this.add(mainLight);

		var material1 = new MeshLambertMaterial({ color: 0xff0000, emissive: 0xffffff, emissiveIntensity: 10 });
		var light1 = new Mesh(geometry, material1);
		light1.position.set(-5, 2, 0);
		light1.scale.set(0.1, 1, 1);
		this.add(light1);

		var material2 = new MeshLambertMaterial({ color: 0x00ff00, emissive: 0xffffff, emissiveIntensity: 10 });
		var light2 = new Mesh(geometry, material2);
		light2.position.set(0, 5, 0);
		light2.scale.set(1, 0.1, 1);
		this.add(light2);

		var material3 = new MeshLambertMaterial({ color: 0x0000ff, emissive: 0xffffff, emissiveIntensity: 10 });
		var light3 = new Mesh(geometry, material3);
		light3.position.set(2, 1, 5);
		light3.scale.set(1.5, 2, 0.1);
		this.add(light3);
	}

}

class Export {
	public static inline var DebugEnvironment:DebugEnvironment;
}