package three.js.loaders;

import three.DataTextureLoader;
import three.DataUtils;
import three.FloatType;
import three.HalfFloatType;
import three.LinearFilter;
import three.LinearSRGBColorSpace;

class RGBELoader extends DataTextureLoader {
    public var type:FloatType;

    public function new(manager:Dynamic) {
        super(manager);
        this.type = HalfFloatType;
    }

    public function parse(buffer:ByteArray):Dynamic {
        var rgbe_read_error:Int = 1;
        var rgbe_write_error:Int = 2;
        var rgbe_format_error:Int = 3;
        var rgbe_memory_error:Int = 4;

        var rgbe_error = function(code:Int, msg:String) {
            switch (code) {
                case rgbe_read_error:
                    throw new Error('THREE.RGBELoader: Read Error: ' + (msg || ''));
                case rgbe_write_error:
                    throw new Error('THREE.RGBELoader: Write Error: ' + (msg || ''));
                case rgbe_format_error:
                    throw new Error('THREE.RGBELoader: Bad File Format: ' + (msg || ''));
                default:
                case rgbe_memory_error:
                    throw new Error('THREE.RGBELoader: Memory Error: ' + (msg || ''));
            }
        };

        // ... (rest of the code remains the same)

        // ... (fgets function remains the same)

        // ... (RGBE_ReadHeader function remains the same)

        // ... (RGBE_ReadPixels_RLE function remains the same)

        const byteArray = new ByteArray(buffer);
        byteArray.pos = 0;
        const rgbe_header_info = RGBE_ReadHeader(byteArray);

        const w = rgbe_header_info.width;
        const h = rgbe_header_info.height;
        const image_rgba_data = RGBE_ReadPixels_RLE(byteArray.subarray(byteArray.pos), w, h);

        var data:Dynamic;
        var type:FloatType;

        switch (this.type) {
            case FloatType:
                var floatArray = new Float32Array(image_rgba_data.length / 4);
                for (j in 0...floatArray.length) {
                    RGBEByteToRGBFloat(image_rgba_data, j * 4, floatArray, j * 4);
                }
                data = floatArray;
                type = FloatType;
                break;
            case HalfFloatType:
                var halfArray = new Uint16Array(image_rgba_data.length / 4);
                for (j in 0...halfArray.length) {
                    RGBEByteToRGBHalf(image_rgba_data, j * 4, halfArray, j * 4);
                }
                data = halfArray;
                type = HalfFloatType;
                break;
            default:
                throw new Error('THREE.RGBELoader: Unsupported type: ' + this.type);
        }

        return {
            width: w,
            height: h,
            data: data,
            header: rgbe_header_info.string,
            gamma: rgbe_header_info.gamma,
            exposure: rgbe_header_info.exposure,
            type: type
        };
    }

    public function setDataType(value:FloatType) {
        this.type = value;
        return this;
    }

    public override function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
        function onLoadCallback(texture:Dynamic, texData:Dynamic) {
            switch (texture.type) {
                case FloatType:
                case HalfFloatType:
                    texture.colorSpace = LinearSRGBColorSpace;
                    texture.minFilter = LinearFilter;
                    texture.magFilter = LinearFilter;
                    texture.generateMipmaps = false;
                    texture.flipY = true;
                default:
            }
            if (onLoad != null) onLoad(texture, texData);
        }
        return super.load(url, onLoadCallback, onProgress, onError);
    }
}