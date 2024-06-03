import three.Matrix3;
import three.Matrix4;
import three.Vector3;
import VolumeSlice;

/**
 * This class had been written to handle the output of the NRRD loader.
 * It contains a volume of data and informations about it.
 * For now it only handles 3 dimensional data.
 */
class Volume {

    /**
     * @member {number} xLength Width of the volume in the IJK coordinate system
     */
    public var xLength: Int;
    /**
     * @member {number} yLength Height of the volume in the IJK coordinate system
     */
    public var yLength: Int;
    /**
     * @member {number} zLength Depth of the volume in the IJK coordinate system
     */
    public var zLength: Int;
    /**
     * @member {Array<string>} The order of the Axis dictated by the NRRD header
     */
    public var axisOrder: Array<String> = ['x', 'y', 'z'];
    /**
     * @member {Array<Dynamic>} Data of the volume
     */
    public var data: Array<Dynamic>;
    /**
     * @member {Array} spacing Spacing to apply to the volume from IJK to RAS coordinate system
     */
    public var spacing: Array<Float> = [1.0, 1.0, 1.0];
    /**
     * @member {Array} offset Offset of the volume in the RAS coordinate system
     */
    public var offset: Array<Float> = [0.0, 0.0, 0.0];
    /**
     * @member {Martrix3} matrix The IJK to RAS matrix
     */
    public var matrix: Matrix3 = new Matrix3();
    /**
     * @member {number} lowerThreshold The voxels with values under this threshold won't appear in the slices.
     */
    public var lowerThreshold: Float = -Float.POSITIVE_INFINITY;
    /**
     * @member {number} upperThreshold The voxels with values over this threshold won't appear in the slices.
     */
    public var upperThreshold: Float = Float.POSITIVE_INFINITY;
    /**
     * @member {Array} sliceList The list of all the slices associated to this volume
     */
    public var sliceList: Array<VolumeSlice> = [];
    /**
     * @member {boolean} segmentation in segmentation mode, it can load 16-bits nrrds correctly
     */
    public var segmentation: Bool = false;
    /**
     * @member {Array} RASDimensions This array holds the dimensions of the volume in the RAS space
     */
    public var RASDimensions: Array<Float>;

    public function new(xLength: Int, yLength: Int, zLength: Int, type: String, arrayBuffer: haxe.io.BytesBuffer) {
        this.xLength = xLength != null ? xLength : 1;
        this.yLength = yLength != null ? yLength : 1;
        this.zLength = zLength != null ? zLength : 1;

        switch (type) {
            case 'Uint8': case 'uint8': case 'uchar': case 'unsigned char': case 'uint8_t':
                this.data = arrayBuffer.getBytes();
                break;
            case 'Int8': case 'int8': case 'signed char': case 'int8_t':
                this.data = arrayBuffer.getBytes().map(function(byte) { return haxe.Int32.ofBytes(haxe.io.Bytes.ofString(String.fromCharCode(byte))); });
                break;
            case 'Int16': case 'int16': case 'short': case 'short int': case 'signed short': case 'signed short int': case 'int16_t':
                var bytes = arrayBuffer.getBytes();
                this.data = [];
                for (var i = 0; i < bytes.length; i += 2) {
                    this.data.push(haxe.Int32.ofBytes(haxe.io.Bytes.ofString(String.fromCharCode(bytes[i]) + String.fromCharCode(bytes[i + 1]))));
                }
                break;
            case 'Uint16': case 'uint16': case 'ushort': case 'unsigned short': case 'unsigned short int': case 'uint16_t':
                var bytes = arrayBuffer.getBytes();
                this.data = [];
                for (var i = 0; i < bytes.length; i += 2) {
                    this.data.push(haxe.UInt32.ofBytes(haxe.io.Bytes.ofString(String.fromCharCode(bytes[i]) + String.fromCharCode(bytes[i + 1]))));
                }
                break;
            case 'Int32': case 'int32': case 'int': case 'signed int': case 'int32_t':
                var bytes = arrayBuffer.getBytes();
                this.data = [];
                for (var i = 0; i < bytes.length; i += 4) {
                    this.data.push(haxe.Int32.ofBytes(haxe.io.Bytes.ofString(String.fromCharCode(bytes[i]) + String.fromCharCode(bytes[i + 1]) + String.fromCharCode(bytes[i + 2]) + String.fromCharCode(bytes[i + 3]))));
                }
                break;
            case 'Uint32': case 'uint32': case 'uint': case 'unsigned int': case 'uint32_t':
                var bytes = arrayBuffer.getBytes();
                this.data = [];
                for (var i = 0; i < bytes.length; i += 4) {
                    this.data.push(haxe.UInt32.ofBytes(haxe.io.Bytes.ofString(String.fromCharCode(bytes[i]) + String.fromCharCode(bytes[i + 1]) + String.fromCharCode(bytes[i + 2]) + String.fromCharCode(bytes[i + 3]))));
                }
                break;
            case 'longlong': case 'long long': case 'long long int': case 'signed long long': case 'signed long long int': case 'int64': case 'int64_t': case 'ulonglong': case 'unsigned long long': case 'unsigned long long int': case 'uint64': case 'uint64_t':
                throw new js.Error("Error in Volume constructor : this type is not supported in JavaScript");
            case 'Float32': case 'float32': case 'float':
                var bytes = arrayBuffer.getBytes();
                this.data = [];
                for (var i = 0; i < bytes.length; i += 4) {
                    this.data.push(haxe.Lang.instanceField(haxe.io.Bytes.ofString(String.fromCharCode(bytes[i]) + String.fromCharCode(bytes[i + 1]) + String.fromCharCode(bytes[i + 2]) + String.fromCharCode(bytes[i + 3])), 'getFloat32'));
                }
                break;
            case 'Float64': case 'float64': case 'double':
                var bytes = arrayBuffer.getBytes();
                this.data = [];
                for (var i = 0; i < bytes.length; i += 8) {
                    this.data.push(haxe.Lang.instanceField(haxe.io.Bytes.ofString(String.fromCharCode(bytes[i]) + String.fromCharCode(bytes[i + 1]) + String.fromCharCode(bytes[i + 2]) + String.fromCharCode(bytes[i + 3]) + String.fromCharCode(bytes[i + 4]) + String.fromCharCode(bytes[i + 5]) + String.fromCharCode(bytes[i + 6]) + String.fromCharCode(bytes[i + 7])), 'getDouble'));
                }
                break;
            default:
                this.data = arrayBuffer.getBytes();
        }

        if (this.data.length != this.xLength * this.yLength * this.zLength) {
            throw new js.Error("Error in Volume constructor, lengths are not matching arrayBuffer size");
        }

        this.matrix.identity();
    }

    /**
     * @member {Function} getData Shortcut for data[access(i,j,k)]
     * @param {number} i    First coordinate
     * @param {number} j    Second coordinate
     * @param {number} k    Third coordinate
     * @returns {number}  value in the data array
     */
    public function getData(i: Int, j: Int, k: Int): Dynamic {
        return this.data[k * this.xLength * this.yLength + j * this.xLength + i];
    }

    // Other methods...
}