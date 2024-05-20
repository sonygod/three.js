class WebGLUniforms {

	var seq:Array<Dynamic>;
	var map:Map<String, Dynamic>;

	public function new(gl:Dynamic, program:Dynamic) {

		this.seq = [];
		this.map = new Map();

		var n = gl.getProgramParameter(program, gl.ACTIVE_UNIFORMS);

		for (i in 0...n) {

			var info = gl.getActiveUniform(program, i);
			var addr = gl.getUniformLocation(program, info.name);

			parseUniform(info, addr, this);

		}

	}

	public function setValue(gl:Dynamic, name:String, value:Dynamic, textures:Dynamic):Void {

		var u = this.map.get(name);

		if (u !== null) u.setValue(gl, value, textures);

	}

	public function setOptional(gl:Dynamic, object:Dynamic, name:String):Void {

		var v = object[name];

		if (v !== null) this.setValue(gl, name, v);

	}

	public static function upload(gl:Dynamic, seq:Array<Dynamic>, values:Dynamic, textures:Dynamic):Void {

		for (i in 0...seq.length) {

			var u = seq[i];
			var v = values[u.id];

			if (v.needsUpdate !== false) {

				u.setValue(gl, v.value, textures);

			}

		}

	}

	public static function seqWithValue(seq:Array<Dynamic>, values:Dynamic):Array<Dynamic> {

		var r = [];

		for (i in 0...seq.length) {

			var u = seq[i];
			if (u.id in values) r.push(u);

		}

		return r;

	}

}