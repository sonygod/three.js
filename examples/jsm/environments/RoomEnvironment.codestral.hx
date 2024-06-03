import three.BackSide;
import three.BoxGeometry;
import three.Mesh;
import three.MeshBasicMaterial;
import three.MeshStandardMaterial;
import three.PointLight;
import three.Scene;

class RoomEnvironment extends Scene {

    public function new(renderer: three.WebGLRenderer = null) {
        super();

        var geometry: BoxGeometry = new BoxGeometry();
        geometry.deleteAttribute('uv');

        var roomMaterial: MeshStandardMaterial = new MeshStandardMaterial({ side: BackSide });
        var boxMaterial: MeshStandardMaterial = new MeshStandardMaterial();

        var intensity: Float = 5;

        if (renderer != null && !renderer._useLegacyLights) intensity = 900;

        var mainLight: PointLight = new PointLight(0xffffff, intensity, 28, 2);
        mainLight.position.set(0.418, 16.199, 0.300);
        this.add(mainLight);

        var room: Mesh = new Mesh(geometry, roomMaterial);
        room.position.set(-0.757, 13.219, 0.717);
        room.scale.set(31.713, 28.305, 28.591);
        this.add(room);

        var box1: Mesh = new Mesh(geometry, boxMaterial);
        box1.position.set(-10.906, 2.009, 1.846);
        box1.rotation.set(0, -0.195, 0);
        box1.scale.set(2.328, 7.905, 4.651);
        this.add(box1);

        // Add the rest of the boxes and lights here

        // Don't forget to dispose of the resources in the dispose method
    }

    public function dispose(): Void {
        var resources: haxe.ds.Set<Dynamic> = new haxe.ds.Set<Dynamic>();

        this.traverse(function(object) {
            if (Std.is(object, Mesh)) {
                resources.add(object.geometry);
                resources.add(object.material);
            }
        });

        for (resource in resources) {
            resource.dispose();
        }
    }
}

function createAreaLightMaterial(intensity: Float): MeshBasicMaterial {
    var material: MeshBasicMaterial = new MeshBasicMaterial();
    material.color.setScalar(intensity);
    return material;
}