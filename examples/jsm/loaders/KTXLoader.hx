package three.js.examples.jml.loaders;

import three.js.loaders.CompressedTextureLoader;

/**
 * for description see https://www.khronos.org/opengles/sdk/tools/KTX/
 * for file layout see https://www.khronos.org/opengles/sdk/tools/KTX/file_format_spec/
 *
 * ported from https://github.com/BabylonJS/Babylon.js/blob/master/src/Misc/khronosTextureContainer.ts
 */

class KTXLoader extends CompressedTextureLoader {

    public function new(manager:Dynamic) {
        super(manager);
    }

    public function parse(buffer:ByteArray, loadMipmaps:Bool):Dynamic {
        var ktx:KhronosTextureContainer = new KhronosTextureContainer(buffer, 1);
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

// load types
private inline static var COMPRESSED_2D:Int = 0; // uses a gl.compressedTexImage2D()
//private inline static var COMPRESSED_3D:Int = 1; // uses a gl.compressedTexImage3D()
//private inline static var TEX_2D:Int = 2; // uses a gl.texImage2D()
//private inline static var TEX_3D:Int = 3; // uses a gl.texImage3D()

class KhronosTextureContainer {

    private var arrayBuffer:ByteArray;

    public function new(arrayBuffer:ByteArray, facesExpected:Int /*, threeDExpected:Bool, textureArrayExpected:Bool */) {
        this.arrayBuffer = arrayBuffer;

        // Test that it is a ktx formatted file, based on the first 12 bytes, character representation is:
        // '', 'K', 'T', 'X', ' ', '1', '1', '', '\r', '\n', '\x1A', '\n'
        // 0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A
        var identifier:ByteArray = new ByteArray();
        identifier.writeBytes(arrayBuffer, 0, 12);
        if (identifier[0] != 0xAB ||
            identifier[1] != 0x4B ||
            identifier[2] != 0x54 ||
            identifier[3] != 0x58 ||
            identifier[4] != 0x20 ||
            identifier[5] != 0x31 ||
            identifier[6] != 0x31 ||
            identifier[7] != 0xBB ||
            identifier[8] != 0x0D ||
            identifier[9] != 0x0A ||
            identifier[10] != 0x1A ||
            identifier[11] != 0x0A) {
            Console.error("texture missing KTX identifier");
            return;
        }

        // load the reset of the header in native 32 bit uint
        var dataSize:Int = 4; // Uint32Array.BYTES_PER_ELEMENT
        var headerDataView:DataView = new DataView(arrayBuffer, 12, 13 * dataSize);
        var endianness:Int = headerDataView.getUint32(0, true);
        var littleEndian:Bool = endianness == 0x04030201;

        this.glType = headerDataView.getUint32(1 * dataSize, littleEndian); // must be 0 for compressed textures
        this.glTypeSize = headerDataView.getUint32(2 * dataSize, littleEndian); // must be 1 for compressed textures
        this.glFormat = headerDataView.getUint32(3 * dataSize, littleEndian); // must be 0 for compressed textures
        this.glInternalFormat = headerDataView.getUint32(4 * dataSize, littleEndian); // the value of arg passed to gl.compressedTexImage2D(,,x,,,,)
        this.glBaseInternalFormat = headerDataView.getUint32(5 * dataSize, littleEndian); // specify GL_RGB, GL_RGBA, GL_ALPHA, etc (un-compressed only)
        this.pixelWidth = headerDataView.getUint32(6 * dataSize, littleEndian); // level 0 value of arg passed to gl.compressedTexImage2D(,,,x,,)
        this.pixelHeight = headerDataView.getUint32(7 * dataSize, littleEndian); // level 0 value of arg passed to gl.compressedTexImage2D(,,,,x,,)
        this.pixelDepth = headerDataView.getUint32(8 * dataSize, littleEndian); // level 0 value of arg passed to gl.compressedTexImage3D(,,,,,x,,)
        this.numberOfArrayElements = headerDataView.getUint32(9 * dataSize, littleEndian); // used for texture arrays
        this.numberOfFaces = headerDataView.getUint32(10 * dataSize, littleEndian); // used for cubemap textures, should either be 1 or 6
        this.numberOfMipmapLevels = headerDataView.getUint32(11 * dataSize, littleEndian); // number of levels; disregard possibility of 0 for compressed textures
        this.bytesOfKeyValueData = headerDataView.getUint32(12 * dataSize, littleEndian); // the amount of space after the header for meta-data

        // Make sure we have a compressed type.  Not only reduces work, but probably better to let dev know they are not compressing.
        if (this.glType != 0) {
            Console.warn("only compressed formats currently supported");
            return;
        } else {
            // value of zero is an indication to generate mipmaps @ runtime.  Not usually allowed for compressed, so disregard.
            this.numberOfMipmapLevels = Math.max(1, this.numberOfMipmapLevels);
        }

        if (this.pixelHeight == 0 || this.pixelDepth != 0) {
            Console.warn("only 2D textures currently supported");
            return;
        }

        if (this.numberOfArrayElements != 0) {
            Console.warn("texture arrays not currently supported");
            return;
        }

        if (this.numberOfFaces != facesExpected) {
            Console.warn("number of faces expected " + facesExpected + ", but found " + this.numberOfFaces);
            return;
        }

        // we now have a completely validated file, so could use existence of loadType as success
        // would need to make this more elaborate & adjust checks above to support more than one load type
        this.loadType = COMPRESSED_2D;
    }

    public function mipmaps(loadMipmaps:Bool):Array<Dynamic> {
        var mipmaps:Array<Dynamic> = [];

        // initialize width & height for level 1
        var dataOffset:Int = HEADER_LEN + this.bytesOfKeyValueData;
        var width:Int = this.pixelWidth;
        var height:Int = this.pixelHeight;
        var mipmapCount:Int = loadMipmaps ? this.numberOfMipmapLevels : 1;

        for (level in 0...mipmapCount) {
            var imageSize:Int = new Int32Array(arrayBuffer, dataOffset, 1)[0]; // size per face, since not supporting array cubemaps
            dataOffset += 4; // size of the image + 4 for the imageSize field

            for (face in 0...this.numberOfFaces) {
                var byteArray:ByteArray = new ByteArray();
                byteArray.writeBytes(arrayBuffer, dataOffset, imageSize);

                mipmaps.push({
                    data: byteArray,
                    width: width,
                    height: height
                });

                dataOffset += imageSize;
                dataOffset += 3 - ((imageSize + 3) % 4); // add padding for odd sized image
            }

            width = Math.max(1, width * 0.5);
            height = Math.max(1, height * 0.5);
        }

        return mipmaps;
    }
}