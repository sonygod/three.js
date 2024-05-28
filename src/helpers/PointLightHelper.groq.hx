package three.helpers;

import three.objects.Mesh;
import three.materials.MeshBasicMaterial;
import three.geometries.SphereGeometry;

class PointLightHelper extends Mesh {

    public var light:Dynamic;
    public var color:Int;
    public var type:String;

    public function new(light:Dynamic, sphereSize:Float, color:Int) {
        super(new SphereGeometry(sphereSize, 4, 2), new MeshBasicMaterial({ wireframe: true, fog: false, toneMapped: false }));
        this.light = light;
        this.color = color;
        this.type = 'PointLightHelper';
        this.matrix = light.matrixWorld;
        this.matrixAutoUpdate = false;
        update();
    }

    public function dispose():Void {
        geometry.dispose();
        material.dispose();
    }

    public function update():Void {
        light.updateWorldMatrix(true, false);
        if (color != null) {
            material.color.set(color);
        } else {
            material.color.copy(light.color);
        }
    }
}