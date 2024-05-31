import haxe.ds.Vector;
import three.core.EventDispatcher;
import three.constants.StaticDrawUsage;

class UniformsGroup extends EventDispatcher {
	public var isUniformsGroup:Bool = true;
	private static var _id:Int = 0;
	public var id:Int;
	public var name:String;
	public var usage:Int;
	public var uniforms:Vector<Dynamic>;

	public function new() {
		super();
		this.id = UniformsGroup._id++;
		this.name = "";
		this.usage = StaticDrawUsage;
		this.uniforms = new Vector<Dynamic>();
	}

	public function add(uniform:Dynamic):UniformsGroup {
		this.uniforms.push(uniform);
		return this;
	}

	public function remove(uniform:Dynamic):UniformsGroup {
		var index = this.uniforms.indexOf(uniform);
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
		this.dispatchEvent({ type: 'dispose' });
		return this;
	}

	public function copy(source:UniformsGroup):UniformsGroup {
		this.name = source.name;
		this.usage = source.usage;

		this.uniforms.length = 0;
		for (i in 0...source.uniforms.length) {
			var uniforms = (if (Std.is(source.uniforms[i], Array)) source.uniforms[i] else [source.uniforms[i]]);
			for (j in 0...uniforms.length) {
				this.uniforms.push(cast uniforms[j].clone());
			}
		}

		return this;
	}

	public function clone():UniformsGroup {
		return cast new UniformsGroup().copy(this);
	}
}