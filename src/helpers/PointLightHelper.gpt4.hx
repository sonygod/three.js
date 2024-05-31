import three.objects.Mesh;
import three.materials.MeshBasicMaterial;
import three.geometries.SphereGeometry;

class PointLightHelper extends Mesh {

    public var light:Dynamic;
    public var color:Dynamic;

    public function new(light:Dynamic, sphereSize:Float, color:Dynamic) {
        var geometry = new SphereGeometry(sphereSize, 4, 2);
        var material = new MeshBasicMaterial({
            wireframe: true,
            fog: false,
            toneMapped: false
        });

        super(geometry, material);

        this.light = light;
        this.color = color;

        this.type = 'PointLightHelper';

        this.matrix = this.light.matrixWorld;
        this.matrixAutoUpdate = false;

        this.update();

        /*
        // TODO: delete this comment?
        var distanceGeometry = new THREE.IcosahedronGeometry(1, 2);
        var distanceMaterial = new THREE.MeshBasicMaterial({
            color: hexColor,
            fog: false,
            wireframe: true,
            opacity: 0.1,
            transparent: true
        });

        this.lightSphere = new THREE.Mesh(bulbGeometry, bulbMaterial);
        this.lightDistance = new THREE.Mesh(distanceGeometry, distanceMaterial);

        var d = light.distance;

        if (d == 0.0) {
            this.lightDistance.visible = false;
        } else {
            this.lightDistance.scale.set(d, d, d);
        }

        this.add(this.lightDistance);
        */
    }

    public function dispose():Void {
        this.geometry.dispose();
        this.material.dispose();
    }

    public function update():Void {
        this.light.updateWorldMatrix(true, false);

        if (this.color != null) {
            this.material.color.set(this.color);
        } else {
            this.material.color.copy(this.light.color);
        }

        /*
        var d = this.light.distance;

        if (d == 0.0) {
            this.lightDistance.visible = false;
        } else {
            this.lightDistance.visible = true;
            this.lightDistance.scale.set(d, d, d);
        }
        */
    }
}

@:expose("PointLightHelper")
class ExposedPointLightHelper extends PointLightHelper {
    public function new(light:Dynamic, sphereSize:Float, color:Dynamic) {
        super(light, sphereSize, color);
    }
}