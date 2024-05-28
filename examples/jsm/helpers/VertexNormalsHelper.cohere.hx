import js.three.BufferGeometry;
import js.three.Float32BufferAttribute;
import js.three.LineSegments;
import js.three.LineBasicMaterial;
import js.three.Matrix3;
import js.three.Vector3;

class VertexNormalsHelper extends LineSegments {
    var _v1:Vector3;
    var _v2:Vector3;
    var _normalMatrix:Matrix3;

    public function new(object:Dynamic, size:Float = 1., color:Int = 0xff0000) {
        super(
            geometry = new BufferGeometry(),
            material = new LineBasicMaterial({
                color: color,
                toneMapped: false
            })
        );

        _v1 = new Vector3();
        _v2 = new Vector3();
        _normalMatrix = new Matrix3();

        var geometry = cast object.geometry;
        var nNormals = geometry.attributes.normal.count;
        var positions = new Float32BufferAttribute(nNormals * 2 * 3, 3);
        cast <BufferGeometry> geometry.setAttribute('position', positions);

        this.object = object;
        this.size = size;
        this.type = 'VertexNormalsHelper';
        this.matrixAutoUpdate = false;
        this.update();
    }

    public function update() {
        object.updateMatrixWorld(true);
        _normalMatrix.getNormalMatrix(object.matrixWorld);

        var matrixWorld = object.matrixWorld;
        var position = cast <Float32BufferAttribute> geometry.attributes.position;

        var objGeometry = cast object.geometry;
        var objPos = cast <Float32BufferAttribute> objGeometry.attributes.position;
        var objNorm = cast <Float32BufferAttribute> objGeometry.attributes.normal;

        var idx:Int = 0;
        for (i in 0...objPos.count) {
            _v1.fromBufferAttribute(objPos, i).applyMatrix4(matrixWorld);
            _v2.fromBufferAttribute(objNorm, i);
            _v2.applyMatrix3(_normalMatrix).normalize().multiplyScalar(size).add(_v1);
            position.setXYZ(idx, _v1.x, _v1.y, _v1.z);
            idx++;
            position.setXYZ(idx, _v2.x, _v2.y, _v2.z);
            idx++;
        }

        position.needsUpdate = true;
    }

    public function dispose() {
        geometry.dispose();
        material.dispose();
    }
}

class js.VertexNormalsHelper {
    public static function new(object:Dynamic, ?size:Float, ?color:Int) {
        return new VertexNormalsHelper(object, size, color);
    }
}