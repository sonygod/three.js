import three.Matrix3;
import three.Matrix4;
import three.Vector3;
import misc.VolumeSlice;

class Volume {

    public var xLength(default, null):Float;
    public var yLength(default, null):Float;
    public var zLength(default, null):Float;
    public var axisOrder(default, null):Array<String>;
    public var data(default, null):haxe.io.Bytes;
    public var spacing(default, null):Array<Float>;
    public var offset(default, null):Array<Float>;
    public var matrix(default, null):Matrix3;
    public var inverseMatrix(default, null):Matrix3;
    public var lowerThreshold(default, null):Float;
    public var upperThreshold(default, null):Float;
    public var sliceList(default, null):Array<VolumeSlice>;
    public var segmentation(default, null):Bool;
    public var RASDimensions(default, null):Array<Float>;

    public function new(xLength:Float, yLength:Float, zLength:Float, type:String, arrayBuffer:haxe.io.Bytes) {
        if (xLength !== undefined) {
            this.xLength = xLength;
            this.yLength = yLength;
            this.zLength = zLength;
            this.axisOrder = ['x', 'y', 'z'];
            switch (type) {
                case 'Uint8':
                case 'uint8':
                case 'uchar':
                case 'unsigned char':
                case 'uint8_t':
                    this.data = new haxe.io.Bytes(arrayBuffer.b, arrayBuffer.pos, arrayBuffer.length);
                    break;
                case 'Int8':
                case 'int8':
                case 'signed char':
                case 'int8_t':
                    this.data = new haxe.io.Bytes(arrayBuffer.b, arrayBuffer.pos, arrayBuffer.length);
                    break;
                case 'Int16':
                case 'int16':
                case 'short':
                case 'short int':
                case 'signed short':
                case 'signed short int':
                case 'int16_t':
                    this.data = new haxe.io.Bytes(arrayBuffer.b, arrayBuffer.pos, arrayBuffer.length);
                    break;
                case 'Uint16':
                case 'uint16':
                case 'ushort':
                case 'unsigned short':
                case 'unsigned short int':
                case 'uint16_t':
                    this.data = new haxe.io.Bytes(arrayBuffer.b, arrayBuffer.pos, arrayBuffer.length);
                    break;
                case 'Int32':
                case 'int32':
                case 'int':
                case 'signed int':
                case 'int32_t':
                    this.data = new haxe.io.Bytes(arrayBuffer.b, arrayBuffer.pos, arrayBuffer.length);
                    break;
                case 'Uint32':
                case 'uint32':
                case 'uint':
                case 'unsigned int':
                case 'uint32_t':
                    this.data = new haxe.io.Bytes(arrayBuffer.b, arrayBuffer.pos, arrayBuffer.length);
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
                    throw 'Error in Volume constructor : this type is not supported in JavaScript';
                    break;
                case 'Float32':
                case 'float32':
                case 'float':
                    this.data = new haxe.io.Bytes(arrayBuffer.b, arrayBuffer.pos, arrayBuffer.length);
                    break;
                case 'Float64':
                case 'float64':
                case 'double':
                    this.data = new haxe.io.Bytes(arrayBuffer.b, arrayBuffer.pos, arrayBuffer.length);
                    break;
                default:
                    this.data = new haxe.io.Bytes(arrayBuffer.b, arrayBuffer.pos, arrayBuffer.length);
            }
            if (this.data.length !== this.xLength * this.yLength * this.zLength) {
                throw 'Error in Volume constructor, lengths are not matching arrayBuffer size';
            }
        }
        this.spacing = [1, 1, 1];
        this.offset = [0, 0, 0];
        this.matrix = new Matrix3();
        this.matrix.identity();
        this.sliceList = [];
        this.segmentation = false;
    }

    public function getData(i:Int, j:Int, k:Int):Float {
        return this.data.getFloat(k * this.xLength * this.yLength + j * this.xLength + i);
    }

    public function access(i:Int, j:Int, k:Int):Int {
        return k * this.xLength * this.yLength + j * this.xLength + i;
    }

    public function reverseAccess(index:Int):Array<Int> {
        var z = Math.floor(index / (this.yLength * this.xLength));
        var y = Math.floor((index - z * this.yLength * this.xLength) / this.xLength);
        var x = index - z * this.yLength * this.xLength - y * this.xLength;
        return [x, y, z];
    }

    public function map(functionToMap:Dynamic->Float, context:Dynamic):Volume {
        var length = this.data.length;
        context = context || this;
        for (i in 0...length) {
            this.data.setFloat(i, functionToMap.call(context, this.data.getFloat(i), i, this.data));
        }
        return this;
    }

    public function extractPerpendicularPlane(axis:String, RASIndex:Float):Dynamic {
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
            var si = (iDirection === axisInIJK) ? IJKIndex : (iDirection.arglet === 'i' ? i : j);
            var sj = (jDirection === axisInIJK) ? IJKIndex : (jDirection.arglet === 'i' ? i : j);
            var sk = (kDirection === axisInIJK) ? IJKIndex : (kDirection.arglet === 'i' ? i : j);
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

    public function extractSlice(axis:String, index:Float):VolumeSlice {
        var slice = new VolumeSlice(this, index, axis);
        this.sliceList.push(slice);
        return slice;
    }

    public function repaintAllSlices():Volume {
        this.sliceList.forEach(function(slice) {
            slice.repaint();
        });
        return this;
    }

    public function computeMinMax():Array<Float> {
        var min = Infinity;
        var max = -Infinity;
        var datasize = this.data.length;
        for (i in 0...datasize) {
            if (!isNaN(this.data.getFloat(i))) {
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