import three.Matrix3;
import three.Matrix4;
import three.Vector3;
import misc.VolumeSlice;

/**
 * This class had been written to handle the output of the NRRD loader.
 * It contains a volume of data and informations about it.
 * For now it only handles 3 dimensional data.
 * See the webgl_loader_nrrd.html example and the loaderNRRD.js file to see how to use this class.
 * @class
 * @param   {number}        xLength         Width of the volume
 * @param   {number}        yLength         Length of the volume
 * @param   {number}        zLength         Depth of the volume
 * @param   {string}        type            The type of data (uint8, uint16, ...)
 * @param   {ArrayBuffer}   arrayBuffer     The buffer with volume data
 */
class Volume {

	public var xLength:Int;
	public var yLength:Int;
	public var zLength:Int;
	public var axisOrder:Array<String> = [ 'x', 'y', 'z' ];
	public var data:haxe.io.Bytes;
	public var spacing:Array<Float> = [ 1, 1, 1 ];
	public var offset:Array<Float> = [ 0, 0, 0 ];
	public var matrix:Matrix3 = new Matrix3();
	public var inverseMatrix:Matrix3;
	public var lowerThreshold:Float;
	public var upperThreshold:Float;
	public var sliceList:Array<VolumeSlice> = [];
	public var segmentation:Bool = false;
	public var RASDimensions:Array<Int>;
	public var min:Float;
	public var max:Float;

	public function new(xLength:Int, yLength:Int, zLength:Int, type:String, arrayBuffer:ArrayBuffer) {
		this.xLength = xLength;
		this.yLength = yLength;
		this.zLength = zLength;

		switch (type) {
			case 'Uint8':
			case 'uint8':
			case 'uchar':
			case 'unsigned char':
			case 'uint8_t':
				this.data = new haxe.io.Bytes(arrayBuffer);
				break;
			case 'Int8':
			case 'int8':
			case 'signed char':
			case 'int8_t':
				this.data = new haxe.io.Bytes(arrayBuffer);
				break;
			case 'Int16':
			case 'int16':
			case 'short':
			case 'short int':
			case 'signed short':
			case 'signed short int':
			case 'int16_t':
				this.data = new haxe.io.Bytes(arrayBuffer);
				break;
			case 'Uint16':
			case 'uint16':
			case 'ushort':
			case 'unsigned short':
			case 'unsigned short int':
			case 'uint16_t':
				this.data = new haxe.io.Bytes(arrayBuffer);
				break;
			case 'Int32':
			case 'int32':
			case 'int':
			case 'signed int':
			case 'int32_t':
				this.data = new haxe.io.Bytes(arrayBuffer);
				break;
			case 'Uint32':
			case 'uint32':
			case 'uint':
			case 'unsigned int':
			case 'uint32_t':
				this.data = new haxe.io.Bytes(arrayBuffer);
				break;
			case 'longlong':
			case 'long long':
			case 'long long int':
			case 'signed long long':
			case 'signed long long int':
			case 'int64':
			case 'int64_t':
			case 'ulonglong':
			case 'unsigned long long':
			case 'unsigned long long int':
			case 'uint64':
			case 'uint64_t':
				throw new Error('Error in Volume constructor : this type is not supported in JavaScript');
				break;
			case 'Float32':
			case 'float32':
			case 'float':
				this.data = new haxe.io.Bytes(arrayBuffer);
				break;
			case 'Float64':
			case 'float64':
			case 'double':
				this.data = new haxe.io.Bytes(arrayBuffer);
				break;
			default:
				this.data = new haxe.io.Bytes(arrayBuffer);
		}

		if (this.data.length != this.xLength * this.yLength * this.zLength) {
			throw new Error('Error in Volume constructor, lengths are not matching arrayBuffer size');
		}

		this.matrix.identity();
		this.inverseMatrix = this.matrix.clone().invert();
		this.lowerThreshold = -Float.POSITIVE_INFINITY;
		this.upperThreshold = Float.POSITIVE_INFINITY;
	}

	/**
	 * @member {Function} getData Shortcut for data[access(i,j,k)]
	 * @memberof Volume
	 * @param {number} i    First coordinate
	 * @param {number} j    Second coordinate
	 * @param {number} k    Third coordinate
	 * @returns {number}  value in the data array
	 */
	public function getData(i:Int, j:Int, k:Int):Float {
		return this.data.getFloat(k * this.xLength * this.yLength + j * this.xLength + i);
	}

