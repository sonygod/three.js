import js.Browser.EventDispatcher;
import three.StaticDrawUsage;

@:keep
class UniformsGroup extends EventDispatcher {

	var isUniformsGroup:Bool = true;
	var id:Int;
	var name:String;
	var usage:Int;
	var uniforms:Array<Dynamic>;

	public function new() {
		super();
		id = _id++;
		name = '';
		usage = StaticDrawUsage;
		uniforms = [];
	}

	public function add(uniform:Dynamic):UniformsGroup {
		uniforms.push(uniform);
		return this;
	}

	public function remove(uniform:Dynamic):UniformsGroup {
		var index = uniforms.indexOf(uniform);
		if (index != -1) uniforms.splice(index, 1);
		return this;
	}

	public function setName(name:String):UniformsGroup {
		this.name = name;
		return this;
	}

	public function setUsage(value:Int):UniformsGroup {
		usage = value;
		return this;
	}

	public function dispose():UniformsGroup {
		this.dispatchEvent({type: 'dispose'});
		return this;
	}

	public function copy(source:UniformsGroup):UniformsGroup {
		name = source.name;
		usage = source.usage;
		var uniformsSource = source.uniforms;
		uniforms.length = 0;
		for (i in 0...uniformsSource.length) {
			var uniforms = (uniformsSource[i] is Array<Dynamic>) ? uniformsSource[i] : [uniformsSource[i]];
			for (j in 0...uniforms.length) {
				uniforms.push(uniforms[j].clone());
			}
		}
		return this;
	}

	public function clone():UniformsGroup {
		return new UniformsGroup().copy(this);
	}

	static var _id:Int = 0;
}