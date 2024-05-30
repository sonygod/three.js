package three.helpers;

import three.bufferGeometry.BufferGeometry;
import three.bufferAttribute.Float32BufferAttribute;
import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.math.Matrix3;
import three.math.Vector3;

class VertexNormalsHelper extends LineSegments {
    public var object:Object3D;
    public var size:Float;
    public var type:String;

    private var _v1:Vector3;
    private var _v2:Vector3;
    private var _normalMatrix:Matrix3;

    public function new(object:Object3D, size:Float = 1, color:Int = 0xff0000) {
        super(new BufferGeometry(), new LineBasicMaterial({color: color, toneMapped: false}));

        this.object = object;
        this.size = size;
        this.type = 'VertexNormalsHelper';

        _v1 = new Vector3();
        _v2 = new Vector3();
        _normalMatrix = new Matrix3();

        this.matrixAutoUpdate = false;

        update();
    }

    public function update() {
        object.updateMatrixWorld(true);
        _normalMatrix.getNormalMatrix(object.matrixWorld);

        var matrixWorld = object.matrixWorld;
        var geometry = this.geometry;
        var objGeometry = object.geometry;

        if (objGeometry != null) {
            var objPos = objGeometry.attributes.position;
            var objNorm = objGeometry.attributes.normal;
            var position = geometry.attributes.position;

            for (j in 0...objPos.count) {
                _v1.fromBufferAttribute(objPos, j).applyMatrix4(matrixWorld);

                _v2.fromBufferAttribute(objNorm, j);
                _v2.applyMatrix3(_normalMatrix).normalize().multiplyScalar(size).add(_v1);

                position.setXYZ(j * 2, _v1.x, _v1.y, _v1.z);
                position.setXYZ(j * 2 + 1, _v2.x, _v2.y, _v2.z);
            }

            position.needsUpdate = true;
        }
    }

    public function dispose() {
        geometry.dispose();
        material.dispose();
    }
}