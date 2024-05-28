import js.Browser.Window;
import js.html.Image;
import js.webgl.Texture;
import js.webgl.TextureCubeMap;
import js.webgl.TextureWrapping;

class CubeTexture extends Texture {

	public var isCubeTexture:Bool;
	public var flipY:Bool;

	public function new(images:Array<Image> = [], mapping:Int = CubeReflectionMapping, wrapS:Int = TextureWrapping.ClampToEdge, wrapT:Int = TextureWrapping.ClampToEdge, magFilter:Int = Texture.LinearFilter, minFilter:Int = Texture.LinearMipMapLinearFilter, format:Int = Texture.RGBAFormat, type:Int = Texture.UnsignedByteType, anisotropy:Int = 0, colorSpace:Int = Texture.GammaColorSpace) {
		super(images, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);
		isCubeTexture = true;
		flipY = false;
	}

	public function set_images(value:Array<Image>) {
		image = value;
	}

	public function get_images():Array<Image> {
		return image;
	}

}