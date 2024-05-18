package three.js.examples.jsw.helpers;

import three.js.lib.BufferGeometry;
import three.js.lib.Float32BufferAttribute;
import three.js.lib.LineSegments;
import three.js.lib.LineBasicMaterial;
import three.js.lib.Matrix3;
import three.js.lib.Vector3;

class VertexNormalsHelper extends LineSegments {
    private var object:Dynamic;
    private var size:Float;
    private var type:String;

    private static var _v1:Vector3 = new Vector3();
    private static var _v2:Vector3 = new Vector3();
    private static var _normalMatrix:Matrix3 = new Matrix3();

    public function new(object:Dynamic, size:Float = 1, color:Int = 0xff0000) {
        var geometry:BufferGeometry = new BufferGeometry();

        var nNormals:Int = object.geometry.attributes.normal.count;
        var positions:Float32BufferAttribute = new Float32BufferAttribute(nNormals * 2 * 3, 3);

        geometry.setAttribute('position', positions);

        super(geometry, new LineBasicMaterial({ color: color, toneMapped: false }));

        this.object = object;
        this.size = size;
        this.type = 'VertexNormalsHelper';

        this.matrixAutoUpdate = false;

        this.update();
    }

    public function update():Void {
        this.object.updateMatrixWorld(true);

        _normalMatrix.getNormalMatrix(this.object.matrixWorld);

        var matrixWorld:Matrix = this.object.matrixWorld;

        var position:Float32BufferAttribute = this.geometry.attributes.position;

        var objGeometry:BufferGeometry = this.object.geometry;

        if (objGeometry != null) {
            var objPos:Float32BufferAttribute = objGeometry.attributes.position;
            var objNorm:Float32BufferAttribute = objGeometry.attributes.normal;

            var idx:Int = 0;

            for (j in 0...objPos.count) {
                _v1.fromBufferAttribute(objPos, j).applyMatrix4(matrixWorld);

                _v2.fromBufferAttribute(objNorm, j);

                _v2.applyMatrix3(_normalMatrix).normalize().multiplyScalar(this.size).add(_v1);

                position.setXYZ(idx, _v1.x, _v1.y, _v1.z);
                idx++;

                position.setXYZ(idx, _v2.x, _v2.y, _v2.z);
                idx++;
            }
        }

        position.needsUpdate = true;
    }

    public function dispose():Void {
        this.geometry.dispose();
        this.material.dispose();
    }
}