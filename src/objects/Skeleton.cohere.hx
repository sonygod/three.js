import MathUtils from js.three.MathUtils;
import Matrix4 from js.three.Matrix4;
import DataTexture from js.three.DataTexture;
import RGBAFormat from js.three.RGBAFormat;
import FloatType from js.three.FloatType;

class Skeleton {
    public var uuid:String;
    public var bones:Array<Bone>;
    public var boneInverses:Array<Matrix4>;
    public var boneMatrices:Float32Array;
    public var boneTexture:DataTexture;

    public function new(bones:Array<Bone> = [], boneInverses:Array<Matrix4> = []) {
        this.uuid = MathUtils.generateUUID();
        this.bones = bones.slice();
        this.boneInverses = boneInverses;
        this.boneMatrices = null;
        this.boneTexture = null;
        this.init();
    }

    public function init() {
        var bones = this.bones;
        var boneInverses = this.boneInverses;

        this.boneMatrices = new Float32Array(bones.length * 16);

        if (boneInverses.length == 0) {
            this.calculateInverses();
        } else {
            if (bones.length != boneInverses.length) {
                trace("Skeleton: Number of inverse bone matrices does not match amount of bones.");
                this.boneInverses = [];
                for (i in 0...bones.length) {
                    this.boneInverses.push(new Matrix4());
                }
            }
        }
    }

    public function calculateInverses() {
        this.boneInverses.length = 0;
        for (i in 0...this.bones.length) {
            var inverse = new Matrix4();
            if (this.bones[i] != null) {
                inverse.copy(this.bones[i].matrixWorld).invert();
            }
            this.boneInverses.push(inverse);
        }
    }

    public function pose() {
        for (i in 0...this.bones.length) {
            var bone = this.bones[i];
            if (bone != null) {
                bone.matrixWorld.copy(this.boneInverses[i]).invert();
            }
        }

        for (i in 0...this.bones.length) {
            var bone = this.bones[i];
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
        var bones = this.bones;
        var boneInverses = this.boneInverses;
        var boneMatrices = this.boneMatrices;
        var boneTexture = this.boneTexture;

        for (i in 0...bones.length) {
            var matrix = bones[i] != null ? bones[i].matrixWorld : _identityMatrix;
            _offsetMatrix.multiplyMatrices(matrix, boneInverses[i]);
            _offsetMatrix.toArray(boneMatrices, i * 16);
        }

        if (boneTexture != null) {
            boneTexture.needsUpdate = true;
        }
    }

    public function clone() {
        return new Skeleton(this.bones, this.boneInverses);
    }

    public function computeBoneTexture() {
        var size = Std.int(Math.sqrt(this.bones.length * 4));
        size = (Std.int(size / 4) * 4);
        size = Math.max(size, 4);

        var boneMatrices = new Float32Array(size * size * 4);
        boneMatrices.set(this.boneMatrices);

        var boneTexture = new DataTexture(boneMatrices, size, size, RGBAFormat, FloatType);
        boneTexture.needsUpdate = true;

        this.boneMatrices = boneMatrices;
        this.boneTexture = boneTexture;

        return this;
    }

    public function getBoneByName(name:String) {
        for (i in 0...this.bones.length) {
            var bone = this.bones[i];
            if (bone.name == name) {
                return bone;
            }
        }
        return null;
    }

    public function dispose() {
        if (this.boneTexture != null) {
            this.boneTexture.dispose();
            this.boneTexture = null;
        }
    }

    public function fromJSON(json:Dynamic, bones:Array<Bone>) {
        this.uuid = json.uuid;
        for (i in 0...json.bones.length) {
            var uuid = json.bones[i];
            var bone = bones[uuid];
            if (bone == null) {
                trace("Skeleton: No bone found with UUID:", uuid);
                bone = new Bone();
            }
            this.bones.push(bone);
            this.boneInverses.push(new Matrix4().fromArray(json.boneInverses[i]));
        }
        this.init();
        return this;
    }

    public function toJSON() {
        var data = {
            metadata: {
                version: 4.6,
                type: 'Skeleton',
                generator: 'Skeleton.toJSON'
            },
            bones: [],
            boneInverses: []
        };

        data.uuid = this.uuid;

        var bones = this.bones;
        var boneInverses = this.boneInverses;

        for (i in 0...bones.length) {
            var bone = bones[i];
            data.bones.push(bone.uuid);
            var boneInverse = boneInverses[i];
            data.boneInverses.push(boneInverse.toArray());
        }

        return data;
    }
}