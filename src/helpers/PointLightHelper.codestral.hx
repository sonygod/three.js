import js.three.objects.Mesh;
import js.three.materials.MeshBasicMaterial;
import js.three.geometries.SphereGeometry;
import js.three.math.Color;
import js.three.core.Object3D;

class PointLightHelper extends Mesh {

    public var light: Object3D;
    public var color: Color;
    public var type: String;

    public function new(light: Object3D, sphereSize: Float, color: Color) {
        super(new SphereGeometry(sphereSize, 4, 2), new MeshBasicMaterial(js.__map([
            "wireframe", true,
            "fog", false,
            "toneMapped", false
        ])));

        this.light = light;
        this.color = color;
        this.type = 'PointLightHelper';
        this.matrix = this.light.matrixWorld;
        this.matrixAutoUpdate = false;
        this.update();
    }

    public function dispose(): Void {
        this.geometry.dispose();
        this.material.dispose();
    }

    public function update(): Void {
        this.light.updateWorldMatrix(true, false);
        if (this.color != null) {
            this.material.color.set(this.color);
        } else {
            this.material.color.copy(this.light.color);
        }
    }
}