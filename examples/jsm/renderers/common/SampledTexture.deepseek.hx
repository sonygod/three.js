import Binding from './Binding.js';

static var id:Int = 0;

class SampledTexture extends Binding {

	public var id:Int;
	public var texture:Dynamic;
	public var version:Int;
	public var store:Bool;
	public var isSampledTexture:Bool;

	public function new(name:String, texture:Dynamic) {
		super(name);
		this.id = id++;
		this.texture = texture;
		this.version = if (texture != null) texture.version else 0;
		this.store = false;
		this.isSampledTexture = true;
	}

	public function get needsBindingsUpdate():Bool {
		return (this.texture.isVideoTexture) ? true : (this.version != this.texture.version);
	}

	public function update():Bool {
		if (this.version != this.texture.version) {
			this.version = this.texture.version;
			return true;
		}
		return false;
	}
}

class SampledArrayTexture extends SampledTexture {

	public var isSampledArrayTexture:Bool;

	public function new(name:String, texture:Dynamic) {
		super(name, texture);
		this.isSampledArrayTexture = true;
	}
}

class Sampled3DTexture extends SampledTexture {

	public var isSampled3DTexture:Bool;

	public function new(name:String, texture:Dynamic) {
		super(name, texture);
		this.isSampled3DTexture = true;
	}
}

class SampledCubeTexture extends SampledTexture {

	public var isSampledCubeTexture:Bool;

	public function new(name:String, texture:Dynamic) {
		super(name, texture);
		this.isSampledCubeTexture = true;
	}
}

typedef SampledTextureTypes = {
	SampledTexture:SampledTexture,
	SampledArrayTexture:SampledArrayTexture,
	Sampled3DTexture:Sampled3DTexture,
	SampledCubeTexture:SampledCubeTexture
};