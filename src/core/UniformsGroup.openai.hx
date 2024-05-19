import js.threejs.EventDispatcher;
import js.threejs.constants.StaticDrawUsage;

class UniformsGroup extends EventDispatcher {
	private static var _id:Int = 0;
	private var id:Int;
	public var name:String;
	public var usage:Int;
	public var uniforms:Array<Uniform>;

	public function new() {
		super();
		
		this.isUniformsGroup = true;
		this.id = _id++;
		this.name = '';
		this.usage = StaticDrawUsage;
		this.uniforms = [];
	}

	public function add(uniform:Uniform):UniformsGroup {
		this.uniforms.push(uniform);
		return this;
	}

	public function remove(uniform:Uniform):UniformsGroup {
		var index:Int = this.uniforms.indexOf(uniform);
		if (index != -1) {
			this.uniforms.splice(index, 1);
		}
		return this;
	}

	public function setName(name:String):UniformsGroup {
		this.name = name;
		return this;
	}

	public function setUsage(value:Int):UniformsGroup {
		this.usage = value;
		return this;
	}

	public function dispose():UniformsGroup {
		this.dispatchEvent({type: 'dispose'});
		return this;
	}

	public function copy(source:UniformsGroup):UniformsGroup {
		this.name = source.name;
		this.usage = source.usage;
		this.uniforms.length = 0;

		var uniformsSource:Array<Uniform> = source.uniforms;
		for (i in 0...uniformsSource.length) {
			var uniforms:Array<Uniform> = (js.Lib.isArray(uniformsSource[i])) ? uniformsSource[i] : [uniformsSource[i]];

			for (j in 0...uniforms.length) {
				this.uniforms.push(uniforms[j].clone());
			}
		}

		return this;
	}

	public function clone():UniformsGroup {
		return new this.constructor().copy(this);
	}
}