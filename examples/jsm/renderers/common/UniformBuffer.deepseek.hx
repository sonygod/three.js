import Buffer from './Buffer.js';

class UniformBuffer extends Buffer {

	public function new(name:String, ?buffer:Dynamic) {

		super(name, buffer);

		this.isUniformBuffer = true;

	}

}

@:expose
class UniformBuffer {}