import three.BufferGeometry;
import three.Float32BufferAttribute;
import three.LineSegments;
import three.LineBasicMaterial;
import three.Matrix3;
import three.Vector3;

class VertexNormalsHelper extends LineSegments {

    static var _v1:Vector3 = new Vector3();
    static var _v2:Vector3 = new Vector3();
    static var _normalMatrix:Matrix3 = new Matrix3();

    public function new(object:Dynamic, size:Float = 1, color:Int = 0xff0000) {

        var geometry = new BufferGeometry();

        var nNormals = object.geometry.attributes.normal.count;
        var positions = new Float32BufferAttribute(nNormals * 2 * 3, 3);

        geometry.setAttribute('position', positions);

        super(geometry, new LineBasicMaterial({color: color, toneMapped: false}));

        this.object = object;
        this.size = size;
        this.type = 'VertexNormalsHelper';

        this.matrixAutoUpdate = false;

        this.update();

    }

    public function update() {

        this.object.updateMatrixWorld(true);

        _normalMatrix.getNormalMatrix(this.object.matrixWorld);

        var matrixWorld = this.object.matrixWorld;

        var position = this.geometry.attributes.position;

        var objGeometry = this.object.geometry;

        if (objGeometry) {

            var objPos = objGeometry.attributes.position;

            var objNorm = objGeometry.attributes.normal;

            var idx = 0;

            for (i in 0...objPos.count) {

                _v1.fromBufferAttribute(objPos, i).applyMatrix4(matrixWorld);

                _v2.fromBufferAttribute(objNorm, i);

                _v2.applyMatrix3(_normalMatrix).normalize().multiplyScalar(this.size).add(_v1);

                position.setXYZ(idx, _v1.x, _v1.y, _v1.z);

                idx = idx + 1;

                position.setXYZ(idx, _v2.x, _v2.y, _v2.z);

                idx = idx + 1;

            }

        }

        position.needsUpdate = true;

    }

    public function dispose() {

        this.geometry.dispose();
        this.material.dispose();

    }

}