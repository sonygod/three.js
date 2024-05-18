import DataUtils from 'three/src/math/DataUtils';
import FloatType from 'three/src/constants';
import HalfFloatType from 'three/src/constants';
import LinearFilter from 'three/src/constants';
import LinearSRGBColorSpace from 'three/src/constants';
import RedFormat from 'three/src/constants';
import RGBAFormat from 'three/src/constants';
import Uint8Array from 'std/Uint8Array';
import DataView from 'std/DataView';

class EXRLoader extends DataTextureLoader {

	public type:Int;

	public function new(manager:Dynamic) {
		super(manager);
		this.type = HalfFloatType;
	}

	public function parse(buffer:ArrayBuffer):Dynamic {
		// Code for parsing the EXR file
	}

	public function setDataType(value:Int):EXRLoader {
		this.type = value;
		return this;
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Dynamic {
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

export { EXRLoader };