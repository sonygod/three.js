import js.three.BufferAttribute;
import js.three.BufferGeometry;
import js.three.Color;
import js.three.LineBasicMaterial;
import js.three.LineSegments;
import js.three.Matrix4;
import js.three.Vector3;

class SkeletonHelper extends LineSegments {
    var bones:Array<Dynamic>;
    var root:Dynamic;
    var matrix:Matrix4;
    var matrixAutoUpdate:Bool;
    var _vector:Vector3;
    var _boneMatrix:Matrix4;
    var _matrixWorldInv:Matrix4;

    public function new(object:Dynamic) {
        super();

        bones = getBoneList(object);
        var geometry = new BufferGeometry();
        var vertices = [];
        var colors = [];
        var color1 = new Color(0, 0, 1);
        var color2 = new Color(0, 1, 0);

        for (i in 0...bones.length) {
            var bone = bones[i];
            if (bone.parent != null && bone.parent.isBone) {
                vertices.push(0, 0, 0);
                vertices.push(0, 0, 0);
                colors.push(color1.r, color1.g, color1.b);
                colors.push(color2.r, color2.g, color2.b);
            }
        }

        geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        geometry.setAttribute('color', new Float32BufferAttribute(colors, 3));

        var material = new LineBasicMaterial({ vertexColors: true, depthTest: false, depthWrite: false, toneMapped: false, transparent: true });

        super(geometry, material);

        this.isSkeletonHelper = true;
        this.type = 'SkeletonHelper';
        this.root = object;
        this.bones = bones;
        this.matrix = object.matrixWorld;
        this.matrixAutoUpdate = false;
    }

    public function updateMatrixWorld(force:Bool) {
        var bones = this.bones;
        var geometry = this.geometry;
        var position = geometry.getAttribute('position');

        _matrixWorldInv.copy(this.root.matrixWorld).invert();

        for (i in 0...bones.length) {
            var bone = bones[i];
            if (bone.parent != null && bone.parent.isBone) {
                _boneMatrix.multiplyMatrices(_matrixWorldInv, bone.matrixWorld);
                _vector.setFromMatrixPosition(_boneMatrix);
                position.setXYZ(i * 2, _vector.x, _vector.y, _vector.z);

                _boneMatrix.multiplyMatrices(_matrixWorldInv, bone.parent.matrixWorld);
                _vector.setFromMatrixPosition(_boneMatrix);
                position.setXYZ(i * 2 + 1, _vector.x, _vector.y, _vector.z);
            }
        }

        geometry.getAttribute('position').needsUpdate = true;

        super.updateMatrixWorld(force);
    }

    public function dispose() {
        this.geometry.dispose();
        this.material.dispose();
    }
}

function getBoneList(object:Dynamic):Array<Dynamic> {
    var boneList = [];

    if (object.isBone) {
        boneList.push(object);
    }

    for (i in 0...object.children.length) {
        boneList.pushArray(getBoneList(object.children[i]));
    }

    return boneList;
}