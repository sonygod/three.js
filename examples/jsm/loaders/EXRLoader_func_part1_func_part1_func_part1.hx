import haxe.format.DataView;
import haxe.format.Int16Array;
import haxe.format.Uint16Array;
import haxe.format.Int32Array;
import haxe.format.Uint32Array;
import haxe.format.Float32Array;
import haxe.format.Uint8Array;
import three.DataUtils;
import three.LinearFilter;
import three.LinearSRGBColorSpace;
import three.RedFormat;
import three.RGBAFormat;
import three.NoColorSpace;

class EXRLoader extends DataTextureLoader {

	public function new(manager:Dynamic) {
		super(manager);
		this.type = HalfFloatType;
	}

	public function parse(buffer:ArrayBuffer):Dynamic {
		// Your parse implementation here
	}

	public function setDataType(value:Dynamic):EXRLoader {
		this.type = value;
		return this;
	}

	override public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Dynamic {
		// Your load implementation here
	}
}