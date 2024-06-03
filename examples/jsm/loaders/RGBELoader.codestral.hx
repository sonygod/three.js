import three.DataTextureLoader;
import three.DataUtils;
import three.FloatType;
import three.HalfFloatType;
import three.LinearFilter;
import three.LinearSRGBColorSpace;

class RGBELoader extends DataTextureLoader {
    private var type:Int;

    public function new(manager:haxe.ds.StringMap) {
        super(manager);
        this.type = HalfFloatType;
    }

    public function parse(buffer:haxe.io.Bytes):Dynamic {
        const rgbe_read_error:Int = 1;
        const rgbe_write_error:Int = 2;
        const rgbe_format_error:Int = 3;
        const rgbe_memory_error:Int = 4;

        var rgbe_error = function (rgbe_error_code:Int, msg:String) {
            switch (rgbe_error_code) {
                case rgbe_read_error: throw new js.Error('THREE.RGBELoader: Read Error: ' + (msg != null ? msg : ''));
                case rgbe_write_error: throw new js.Error('THREE.RGBELoader: Write Error: ' + (msg != null ? msg : ''));
                case rgbe_format_error: throw new js.Error('THREE.RGBELoader: Bad File Format: ' + (msg != null ? msg : ''));
                default:
                case rgbe_memory_error: throw new js.Error('THREE.RGBELoader: Memory Error: ' + (msg != null ? msg : ''));
            }
        };

        const RGBE_VALID_PROGRAMTYPE:Int = 1;
        const RGBE_VALID_FORMAT:Int = 2;
        const RGBE_VALID_DIMENSIONS:Int = 4;

        const NEWLINE:String = '\n';

        var fgets = function (buffer:haxe.io.Bytes, lineLimit:Int=1024, consume:Bool=true):String {
            const chunkSize:Int = 128;
            var p:Int = buffer.position;
            var i:Int = -1;
            var len:Int = 0;
            var s:String = '';
            var chunk:String = buffer.getString(p, chunkSize);

            while ((i = chunk.indexOf(NEWLINE)) == -1 && len < lineLimit && p < buffer.length) {
                s += chunk;
                len += chunk.length;
                p += chunkSize;
                chunk += buffer.getString(p, chunkSize);
            }

            if (i != -1) {
                if (consume) buffer.position += len + i + 1;
                return s + chunk.substring(0, i);
            }

            return null;
        };

        // Continue with the rest of the JavaScript code translated to Haxe...
    }

    public function setDataType(value:Int):RGBELoader {
        this.type = value;
        return this;
    }

    @:override
    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Dynamic {
        var onLoadCallback = function (texture, texData) {
            switch (texture.type) {
                case FloatType:
                case HalfFloatType:
                    texture.colorSpace = LinearSRGBColorSpace;
                    texture.minFilter = LinearFilter;
                    texture.magFilter = LinearFilter;
                    texture.generateMipmaps = false;
                    texture.flipY = true;
                    break;
            }

            if (onLoad != null) onLoad(texture, texData);
        };

        return super.load(url, onLoadCallback, onProgress, onError);
    }
}

class js {
    static function Error(msg:String) return new haxe.Exception(msg);
}