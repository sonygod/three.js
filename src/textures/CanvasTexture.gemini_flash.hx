import js.three.Texture;

class CanvasTexture extends Texture {

	public var isCanvasTexture:Bool;

	public var needsUpdate:Bool;

	public function new(canvas:Dynamic, mapping:Int = 0, wrapS:Int = 1001, wrapT:Int = 1001, magFilter:Int = 1006, minFilter:Int = 1006, format:Int = 1023, type:Int = 1009, anisotropy:Int = 1) {

		super(canvas, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);

		this.isCanvasTexture = true;

		this.needsUpdate = true;

	}

}