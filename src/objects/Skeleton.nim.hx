import three.js.src.constants.RGBAFormat;
import three.js.src.constants.FloatType;
import three.js.src.objects.Bone;
import three.js.src.math.Matrix4;
import three.js.src.textures.DataTexture;
import three.js.src.math.MathUtils;

class Skeleton {

	public var uuid:String;
	public var bones:Array<Bone>;
	public var boneInverses:Array<Matrix4>;
	public var boneMatrices:Float32Array;
	public var boneTexture:DataTexture;

	public function new(bones:Array<Bone> = [], boneInverses:Array<Matrix4> = []) {
		this.uuid = MathUtils.generateUUID();
		this.bones = bones.slice(0);
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
				trace("THREE.Skeleton: Number of inverse bone matrices does not match amount of bones.");
				this.boneInverses = [];
				for (i in 0...this.bones.length) {
					this.boneInverses.push(new Matrix4());
				}
			}
		}
	}

	public function calculateInverses() {
		this.boneInverses.length = 0;
		for (i in 0...this.bones.length) {
			var inverse = new Matrix4();
			if (this.bones[i]) {
				inverse.copy(this.bones[i].matrixWorld).invert();
			}
			this.boneInverses.push(inverse);
		}
	}

	public function pose() {
		for (i in 0...this.bones.length) {
			var bone = this.bones[i];
			if (bone) {
				bone.matrixWorld.copy(this.boneInverses[i]).invert();
			}
		}

		for (i in 0...this.bones.length) {
			var bone = this.bones[i];
			if (bone) {
				if (bone.parent && bone.parent.isBone) {
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
			var matrix = bones[i] ? bones[i].matrixWorld : _identityMatrix;
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

	public function getBoneByName(name:String) {
		for (i in 0...this.bones.length) {
			var bone = this.bones[i];
			if (bone.name == name) {
				return bone;
			}
		}
		return undefined;
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
			if (bone == undefined) {
				trace("THREE.Skeleton: No bone found with UUID:", uuid);
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