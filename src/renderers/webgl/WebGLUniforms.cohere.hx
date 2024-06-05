import js.Browser.Location;
import js.html.Document;
import js.html.Element;
import js.html.HTMLElement;
import js.html.Window;

class WebGLUniforms {
	public var seq:Array<Dynamic>;
	public var map:Map<String, Dynamic>;

	public function new(gl:WebGLRenderingContext, program:WebGLProgram) {
		seq = [];
		map = new Map();

		var n = gl.getProgramParameter(program, gl.ACTIVE_UNIFORMS);

		for (i in 0...n) {
			var info = gl.getActiveUniform(program, i);
			var addr = gl.getUniformLocation(program, info.name);

			parseUniform(info, addr, this);
		}
	}

	public function setValue(gl:WebGLRenderingContext, name:String, value:Dynamic, textures:Dynamic) {
		var u = map.get(name);
		if (u != null)
			u.setValue(gl, value, textures);
	}

	public static function upload(gl:WebGLRenderingContext, seq:Array<Dynamic>, values:Dynamic, textures:Dynamic) {
		for (i in 0...seq.length) {
			var u = seq[i];
			var v = values[u.id];

			if (v.needsUpdate || v.needsUpdate == null) {
				u.setValue(gl, v.value, textures);
			}
		}
	}

	public static function seqWithValue(seq:Array<Dynamic>, values:Dynamic):Array<Dynamic> {
		var r = [];

		for (i in 0...seq.length) {
			var u = seq[i];
			if (values.exists(u.id))
				r.push(u);
		}

		return r;
	}

	static function parseUniform(activeInfo:WebGLActiveInfo, addr:WebGLUniformLocation, container:WebGLUniforms) {
		var path = activeInfo.name;
		var pathLength = path.length;

		var RePathPart = EReg("[\\w]+(\\])?(\\[|\\.)?", "g");

		while (true) {
			var match = RePathPart.match(path);
			var matchEnd = RePathPart.matchedPos();

			var id = match[1];
			var idIsIndex = match[2] == "]";
			var subscript = match[3];

			if (idIsIndex)
				id = Std.parseInt(id);

			if (subscript == null || subscript == "[" && matchEnd + 2 == pathLength) {
				if (subscript == null) {
					addUniform(container, new SingleUniform(id, activeInfo, addr));
				} else {
					addUniform(container, new PureArrayUniform(id, activeInfo, addr));
				}

				break;
			} else {
				var map = container.map;
				var next = map.get(id);

				if (next == null) {
					next = new StructuredUniform(id);
					addUniform(container, next);
				}

				container = next;
			}
		}
	}
}

class SingleUniform {
	public var id:Int;
	public var addr:WebGLUniformLocation;
	public var cache:Array<Float>;
	public var type:Int;
	public var setValue:Dynamic;

	public function new(id:Int, activeInfo:WebGLActiveInfo, addr:WebGLUniformLocation) {
		this.id = id;
		this.addr = addr;
		this.cache = [];
		this.type = activeInfo.type;
		this.setValue = getSingularSetter(activeInfo.type);
	}
}

class PureArrayUniform {
	public var id:Int;
	public var addr:WebGLUniformLocation;
	public var cache:Array<Float>;
	public var type:Int;
	public var size:Int;
	public var setValue:Dynamic;

