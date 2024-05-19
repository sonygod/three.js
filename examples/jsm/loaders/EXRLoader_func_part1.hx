import haxe.io.Bytes;
import haxe.io.BytesInput;
import js.Browser;

class EXRLoader extends DataTextureLoader {

	public var type:Float = HalfFloatType;
	public function new(manager:Dynamic) {
		super(manager);
		this.type = HalfFloatType;
	}

	public function parse(buffer:Bytes):Dynamic {
		// ... (same as JavaScript code)
	}

	public function setDataType(value:Dynamic):EXRLoader {
		this.type = value;
		return this;
	}

	public function load(url:String, onLoad, onProgress, onError):Void {
		function onLoadCallback(texture:Dynamic, texData:Dynamic) {
			texture.colorSpace = texData.colorSpace;
			texture.minFilter = LinearFilter;
			texture.magFilter = LinearFilter;
			texture.generateMipmaps = false;
			texture.flipY = false;
			if (onLoad != null) onLoad(texture, texData);
		}
		return super.load(url, onLoadCallback, onProgress, onError);
	}

}

export class EXRLoader_Func_Part1 {
	public static function main():Void {
		var buffer:Bytes = Browser.load("path/to/exr/file");
		var texLoader = new EXRLoader(null);
		texLoader.setDataType(FloatType);
		var tex = texLoader.load(buffer.toString(), (texture:Dynamic, texData:Dynamic) -> Void, (event:Dynamic) -> Void, (error:Dynamic) -> Void);
	}
}