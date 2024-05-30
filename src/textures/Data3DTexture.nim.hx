import three.js.src.textures.Texture;
import three.js.src.constants.ClampToEdgeWrapping;
import three.js.src.constants.NearestFilter;

class Data3DTexture extends Texture {

	public function new(data:Dynamic = null, width:Int = 1, height:Int = 1, depth:Int = 1) {

		super(null);

		this.isData3DTexture = true;

		this.image = { data: data, width: width, height: height, depth: depth };

		this.magFilter = NearestFilter;
		this.minFilter = NearestFilter;

		this.wrapR = ClampToEdgeWrapping;

		this.generateMipmaps = false;
		this.flipY = false;
		this.unpackAlignment = 1;

	}

}

export haxe.macro.Macro.addField(Data3DTexture, "isData3DTexture", true);
export haxe.macro.Macro.addField(Data3DTexture, "image", {});
export haxe.macro.Macro.addField(Data3DTexture, "magFilter", NearestFilter);
export haxe.macro.Macro.addField(Data3DTexture, "minFilter", NearestFilter);
export haxe.macro.Macro.addField(Data3DTexture, "wrapR", ClampToEdgeWrapping);
export haxe.macro.Macro.addField(Data3DTexture, "generateMipmaps", false);
export haxe.macro.Macro.addField(Data3DTexture, "flipY", false);
export haxe.macro.Macro.addField(Data3DTexture, "unpackAlignment", 1);

export haxe.macro.Macro.addType(Data3DTexture, "three.js.src.textures.Data3DTexture");