import haxe.Event;
import haxe.events.EventDispatcher;
import haxe.ds.Vector;
import haxe.ds.StringMap;

import three.constants.StaticDrawUsage;

class UniformsGroup extends EventDispatcher {

	public var isUniformsGroup:Bool = true;
	public var id:Int;
	public var name:String = "";
	public var usage:Int = StaticDrawUsage;
	public var uniforms:Vector<Dynamic>;

	static var _id:Int = 0;

	public function new() {
		super();
		id = _id++;
		uniforms = new Vector<Dynamic>();
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
		dispatchEvent(new Event("dispose"));
		return this;
	}

	public function copy(source:UniformsGroup):UniformsGroup {
		name = source.name;
		usage = source.usage;

		uniforms.clear();

		for (uniform in source.uniforms) {
			if (Std.is(uniform, Vector)) {
				for (item in uniform) {
					uniforms.push(item.clone());
				}
			} else {
				uniforms.push(uniform.clone());
			}
		}

		return this;
	}

	public function clone():UniformsGroup {
		return new UniformsGroup().copy(this);
	}
}