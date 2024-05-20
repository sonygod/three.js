class WebGLUniformsGroups {

	var buffers:Map<String, Int>;
	var updateList:Map<String, Int>;
	var allocatedBindingPoints:Array<Int>;
	var maxBindingPoints:Int;

	public function new(gl:WebGLRenderingContext, info:Dynamic, capabilities:Dynamic, state:Dynamic) {

		buffers = new Map();
		updateList = new Map();
		allocatedBindingPoints = [];

		maxBindingPoints = gl.getParameter(gl.MAX_UNIFORM_BUFFER_BINDINGS); // binding points are global whereas block indices are per shader program

	}

	public function bind(uniformsGroup:Dynamic, program:Dynamic):Void {

		var webglProgram = program.program;
		state.uniformBlockBinding(uniformsGroup, webglProgram);

	}

	public function update(uniformsGroup:Dynamic, program:Dynamic):Void {

		var buffer = buffers.get(uniformsGroup.id);

		if (buffer == null) {

			prepareUniformsGroup(uniformsGroup);

			buffer = createBuffer(uniformsGroup);
			buffers.set(uniformsGroup.id, buffer);

			uniformsGroup.addEventListener('dispose', onUniformsGroupsDispose);

		}

		// ensure to update the binding points/block indices mapping for this program

		var webglProgram = program.program;
		state.updateUBOMapping(uniformsGroup, webglProgram);

		// update UBO once per frame

		var frame = info.render.frame;

		if (updateList.get(uniformsGroup.id) != frame) {

			updateBufferData(uniformsGroup);

			updateList.set(uniformsGroup.id, frame);

		}

	}

	public function createBuffer(uniformsGroup:Dynamic):Int {

		// the setup of an UBO is independent of a particular shader program but global

		var bindingPointIndex = allocateBindingPointIndex();
		uniformsGroup.__bindingPointIndex = bindingPointIndex;

		var buffer = gl.createBuffer();
		var size = uniformsGroup.__size;
		var usage = uniformsGroup.usage;

		gl.bindBuffer(gl.UNIFORM_BUFFER, buffer);
		gl.bufferData(gl.UNIFORM_BUFFER, size, usage);
		gl.bindBuffer(gl.UNIFORM_BUFFER, null);
		gl.bindBufferBase(gl.UNIFORM_BUFFER, bindingPointIndex, buffer);

		return buffer;

	}

	public function allocateBindingPointIndex():Int {

		for (i in 0...maxBindingPoints) {

			if (allocatedBindingPoints.indexOf(i) == -1) {

				allocatedBindingPoints.push(i);
				return i;

			}

		}

		trace('THREE.WebGLRenderer: Maximum number of simultaneously usable uniforms groups reached.');

		return 0;

	}

	public function updateBufferData(uniformsGroup:Dynamic):Void {

		var buffer = buffers.get(uniformsGroup.id);
		var uniforms = uniformsGroup.uniforms;
		var cache = uniformsGroup.__cache;

		gl.bindBuffer(gl.UNIFORM_BUFFER, buffer);

		for (i in 0...uniforms.length) {

			var uniformArray = (uniforms[i] is Array) ? uniforms[i] : [uniforms[i]];

			for (j in 0...uniformArray.length) {

				var uniform = uniformArray[j];

				if (hasUniformChanged(uniform, i, j, cache)) {

					var offset = uniform.__offset;

					var values = (uniform.value is Array) ? uniform.value : [uniform.value];

					var arrayOffset = 0;

					for (k in 0...values.length) {

						var value = values[k];

						var info = getUniformSize(value);

						// TODO add integer and struct support
						if (Std.is(value, Number) || Std.is(value, Bool)) {

							uniform.__data[0] = value;
							gl.bufferSubData(gl.UNIFORM_BUFFER, offset + arrayOffset, uniform.__data);

						} else if (value.isMatrix3) {

							// manually converting 3x3 to 3x4

							uniform.__data[0] = value.elements[0];
							uniform.__data[1] = value.elements[1];
							uniform.__data[2] = value.elements[2];
							uniform.__data[3] = 0;
							uniform.__data[4] = value.elements[3];
							uniform.__data[5] = value.elements[4];
							uniform.__data[6] = value.elements[5];
							uniform.__data[7] = 0;
							uniform.__data[8] = value.elements[6];
							uniform.__data[9] = value.elements[7];
							uniform.__data[10] = value.elements[8];
							uniform.__data[11] = 0;

						} else {

							value.toArray(uniform.__data, arrayOffset);

							arrayOffset += info.storage / Float32Array.BYTES_PER_ELEMENT;

						}

					}

					gl.bufferSubData(gl.UNIFORM_BUFFER, offset, uniform.__data);

				}

			}

		}

		gl.bindBuffer(gl.UNIFORM_BUFFER, null);

	}

	public function hasUniformChanged(uniform:Dynamic, index:Int, indexArray:Int, cache:Dynamic):Bool {

		var value = uniform.value;
		var indexString = index + '_' + indexArray;

		if (cache[indexString] == null) {

			// cache entry does not exist so far

			if (Std.is(value, Number) || Std.is(value, Bool)) {

				cache[indexString] = value;

			} else {

				cache[indexString] = value.clone();

			}

			return true;

		} else {

			var cachedObject = cache[indexString];

			// compare current value with cached entry

			if (Std.is(value, Number) || Std.is(value, Bool)) {

				if (cachedObject != value) {

					cache[indexString] = value;
					return true;

				}

			} else {

				if (cachedObject.equals(value) == false) {

					cachedObject.copy(value);
					return true;

				}

			}

		}

		return false;

	}

	public function prepareUniformsGroup(uniformsGroup:Dynamic):Void {

		// determine total buffer size according to the STD140 layout
		// Hint: STD140 is the only supported layout in WebGL 2

		var uniforms = uniformsGroup.uniforms;

		var offset = 0; // global buffer offset in bytes
		var chunkSize = 16; // size of a chunk in bytes

		for (i in 0...uniforms.length) {

			var uniformArray = (uniforms[i] is Array) ? uniforms[i] : [uniforms[i]];

			for (j in 0...uniformArray.length) {

				var uniform = uniformArray[j];

				var values = (uniform.value is Array) ? uniform.value : [uniform.value];

				for (k in 0...values.length) {

					var value = values[k];

					var info = getUniformSize(value);

					// Calculate the chunk offset
					var chunkOffsetUniform = offset % chunkSize;

					// Check for chunk overflow
					if (chunkOffsetUniform != 0 && (chunkSize - chunkOffsetUniform) < info.boundary) {

						// Add padding and adjust offset
						offset += (chunkSize - chunkOffsetUniform);

					}

					// the following two properties will be used for partial buffer updates

					uniform.__data = new Float32Array(info.storage / Float32Array.BYTES_PER_ELEMENT);
					uniform.__offset = offset;


					// Update the global offset
					offset += info.storage;


				}

			}

		}

		// ensure correct final padding

		var chunkOffset = offset % chunkSize;

		if (chunkOffset > 0) offset += (chunkSize - chunkOffset);

		//

		uniformsGroup.__size = offset;
		uniformsGroup.__cache = {};

		return this;

	}

	public function getUniformSize(value:Dynamic):Dynamic {

		var info = {
			boundary: 0, // bytes
			storage: 0 // bytes
		};

		// determine sizes according to STD140

		if (Std.is(value, Number) || Std.is(value, Bool)) {

			// float/int/bool

			info.boundary = 4;
			info.storage = 4;

		} else if (value.isVector2) {

			// vec2

			info.boundary = 8;
			info.storage = 8;

		} else if (value.isVector3 || value.isColor) {

			// vec3

			info.boundary = 16;
			info.storage = 12; // evil: vec3 must start on a 16-byte boundary but it only consumes 12 bytes

		} else if (value.isVector4) {

			// vec4

			info.boundary = 16;
			info.storage = 16;

		} else if (value.isMatrix3) {

			// mat3 (in STD140 a 3x3 matrix is represented as 3x4)

			info.boundary = 48;
			info.storage = 48;

		} else if (value.isMatrix4) {

			// mat4

			info.boundary = 64;
			info.storage = 64;

		} else if (value.isTexture) {

			trace('THREE.WebGLRenderer: Texture samplers can not be part of an uniforms group.');

		} else {

			trace('THREE.WebGLRenderer: Unsupported uniform value type.', value);

		}

		return info;

	}

	public function onUniformsGroupsDispose(event:Dynamic):Void {

		var uniformsGroup = event.target;

		uniformsGroup.removeEventListener('dispose', onUniformsGroupsDispose);

		var index = allocatedBindingPoints.indexOf(uniformsGroup.__bindingPointIndex);
		allocatedBindingPoints.splice(index, 1);

		gl.deleteBuffer(buffers.get(uniformsGroup.id));

		buffers.remove(uniformsGroup.id);
		updateList.remove(uniformsGroup.id);

	}

	public function dispose():Void {

		for (id in buffers.keys()) {

			gl.deleteBuffer(buffers.get(id));

		}

		allocatedBindingPoints = [];
		buffers = new Map();
		updateList = new Map();

	}

}