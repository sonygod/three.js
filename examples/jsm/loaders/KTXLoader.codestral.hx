import three.CompressedTextureLoader;

class KTXLoader extends CompressedTextureLoader {

    public function new(manager:any) {
        super(manager);
    }

    public function parse(buffer:haxe.io.Bytes, loadMipmaps:Bool):Dynamic {
        var ktx = new KhronosTextureContainer(buffer, 1);

        return {
            'mipmaps': ktx.mipmaps(loadMipmaps),
            'width': ktx.pixelWidth,
            'height': ktx.pixelHeight,
            'format': ktx.glInternalFormat,
            'isCubemap': ktx.numberOfFaces === 6,
            'mipmapCount': ktx.numberOfMipmapLevels
        };
    }
}

class KhronosTextureContainer {
    private var arrayBuffer:haxe.io.Bytes;
    public var glInternalFormat:Int;
    public var pixelWidth:Int;
    public var pixelHeight:Int;
    public var numberOfFaces:Int;
    public var numberOfMipmapLevels:Int;
    private var bytesOfKeyValueData:Int;

    public function new(arrayBuffer:haxe.io.Bytes, facesExpected:Int) {
        this.arrayBuffer = arrayBuffer;

        if (!this.validateHeader()) {
            return;
        }

        var dataSize = 4;
        var headerDataView = new haxe.io.BytesInput(this.arrayBuffer.sub(12, 13 * dataSize));
        var littleEndian = this.isLittleEndian(headerDataView);

        this.glInternalFormat = this.readUint32(headerDataView, 4 * dataSize, littleEndian);
        this.pixelWidth = this.readUint32(headerDataView, 6 * dataSize, littleEndian);
        this.pixelHeight = this.readUint32(headerDataView, 7 * dataSize, littleEndian);
        this.numberOfFaces = this.readUint32(headerDataView, 10 * dataSize, littleEndian);
        this.numberOfMipmapLevels = this.readUint32(headerDataView, 11 * dataSize, littleEndian);
        this.bytesOfKeyValueData = this.readUint32(headerDataView, 12 * dataSize, littleEndian);

        this.numberOfMipmapLevels = Math.max(1, this.numberOfMipmapLevels);
    }

    private function validateHeader():Bool {
        var identifier = this.arrayBuffer.sub(0, 12);

        if (identifier.get(0) !== 0xAB ||
            identifier.get(1) !== 0x4B ||
            identifier.get(2) !== 0x54 ||
            identifier.get(3) !== 0x58 ||
            identifier.get(4) !== 0x20 ||
            identifier.get(5) !== 0x31 ||
            identifier.get(6) !== 0x31 ||
            identifier.get(7) !== 0xBB ||
            identifier.get(8) !== 0x0D ||
            identifier.get(9) !== 0x0A ||
            identifier.get(10) !== 0x1A ||
            identifier.get(11) !== 0x0A) {

            haxe.Log.trace('texture missing KTX identifier');
            return false;
        }

        return true;
    }

    private function isLittleEndian(headerDataView:haxe.io.BytesInput):Bool {
        var endianness = headerDataView.readUInt32();
        return endianness === 0x04030201;
    }

    private function readUint32(headerDataView:haxe.io.BytesInput, offset:Int, littleEndian:Bool):Int {
        headerDataView.setPosition(offset);
        return headerDataView.readUInt32();
    }

    public function mipmaps(loadMipmaps:Bool):Array<Dynamic> {
        var mipmaps = [];

        var dataOffset = 12 + this.bytesOfKeyValueData;
        var width = this.pixelWidth;
        var height = this.pixelHeight;
        var mipmapCount = loadMipmaps ? this.numberOfMipmapLevels : 1;

        for (var level = 0; level < mipmapCount; level++) {
            var imageSize = this.arrayBuffer.getInt32(dataOffset);
            dataOffset += 4;

            for (var face = 0; face < this.numberOfFaces; face++) {
                var byteArray = this.arrayBuffer.sub(dataOffset, imageSize);

                mipmaps.push({ 'data': byteArray, 'width': width, 'height': height });

                dataOffset += imageSize;
                dataOffset += 3 - ((imageSize + 3) % 4);
            }

            width = Math.max(1, width * 0.5);
            height = Math.max(1, height * 0.5);
        }

        return mipmaps;
    }
}