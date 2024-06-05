import three.core.BufferGeometry;
import three.core.LineSegments;
import three.materials.LineBasicMaterial;
import three.math.Matrix3;
import three.math.Vector3;
import three.core.Float32BufferAttribute;

class VertexNormalsHelper extends LineSegments {

    public var object:Dynamic;
    public var size:Float;

    public function new(object:Dynamic, size:Float = 1, color:Int = 0xff0000) {
        var geometry = new BufferGeometry();
        var nNormals = cast object.geometry.attributes.normal.count : Int;
        var positions = new Float32BufferAttribute(nNormals * 2 * 3, 3);

        geometry.setAttribute('position', positions);
        super(geometry, new LineBasicMaterial({color:color, toneMapped:false}));

        this.object = object;
        this.size = size;
        this.type = 'VertexNormalsHelper';

        this.matrixAutoUpdate = false;
        this.update();
    }

    public function update() {
        this.object.updateMatrixWorld(true);

        var _normalMatrix = new Matrix3();
        _normalMatrix.getNormalMatrix(this.object.matrixWorld);

        var matrixWorld = this.object.matrixWorld;

        var position = this.geometry.attributes.position;

        var objGeometry = this.object.geometry;
        if (objGeometry != null) {
            var objPos = objGeometry.attributes.position;
            var objNorm = objGeometry.attributes.normal;

            var _v1 = new Vector3();
            var _v2 = new Vector3();

            var idx = 0;

            for (j in 0...objPos.count) {
                _v1.fromBufferAttribute(objPos, j).applyMatrix4(matrixWorld);
                _v2.fromBufferAttribute(objNorm, j);
                _v2.applyMatrix3(_normalMatrix).normalize().multiplyScalar(this.size).add(_v1);

                position.setXYZ(idx, _v1.x, _v1.y, _v1.z);
                idx += 1;
                position.setXYZ(idx, _v2.x, _v2.y, _v2.z);
                idx += 1;
            }
        }

        position.needsUpdate = true;
    }

    public function dispose() {
        this.geometry.dispose();
        this.material.dispose();
    }
}