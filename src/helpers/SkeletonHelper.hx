package three.helpers;

import three.objects.LineSegments;
import three.math.Matrix4;
import three.materials.LineBasicMaterial;
import three.math.Color;
import three.math.Vector3;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;

class SkeletonHelper extends LineSegments {
    public var isSkeletonHelper:Bool = true;
    public var type:String = 'SkeletonHelper';
    public var root:Dynamic;
    public var bones:Array<Dynamic>;
    public var matrix:Matrix4;
    public var matrixAutoUpdate:Bool = false;

    private var _vector:Vector3 = new Vector3();
    private var _boneMatrix:Matrix4 = new Matrix4();
    private var _matrixWorldInv:Matrix4 = new Matrix4();

    public function new(object:Dynamic) {
        super();

        bones = getBoneList(object);

        var geometry:BufferGeometry = new BufferGeometry();

        var vertices:Array<Float> = [];
        var colors:Array<Float> = [];

        var color1:Color = new Color(0, 0, 1);
        var color2:Color = new Color(0, 1, 0);

        for (i in 0...bones.length) {
            var bone:Dynamic = bones[i];

            if (bone.parent != null && bone.parent.isBone) {
                vertices.push(0, 0, 0);
                vertices.push(0, 0, 0);
                colors.push(color1.r, color1.g, color1.b);
                colors.push(color2.r, color2.g, color2.b);
            }
        }

        geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        geometry.setAttribute('color', new Float32BufferAttribute(colors, 3));

        var material:LineBasicMaterial = new LineBasicMaterial({
            vertexColors: true,
            depthTest: false,
            depthWrite: false,
            toneMapped: false,
            transparent: true
        });

        super(geometry, material);

        this.root = object;
        this.bones = bones;
        this.matrix = object.matrixWorld;
        this.matrixAutoUpdate = false;
    }

    public function updateMatrixWorld(force:Bool) {
        var bones:Array<Dynamic> = this.bones;
        var geometry:BufferGeometry = this.geometry;
        var position:Float32BufferAttribute = geometry.getAttribute('position');

        _matrixWorldInv.copy(this.root.matrixWorld).invert();

        for (i in 0...bones.length) {
            var bone:Dynamic = bones[i];

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

    public function dispose() {
        geometry.dispose();
        material.dispose();
    }
}

function getBoneList(object:Dynamic):Array<Dynamic> {
    var boneList:Array<Dynamic> = [];

    if (object.isBone) {
        boneList.push(object);
    }

    for (i in 0...object.children.length) {
        boneList = boneList.concat(getBoneList(object.children[i]));
    }

    return boneList;
}