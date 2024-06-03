import js.Boot;
import js.Browser;
import js.html.ArrayBuffer;
import js.html.Float32Array;
import js.html.Matrix;
import three.constants.RGBAFormat;
import three.constants.FloatType;
import three.math.Matrix4;
import three.objects.Bone;
import three.textures.DataTexture;
import three.math.MathUtils;

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

    public function init():Void {
        this.boneMatrices = new Float32Array(this.bones.length * 16);
        if (this.boneInverses.length == 0) {
            this.calculateInverses();
        } else {
            if (this.bones.length != this.boneInverses.length) {
                Browser.console.warn("THREE.Skeleton: Number of inverse bone matrices does not match amount of bones.");
                this.boneInverses = [];
                for (i in 0...this.bones.length) {
                    this.boneInverses.push(new Matrix4());
                }
            }
        }
    }

    public function calculateInverses():Void {
        this.boneInverses = [];
        for (i in 0...this.bones.length) {
            var inverse = new Matrix4();
            if (this.bones[i] != null) {
                inverse.copy(this.bones[i].matrixWorld).invert();
            }
            this.boneInverses.push(inverse);
        }
    }

    public function pose():Void {
        for (i in 0...this.bones.length) {
            var bone = this.bones[i];
            if (bone != null) {
                bone.matrixWorld.copy(this.boneInverses[i]).invert();
            }
        }
        for (i in 0...this.bones.length) {
            var bone = this.bones[i];
            if (bone != null) {
                if (bone.parent != null && bone.parent is Bone) {
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
        var _offsetMatrix = new Matrix4();
        var _identityMatrix = new Matrix4();
        for (i in 0...this.bones.length) {
            var matrix = this.bones[i] != null ? this.bones[i].matrixWorld : _identityMatrix;
            _offsetMatrix.multiplyMatrices(matrix, this.boneInverses[i]);
            _offsetMatrix.toArray(this.boneMatrices, i * 16);
        }
        if (this.boneTexture != null) {
            this.boneTexture.needsUpdate = true;
        }
    }

    public function clone():Skeleton {
        return new Skeleton(this.bones, this.boneInverses);
    }

    public function computeBoneTexture():Skeleton {
        var size = Math.sqrt(this.bones.length * 4);
        size = Math.ceil(size / 4) * 4;
        size = Math.max(size, 4);
        var boneMatrices = new Float32Array(size * size * 4);
        boneMatrices.set(this.boneMatrices);
        var boneTexture = new DataTexture(boneMatrices, size, size, RGBAFormat, FloatType);
        boneTexture.needsUpdate = true;
        this.boneMatrices = boneMatrices;
        this.boneTexture = boneTexture;
        return this;
    }

    public function getBoneByName(name:String):Bone {
        for (bone in this.bones) {
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
            var uuid = json.bones[i];
            var bone = bones[uuid];
            if (bone == null) {
                Browser.console.warn("THREE.Skeleton: No bone found with UUID:", uuid);
                bone = new Bone();
            }
            this.bones.push(bone);
            this.boneInverses.push(new Matrix4().fromArray(json.boneInverses[i]));
        }
        this.init();
        return this;
    }

    public function toJSON():Dynamic {
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
        for (i in 0...this.bones.length) {
            var bone = this.bones[i];
            data.bones.push(bone.uuid);
            var boneInverse = this.boneInverses[i];
            data.boneInverses.push(boneInverse.toArray());
        }
        return data;
    }
}