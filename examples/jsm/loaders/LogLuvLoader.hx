import three.math.DataUtils;
import three.textures.DataTextureLoader;
import three.textures.TextureFormat;
import three.textures.TextureType;

class LogLuvLoader extends DataTextureLoader {

	public function new(manager:Dynamic) {
		super(manager);
		this.type = TextureType.HalfFloatType;
	}

	public override function parse(buffer:Dynamic):Dynamic {
		var ifds:Array<Dynamic> = UTIF.decode(buffer);
		UTIF.decodeImage(buffer, ifds[0]);
		var rgba:Array<Int> = UTIF.toRGBA(ifds[0], this.type);

		return {
			width: ifds[0].width,
			height: ifds[0].height,
			data: rgba,
			format: TextureFormat.RGBAFormat,
			type: this.type,
			flipY: true
		};
	}

	public function setDataType(value:Dynamic):LogLuvLoader {
		this.type = value;
		return this;
	}
}

// from https://github.com/photopea/UTIF.js (MIT License)

class UTIF {

	public static function decode(buff:Dynamic, prm:Dynamic):Array<Dynamic> {
		// ...
	}

	public static function decodeImage(buff:Dynamic, img:Dynamic, ifds:Array<Dynamic>):Void {
		// ...
	}

	// ... other functions from the UTIF class
}

// ... other code from the UTIF class

export class ThreeExports {
	public static function main():Void {
		// ...
	}
}