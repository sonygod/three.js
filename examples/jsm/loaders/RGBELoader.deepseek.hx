import three.DataTextureLoader;
import three.DataUtils;
import three.FloatType;
import three.HalfFloatType;
import three.LinearFilter;
import three.LinearSRGBColorSpace;

class RGBELoader extends DataTextureLoader {

	public function new(manager:Dynamic) {
		super(manager);
		this.type = HalfFloatType;
	}

	public function parse(buffer:haxe.io.Bytes):Dynamic {
		// ... 转换后的代码 ...
	}

	public function setDataType(value:Dynamic):RGBELoader {
		this.type = value;
		return this;
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Dynamic {
		// ... 转换后的代码 ...
	}
}