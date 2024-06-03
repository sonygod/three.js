import three.math.Matrix4;
import three.math.MathUtils;
import three.textures.DataTexture;
import three.constants.RGBAFormat;
import three.constants.FloatType;
import three.objects.Bone;

class Skeleton {
	public uuid:String;
	public bones:Array<Bone>;
	public boneInverses:Array<Matrix4>;
	public boneMatrices:Float32Array;
	public boneTexture:DataTexture;

	public function new(bones:Array<Bone> = [], boneInverses:Array<Matrix4> = []) {
		this.uuid = MathUtils.generateUUID();
		this.bones = bones.copy();
		this.boneInverses = boneInverses;
		this.boneMatrices = null;
		this.boneTexture = null;
		this.init();
	}

	public function init() {
		var bones = this.bones;
		var boneInverses = this.boneInverses;
		this.boneMatrices = new Float32Array(bones.length * 16);

		// calculate inverse bone matrices if necessary
		if (boneInverses.length == 0) {
			this.calculateInverses();
		} else {
			// handle special case
			if (bones.length != boneInverses.length) {
				Sys.warning("THREE.Skeleton: Number of inverse bone matrices does not match amount of bones.");
				this.boneInverses = new Array<Matrix4>();
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
			if (this.bones[i] != null) {
				inverse.copy(this.bones[i].matrixWorld).invert();
			}
			this.boneInverses.push(inverse);
		}
	}

	public function pose() {
		// recover the bind-time world matrices
		for (i in 0...this.bones.length) {
			var bone = this.bones[i];
			if (bone != null) {
				bone.matrixWorld.copy(this.boneInverses[i]).invert();
			}
		}

		// compute the local matrices, positions, rotations and scales
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

		// flatten bone matrices to array
		for (i in 0...bones.length) {
			// compute the offset between the current and the original transform
			var matrix = bones[i] != null ? bones[i].matrixWorld : new Matrix4();
			var offsetMatrix = new Matrix4();
			offsetMatrix.multiplyMatrices(matrix, boneInverses[i]);
			offsetMatrix.toArray(boneMatrices, i * 16);
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
		var size = Math.sqrt(this.bones.length * 4); // 4 pixels needed for 1 matrix
		size = Math.ceil(size / 4) * 4;
		size = Math.max(size, 4);
		var boneMatrices = new Float32Array(size * size * 4); // 4 floats per RGBA pixel
		boneMatrices.set(this.boneMatrices); // copy current values
		var boneTexture = new DataTexture(boneMatrices, size, size, RGBAFormat, FloatType);
		boneTexture.needsUpdate = true;
		this.boneMatrices = boneMatrices;
		this.boneTexture = boneTexture;
		return this;
	}

	public function getBoneByName(name:String):Bone {
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

	public function fromJSON(json:Dynamic, bones:Array<Bone>):Skeleton {
		this.uuid = json.uuid;
		for (i in 0...json.bones.length) {
			var uuid = json.bones[i];
			var bone = bones[uuid];
			if (bone == null) {
				Sys.warning("THREE.Skeleton: No bone found with UUID:", uuid);
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
				type: "Skeleton",
				generator: "Skeleton.toJSON"
			},
			bones: new Array<String>(),
			boneInverses: new Array<Array<Float>>(),
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