	/**
	 * @member {Function} access compute the index in the data array corresponding to the given coordinates in IJK system
	 * @memberof Volume
	 * @param {number} i    First coordinate
	 * @param {number} j    Second coordinate
	 * @param {number} k    Third coordinate
	 * @returns {number}  index
	 */
	public function access(i:Int, j:Int, k:Int):Int {
		return k * this.xLength * this.yLength + j * this.xLength + i;
	}

	/**
	 * @member {Function} reverseAccess Retrieve the IJK coordinates of the voxel corresponding of the given index in the data
	 * @memberof Volume
	 * @param {number} index index of the voxel
	 * @returns {Array}  [x,y,z]
	 */
	public function reverseAccess(index:Int):Array<Int> {
		var z = Math.floor(index / (this.yLength * this.xLength));
		var y = Math.floor((index - z * this.yLength * this.xLength) / this.xLength);
		var x = index - z * this.yLength * this.xLength - y * this.xLength;
		return [x, y, z];
	}

	/**
	 * @member {Function} map Apply a function to all the voxels, be careful, the value will be replaced
	 * @memberof Volume
	 * @param {Function} functionToMap A function to apply to every voxel, will be called with the following parameters :
	 *                                 value of the voxel
	 *                                 index of the voxel
	 *                                 the data (TypedArray)
	 * @param {Object}   context    You can specify a context in which call the function, default if this Volume
	 * @returns {Volume}   this
	 */
	public function map(functionToMap:Dynamic, context:Dynamic = this):Volume {
		var length = this.data.length;
		for (var i = 0; i < length; i++) {
			this.data.setFloat(i, Reflect.callMethod(functionToMap, context, [this.data.getFloat(i), i, this.data]));
		}
		return this;
	}

