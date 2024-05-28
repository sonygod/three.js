package three.helpers;

import three.objects.LineSegments;
import three.math.Matrix4;
import three.math.Color;
import three.math.Vector3;
import three.core.BufferGeometry;
import three.core.BufferAttribute;

class SkeletonHelper extends LineSegments {
    var _vector:Vector3;
    var _boneMatrix:Matrix4;
    var _matrixWorldInv:Matrix4;

    public function new(object:Object3D) {
        super();
        _vector = new Vector3();
        _boneMatrix = new Matrix4();
        _matrixWorldInv = new Matrix4();

        var bones:Array<Bone> = getBoneList(object);

        var geometry:BufferGeometry = new BufferGeometry();
        var vertices:Array<Float> = [];
        var colors:Array<Float> = [];

        var color1:Color = new Color(0, 0, 1);
        var color2:Color = new Color(0, 1, 0);

        for (i in 0...bones.length) {
            var bone:Bone = bones[i];

            if (bone.parent != null && bone.parent.isBone) {
                vertices.push(0);
                vertices.push(0);
                vertices.push(0);
                vertices.push(0);
                vertices.push(0);
                vertices.push(0);

                colors.push(color1.r);
                colors.push(color1.g);
                colors.push(color1.b);
                colors.push(color2.r);
                colors.push(color2.g);
                colors.push(color2.b);
            }
        }

        geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        geometry.setAttribute('color', new Float32BufferAttribute(colors, 3));

        var material:LineBasicMaterial = new LineBasicMaterial({ vertexColors: true, depthTest: false, depthWrite: false, toneMapped: false, transparent: true });
        super(geometry, material);

        this.isSkeletonHelper = true;
        this.type = 'SkeletonHelper';

        this.root = object;
        this.bones = bones;

        this.matrix = object.matrixWorld;
        this.matrixAutoUpdate = false;
    }

    override function updateMatrixWorld(force:Bool) {
        var bones:Array<Bone> = this.bones;

        var geometry:BufferGeometry = this.geometry;
        var position:BufferAttribute = geometry.getAttribute('position');

        _matrixWorldInv.copy(this.root.matrixWorld).invert();

        for (i in 0...bones.length) {
            var bone:Bone = bones[i];

            if (bone.parent != null && bone.parent.isBone) {
                _boneMatrix.multiplyMatrices(_matrixWorldInv, bone.matrixWorld);
                _vector.setFromMatrixPosition(_boneMatrix);
                position.setXYZ(i * 2, _vector.x, _vector.y, _vector.z);

                _boneMatrix.multiplyMatrices(_matrixWorldInv, bone.parent.matrixWorld);
                _vector.setFromMatrixPosition(_boneMatrix);
                position.setXYZ(i * 2 + 1, _vector.x, _vector.y, _vector.z);
            }
        }

        position.needsUpdate = true;

        super.updateMatrixWorld(force);
    }

    override function dispose() {
        this.geometry.dispose();
        this.material.dispose();
    }
}

function getBoneList(object:Object3D):Array<Bone> {
    var boneList:Array<Bone> = [];

    if (object.isBone) {
        boneList.push(object);
    }

    for (child in object.children) {
        boneList = boneList.concat(getBoneList(child));
    }

    return boneList;
}