	public function new(id:Int, activeInfo:WebGLActiveInfo, addr:WebGLUniformLocation) {
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
	public var map:Map<String, Dynamic>;

	public function new(id:Int) {
		this.id = id;
		this.seq = [];
		this.map = new Map();
	}

	public function setValue(gl:WebGLRenderingContext, value:Dynamic, textures:Dynamic) {
		var seq = this.seq;

		for (i in 0...seq.length) {
			var u = seq[i];
			u.setValue(gl, value[u.id], textures);
		}
	}
}

function addUniform(container:WebGLUniforms, uniformObject:Dynamic) {
	container.seq.push(uniformObject);
	container.map.set(uniformObject.id, uniformObject);
}

function flatten(array:Array<Dynamic>, nBlocks:Int, blockSize:Int):Float32Array {
	var firstElem = array[0];

	if (firstElem <= 0 || firstElem > 0)
		return array;

	var n = nBlocks * blockSize;
	var r = arrayCacheF32[n];

	if (r == null) {
		r = new Float32Array(n);
		arrayCacheF32[n] = r;
	}

	if (nBlocks != 0) {
		firstElem.toArray(r, 0);

		for (i in 1...nBlocks) {
			var offset = 0;
			array[i].toArray(r, offset);
			offset += blockSize;
		}
	}

	return r;
}

function arraysEqual(a:Array<Float>, b:Array<Float>):Bool {
	if (a.length != b.length)
		return false;

	for (i in 0...a.length) {
		if (a[i] != b[i])
			return false;
	}

	return true;
}

function copyArray(a:Array<Float>, b:Array<Float>) {
	for (i in 0...b.length) {
		a[i] = b[i];
	}
}

function allocTexUnits(textures:Dynamic, n:Int):Int32Array {
	var r = arrayCacheI32[n];

	if (r == null) {
		r = new Int32Array(n);
		arrayCacheI32[n] = r;
	}

	for (i in 0...n) {
		r[i] = textures.allocateTextureUnit();
	}

	return r;
}

function setValueV1f(gl:WebGLRenderingContext, v:Float) {
	var cache = this.cache;

	if (cache[0] == v)
		return;

	gl.uniform1f(this.addr, v);

	cache[0] = v;
}

function setValueV2f(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;

	if (Reflect.hasField(v, "x")) {
		if (cache[0] != v.x || cache[1] != v.y) {
			gl.uniform2f(this.addr, v.x, v.y);

			cache[0] = v.x;
			cache[1] = v.y;
		}
	} else {
		if (arraysEqual(cache, v))
			return;

		gl.uniform2fv(this.addr, v);

		copyArray(cache, v);
	}
}

function setValueV3f(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;

	if (Reflect.hasField(v, "x")) {
		if (cache[0] != v.x || cache[1] != v.y || cache[2] != v.z) {
			gl.uniform3f(this.addr, v.x, v.y, v.z);

			cache[0] = v.x;
			cache[1] = v.y;
			cache[2] = v.z;
		}
	} else if (Reflect.hasField(v, "r")) {
		if (cache[0] != v.r || cache[1] != v.g || cache[2] != v.b) {
			gl.uniform3f(this.addr, v.r, v.g, v.b);

			cache[0] = v.r;
			cache[1] = v.g;
			cache[2] = v.b;
		}
	} else {
		if (arraysEqual(cache, v))
			return;

		gl.uniform3fv(this.addr, v);

		copyArray(cache, v);
	}
}

function setValueV4f(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;

	if (Reflect.hasField(v, "x")) {
		if (cache[0] != v.x || cache[1] != v.y || cache[2] != v.z || cache[3] != v.w) {
			gl.uniform4f(this.addr, v.x, v.y, v.z, v.w);

			cache[0] = v.x;
			cache[1] = v.y;
			cache[2] = v.z;
			cache[3] = v.w;
		}
	} else {
		if (arraysEqual(cache, v))
			return;

		gl.uniform4fv(this.addr, v);

		copyArray(cache, v);
	}
}

function setValueM2(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;
	var elements = v.elements;

	if (elements == null) {
		if (arraysEqual(cache, v))
			return;

		gl.uniformMatrix2fv(this.addr, false, v);

		copyArray(cache, v);
	} else {
		if (arraysEqual(cache, elements))
			return;

		mat2array.set(elements);

		gl.uniformMatrix2fv(this.addr, false, mat2array);

		copyArray(cache, elements);
	}
}

function setValueM3(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;
	var elements = v.elements;

	if (elements == null) {
		if (arraysEqual(cache, v))
			return;

		gl.uniformMatrix3fv(this.addr, false, v);

		copyArray(cache, v);
	} else {
		if (arraysEqual(cache, elements))
			return;

		mat3array.set(elements);

		gl.uniformMatrix3fv(this.addr, false, mat3array);

		copyArray(cache, elements);
	}
}

function setValueM4(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;
	var elements = v.elements;

	if (elements == null) {
		if (arraysEqual(cache, v))
			return;

		gl.uniformMatrix4fv(this.addr, false, v);

		copyArray(cache, v);
	} else {
		if (arraysEqual(cache, elements))
			return;

		mat4array.set(elements);

		gl.uniformMatrix4fv(this.addr, false, mat4array);

		copyArray(cache, elements);
	}
}

function setValueV1i(gl:WebGLRenderingContext, v:Int) {
	var cache = this.cache;

	if (cache[0] == v)
		return;

	gl.uniform1i(this.addr, v);

	cache[0] = v;
}

function setValueV2i(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;

	if (Reflect.hasField(v, "x")) {
		if (cache[0] != v.x || cache[1] != v.y) {
			gl.uniform2i(this.addr, v.x, v.y);

			cache[0] = v.x;
			cache[1] = v.y;
		}
	} else {
		if (arraysEqual(cache, v))
			return;

		gl.uniform2iv(this.addr, v);

		copyArray(cache, v);
	}
}

function setValueV3i(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;

	if (Reflect.hasField(v, "x")) {
		if (cache[0] != v.x || cache[1] != v.y || cache[2] != v.z) {
			gl.uniform3i(this.addr, v.x, v.y, v.z);

			cache[0] = v.x;
			cache[1] = v.y;
			cache[2] = v.z;
		}
	} else {
		if (arraysEqual(cache, v))
			return;

		gl.uniform3iv(this.addr, v);

		copyArray(cache, v);
	}
}

function setValueV4i(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;

	if (Reflect.hasField(v, "x")) {
		if (cache[0] != v.x || cache[1] != v.y || cache[2] != v.z || cache[3] != v.w) {
			gl.uniform4i(this.addr, v.x, v.y, v.z, v.w);

			cache[0] = v.x;
			cache[1] = v.y;
			cache[2] = v.z;
			cache[3] = v.w;
		}
	} else {
		if (arraysEqual(cache, v))
			return;

		gl.uniform4iv(this.addr, v);

		copyArray(cache, v);
	}
}

function setValueV1ui(gl:WebGLRenderingContext, v:Int) {
	var cache = this.cache;

	if (cache[0] == v)
		return;

	gl.uniform1ui(this.addr, v);

	cache[0] = v;
}

function setValueV2ui(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;

	if (Reflect.hasField(v, "x")) {
		if (cache[0] != v.x || cache[1] != v.y) {
			gl.uniform2ui(this.addr, v.x, v.y);

			cache[0] = v.x;
			cache[1] = v.y;
		}
	} else {
		if (arraysEqual(cache, v))
			return;

		gl.uniform2uiv(this.addr, v);

		copyArray(cache, v);
	}
}

function setValueV3ui(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;

	if (Reflect.hasField(v, "x")) {
		if (cache[0] != v.x || cache[1] != v.y || cache[2] != v.z) {
			gl.uniform3ui(this.addr, v.x, v.y, v.z);

			cache[0] = v.x;
			cache[1] = v.y;
			cache[2] = v.z;
		}
	} else {
		if (arraysEqual(cache, v))
			return;

		gl.uniform3uiv(this.addr, v);

		copyArray(cache, v);
	}
}

function setValueV4ui(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;

	if (Reflect.hasField(v, "x")) {
		if (cache[0] != v.x || cache[1] != v.y || cache[2] != v.z || cache[3] != v.w) {
			gl.uniform4ui(this.addr, v.x, v.y, v.z, v.w);

			cache[0] = v.x;
			cache[1] = v.y;
			cache[2] = v.z;
			cache[3] = v.w;
	} else {
		if (arraysEqual(cache, v))
			return;

		gl.uniform4uiv(this.addr, v);

		copyArray(cache, v);
	}
}

function setValueT1(gl:WebGLRenderingContext, v:Dynamic, textures:Dynamic) {
	var cache = this.cache;
	var unit = textures.allocateTextureUnit();

	if (cache[0] != unit) {
		gl.uniform1i(this.addr, unit);
		cache[0] = unit;
	}

	var emptyTexture2D = if (this.type == gl.SAMPLER_2D_SHADOW)
		emptyShadowTexture
	else
		emptyTexture;

	textures.setTexture2D(v != null ? v : emptyTexture2D, unit);
}

function setValueT3D1(gl:WebGLRenderingContext, v:Dynamic, textures:Dynamic) {
	var cache = this.cache;
	var unit = textures.allocateTextureUnit();

	if (cache[0] != unit) {
		gl.uniform1i(this.addr, unit);
		cache[0] = unit;
	}

	textures.setTexture3D(v != null ? v : empty3dTexture, unit);
}

function setValueT6(gl:WebGLRenderingContext, v:Dynamic, textures:Dynamic) {
	var cache = this.cache;
	var unit = textures.allocateTextureUnit();

	if (cache[0] != unit) {
		gl.uniform1i(this.addr, unit);
		cache[0] = unit;
	}

	textures.setTextureCube(v != null ? v : emptyCubeTexture, unit);
}

function setValueT2DArray1(gl:WebGLRenderingContext, v:Dynamic, textures:Dynamic) {
	var cache = this.cache;
	var unit = textures.allocateTextureUnit();

	if (cache[0] != unit) {
		gl.uniform1i(this.addr, unit);
		cache[0] = unit;
	}

	textures.setTexture2DArray(v != null ? v : emptyArrayTexture, unit);
}

function getSingularSetter(type:Int):Dynamic {
	switch (type) {
		case 0x1406:
			return setValueV1f; // FLOAT
		case 0x8b50:
			return setValueV2f; // _VEC2
		case 0x8b51:
			return setValueV3f; // _VEC3
		case 0x8b52:
			return setValueV4f; // _VEC4

		case 0x8b5a:
			return setValueM2; // _MAT2
		case 0x8b5b:
			return setValueM3; // _MAT3
		case 0x8b5c:
			return setValueM4; // _MAT4

		case 0x1404:
		case 0x8b56:
			return setValueV1i; // INT, BOOL
		case 0x8b53:
		case 0x8b57:
			return setValueV2i; // _VEC2
		case 0x8b54:
		case 0x8b58:
			return setValueV3i; // _VEC3
		case 0x8b55:
		case 0x8b59:
			return setValueV4i; // _VEC4

		case 0x1405:
			return setValueV1ui; // UINT
		case 0x8dc6:
			return setValueV2ui; // _VEC2
		case 0x8dc7:
			return setValueV3ui; // _VEC3
		case 0x8dc8:
			return setValueV4ui; // _VEC4

		case 0x8b5e: // SAMPLER_2D
		case 0x8d66: // SAMPLER_EXTERNAL_OES
		case 0x8dca: // INT_SAMPLER_2D
		case 0x8dd2: // UNSIGNED_INT_SAMPLER_2D
		case 0x8b62: // SAMPLER_2D_SHADOW
			return setValueT1;

		case 0x8b5f: // SAMPLER_3D
		case 0x8dcb: // INT_SAMPLER_3D
		case 0x8dd3: // UNSIGNED_INT_SAMPLER_3D
			return setValueT3D1;

		case 0x8b60: // SAMPLER_CUBE
		case 0x8dcc: // INT_SAMPLER_CUBE
		case 0x8dd4: // UNSIGNED_INT_SAMPLER_CUBE
		case 0x8dc5: // SAMPLER_CUBE_SHADOW
			return setValueT6;

		case 0x8dc1: // SAMPLER_2D_ARRAY
		case 0x8dcf: // INT_SAMPLER_2D_ARRAY
		case 0x8dd7: // UNSIGNED_INT_SAMPLER_2D_ARRAY
		case 0x8dc4: // SAMPLER_2D_ARRAY_SHADOW
			return setValueT2DArray1;
	}
}

function setValueV1fArray(gl:WebGLRenderingContext, v:Float32Array) {
	gl.uniform1fv(this.addr, v);
}

function setValueV2fArray(gl:WebGLRenderingContext, v:Dynamic) {
	var data = flatten(v, this.size, 2);

	gl.uniform2fv(this.addr, data);
}

function setValueV3fArray(gl:WebGLRenderingContext, v:Dynamic) {
	var data = flatten(v, this.size, 3);

	gl.uniform3fv(this.addr, data);
}

function setValueV4fArray(gl:WebGLRenderingContext, v:Dynamic) {
	var data = flatten(v, this.size, 4);

	gl.uniform4fv(this.addr, data);
}

function setValueM2Array(gl:WebGLRenderingContext, v:Dynamic) {
	var data = flatten(v, this.size, 4);

	gl.uniformMatrix2fv(this.addr, false, data);
}

function setValueM3Array(gl:WebGLRenderingContext, v:Dynamic) {
	var data = flatten(v, this.size, 9);

	gl.uniformMatrix3fv(this.addr, false, data);
}

function setValueM4Array(gl:WebGLRenderingContext, v:Dynamic) {
	var data = flatten(v, this.size, 16);

	gl.uniformMatrix4fv(this.addr, false, data);
}

function setValueV1iArray(gl:WebGLRenderingContext, v:Int32Array) {
	gl.uniform1iv(this.addr, v);
}

function setValueV2iArray(gl:WebGLRenderingContext, v:Int32Array) {
	gl.uniform2iv(this.addr, v);
}

function setValueV3iArray(gl:WebGLRenderingContext, v:Int32Array) {
	gl.uniform3iv(this.addr, v);
}

function setValueV4iArray(gl:WebGLRenderingContext, v:Int32Array) {
	gl.uniform4iv(this.addr, v);
}

function setValueV1uiArray(gl:WebGLRenderingContext, v:Int32Array) {
	gl.uniform1uiv(this.addr, v);
}

function setValueV2uiArray(gl:WebGLRenderingContext, v:Int32Array) {
	gl.uniform2uiv(this.addr, v);
}

function setValueV3uiArray(gl:WebGLRenderingContext, v:Int32Array) {
	gl.uniform3uiv(this.addr, v);
}

function setValueV4uiArray(gl:WebGLRenderingContext, v:Int32Array) {
	gl.uniform4uiv(this.addr, v);
}

function setValueT1Array(gl:WebGLRenderingContext, v:Dynamic, textures:Dynamic) {
	var cache = this.cache;

	var n = v.length;

	var units = allocTexUnits(textures, n);

	if (!arraysEqual(cache, units)) {
		gl.uniform1iv(this.addr, units);

		copyArray(cache, units);
	}

	for (i in 0...n) {
		textures.setTexture2D(v[i] != null ? v[i] : emptyTexture, units[i]);
	}
}

function setValueT3DArray(gl:WebGLRenderingContext, v:Dynamic, textures:Dynamic) {
	var cache = this.cache;

	var n = v.length;

	var units = allocTexUnits(textures, n);

	if (!arraysEqual(cache, units)) {
		gl.uniform1iv(this.addr, units);

		copyArray(cache, units);
	}

	for (i in 0...n) {
		textures.setTexture3D(v[i] != null ? v[i] : empty3dTexture, units[i]);
	}
}

function setValueT6Array(gl:WebGLRenderingContext, v:Dynamic, textures:Dynamic) {
	var cache = this.cache;

	var n = v.length;

	var units = allocTexUnits(textures, n);

	if (!arraysEqual(cache, units)) {
		gl.uniform1iv(this.addr, units);

		copyArray(cache, units);
	}

	for (i in 0...n) {
		textures.setTextureCube(v[i] != null ? v[i] : emptyCubeTexture, units[i]);
	}
}

function setValueT2DArrayArray(gl:WebGLRenderingContext, v:Dynamic, textures:Dynamic) {
	var cache = this.cache;

	var n = v.length;

	var units = allocTexUnits(textures, n);

	if (!arraysEqual(cache, units)) {
		gl.uniform1iv(this.addr, units);

		copyArray(cache, units);
	}

	for (i in 0...n) {
		textures.setTexture2DArray(v[i] != null ? v[i] : emptyArrayTexture, units[i]);
	}
}

function getPureArraySetter(type:Int):Dynamic {
	switch (type) {
		case 0x1406:
			return setValueV1fArray; // FLOAT
		case 0x8b50:
			return setValueV2fArray; // _VEC2
		case 0x8b51:
			return setValueV3fArray; // _VEC3
		case 0x8b52:
			return setValueV4fArray; // _VEC4

		case 0x8b5a:
			return setValueM2Array; // _MAT2
		case 0x8b5b:
			return setValueM3Array; // _MAT3
		case 0x8b5c:
			return setValueM4Array; // _MAT4

		case 0x1404:
		case 0x8b56:
			return setValueV1iArray; // INT, BOOL
		case 0x8b53:
		case 0x8b57:
			return setValueV2iArray; // _VEC2
		case 0x8b54:
		case 0x8b58:
			return setValueV3iArray; // _VEC3
		case 0x8b55:
		case 0x8b59:
			return setValueV4iArray; // _VEC4

		case 0x1405:
			return setValueV1uiArray; // UINT
		case 0x8dc6:
			return setValueV2uiArray; // _VEC2
		case 0x8dc7:
			return setValueV3uiArray; // _VEC3
		case 0x8dc8:
			return setValueV4uiArray; // _VEC4

		case 0x8b5e: // SAMPLER_2D
		case 0x8d66: // SAMPLER_EXTERNAL_OES
		case 0x8dca: // INT_SAMPLER_2D
		case 0x8dd2: // UNSIGNED_INT_SAMPLER_2D
		case 0x8b62: // SAMPLER_2D_SHADOW
			return setValueT1Array;

		case 0x8b5f: // SAMPLER_3D
		case 0x8dcb: // INT_SAMPLER_3D
		case 0x8dd3: // UNSIGNED_INT_SAMPLER_3D
			return setValueT3DArray;

		case 0x8b60: // SAMPLER_CUBE
		case 0x8dcc: // INT_SAMPLER_CUBE
		case 0x8dd4: // UNSIGNED_INT_SAMPLER_CUBE
		case 0x8dc5: // SAMPLER_CUBE_SHADOW
			return setValueT6Array;

		case 0x8dc1: // SAMPLER_2D_ARRAY
		case 0x8dcf: // INT_SAMPLER_2D_ARRAY
		case 0x8dd7: // UNSIGNED_INT_SAMPLER_2D_ARRAY
		case 0x8dc4: // SAMPLER_2D_ARRAY_SHADOW
			return setValueT2DArrayArray;
	}
}

var arrayCacheF32:Array<Float32Array> = [];
var arrayCacheI32:Array<Int32Array> = [];

var mat4array:Float32Array = new Float32Array(16);
var mat3array:Float32Array = new Float32Array(9);
var mat2array:Float32Array = new Float32Array(4);

var emptyTexture:Texture = new Texture();
var emptyShadowTexture:DepthTexture = new DepthTexture(1, 1);
emptyShadowTexture.compareFunction = LessEqualCompare;

var emptyArrayTexture:DataArrayTexture = new DataArrayTexture();
var empty3dTexture:Data3DTexture = new Data3DTexture();
var emptyCubeTexture:CubeTexture = new CubeTexture();

class Texture {
	// ...
}

class DepthTexture {
	// ...
}

class DataArrayTexture {
	// ...
}

class Data3DTexture {
	// ...
}

class CubeTexture {
	// ...
}

enum LessEqualCompare {
	// ...
}