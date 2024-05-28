import openfl.display.BitmapData;
import openfl.utils.ByteArrayData;

class DataTexture extends openfl.display3D.textures.Texture {

	public var isDataTexture:Bool;

	public function new (data:ByteArrayData = null, width:Int = 1, height:Int = 1, format:String, type:String, mapping:String, wrapS:Int, wrapT:Int, magFilter:Int = NearestFilter, minFilter:Int = NearestFilter, anisotropy:Int, colorSpace:Int) {
		super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);
		this.isDataTexture = true;
		this.bitmapData = new BitmapData(width, height, false, 0x00000000);
		if (data != null) {
			this.bitmapData.setPixels(data.position, data.length, 0, 0, width, height);
		}
		this.generateMipmaps = false;
		this.flipY = false;
		this.unpackAlignment = 1;
	}

}