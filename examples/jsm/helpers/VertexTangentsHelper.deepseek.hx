import three.BufferGeometry;
import three.Float32BufferAttribute;
import three.LineSegments;
import three.LineBasicMaterial;
import three.Vector3;

class VertexTangentsHelper extends LineSegments {

    static var _v1:Vector3 = new Vector3();
    static var _v2:Vector3 = new Vector3();

    public function new(object:Dynamic, size:Float = 1, color:Int = 0x00ffff) {

        var geometry = new BufferGeometry();

        var nTangents = object.geometry.attributes.tangent.count;
        var positions = new Float32BufferAttribute(nTangents * 2 * 3, 3);

        geometry.setAttribute('position', positions);

        super(geometry, new LineBasicMaterial({color: color, toneMapped: false}));

        this.object = object;
        this.size = size;
        this.type = 'VertexTangentsHelper';

        this.matrixAutoUpdate = false;

        this.update();

    }

    public function update() {

        this.object.updateMatrixWorld(true);

        var matrixWorld = this.object.matrixWorld;

        var position = this.geometry.attributes.position;

        var objGeometry = this.object.geometry;

        var objPos = objGeometry.attributes.position;

        var objTan = objGeometry.attributes.tangent;

        var idx = 0;

        for (i in 0...objPos.count) {

            _v1.fromBufferAttribute(objPos, i).applyMatrix4(matrixWorld);

            _v2.fromBufferAttribute(objTan, i);

            _v2.transformDirection(matrixWorld).multiplyScalar(this.size).add(_v1);

            position.setXYZ(idx, _v1.x, _v1.y, _v1.z);

            idx = idx + 1;

            position.setXYZ(idx, _v2.x, _v2.y, _v2.z);

            idx = idx + 1;

        }

        position.needsUpdate = true;

    }

    public function dispose() {

        this.geometry.dispose();
        this.material.dispose();

    }

}