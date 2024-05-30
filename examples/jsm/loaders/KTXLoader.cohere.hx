import haxe.io.Bytes;

class KTXLoader {
    public function new() {

    }

    public function parse(buffer: Bytes, loadMipmaps: Bool): Void {
        var ktx = new KhronosTextureContainer(buffer, 1);

        return {
            mipmaps: ktx.mipmaps(loadMipmaps),
            width: ktx.pixelWidth,
            height: ktx.pixelHeight,
            format: ktx.glInternalFormat,
            isCubemap: ktx.numberOfFaces == 6,
            mipmapCount: ktx.numberOfMipmapLevels
        };
    }
}

class KhronosTextureContainer {
    public var arrayBuffer: Bytes;
    public var glType: Int;
    public var glTypeSize: Int;
    public var glFormat: Int;
    public var glInternalFormat: Int;
    public var glBaseInternalFormat: Int;
    public var pixelWidth: Int;
    public var pixelHeight: Int;
    public var pixelDepth: Int;
    public var numberOfArrayElements: Int;
    public var numberOfFaces: Int;
    public var numberOfMipmapLevels: Int;
    public var bytesOfKeyValueData: Int;
    public var loadType: Int;

    public function new(arrayBuffer: Bytes, facesExpected: Int) {
        this.arrayBuffer = arrayBuffer;

        // Test that it is a ktx formatted file
        var identifier = arrayBuffer.getBytes(0, 12);
        if (identifier != [0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A]) {
            trace("texture missing KTX identifier");
            return;
        }

        // Load the rest of the header
        var headerDataView = arrayBuffer.getDataView();
        var endianness = headerDataView.getInt32(0, true);
        var littleEndian = endianness == 0x04030201;

        this.glType = headerDataView.getInt32(4, littleEndian);
        this.glTypeSize = headerDataView.getInt32(8, littleEndian);
        this.glFormat = headerDataView.getInt32(12, littleEndian);
        this.glInternalFormat = headerDataView.getInt32(16, littleEndian);
        this.glBaseInternalFormat = headerDataView.getInt32(20, littleEndian);
        this.pixelWidth = headerDataView.getInt32(24, littleEndian);
        this.pixelHeight = headerDataView.getInt32(28, littleEndian);
        this.pixelDepth = headerDataView.getInt32(32, littleEndian);
        this.numberOfArrayElements = headerDataView.getInt32(36, littleEndian);
        this.numberOfFaces = headerDataView.getInt32(40, littleEndian);
        this.numberOfMipmapLevels = headerDataView.getInt32(44, littleEndian);
        this.bytesOfKeyValueData = headerDataView.getInt32(48, littleEndian);

        // Validate and set load type
        if (this.glType != 0) {
            trace("only compressed formats currently supported");
            return;
        }

        this.numberOfMipmapLevels = max(1, this.numberOfMipmapLevels);

        if (this.pixelHeight == 0 || this.pixelDepth != 0) {
            trace("only 2D textures currently supported");
            return;
        }

        if (this.numberOfArrayElements != 0) {
            trace("texture arrays not currently supported");
            return;
        }

        if (this.numberOfFaces != facesExpected) {
            trace("number of faces expected: $facesExpected, but found: $this.numberOfFaces");
            return;
        }

        this.loadType = COMPRESSED_2D;
    }

    public function mipmaps(loadMipmaps: Bool): Array<Map<String, Dynamic>> {
        var mipmaps = [];

        var dataOffset = HEADER_LEN + this.bytesOfKeyValueData;
        var width = this.pixelWidth;
        var height = this.pixelHeight;
        var mipmapCount = loadMipmaps ? this.numberOfMipmapLevels : 1;

        for (level in 0...mipmapCount) {
            var imageSize = arrayBuffer.getInt32(dataOffset);
            dataOffset += 4;

            for (face in 0...this.numberOfFaces) {
                var byteArray = arrayBuffer.getBytes(dataOffset, imageSize);

                mipmaps.push({
                    'data': byteArray,
                    'width': width,
                    'height': height
                });

                dataOffset += imageSize;
                dataOffset += 3 - ((imageSize + 3) % 4);
            }

            width = max(1, width / 2);
            height = max(1, height / 2);
        }

        return mipmaps;
    }
}

class KTXConstants {
    static var COMPRESSED_2D: Int = 0;
}