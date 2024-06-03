import three.math.Matrix4;
import three.math.Color;
import three.math.Vector3;
import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.objects.LineSegments;
import three.materials.LineBasicMaterial;

class SkeletonHelper extends LineSegments {
    private var _vector: Vector3 = new Vector3();
    private var _boneMatrix: Matrix4 = new Matrix4();
    private var _matrixWorldInv: Matrix4 = new Matrix4();

    public var root: any;
    public var bones: Array<any>;

    public function new(object: any) {
        var bones: Array<any> = getBoneList(object);

        var geometry: BufferGeometry = new BufferGeometry();

        var vertices: Array<Float> = [];
        var colors: Array<Float> = [];

        var color1: Color = new Color(0, 0, 1);
        var color2: Color = new Color(0, 1, 0);

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

        var material: LineBasicMaterial = new LineBasicMaterial({
            vertexColors: true,
            depthTest: false,
            depthWrite: false,
            toneMapped: false,
            transparent: true
        });

        super(geometry, material);

        this.isSkeletonHelper = true;
        this.type = 'SkeletonHelper';
        this.root = object;
        this.bones = bones;
        this.matrix = object.matrixWorld;
        this.matrixAutoUpdate = false;
    }

    public function updateMatrixWorld(force: Bool) {
        var bones = this.bones;
        var geometry = this.geometry;
        var position = geometry.getAttribute('position');

        _matrixWorldInv.copy(this.root.matrixWorld).invert();

        for (i in 0...bones.length) {
            var bone = bones[i];

            if (bone.parent != null && bone.parent.isBone) {
                _boneMatrix.multiplyMatrices(_matrixWorldInv, bone.matrixWorld);
                _vector.setFromMatrixPosition(_boneMatrix);
                position.setXYZ(j, _vector.x, _vector.y, _vector.z);

                _boneMatrix.multiplyMatrices(_matrixWorldInv, bone.parent.matrixWorld);
                _vector.setFromMatrixPosition(_boneMatrix);
                position.setXYZ(j + 1, _vector.x, _vector.y, _vector.z);

                j += 2;
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

function getBoneList(object: any): Array<any> {
    var boneList: Array<any> = [];

    if (object.isBone == true) {
        boneList.push(object);
    }

    for (i in 0...object.children.length) {
        boneList = boneList.concat(getBoneList(object.children[i]));
    }

    return boneList;
}