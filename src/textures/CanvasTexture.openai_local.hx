import three.textures.Texture;

class CanvasTexture extends Texture {

	public var isCanvasTexture:Bool;
	public var needsUpdate:Bool;

	public function new(
		canvas:Dynamic,
		mapping:Dynamic = null,
		wrapS:Dynamic = null,
		wrapT:Dynamic = null,
		magFilter:Dynamic = null,
		minFilter:Dynamic = null,
		format:Dynamic = null,
		type:Dynamic = null,
		anisotropy:Dynamic = null
	) {
		super(canvas, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
		
		this.isCanvasTexture = true;
		this.needsUpdate = true;
	}
}