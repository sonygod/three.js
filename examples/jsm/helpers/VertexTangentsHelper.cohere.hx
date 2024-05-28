import js.three.BufferGeometry;
import js.three.Float32BufferAttribute;
import js.three.LineSegments;
import js.three.LineBasicMaterial;
import js.three.Vector3;

class VertexTangentsHelper extends LineSegments {
    var _v1:Vector3;
    var _v2:Vector3;
    var object:Dynamic;
    var size:Float;
    var color:Int;

    public function new(object:Dynamic, size:Float = 1., color:Int = 0x00ffff) {
        super();
        _v1 = new Vector3();
        _v2 = new Vector3();
        this.object = object;
        this.size = size;
        this.color = color;

        var geometry = new BufferGeometry();
        var nTangents = object.geometry.attributes.tangent.count;
        var positions = new Float32BufferAttribute(nTangents * 2 * 3, 3);
        geometry.setAttribute('position', positions);

        var material = new LineBasicMaterial({ color : color, toneMapped : false });

        this.setGeometry(geometry);
        this.setMaterial(material);

        this.matrixAutoUpdate = false;
        this.update();
    }

    public function update():Void {
        object.updateMatrixWorld(true);
        var matrixWorld = object.matrixWorld;
        var position = this.geometry.attributes.position;

        var objGeometry = object.geometry;
        var objPos = objGeometry.attributes.position;
        var objTan = objGeometry.attributes.tangent;

        var idx = 0;
        for (i in 0...objPos.count) {
            _v1.fromBufferAttribute(objPos, i).applyMatrix4(matrixWorld);
            _v2.fromBufferAttribute(objTan, i);
            _v2.transformDirection(matrixWorld).multiplyScalar(size).add(_v1);
            position.setXYZ(idx, _v1.x, _v1.y, _v1.z);
            idx++;
            position.setXYZ(idx, _v2.x, _v2.y, _v2.z);
            idx++;
        }
        position.needsUpdate = true;
    }

    public function dispose():Void {
        this.geometry.dispose();
        this.material.dispose();
    }
}

class Export {
    static function VertexTangentsHelper() return VertexTangentsHelper;
}