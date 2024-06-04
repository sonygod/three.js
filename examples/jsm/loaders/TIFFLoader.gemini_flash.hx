import three.extras.DataTextureLoader;
import three.constants.Filters;

class TIFFLoader extends DataTextureLoader {

	public function new(manager:Dynamic = null) {
		super(manager);
	}

	public function parse(buffer:haxe.io.Bytes):Dynamic {
		var ifds = UTIF.decode(buffer);
		UTIF.decodeImage(buffer, ifds[0]);
		var rgba = UTIF.toRGBA8(ifds[0]);

		return {
			width: ifds[0].width,
			height: ifds[0].height,
			data: rgba,
			flipY: true,
			magFilter: Filters.LinearFilter,
			minFilter: Filters.LinearMipmapLinearFilter
		};
	}

}