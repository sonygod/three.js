import three.math.Vector3;
import three.core.Object3D;
import three.objects.Line;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.materials.LineBasicMaterial;

class DirectionalLightHelper extends Object3D {

    var light:Dynamic;
    var color:Dynamic;
    var lightPlane:Line;
    var targetLine:Line;

    public function new(light:Dynamic, size:Float, color:Dynamic) {
        super();

        this.light = light;

        this.matrix = light.matrixWorld;
        this.matrixAutoUpdate = false;

        this.color = color;

        this.type = 'DirectionalLightHelper';

        if (size === null) size = 1;

        var geometry = new BufferGeometry();
        geometry.setAttribute('position', new BufferAttribute(
            [
                - size, size, 0,
                size, size, 0,
                size, - size, 0,
                - size, - size, 0,
                - size, size, 0
            ], 3
        ));

        var material = new LineBasicMaterial({fog: false, toneMapped: false});

        this.lightPlane = new Line(geometry, material);
        this.add(this.lightPlane);

        geometry = new BufferGeometry();
        geometry.setAttribute('position', new BufferAttribute([0, 0, 0, 0, 0, 1], 3));

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

        var _v1 = new Vector3();
        var _v2 = new Vector3();
        var _v3 = new Vector3();

        _v1.setFromMatrixPosition(this.light.matrixWorld);
        _v2.setFromMatrixPosition(this.light.target.matrixWorld);
        _v3.subVectors(_v2, _v1);

        this.lightPlane.lookAt(_v2);

        if (this.color !== null) {
            this.lightPlane.material.color.set(this.color);
            this.targetLine.material.color.set(this.color);
        } else {
            this.lightPlane.material.color.copy(this.light.color);
            this.targetLine.material.color.copy(this.light.color);
        }

        this.targetLine.lookAt(_v2);
        this.targetLine.scale.z = _v3.length();
    }
}