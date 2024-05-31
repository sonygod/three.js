import three.core.Object3D;
import three.math.Matrix4;
import three.textures.DataTexture;
import three.math.MathUtils;
import three.constants.RGBAFormat;
import three.constants.FloatType;

class Skeleton {

    public var uuid : String;
    public var bones : Array<Bone>;
    public var boneInverses : Array<Matrix4>;
    public var boneMatrices : Array<Float>;
    public var boneTexture : DataTexture;

    public function new( bones : Array<Bone> = null, boneInverses : Array<Matrix4> = null) {

        if (bones == null) bones = [];
        if (boneInverses == null) boneInverses = [];

        this.uuid = MathUtils.generateUUID();

        this.bones = bones.copy();
        this.boneInverses = boneInverses;
        this.boneMatrices = null;
        this.boneTexture = null;

        this.init();

    }

    public function init() : Void {

        var bones = this.bones;
        var boneInverses = this.boneInverses;

        this.boneMatrices = new Array<Float>(bones.length * 16);

        // calculate inverse bone matrices if necessary

        if (boneInverses.length == 0) {

            this.calculateInverses();

        } else {

            // handle special case

            if (bones.length != boneInverses.length) {

                trace('THREE.Skeleton: Number of inverse bone matrices does not match amount of bones.');

                this.boneInverses = [];

                for (i in 0...this.bones.length) {

                    this.boneInverses.push(new Matrix4());

                }

            }

        }

    }

    public function calculateInverses() : Void {

        this.boneInverses = [];

        for (i in 0...this.bones.length) {

            var inverse = new Matrix4();

            if (this.bones[i] != null) {

                inverse.copy(this.bones[i].matrixWorld).invert();

            }

            this.boneInverses.push(inverse);

        }

    }

    public function pose() : Void {

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

                if (bone.parent != null && Std.isOfType(bone.parent, Bone)) {

                    bone.matrix.copy(cast(bone.parent, Bone).matrixWorld).invert();
                    bone.matrix.multiply(bone.matrixWorld);

                } else {

                    bone.matrix.copy(bone.matrixWorld);

                }

                bone.matrix.decompose(bone.position, bone.quaternion, bone.scale);

            }

        }

    }

    public function update() : Void {

        var bones = this.bones;
        var boneInverses = this.boneInverses;
        var boneMatrices = this.boneMatrices;
        var boneTexture = this.boneTexture;

        // flatten bone matrices to array
        var _offsetMatrix = new Matrix4();
        var _identityMatrix = new Matrix4();

        for (i in 0...bones.length) {

            // compute the offset between the current and the original transform

            var matrix = (bones[i] != null) ? bones[i].matrixWorld : _identityMatrix;

            _offsetMatrix.multiplyMatrices(matrix, boneInverses[i]);
            // @ts-ignore
            _offsetMatrix.toArray(boneMatrices, i * 16);

        }

        if (boneTexture != null) {

            boneTexture.needsUpdate = true;

        }

    }

    public function clone() : Skeleton {

        return new Skeleton(this.bones, this.boneInverses);

    }

    public function computeBoneTexture() : Skeleton {

        // layout (1 matrix = 4 pixels)
        //      RGBA RGBA RGBA RGBA (=> column1, column2, column3, column4)
        //  with  8x8  pixel texture max   16 bones * 4 pixels =  (8 * 8)
        //       16x16 pixel texture max   64 bones * 4 pixels = (16 * 16)
        //       32x32 pixel texture max  256 bones * 4 pixels = (32 * 32)
        //       64x64 pixel texture max 1024 bones * 4 pixels = (64 * 64)

        var size = Math.sqrt(this.bones.length * 4); // 4 pixels needed for 1 matrix
        size = Math.ceil(size / 4) * 4;
        size = Math.max(size, 4);

        var boneMatrices = new Array<Float>(Std.int(size * size * 4)); // 4 floats per RGBA pixel
        // @ts-ignore
        boneMatrices = boneMatrices.concat(this.boneMatrices); // copy current values

        var boneTexture = new DataTexture(boneMatrices, size, size, RGBAFormat, FloatType);
        boneTexture.needsUpdate = true;

        this.boneMatrices = boneMatrices;
        this.boneTexture = boneTexture;

        return this;

    }

    public function getBoneByName(name : String) : Bone {

        for (i in 0...this.bones.length) {

            var bone = this.bones[i];

            if (bone.name == name) {

                return bone;

            }

        }

        return null;

    }

    public function dispose() : Void {

        if (this.boneTexture != null) {

            this.boneTexture.dispose();

            this.boneTexture = null;

        }

    }

    // public fromJSON( json, bones ) {

    // 	this.uuid = json.uuid;

    // 	for ( let i = 0, l = json.bones.length; i < l; i ++ ) {

    // 		const uuid = json.bones[ i ];
    // 		let bone = bones[ uuid ];

    // 		if ( bone === undefined ) {

    // 			console.warn( 'THREE.Skeleton: No bone found with UUID:', uuid );
    // 			bone = new Bone();

    // 		}

    // 		this.bones.push( bone );
    // 		this.boneInverses.push( new Matrix4().fromArray( json.boneInverses[ i ] ) );

    // 	}

    // 	this.init();

    // 	return this;

    // }

    // public toJSON() {

    // 	const data = {
    // 		metadata: {
    // 			version: 4.6,
    // 			type: 'Skeleton',
    // 			generator: 'Skeleton.toJSON'
    // 		},
    // 		bones: [],
    // 		boneInverses: []
    // 	};

    // 	data.uuid = this.uuid;

    // 	const bones = this.bones;
    // 	const boneInverses = this.boneInverses;

    // 	for ( let i = 0, l = bones.length; i < l; i ++ ) {

    // 		const bone = bones[ i ];
    // 		data.bones.push( bone.uuid );

    // 		const boneInverse = boneInverses[ i ];
    // 		data.boneInverses.push( boneInverse.toArray() );

    // 	}

    // 	return data;

    // }

}