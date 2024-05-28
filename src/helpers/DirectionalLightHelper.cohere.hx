import js.Browser.window;
import js.Three.*;

class DirectionalLightHelper extends Object3D {
    var light:DirectionalLight;
    var size:Float;
    var color:Color;
    var _v1:Vector3;
    var _v2:Vector3;
    var _v3:Vector3;
    var lightPlane:Line;
    var targetLine:Line;

    public function new(light:DirectionalLight, ?size:Float, ?color:Int) {
        super();

        this.light = light;
        this.matrix = light.matrixWorld;
        this.matrixAutoUpdate = false;

        this.size = size ?? 1.0;
        this.color = color != null ? new Color(color) : null;

        _v1 = new Vector3();
        _v2 = new Vector3();
        _v3 = new Vector3();

        var geometry = new BufferGeometry();
        geometry.setAttribute('position', new Float32BufferAttribute([
            -size, size, 0,
            size, size, 0,
            size, -size, 0,
            -size, -size, 0,
            -size, size, 0
        ], 3));

        var material = new LineBasicMaterial({ fog: false, toneMapped: false });

        lightPlane = new Line(geometry, material);
        this.add(lightPlane);

        geometry = new BufferGeometry();
        geometry.setAttribute('position', new Float32BufferAttribute([0, 0, 0, 0, 0, 1], 3));

        targetLine = new Line(geometry, material);
        this.add(targetLine);

        this.update();
    }

    public function dispose() {
        lightPlane.geometry.dispose();
        lightPlane.material.dispose();
        targetLine.geometry.dispose();
        targetLine.material.dispose();
    }

    public function update() {
        light.updateWorldMatrix(true, false);
        light.target.updateWorldMatrix(true, false);

        _v1.setFromMatrixPosition(light.matrixWorld);
        _v2.setFromMatrixPosition(light.target.matrixWorld);
        _v3.subVectors(_v2, _v1);

        lightPlane.lookAt(_v2);

        if (color != null) {
            lightPlane.material.color.set(color);
            targetLine.material.color.set(color);
        } else {
            lightPlane.material.color.copy(light.color);
            targetLine.material.color.copy(light.color);
        }

        targetLine.lookAt(_v2);
        targetLine.scale.z = _v3.length();
    }
}