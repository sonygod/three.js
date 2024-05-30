import js.three.DataTextureLoader;
import js.three.LinearFilter;
import js.three.LinearMipmapLinearFilter;

import js.utif.UTIF;

class TIFFLoader extends DataTextureLoader {
	public function new(manager:Dynamic) {
		super(manager);
	}

	public function parse(buffer:ArrayBuffer):Dynamic {
		var ifds = UTIF.decode(buffer);
		UTIF.decodeImage(buffer, ifds[0]);
		var rgba = UTIF.toRGBA8(ifds[0]);

		return {
			width: Std.int(ifds[0].width),
			height: Std.int(ifds[0].height),
			data: rgba,
			flipY: true,
			magFilter: LinearFilter,
			minFilter: LinearMipmapLinearFilter
		};
	}
}

class Exports {
	public static inline var TIFFLoader:TIFFLoader;
}