import haxe.ds.EnumValueMap;
import haxe.ds.StringMap;
import haxe.ds.StringTools;
import webgl.types.WebGLRenderingContext;

class SingleUniform {
	public var id:Int;
	public var addr:Int;
	public var cache:Array<Float>;
	public var type:Int;
	public var setValue:Dynamic;

	public function new(id:Int, activeInfo:Dynamic, addr:Int) {
		this.id = id;
		this.addr = addr;
		this.cache = [];
		this.type = activeInfo.type;
		this.setValue = getSingularSetter(activeInfo.type);
	}
}

class PureArrayUniform {
	public var id:Int;
	public var addr:Int;
	public var cache:Array<Float>;
	public var type:Int;
	public var size:Int;
	public var setValue:Dynamic;

	public function new(id:Int, activeInfo:Dynamic, addr:Int) {
		this.id = id;
		this.addr = addr;
		this.cache = [];
		this.type = activeInfo.type;
		this.size = activeInfo.size;
		this.setValue = getPureArraySetter(activeInfo.type);
	}
}

class StructuredUniform {
	public var id:Int;
	public var seq:Array<Dynamic>;
	public var map:StringMap<Dynamic>;

	public function new(id:Int) {
		this.id = id;
		this.seq = [];
		this.map = new StringMap<Dynamic>();
	}

	public function setValue(gl:WebGLRenderingContext, value:Dynamic, textures:Dynamic) {
		for (i in 0...seq.length) {
			const u = seq[i];
			u.setValue(gl, value[u.id], textures);
		}
	}
}

class WebGLUniforms {
	public var seq:Array<Dynamic>;
	public var map:StringMap<Dynamic>;

	public function new(gl:WebGLRenderingContext, program:Int) {
		this.seq = [];
		this.map = new StringMap<Dynamic>();

		var n = gl.getProgramParameter(program, gl.ACTIVE_UNIFORMS);
		for (i in 0...n) {
			var info = gl.getActiveUniform(program, i);
			var addr = gl.getUniformLocation(program, info.name);
			parseUniform(info, addr, this);
		}
	}

	public function setValue(gl:WebGLRenderingContext, name:String, value:Dynamic, textures:Dynamic) {
		const u = this.map[name];
		if (u !== null) u.setValue(gl, value, textures);
	}

	public static function upload(gl:WebGLRenderingContext, seq:Array<Dynamic>, values:EnumValueMap<Dynamic>, textures:Dynamic) {
		for (u in seq) {
			const v = values[u.id];
			if (v.needsUpdate !== false) {
				u.setValue(gl, v.value, textures);
			}
		}
	}

	public static function seqWithValue(seq:Array<Dynamic>, values:EnumValueMap<Dynamic>) {
		const r = [];
		for (u in seq) {
			if (u.id in values) r.push(u);
		}
		return r;
	}
}

// Helper functions

function addUniform(container:Dynamic, uniformObject:Dynamic) {
	container.seq.push(uniformObject);
	container.map[uniformObject.id] = uniformObject;
}

function parseUniform(activeInfo:Dynamic, addr:Int, container:Dynamic) {
	const path = activeInfo.name;
	RePathPart.lastIndex = 0;
	while (true) {
		const match = RePathPart.exec(path);
		if (match == null) break;
		const matchEnd = RePathPart.lastIndex;
		const id = match[1];
		const idIsIndex = match[2] === ']';
		const subscript = match[3];
		if (idIsIndex) id = id | 0;
		if (subscript === undefined || subscript === '[' && matchEnd + 2 === path.length) {
			addUniform(container, subscript === undefined ?
				new SingleUniform(haxe.IntImpl.parseInt(id), activeInfo, addr) :
				new PureArrayUniform(haxe.IntImpl.parseInt(id), activeInfo, addr));
		} else {
			const map = container.map;
			let next = map[id];
			if (next === undefined) {
				next = new StructuredUniform(haxe.IntImpl.parseInt(id));
				addUniform(container, next);
			}
			container = next;
		}
	}
}

const RePathPart = /(\w+)(\])?(\[|\.)?/g;

// ... rest of the code