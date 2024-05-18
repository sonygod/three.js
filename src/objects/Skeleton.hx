package three.objects;

import three.constants.RGBAFormat;
import three.constants.FloatType;
import three.math.Matrix4;
import three.math.MathUtils;
import three.textures.DataTexture;
import three.bone.Bone;

class Skeleton {

    public var uuid:String;

    public var bones:Array<Bone>;
    public var boneInverses:Array<Matrix4>;
    public var boneMatrices:Array<Float>;
    public var boneTexture:DataTexture;

    private var _offsetMatrix:Matrix4;
    private var _identityMatrix:Matrix4;

    public function new(bones:Array<Bone> = [], boneInverses:Array<Matrix4> = []) {
        uuid = MathUtils.generateUUID();

        this.bones = bones.copy();
        this.boneInverses = boneInverses;
        this.boneMatrices = null;

        this.boneTexture = null;

        init();
    }

    private function init():Void {
        var bones:Array<Bone> = this.bones;
        var boneInverses:Array<Matrix4> = this.boneInverses;

        this.boneMatrices = new Array<Float>();

        // calculate inverse bone matrices if necessary
        if (boneInverses.length == 0) {
            calculateInverses();
        } else {
            // handle special case
            if (bones.length != boneInverses.length) {
                trace("THREE.Skeleton: Number of inverse bone matrices does not match amount of bones.");
                this.boneInverses = [];

                for (i in 0...this.bones.length) {
                    this.boneInverses.push(new Matrix4());
                }
            }
        }
    }

    private function calculateInverses():Void {
        this.boneInverses.splice(0, this.boneInverses.length);

        for (i in 0...this.bones.length) {
            var inverse:Matrix4 = new Matrix4();

            if (this.bones[i] != null) {
                inverse.copy(this.bones[i].matrixWorld).invert();
            }

            this.boneInverses.push(inverse);
        }
    }

    public function pose():Void {
        // recover the bind-time world matrices
        for (i in 0...this.bones.length) {
            var bone:Bone = this.bones[i];

            if (bone != null) {
                bone.matrixWorld.copy(this.boneInverses[i]).invert();
            }
        }

        // compute the local matrices, positions, rotations and scales
        for (i in 0...this.bones.length) {
            var bone:Bone = this.bones[i];

            if (bone != null) {
                if (bone.parent != null && bone.parent.isBone) {
                    bone.matrix.copy(bone.parent.matrixWorld).invert();
                    bone.matrix.multiply(bone.matrixWorld);
                } else {
                    bone.matrix.copy(bone.matrixWorld);
                }

                bone.matrix.decompose(bone.position, bone.quaternion, bone.scale);
            }
        }
    }

    public function update():Void {
        var bones:Array<Bone> = this.bones;
        var boneInverses:Array<Matrix4> = this.boneInverses;
        var boneMatrices:Array<Float> = this.boneMatrices;
        var boneTexture:DataTexture = this.boneTexture;

        // flatten bone matrices to array
        for (i in 0...bones.length) {
            // compute the offset between the current and the original transform
            var matrix:Matrix4 = bones[i] != null ? bones[i].matrixWorld : _identityMatrix;

            _offsetMatrix.multiplyMatrices(matrix, boneInverses[i]);
            _offsetMatrix.toArray(boneMatrices, i * 16);
        }

        if (boneTexture != null) {
            boneTexture.needsUpdate = true;
        }
    }

    public function clone():Skeleton {
        return new Skeleton(this.bones, this.boneInverses);
    }

    public function computeBoneTexture():Skeleton {
        // layout (1 matrix = 4 pixels)
        //      RGBA RGBA RGBA RGBA (=> column1, column2, column3, column4)
        //  with  8x8  pixel texture max   16 bones * 4 pixels =  (8 * 8)
        //       16x16 pixel texture max   64 bones * 4 pixels = (16 * 16)
        //       32x32 pixel texture max  256 bones * 4 pixels = (32 * 32)
        //       64x64 pixel texture max 1024 bones * 4 pixels = (64 * 64)

        var size:Int = Math.ceil(Math.sqrt(this.bones.length * 4) / 4) * 4;
        size = Math.max(size, 4);

        var boneMatrices:Array<Float> = new Array<Float>();
        boneMatrices.resize(size * size * 4); // 4 floats per RGBA pixel
        boneMatrices.set(this.boneMatrices); // copy current values

        var boneTexture:DataTexture = new DataTexture(boneMatrices, size, size, RGBAFormat, FloatType);
        boneTexture.needsUpdate = true;

        this.boneMatrices = boneMatrices;
        this.boneTexture = boneTexture;

        return this;
    }

    public function getBoneByName(name:String):Bone {
        for (i in 0...this.bones.length) {
            var bone:Bone = this.bones[i];

            if (bone.name == name) {
                return bone;
            }
        }

        return null;
    }

    public function dispose():Void {
        if (this.boneTexture != null) {
            this.boneTexture.dispose();

            this.boneTexture = null;
        }
    }

    public function fromJSON(json:Dynamic, bones:Array<Bone>):Skeleton {
        this.uuid = json.uuid;

        for (i in 0...json.bones.length) {
            var uuid:String = json.bones[i];
            var bone:Bone = bones[uuid];

            if (bone == null) {
                trace("THREE.Skeleton: No bone found with UUID:", uuid);
                bone = new Bone();
            }

            this.bones.push(bone);
            this.boneInverses.push(new Matrix4().fromArray(json.boneInverses[i]));
        }

        init();

        return this;
    }

    public function toJSON():Dynamic {
        var data:Dynamic = {
            metadata: {
                version: 4.6,
                type: 'Skeleton',
                generator: 'Skeleton.toJSON'
            },
            bones: [],
            boneInverses: []
        };

        data.uuid = this.uuid;

        var bones:Array<Bone> = this.bones;
        var boneInverses:Array<Matrix4> = this.boneInverses;

        for (i in 0...bones.length) {
            var bone:Bone = bones[i];
            data.bones.push(bone.uuid);

            var boneInverse:Matrix4 = boneInverses[i];
            data.boneInverses.push(boneInverse.toArray());
        }

        return data;
    }
}