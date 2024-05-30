import three.js.extras.helpers.LineSegments;
import three.js.extras.core.BufferGeometry;
import three.js.extras.materials.LineBasicMaterial;
import three.js.math.Vector3;

class VertexTangentsHelper extends LineSegments {

    public var object:Dynamic;
    public var size:Float;
    public var type:String;

    private var _v1:Vector3;
    private var _v2:Vector3;

    public function new(object:Dynamic, size:Float = 1, color:Int = 0x00ffff) {

        this._v1 = new Vector3();
        this._v2 = new Vector3();

        var geometry:BufferGeometry = new BufferGeometry();

        var nTangents:Int = untyped __object.geometry.attributes.tangent.count;
        var positions:Float32BufferAttribute = new Float32BufferAttribute(nTangents * 2 * 3, 3);

        geometry.setAttribute('position', positions);

        super(geometry, new LineBasicMaterial({color: color, toneMapped: false}));

        this.object = object;
        this.size = size;
        this.type = 'VertexTangentsHelper';

        //

        this.matrixAutoUpdate = false;

        this.update();

    }

    public function update() {

        this.object.updateMatrixWorld(true);

        var matrixWorld:Matrix4 = this.object.matrixWorld;

        var position:Float32BufferAttribute = this.geometry.attributes.position;

        //

        var objGeometry:BufferGeometry = this.object.geometry;

        var objPos:Float32BufferAttribute = objGeometry.attributes.position;

        var objTan:Float32BufferAttribute = objGeometry.attributes.tangent;

        var idx:Int = 0;

        // for simplicity, ignore index and drawcalls, and render every tangent

        for (j in 0...objPos.count) {

            this._v1.fromBufferAttribute(objPos, j).applyMatrix4(matrixWorld);

            this._v2.fromBufferAttribute(objTan, j);

            this._v2.transformDirection(matrixWorld).multiplyScalar(this.size).add(this._v1);

            position.setXYZ(idx, this._v1.x, this._v1.y, this._v1.z);

            idx++;

            position.setXYZ(idx, this._v2.x, this._v2.y, this._v2.z);

            idx++;

        }

        position.needsUpdate = true;

    }

    public function dispose() {

        this.geometry.dispose();
        this.material.dispose();

    }

}