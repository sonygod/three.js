package;

import three.textures.CubeTexture;
import three.textures.Texture;
import three.textures.DataArrayTexture;
import three.textures.Data3DTexture;
import three.textures.DepthTexture;
import three.constants.LessEqualCompare;

class WebGLUniforms {

	public var seq:Array<Uniform>;
	public var map:Map<String, Uniform>;

	public function new(gl:WebGLRenderingContext, program:WebGLProgram) {
		this.seq = new Array();
		this.map = new Map();
		var n = gl.getProgramParameter(program, gl.ACTIVE_UNIFORMS);

		for (i in 0...n) {
			var info = gl.getActiveUniform(program, i);
			var addr = gl.getUniformLocation(program, info.name);
			parseUniform(info, addr, this);
		}
	}

	public function setValue(gl:WebGLRenderingContext, name:String, value:Dynamic, textures:Dynamic) {
		var u = this.map.get(name);
		if (u != null) u.setValue(gl, value, textures);
	}

	public function setOptional(gl:WebGLRenderingContext, object:Dynamic, name:String) {
		var v = object[name];
		if (v != null) this.setValue(gl, name, v);
	}

	public static function upload(gl:WebGLRenderingContext, seq:Array<Uniform>, values:Array<Dynamic>, textures:Dynamic) {
		for (i in 0...seq.length) {
			var u = seq[i];
			var v = values[u.id];
			if (v.needsUpdate != false) {
				u.setValue(gl, v.value, textures);
			}
		}
	}

	public static function seqWithValue(seq:Array<Uniform>, values:Array<Dynamic>):Array<Uniform> {
		var r = new Array();
		for (i in 0...seq.length) {
			var u = seq[i];
			if (values.exists(u.id)) r.push(u);
		}
		return r;
	}
}

class Uniform {

	public var id:Dynamic;
	public var addr:Dynamic;
	public var cache:Array<Dynamic>;
	public var type:Int;
	public var setValue:Dynamic;

	public function new(id:Dynamic, activeInfo:Dynamic, addr:Dynamic) {
		this.id = id;
		this.addr = addr;
		this.cache = new Array();
		this.type = activeInfo.type;
		this.setValue = getSingularSetter(activeInfo.type);
	}

	public function setValue(gl:WebGLRenderingContext, value:Dynamic, textures:Dynamic) {
		// TODO: Implement setValue for each Uniform type
	}
}

class PureArrayUniform extends Uniform {

	public var size:Int;

	public function new(id:Dynamic, activeInfo:Dynamic, addr:Dynamic) {
		super(id, activeInfo, addr);
		this.size = activeInfo.size;
		this.setValue = getPureArraySetter(activeInfo.type);
	}
}

class StructuredUniform extends Uniform {

	public var seq:Array<Uniform>;
	public var map:Map<String, Uniform>;

	public function new(id:Dynamic) {
		super(id, null, null); // TODO: Pass activeInfo?
		this.seq = new Array();
		this.map = new Map();
	}

	override public function setValue(gl:WebGLRenderingContext, value:Dynamic, textures:Dynamic) {
		for (i in 0...this.seq.length) {
			var u = this.seq[i];
			u.setValue(gl, value[u.id], textures);
		}
	}
}

// --- Helpers ---

private var emptyTexture = new Texture();
private var emptyShadowTexture = new DepthTexture(1, 1);
emptyShadowTexture.compareFunction = LessEqualCompare;
private var emptyArrayTexture = new DataArrayTexture();
private var empty3dTexture = new Data3DTexture();
private var emptyCubeTexture = new CubeTexture();

private var arrayCacheF32:Array<Float32Array> = new Array();
private var arrayCacheI32:Array<Int32Array> = new Array();

private var mat4array = new Float32Array(16);
private var mat3array = new Float32Array(9);
private var mat2array = new Float32Array(4);

