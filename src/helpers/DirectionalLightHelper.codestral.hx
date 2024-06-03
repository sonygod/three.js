import three.Vector3;
import three.Object3D;
import three.Line;
import three.Float32BufferAttribute;
import three.BufferGeometry;
import three.LineBasicMaterial;

class DirectionalLightHelper extends Object3D {

    private var _v1:Vector3 = new Vector3();
    private var _v2:Vector3 = new Vector3();
    private var _v3:Vector3 = new Vector3();

    public var lightPlane:Line;
    public var targetLine:Line;
    public var light;
    public var color:Int;

    public function new(light, size:Float, color:Int) {
        super();

        this.light = light;

        this.matrix = light.matrixWorld;
        this.matrixAutoUpdate = false;

        this.color = color;

        this.type = 'DirectionalLightHelper';

        if (size == null) size = 1;

        var geometry:BufferGeometry = new BufferGeometry();
        geometry.setAttribute('position', new Float32BufferAttribute(Array<Float>(
            -size, size, 0,
            size, size, 0,
            size, -size, 0,
            -size, -size, 0,
            -size, size, 0
        ), 3));

        var material:LineBasicMaterial = new LineBasicMaterial({fog: false, toneMapped: false});

        this.lightPlane = new Line(geometry, material);
        this.add(this.lightPlane);

        geometry = new BufferGeometry();
        geometry.setAttribute('position', new Float32BufferAttribute(Array<Float>(0, 0, 0, 0, 0, 1), 3));

        this.targetLine = new Line(geometry, material);
        this.add(this.targetLine);

        this.update();
    }

    public function dispose():Void {
        this.lightPlane.geometry.dispose();
        this.lightPlane.material.dispose();
        this.targetLine.geometry.dispose();
        this.targetLine.material.dispose();
    }

    public function update():Void {
        this.light.updateWorldMatrix(true, false);
        this.light.target.updateWorldMatrix(true, false);

        _v1.setFromMatrixPosition(this.light.matrixWorld);
        _v2.setFromMatrixPosition(this.light.target.matrixWorld);
        _v3.subVectors(_v2, _v1);

        this.lightPlane.lookAt(_v2);

        if (this.color != null) {
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