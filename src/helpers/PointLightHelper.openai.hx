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
        type = 'PointLightHelper';
        matrix = light.matrixWorld;
        matrixAutoUpdate = false;
        update();
    }

    public function dispose() {
        geometry.dispose();
        material.dispose();
    }

    public function update() {
        light.updateWorldMatrix(true, false);
        if (color != null) {
            material.color.set(color);
        } else {
            material.color.copy(light.color);
        }
    }
}