import Binding from './Binding.hx';

class Sampler extends Binding {

	public function new(name:String, texture:Dynamic) {

		super(name);

		this.texture = texture;
		this.version = if (texture != null) texture.version else 0;

		this.isSampler = true;

	}

}

@:keep
class Sampler {}