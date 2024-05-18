package three.helpers;

import three.objects.Mesh;
import three.materials.MeshBasicMaterial;
import three.geometries.SphereGeometry;

class PointLightHelper extends Mesh {
    public var light:Dynamic;
    public var color:Int;

    public function new(light:Dynamic, sphereSize:Float, color:Int) {
        var geometry = new SphereGeometry(sphereSize, 4, 2);
        var material = new MeshBasicMaterial({ wireframe: true, fog: false, toneMapped: false });
        super(geometry, material);

        this.light = light;
        this.color = color;

        this.type = 'PointLightHelper';

        this.matrix = this.light.matrixWorld;
        this.matrixAutoUpdate = false;

        this.update();
    }

    public function dispose() {
        geometry.dispose();
        material.dispose();
    }

    public function update() {
        this.light.updateWorldMatrix(true, false);

        if (this.color != null) {
            material.color.set(this.color);
        } else {
            material.color.copy(this.light.color);
        }
    }
}