	/**
	 * @member {Function} extractPerpendicularPlane Compute the orientation of the slice and returns all the information relative to the geometry such as sliceAccess, the plane matrix (orientation and position in RAS coordinate) and the dimensions of the plane in both coordinate system.
	 * @memberof Volume
	 * @param {string}            axis  the normal axis to the slice 'x' 'y' or 'z'
	 * @param {number}            index the index of the slice
	 * @returns {Object} an object containing all the usefull information on the geometry of the slice
	 */
	public function extractPerpendicularPlane(axis:String, RASIndex:Int):Dynamic {
		var firstSpacing:Float;
		var secondSpacing:Float;
		var positionOffset:Float;
		var IJKIndex:Vector3;

		var axisInIJK = new Vector3();
		var firstDirection = new Vector3();
		var secondDirection = new Vector3();
		var planeMatrix = new Matrix4();
		planeMatrix.identity();
		var volume = this;

		var dimensions = new Vector3(this.xLength, this.yLength, this.zLength);


		switch (axis) {
			case 'x':
				axisInIJK.set(1, 0, 0);
				firstDirection.set(0, 0, -1);
				secondDirection.set(0, -1, 0);
				firstSpacing = this.spacing[this.axisOrder.indexOf('z')];
				secondSpacing = this.spacing[this.axisOrder.indexOf('y')];
				IJKIndex = new Vector3(RASIndex, 0, 0);

				planeMatrix.multiply(new Matrix4().makeRotationY(Math.PI / 2));
				positionOffset = (volume.RASDimensions[0] - 1) / 2;
				planeMatrix.setPosition(new Vector3(RASIndex - positionOffset, 0, 0));
				break;
			case 'y':
				axisInIJK.set(0, 1, 0);
				firstDirection.set(1, 0, 0);
				secondDirection.set(0, 0, 1);
				firstSpacing = this.spacing[this.axisOrder.indexOf('x')];
				secondSpacing = this.spacing[this.axisOrder.indexOf('z')];
				IJKIndex = new Vector3(0, RASIndex, 0);

				planeMatrix.multiply(new Matrix4().makeRotationX(-Math.PI / 2));
				positionOffset = (volume.RASDimensions[1] - 1) / 2;
				planeMatrix.setPosition(new Vector3(0, RASIndex - positionOffset, 0));
				break;
			case 'z':
			default:
				axisInIJK.set(0, 0, 1);
				firstDirection.set(1, 0, 0);
				secondDirection.set(0, -1, 0);
				firstSpacing = this.spacing[this.axisOrder.indexOf('x')];
				secondSpacing = this.spacing[this.axisOrder.indexOf('y')];
				IJKIndex = new Vector3(0, 0, RASIndex);

				positionOffset = (volume.RASDimensions[2] - 1) / 2;
				planeMatrix.setPosition(new Vector3(0, 0, RASIndex - positionOffset));
				break;
		}

		if (!this.segmentation) {
			firstDirection.applyMatrix4(volume.inverseMatrix).normalize();
			secondDirection.applyMatrix4(volume.inverseMatrix).normalize();
			axisInIJK.applyMatrix4(volume.inverseMatrix).normalize();
		}

		firstDirection.arglet = 'i';
		secondDirection.arglet = 'j';
		var iLength = Math.floor(Math.abs(firstDirection.dot(dimensions)));
		var jLength = Math.floor(Math.abs(secondDirection.dot(dimensions)));
		var planeWidth = Math.abs(iLength * firstSpacing);
		var planeHeight = Math.abs(jLength * secondSpacing);

		IJKIndex = Math.abs(Math.round(IJKIndex.applyMatrix4(volume.inverseMatrix).dot(axisInIJK)));
		var base = [new Vector3(1, 0, 0), new Vector3(0, 1, 0), new Vector3(0, 0, 1)];
		var iDirection = [firstDirection, secondDirection, axisInIJK].find(function(x) {
			return Math.abs(x.dot(base[0])) > 0.9;
		});
		var jDirection = [firstDirection, secondDirection, axisInIJK].find(function(x) {
			return Math.abs(x.dot(base[1])) > 0.9;
		});
		var kDirection = [firstDirection, secondDirection, axisInIJK].find(function(x) {
			return Math.abs(x.dot(base[2])) > 0.9;
		});

		function sliceAccess(i:Int, j:Int):Int {
			var si = (iDirection == axisInIJK) ? IJKIndex : (iDirection.arglet == 'i' ? i : j);
			var sj = (jDirection == axisInIJK) ? IJKIndex : (jDirection.arglet == 'i' ? i : j);
			var sk = (kDirection == axisInIJK) ? IJKIndex : (kDirection.arglet == 'i' ? i : j);

			// invert indices if necessary

			var accessI = (iDirection.dot(base[0]) > 0) ? si : (volume.xLength - 1) - si;
			var accessJ = (jDirection.dot(base[1]) > 0) ? sj : (volume.yLength - 1) - sj;
			var accessK = (kDirection.dot(base[2]) > 0) ? sk : (volume.zLength - 1) - sk;

			return volume.access(accessI, accessJ, accessK);
		}

		return {
			iLength: iLength,
			jLength: jLength,
			sliceAccess: sliceAccess,
			matrix: planeMatrix,
			planeWidth: planeWidth,
			planeHeight: planeHeight
		};
	}

	/**
	 * @member {Function} extractSlice Returns a slice corresponding to the given axis and index
	 *                        The coordinate are given in the Right Anterior Superior coordinate format
	 * @memberof Volume
	 * @param {string}            axis  the normal axis to the slice 'x' 'y' or 'z'
	 * @param {number}            index the index of the slice
	 * @returns {VolumeSlice} the extracted slice
	 */
	public function extractSlice(axis:String, index:Int):VolumeSlice {
		var slice = new VolumeSlice(this, index, axis);
		this.sliceList.push(slice);
		return slice;
	}

	/**
	 * @member {Function} repaintAllSlices Call repaint on all the slices extracted from this volume
	 * @see VolumeSlice.repaint
	 * @memberof Volume
	 * @returns {Volume} this
	 */
	public function repaintAllSlices():Volume {
		this.sliceList.forEach(function(slice) {
			slice.repaint();
		});
		return this;
	}

	/**
	 * @member {Function} computeMinMax Compute the minimum and the maximum of the data in the volume
	 * @memberof Volume
	 * @returns {Array} [min,max]
	 */
	public function computeMinMax():Array<Float> {
		var min = Float.POSITIVE_INFINITY;
		var max = -Float.POSITIVE_INFINITY;

		// buffer the length
		var datasize = this.data.length;

		var i = 0;

		for (i = 0; i < datasize; i++) {
			if (!Math.isNaN(this.data.getFloat(i))) {
				var value = this.data.getFloat(i);
				min = Math.min(min, value);
				max = Math.max(max, value);
			}
		}

		this.min = min;
		this.max = max;

		return [min, max];
	}

}