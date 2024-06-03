import three.BufferGeometry;
import three.Float32BufferAttribute;
import three.LineSegments;
import three.LineBasicMaterial;
import three.Matrix3;
import three.Vector3;

class VertexNormalsHelper extends LineSegments {

    private var _v1:Vector3 = new Vector3();
    private var _v2:Vector3 = new Vector3();
    private var _normalMatrix:Matrix3 = new Matrix3();

    public function new(object:three.Object3D, size:Float = 1, color:Int = 0xff0000) {
        super(new BufferGeometry(), new LineBasicMaterial({color: color, toneMapped: false}));

        this.object = object;
        this.size = size;
        this.type = 'VertexNormalsHelper';
        this.matrixAutoUpdate = false;

        var geometry:BufferGeometry = this.geometry;
        var nNormals = object.geometry.attributes.normal.count;
        var positions = new Float32BufferAttribute(nNormals * 2 * 3, 3);
        geometry.setAttribute('position', positions);

        this.update();
    }

    public function update() {
        this.object.updateMatrixWorld(true);
        this._normalMatrix.getNormalMatrix(this.object.matrixWorld);

        var matrixWorld = this.object.matrixWorld;
        var position = this.geometry.attributes.position;
        var objGeometry = this.object.geometry;

        if (objGeometry != null) {
            var objPos = objGeometry.attributes.position;
            var objNorm = objGeometry.attributes.normal;
            var idx = 0;

            for (var j = 0; j < objPos.count; j++) {
                this._v1.fromBufferAttribute(objPos, j).applyMatrix4(matrixWorld);
                this._v2.fromBufferAttribute(objNorm, j);

                this._v2.applyMatrix3(this._normalMatrix).normalize().multiplyScalar(this.size).add(this._v1);
                position.setXYZ(idx, this._v1.x, this._v1.y, this._v1.z);
                idx += 1;

                position.setXYZ(idx, this._v2.x, this._v2.y, this._v2.z);
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