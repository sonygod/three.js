package three.objects;

import three.constants.RGBAFormat;
import three.constants.FloatType;
import three.math.Matrix4;
import three.textures.DataTexture;
import three.math.MathUtils;
import three.objects.Bone;

class Skeleton {
    public var uuid:String;
    public var bones:Array<Bone>;
    public var boneInverses:Array<Matrix4>;
    public var boneMatrices:Array<Float>;
    public var boneTexture:DataTexture;

    private static var _offsetMatrix:Matrix4 = new Matrix4();
    private static var _identityMatrix:Matrix4 = new Matrix4();

    public function new(bones:Array<Bone> = [], boneInverses:Array<Matrix4> = []) {
        uuid = MathUtils.generateUUID();
        this.bones = bones.copy();
        this.boneInverses = boneInverses;
        this.boneMatrices = null;
        this.boneTexture = null;
        init();
    }

    private function init() {
        var bones:Array<Bone> = this.bones;
        var boneInverses:Array<Matrix4> = this.boneInverses;

        this.boneMatrices = new Array<Float>();
        this.boneMatrices.resize(bones.length * 16);

        if (boneInverses.length == 0) {
            calculateInverses();
        } else {
            if (bones.length != boneInverses.length) {
                trace("THREE.Skeleton: Number of inverse bone matrices does not match amount of bones.");
                this.boneInverses = [];
                for (i in 0...this.bones.length) {
                    this.boneInverses.push(new Matrix4());
                }
            }
        }
    }

    private function calculateInverses() {
        boneInverses.resize(0);
        for (i in 0...bones.length) {
            var inverse:Matrix4 = new Matrix4();
            if (bones[i] != null) {
                inverse.copy(bones[i].matrixWorld).invert();
            }
            boneInverses.push(inverse);
        }
    }

    public function pose() {
        // recover the bind-time world matrices
        for (i in 0...bones.length) {
            var bone:Bone = bones[i];
            if (bone != null) {
                bone.matrixWorld.copy(boneInverses[i]).invert();
            }
        }

        // compute the local matrices, positions, rotations and scales
        for (i in 0...bones.length) {
            var bone:Bone = bones[i];
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

    public function update() {
        var bones:Array<Bone> = this.bones;
        var boneInverses:Array<Matrix4> = this.boneInverses;
        var boneMatrices:Array<Float> = this.boneMatrices;
        var boneTexture:DataTexture = this.boneTexture;

        for (i in 0...bones.length) {
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
        var size:Int = Math.ceil(Math.sqrt(bones.length * 4) / 4) * 4;
        size = Math.max(size, 4);

        var boneMatrices:Array<Float> = new Array<Float>();
        boneMatrices.resize(size * size * 4);
        boneMatrices.set(this.boneMatrices); // copy current values

        var boneTexture:DataTexture = new DataTexture(boneMatrices, size, size, RGBAFormat, FloatType);
        boneTexture.needsUpdate = true;

        this.boneMatrices = boneMatrices;
        this.boneTexture = boneTexture;

        return this;
    }

    public function getBoneByName(name:String):Bone {
        for (i in 0...bones.length) {
            var bone:Bone = bones[i];
            if (bone.name == name) {
                return bone;
            }
        }
        return null;
    }

    public function dispose() {
        if (boneTexture != null) {
            boneTexture.dispose();
            boneTexture = null;
        }
    }

    public function fromJSON(json:Dynamic, bones:Map<String, Bone>):Skeleton {
        uuid = json.uuid;

        for (i in 0...json.bones.length) {
            var uuid:String = json.bones[i];
            var bone:Bone = bones[uuid];
            if (bone == null) {
                trace("THREE.Skeleton: No bone found with UUID:", uuid);
                bone = new Bone();
            }
            bones.push(bone);
            boneInverses.push(new Matrix4().fromArray(json.boneInverses[i]));
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