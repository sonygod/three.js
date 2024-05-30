import Binding from './Binding.hx';

class Sampler extends Binding {
	public var texture:Texture;
	public var version:Int;

	public function new(name:String, texture:Texture) {
		super(name);
		this.texture = texture;
		this.version = texture ? texture.version : 0;
	}
}

export default Sampler;