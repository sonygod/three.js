package three.js.loaders;

import three.js.loaders.CompressedTextureLoader;

class KTXLoader extends CompressedTextureLoader {
    public function new(manager:Dynamic) {
        super(manager);
    }

    public function parse(buffer:hx.Bytes, loadMipmaps:Bool) {
        var ktx = new KhronosTextureContainer(buffer, 1);
        return {
            mipmaps: ktx.getMipmaps(loadMipmaps),
            width: ktx.pixelWidth,
            height: ktx.pixelHeight,
            format: ktx.glInternalFormat,
            isCubemap: ktx.numberOfFaces == 6,
            mipmapCount: ktx.numberOfMipmapLevels
        };
    }
}

class KhronosTextureContainer {
    private var arrayBuffer:hx.Bytes;

    public function new(arrayBuffer:hx.Bytes, facesExpected:Int) {
        this.arrayBuffer = arrayBuffer;

        // Check KTX identifier
        var identifier = new hx.ByteBuffer( arrayBuffer, 0, 12 );
        if (identifier.get(0) != 0xAB || identifier.get(1) != 0x4B || identifier.get(2) != 0x54 || identifier.get(3) != 0x58 ||
            identifier.get(4) != 0x20 || identifier.get(5) != 0x31 || identifier.get(6) != 0x31 || identifier.get(7) != 0xBB ||
            identifier.get(8) != 0x0D || identifier.get(9) != 0x0A || identifier.get(10) != 0x1A || identifier.get(11) != 0x0A) {
            trace("texture missing KTX identifier");
            return;
        }

        // Load header
        var headerDataView = new hx.ByteBuffer( arrayBuffer, 12, 13 * 4 );
        var endianness = headerDataView.getUInt32(0, true);
        var littleEndian = endianness == 0x04030201;

        glType = headerDataView.getUInt32(1 * 4, littleEndian); // must be 0 for compressed textures
        glTypeSize = headerDataView.getUInt32(2 * 4, littleEndian); // must be 1 for compressed textures
        glFormat = headerDataView.getUInt32(3 * 4, littleEndian); // must be 0 for compressed textures
        glInternalFormat = headerDataView.getUInt32(4 * 4, littleEndian); // the value of arg passed to gl.compressedTexImage2D(,,x,,,,)
        glBaseInternalFormat = headerDataView.getUInt32(5 * 4, littleEndian); // specify GL_RGB, GL_RGBA, GL_ALPHA, etc (un-compressed only)
        pixelWidth = headerDataView.getUInt32(6 * 4, littleEndian); // level 0 value of arg passed to gl.compressedTexImage2D(,,,x,,,)
        pixelHeight = headerDataView.getUInt32(7 * 4, littleEndian); // level 0 value of arg passed to gl.compressedTexImage2D(,,,,x,,)
        pixelDepth = headerDataView.getUInt32(8 * 4, littleEndian); // level 0 value of arg passed to gl.compressedTexImage3D(,,,,,x,,)
        numberOfArrayElements = headerDataView.getUInt32(9 * 4, littleEndian); // used for texture arrays
        numberOfFaces = headerDataView.getUInt32(10 * 4, littleEndian); // used for cubemap textures, should either be 1 or 6
        numberOfMipmapLevels = headerDataView.getUInt32(11 * 4, littleEndian); // number of levels; disregard possibility of 0 for compressed textures
        bytesOfKeyValueData = headerDataView.getUInt32(12 * 4, littleEndian); // the amount of space after the header for meta-data

        // Check compressed type
        if (glType != 0) {
            trace("only compressed formats currently supported");
            return;
        }

        // Check 2D texture
        if (pixelHeight == 0 || pixelDepth != 0) {
            trace("only 2D textures currently supported");
            return;
        }

        // Check texture array
        if (numberOfArrayElements != 0) {
            trace("texture arrays not currently supported");
            return;
        }

        // Check number of faces
        if (numberOfFaces != facesExpected) {
            trace("number of faces expected " + facesExpected + ", but found " + numberOfFaces);
            return;
        }

        loadType = COMPRESSED_2D;
    }

    public function getMipmaps(loadMipmaps:Bool) {
        var mipmaps = new Array();

        // Initialize width & height for level 1
        var dataOffset = HEADER_LEN + bytesOfKeyValueData;
        var width = pixelWidth;
        var height = pixelHeight;
        var mipmapCount = loadMipmaps ? numberOfMipmapLevels : 1;

        for (level in 0...mipmapCount) {
            var imageSize = new hx.Int32Array(arrayBuffer, dataOffset, 1)[0]; // size per face, since not supporting array cubemaps
            dataOffset += 4; // size of the image + 4 for the imageSize field

            for (face in 0...numberOfFaces) {
                var byteArray = new hx.Uint8Array(arrayBuffer, dataOffset, imageSize);

                mipmaps.push({ data: byteArray, width: width, height: height });

                dataOffset += imageSize;
                dataOffset += 3 - ((imageSize + 3) % 4); // add padding for odd sized image
            }

            width = Math.max(1.0, width * 0.5);
            height = Math.max(1.0, height * 0.5);
        }

        return mipmaps;
    }
}

// Constants
static var HEADER_LEN = 12 + (13 * 4); // identifier + header elements (not including key value meta-data pairs)
static var COMPRESSED_2D = 0; // uses a gl.compressedTexImage2D()