private function flatten(array:Array<Dynamic>, nBlocks:Int, blockSize:Int):Float32Array {
	var firstElem = array[0];
	if (firstElem <= 0 || firstElem > 0) return array;
	var n = nBlocks * blockSize;
	var r = arrayCacheF32[n];
	if (r == null) {
		r = new Float32Array(n);
		arrayCacheF32[n] = r;
	}
	if (nBlocks != 0) {
		firstElem.toArray(r, 0);
		for (i in 1...nBlocks) {
			r.set(array[i].toArray(), i * blockSize);
		}
	}
	return r;
}

private function arraysEqual(a:Array<Dynamic>, b:Array<Dynamic>):Bool {
	if (a.length != b.length) return false;
	for (i in 0...a.length) {
		if (a[i] != b[i]) return false;
	}
	return true;
}

private function copyArray(a:Array<Dynamic>, b:Array<Dynamic>) {
	for (i in 0...b.length) {
		a[i] = b[i];
	}
}

private function allocTexUnits(textures:Dynamic, n:Int):Int32Array {
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

// --- Setters ---

private function setValueV1f(gl:WebGLRenderingContext, v:Float) {
	var cache = this.cache;
	if (cache[0] == v) return;
	gl.uniform1f(this.addr, v);
	cache[0] = v;
}

private function setValueV2f(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;
	if (v.x != null) {
		if (cache[0] != v.x || cache[1] != v.y) {
			gl.uniform2f(this.addr, v.x, v.y);
			cache[0] = v.x;
			cache[1] = v.y;
		}
	} else {
		if (arraysEqual(cache, v)) return;
		gl.uniform2fv(this.addr, v);
		copyArray(cache, v);
	}
}

private function setValueV3f(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;
	if (v.x != null) {
		if (cache[0] != v.x || cache[1] != v.y || cache[2] != v.z) {
			gl.uniform3f(this.addr, v.x, v.y, v.z);
			cache[0] = v.x;
			cache[1] = v.y;
			cache[2] = v.z;
		}
	} else if (v.r != null) {
		if (cache[0] != v.r || cache[1] != v.g || cache[2] != v.b) {
			gl.uniform3f(this.addr, v.r, v.g, v.b);
			cache[0] = v.r;
			cache[1] = v.g;
			cache[2] = v.b;
		}
	} else {
		if (arraysEqual(cache, v)) return;
		gl.uniform3fv(this.addr, v);
		copyArray(cache, v);
	}
}

private function setValueV4f(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;
	if (v.x != null) {
		if (cache[0] != v.x || cache[1] != v.y || cache[2] != v.z || cache[3] != v.w) {
			gl.uniform4f(this.addr, v.x, v.y, v.z, v.w);
			cache[0] = v.x;
			cache[1] = v.y;
			cache[2] = v.z;
			cache[3] = v.w;
		}
	} else {
		if (arraysEqual(cache, v)) return;
		gl.uniform4fv(this.addr, v);
		copyArray(cache, v);
	}
}

private function setValueM2(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;
	var elements = v.elements;
	if (elements == null) {
		if (arraysEqual(cache, v)) return;
		gl.uniformMatrix2fv(this.addr, false, v);
		copyArray(cache, v);
	} else {
		if (arraysEqual(cache, elements)) return;
		mat2array.set(elements);
		gl.uniformMatrix2fv(this.addr, false, mat2array);
		copyArray(cache, elements);
	}
}

private function setValueM3(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;
	var elements = v.elements;
	if (elements == null) {
		if (arraysEqual(cache, v)) return;
		gl.uniformMatrix3fv(this.addr, false, v);
		copyArray(cache, v);
	} else {
		if (arraysEqual(cache, elements)) return;
		mat3array.set(elements);
		gl.uniformMatrix3fv(this.addr, false, mat3array);
		copyArray(cache, elements);
	}
}

private function setValueM4(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;
	var elements = v.elements;
	if (elements == null) {
		if (arraysEqual(cache, v)) return;
		gl.uniformMatrix4fv(this.addr, false, v);
		copyArray(cache, v);
	} else {
		if (arraysEqual(cache, elements)) return;
		mat4array.set(elements);
		gl.uniformMatrix4fv(this.addr, false, mat4array);
		copyArray(cache, elements);
	}
}

private function setValueV1i(gl:WebGLRenderingContext, v:Int) {
	var cache = this.cache;
	if (cache[0] == v) return;
	gl.uniform1i(this.addr, v);
	cache[0] = v;
}

private function setValueV2i(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;
	if (v.x != null) {
		if (cache[0] != v.x || cache[1] != v.y) {
			gl.uniform2i(this.addr, v.x, v.y);
			cache[0] = v.x;
			cache[1] = v.y;
		}
	} else {
		if (arraysEqual(cache, v)) return;
		gl.uniform2iv(this.addr, v);
		copyArray(cache, v);
	}
}

private function setValueV3i(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;
	if (v.x != null) {
		if (cache[0] != v.x || cache[1] != v.y || cache[2] != v.z) {
			gl.uniform3i(this.addr, v.x, v.y, v.z);
			cache[0] = v.x;
			cache[1] = v.y;
			cache[2] = v.z;
		}
	} else {
		if (arraysEqual(cache, v)) return;
		gl.uniform3iv(this.addr, v);
		copyArray(cache, v);
	}
}

private function setValueV4i(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;
	if (v.x != null) {
		if (cache[0] != v.x || cache[1] != v.y || cache[2] != v.z || cache[3] != v.w) {
			gl.uniform4i(this.addr, v.x, v.y, v.z, v.w);
			cache[0] = v.x;
			cache[1] = v.y;
			cache[2] = v.z;
			cache[3] = v.w;
		}
	} else {
		if (arraysEqual(cache, v)) return;
		gl.uniform4iv(this.addr, v);
		copyArray(cache, v);
	}
}

private function setValueV1ui(gl:WebGLRenderingContext, v:Int) {
	var cache = this.cache;
	if (cache[0] == v) return;
	gl.uniform1ui(this.addr, v);
	cache[0] = v;
}

private function setValueV2ui(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;
	if (v.x != null) {
		if (cache[0] != v.x || cache[1] != v.y) {
			gl.uniform2ui(this.addr, v.x, v.y);
			cache[0] = v.x;
			cache[1] = v.y;
		}
	} else {
		if (arraysEqual(cache, v)) return;
		gl.uniform2uiv(this.addr, v);
		copyArray(cache, v);
	}
}

private function setValueV3ui(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;
	if (v.x != null) {
		if (cache[0] != v.x || cache[1] != v.y || cache[2] != v.z) {
			gl.uniform3ui(this.addr, v.x, v.y, v.z);
			cache[0] = v.x;
			cache[1] = v.y;
			cache[2] = v.z;
		}
	} else {
		if (arraysEqual(cache, v)) return;
		gl.uniform3uiv(this.addr, v);
		copyArray(cache, v);
	}
}

private function setValueV4ui(gl:WebGLRenderingContext, v:Dynamic) {
	var cache = this.cache;
	if (v.x != null) {
		if (cache[0] != v.x || cache[1] != v.y || cache[2] != v.z || cache[3] != v.w) {
			gl.uniform4ui(this.addr, v.x, v.y, v.z, v.w);
			cache[0] = v.x;
			cache[1] = v.y;
			cache[2] = v.z;
			cache[3] = v.w;
		}
	} else {
		if (arraysEqual(cache, v)) return;
		gl.uniform4uiv(this.addr, v);
		copyArray(cache, v);
	}
}

private function setValueT1(gl:WebGLRenderingContext, v:Dynamic, textures:Dynamic) {
	var cache = this.cache;
	var unit = textures.allocateTextureUnit();
	if (cache[0] != unit) {
		gl.uniform1i(this.addr, unit);
		cache[0] = unit;
	}
	var emptyTexture2D = (this.type == gl.SAMPLER_2D_SHADOW) ? emptyShadowTexture : emptyTexture;
	textures.setTexture2D(v != null ? v : emptyTexture2D, unit);
}

private function setValueT3D1(gl:WebGLRenderingContext, v:Dynamic, textures:Dynamic) {
	var cache = this.cache;
	var unit = textures.allocateTextureUnit();
	if (cache[0] != unit) {
		gl.uniform1i(this.addr, unit);
		cache[0] = unit;
	}
	textures.setTexture3D(v != null ? v : empty3dTexture, unit);
}

private function setValueT6(gl:WebGLRenderingContext, v:Dynamic, textures:Dynamic) {
	var cache = this.cache;
	var unit = textures.allocateTextureUnit();
	if (cache[0] != unit) {
		gl.uniform1i(this.addr, unit);
		cache[0] = unit;
	}
	textures.setTextureCube(v != null ? v : emptyCubeTexture, unit);
}

private function setValueT2DArray1(gl:WebGLRenderingContext, v:Dynamic, textures:Dynamic) {
	var cache = this.cache;
	var unit = textures.allocateTextureUnit();
	if (cache[0] != unit) {
		gl.uniform1i(this.addr, unit);
		cache[0] = unit;
	}
	textures.setTexture2DArray(v != null ? v : emptyArrayTexture, unit);
}

private function getSingularSetter(type:Int):Dynamic {
	switch (type) {
		case 0x1406: return setValueV1f; // FLOAT
		case 0x8b50: return setValueV2f; // _VEC2
		case 0x8b51: return setValueV3f; // _VEC3
		case 0x8b52: return setValueV4f; // _VEC4
		case 0x8b5a: return setValueM2; // _MAT2
		case 0x8b5b: return setValueM3; // _MAT3
		case 0x8b5c: return setValueM4; // _MAT4
		case 0x1404: case 0x8b56: return setValueV1i; // INT, BOOL
		case 0x8b53: case 0x8b57: return setValueV2i; // _VEC2
		case 0x8b54: case 0x8b58: return setValueV3i; // _VEC3
		case 0x8b55: case 0x8b59: return setValueV4i; // _VEC4
		case 0x1405: return setValueV1ui; // UINT
		case 0x8dc6: return setValueV2ui; // _VEC2
		case 0x8dc7: return setValueV3ui; // _VEC3
		case 0x8dc8: return setValueV4ui; // _VEC4
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
	return null;
}

private function setValueV1fArray(gl:WebGLRenderingContext, v:Array<Float>) {
	gl.uniform1fv(this.addr, v);
}

// Array of vectors (from flat array or array of THREE.VectorN)

private function setValueV2fArray(gl:WebGLRenderingContext, v:Array<Dynamic>) {
	var data = flatten(v, this.size, 2);
	gl.uniform2fv(this.addr, data);
}

private function setValueV3fArray(gl:WebGLRenderingContext, v:Array<Dynamic>) {
	var data = flatten(v, this.size, 3);
	gl.uniform3fv(this.addr, data);
}

private function setValueV4fArray(gl:WebGLRenderingContext, v:Array<Dynamic>) {
	var data = flatten(v, this.size, 4);
	gl.uniform4fv(this.addr, data);
}

// Array of matrices (from flat array or array of THREE.MatrixN)

private function setValueM2Array(gl:WebGLRenderingContext, v:Array<Dynamic>) {
	var data = flatten(v, this.size, 4);
	gl.uniformMatrix2fv(this.addr, false, data);
}

private function setValueM3Array(gl:WebGLRenderingContext, v:Array<Dynamic>) {
	var data = flatten(v, this.size, 9);
	gl.uniformMatrix3fv(this.addr, false, data);
}

private function setValueM4Array(gl:WebGLRenderingContext, v:Array<Dynamic>) {
	var data = flatten(v, this.size, 16);
	gl.uniformMatrix4fv(this.addr, false, data);
}

// Array of integer / boolean

private function setValueV1iArray(gl:WebGLRenderingContext, v:Array<Int>) {
	gl.uniform1iv(this.addr, v);
}

// Array of integer / boolean vectors (from flat array)

private function setValueV2iArray(gl:WebGLRenderingContext, v:Array<Dynamic>) {
	gl.uniform2iv(this.addr, v);
}

private function setValueV3iArray(gl:WebGLRenderingContext, v:Array<Dynamic>) {
	gl.uniform3iv(this.addr, v);
}

private function setValueV4iArray(gl:WebGLRenderingContext, v:Array<Dynamic>) {
	gl.uniform4iv(this.addr, v);
}

// Array of unsigned integer

private function setValueV1uiArray(gl:WebGLRenderingContext, v:Array<Int>) {
	gl.uniform1uiv(this.addr, v);
}

// Array of unsigned integer vectors (from flat array)

private function setValueV2uiArray(gl:WebGLRenderingContext, v:Array<Dynamic>) {
	gl.uniform2uiv(this.addr, v);
}

private function setValueV3uiArray(gl:WebGLRenderingContext, v:Array<Dynamic>) {
	gl.uniform3uiv(this.addr, v);
}

private function setValueV4uiArray(gl:WebGLRenderingContext, v:Array<Dynamic>) {
	gl.uniform4uiv(this.addr, v);
}


// Array of textures (2D / 3D / Cube / 2DArray)

private function setValueT1Array(gl:WebGLRenderingContext, v:Array<Dynamic>, textures:Dynamic) {
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

private function setValueT3DArray(gl:WebGLRenderingContext, v:Array<Dynamic>, textures:Dynamic) {
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

private function setValueT6Array(gl:WebGLRenderingContext, v:Array<Dynamic>, textures:Dynamic) {
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

private function setValueT2DArrayArray(gl:WebGLRenderingContext, v:Array<Dynamic>, textures:Dynamic) {
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


// Helper to pick the right setter for a pure (bottom-level) array

private function getPureArraySetter(type:Int):Dynamic {
	switch (type) {
		case 0x1406: return setValueV1fArray; // FLOAT
		case 0x8b50: return setValueV2fArray; // _VEC2
		case 0x8b51: return setValueV3fArray; // _VEC3
		case 0x8b52: return setValueV4fArray; // _VEC4
		case 0x8b5a: return setValueM2Array; // _MAT2
		case 0x8b5b: return setValueM3Array; // _MAT3
		case 0x8b5c: return setValueM4Array; // _MAT4
		case 0x1404: case 0x8b56: return setValueV1iArray; // INT, BOOL
		case 0x8b53: case 0x8b57: return setValueV2iArray; // _VEC2
		case 0x8b54: case 0x8b58: return setValueV3iArray; // _VEC3
		case 0x8b55: case 0x8b59: return setValueV4iArray; // _VEC4
		case 0x1405: return setValueV1uiArray; // UINT
		case 0x8dc6: return setValueV2uiArray; // _VEC2
		case 0x8dc7: return setValueV3uiArray; // _VEC3
		case 0x8dc8: return setValueV4uiArray; // _VEC4
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
	return null;
}

// --- Parser ---

private var RePathPart = ~/(\w+)(\])?(\[|\.)?/;

private function addUniform(container:StructuredUniform, uniformObject:Uniform) {
	container.seq.push(uniformObject);
	container.map.set(uniformObject.id, uniformObject);
}

private function parseUniform(activeInfo:Dynamic, addr:Dynamic, container:StructuredUniform) {
	var path = activeInfo.name;
	var pathLength = path.length;

	RePathPart.match(path);
	while (true) {
		var match = RePathPart.match(path);
		if (match == null) break;
		var id = match[1];
		var idIsIndex = match[2] == ']';
		var subscript = match[3];
		if (idIsIndex) id = cast id;
		if (subscript == null || (subscript == '[' && match.index + 2 == pathLength)) {
			addUniform(container, subscript == null ? new SingleUniform(id, activeInfo, addr) : new PureArrayUniform(id, activeInfo, addr));
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