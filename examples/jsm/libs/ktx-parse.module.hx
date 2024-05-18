package ktx;

class Si {
    public var vkFormat:Int;
    public var typeSize:Int;
    public var pixelWidth:Int;
    public var pixelHeight:Int;
    public var pixelDepth:Int;
    public var layerCount:Int;
    public var faceCount:Int;
    public var supercompressionScheme:Int;
    public var levels:Array<{levelData:Bytes, uncompressedByteLength:Int}>;
    public var dataFormatDescriptor:Array<{vendorId:Int, descriptorType:Int, versionNumber:Int, colorModel:Int, colorPrimaries:Int, transferFunction:Int, flags:Int, texelBlockDimension:Array<Int>, bytesPlane:Array<Int>, samples:Array<{bitOffset:Int, bitLength:Int, channelType:Int, samplePosition:Array<Int>, sampleLower:Float, sampleUpper:Float>}>;
    public var keyValue:Map<String, Bytes>;

    public function new() {
        this.levels = new Array();
        this.dataFormatDescriptor = new Array();
    }
}

class Ii {
    private var dataView:BytesData;
    private var littleEndian:Bool;
    private var offset:Int;

    public function new(buffer:Bytes, byteOffset:Int, byteLength:Int, littleEndian:Bool) {
        this.dataView = new BytesData(buffer, byteOffset, byteLength);
        this.littleEndian = littleEndian;
        this.offset = 0;
    }

    public function nextUint8():Int {
        var result = this.dataView.getUint8(this.offset);
        this.offset += 1;
        return result;
    }

    public function nextUint16():Int {
        var result = this.dataView.getUint16(this.offset, this.littleEndian);
        this.offset += 2;
        return result;
    }

    public function nextUint32():Int {
        var result = this.dataView.getUint32(this.offset, this.littleEndian);
        this.offset += 4;
        return result;
    }

    public function nextUint64():Float {
        var low = this.dataView.getUint32(this.offset, this.littleEndian);
        var high = this.dataView.getUint32(this.offset + 4, this.littleEndian);
        this.offset += 8;
        return low + Math.pow(2, 32) * high;
    }

    public function nextInt32():Int {
        var result = this.dataView.getInt32(this.offset, this.littleEndian);
        this.offset += 4;
        return result;
    }

    public function skip(bytes:Int) {
        this.offset += bytes;
    }

    public function scan(delimiter:Int, maxLength:Int = 0x7fffffff):Bytes {
        var startPosition = this.offset;
        while (this.offset < maxLength && this.dataView.getUint8(this.offset) != delimiter) {
            this.offset++;
        }
        return Bytes.ofString(this.dataView.getString(startPosition, this.offset));
    }
}

class Oi {
    public static var bytes:Bytes = Bytes.ofString("");
}

class Ti {
    public static var bytes:Array<Int> = [171, 75, 84, 88, 32, 50, 48, 187, 13, 10, 26, 10];
}

function Vi(str:String):Bytes {
    return Bytes.ofString(str);
}

function Ei(bytes:Bytes):String {
    return bytes.toString();
}

function Fi(arrays:Array<Bytes>):Bytes {
    var length = 0;
    for (array in arrays) {
        length += array.length;
    }
    var result = Bytes.alloc(length);
    var offset = 0;
    for (array in arrays) {
        result.blit(offset, array, 0, array.length);
        offset += array.length;
    }
    return result;
}

function Pi(data:Si):Bytes {
    // TO DO: Implement Pi function
    throw "Not implemented";
}

// ... Other functions and classes