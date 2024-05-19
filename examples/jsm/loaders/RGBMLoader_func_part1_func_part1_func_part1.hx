import three.math.MathExt;
import js.console;

class RGBMLoader {

    public var type:Dynamic;
    public var maxRange:Int;

    public function new(manager:Dynamic) {
        this.type = 0x140B; // HalfFloatType in three.js
        this.maxRange = 7;
    }

    public function setDataType(value:Dynamic):RGBMLoader {
        this.type = value;
        return this;
    }

    public function setMaxRange(value:Int):RGBMLoader {
        this.maxRange = value;
        return this;
    }

    @:generic
    public function loadCubemap(urls:Array<String>, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Dynamic {
        var texture = CubeTexture.fromArray(urls);
        texture.type = this.type;
        texture.format = 0x1908; // RGBAFormat in three.js
        texture.minFilter = 0x2601; // LinearFilter in three.js
        texture.generateMipmaps = false;
        return texture;
    }

    @:generic
    public function loadCubemapAsync(urls:Array<String>, onProgress:Dynamic):Dynamic {
        return js.typed_array.Uint8Array.from(this.loadCubemap(urls, null, onProgress, null));
    }

    @:generic
    public function parse(buffer:ArrayBufferView):Dynamic {
        // TODO: Implement the actual parsing logic from the JavaScript code.
        // You can use hxformat library for handling images.
        console.log("Parsing RGBM image data...");
        console.log("Note: The actual parsing logic is not implemented in this example.");
        return null;
    }
}

// You may need to copy the UPNG.decode function from the JavaScript code if you want to use it.
// Then adapt it for Haxe if necessary.