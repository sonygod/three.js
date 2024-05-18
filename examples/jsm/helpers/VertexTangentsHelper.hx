package three.js.examples.jm.helpers;

import three.js.BufferGeometry;
import three.js.Float32BufferAttribute;
import three.js.LineSegments;
import three.js.LineBasicMaterial;
import three.js.Vector3;

class VertexTangentsHelper extends LineSegments {
    private var object:Dynamic;
    private var size:Float;
    private var type:String;

    public function new(object:Dynamic, size:Float = 1, color:Int = 0x00ffff) {
        super(new BufferGeometry(), new LineBasicMaterial({ color: color, toneMapped: false }));

        this.object = object;
        this.size = size;
        this.type = 'VertexTangentsHelper';

        matrixAutoUpdate = false;

        update();

        geometry.setAttribute('position', new Float32BufferAttribute(object.geometry.attributes.tangent.count * 2 * 3, 3));
    }

    public function update() {
        object.updateMatrixWorld(true);

        var matrixWorld = object.matrixWorld;
        var position = geometry.attributes.position;
        var objGeometry = object.geometry;
        var objPos = objGeometry.attributes.position;
        var objTan = objGeometry.attributes.tangent;

        var idx = 0;

        for (j in 0...objPos.count) {
            var _v1 = new Vector3();
            _v1.fromBufferAttribute(objPos, j).applyMatrix4(matrixWorld);

            var _v2 = new Vector3();
            _v2.fromBufferAttribute(objTan, j);

            _v2.transformDirection(matrixWorld).multiplyScalar(size).add(_v1);

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