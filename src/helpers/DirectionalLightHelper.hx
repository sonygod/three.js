package three.helpers;

import three.math.Vector3;
import three.core.Object3D;
import three.objects.Line;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.materials.LineBasicMaterial;

class DirectionalLightHelper extends Object3D {
    
    public var light:Dynamic;
    public var lightPlane:Line;
    public var targetLine:Line;
    public var color:Null<Int>;

    private var _v1:Vector3;
    private var _v2:Vector3;
    private var _v3:Vector3;

    public function new(light:Dynamic, size:Float = 1, color:Null<Int> = null) {
        super();

        this.light = light;

        this.matrix = light.matrixWorld;
        this.matrixAutoUpdate = false;

        this.color = color;

        this.type = 'DirectionalLightHelper';

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
        add(lightPlane);

        geometry = new BufferGeometry();
        geometry.setAttribute('position', new Float32BufferAttribute([0, 0, 0, 0, 0, 1], 3));

        targetLine = new Line(geometry, material);
        add(targetLine);

        update();
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