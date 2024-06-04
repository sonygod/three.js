class WebGLUniformsGroups {

	public var buffers:Map<Int, WebGLBuffer>;
	public var updateList:Map<Int, Int>;
	public var allocatedBindingPoints:Array<Int>;

	public var maxBindingPoints:Int;

	public function new(gl:WebGLRenderingContext, info:Dynamic, capabilities:Dynamic, state:Dynamic) {
		buffers = new Map<Int, WebGLBuffer>();
		updateList = new Map<Int, Int>();
		allocatedBindingPoints = new Array<Int>();

		maxBindingPoints = gl.getParameter(gl.MAX_UNIFORM_BUFFER_BINDINGS); // binding points are global whereas block indices are per shader program
	}

	public function bind(uniformsGroup:Dynamic, program:Dynamic):Void {
		var webglProgram:Dynamic = program.program;
		state.uniformBlockBinding(uniformsGroup, webglProgram);
	}

	public function update(uniformsGroup:Dynamic, program:Dynamic):Void {
		var buffer:WebGLBuffer = buffers.get(uniformsGroup.id);

		if (buffer == null) {
			prepareUniformsGroup(uniformsGroup);

			buffer = createBuffer(uniformsGroup);
			buffers.set(uniformsGroup.id, buffer);

			uniformsGroup.addEventListener('dispose', onUniformsGroupsDispose);
		}

		// ensure to update the binding points/block indices mapping for this program
		var webglProgram:Dynamic = program.program;
		state.updateUBOMapping(uniformsGroup, webglProgram);

		// update UBO once per frame
		var frame:Int = info.render.frame;

		if (updateList.get(uniformsGroup.id) != frame) {
			updateBufferData(uniformsGroup);

			updateList.set(uniformsGroup.id, frame);
		}
	}

	public function createBuffer(uniformsGroup:Dynamic):WebGLBuffer {
		// the setup of an UBO is independent of a particular shader program but global
		var bindingPointIndex:Int = allocateBindingPointIndex();
		uniformsGroup.__bindingPointIndex = bindingPointIndex;

		var buffer:WebGLBuffer = gl.createBuffer();
		var size:Int = uniformsGroup.__size;
		var usage:Int = uniformsGroup.usage;

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

		console.error('THREE.WebGLRenderer: Maximum number of simultaneously usable uniforms groups reached.');
		return 0;
	}

	public function updateBufferData(uniformsGroup:Dynamic):Void {
		var buffer:WebGLBuffer = buffers.get(uniformsGroup.id);
		var uniforms:Array<Dynamic> = uniformsGroup.uniforms;
		var cache:Dynamic = uniformsGroup.__cache;

		gl.bindBuffer(gl.UNIFORM_BUFFER, buffer);

		for (i in 0...uniforms.length) {
			var uniformArray:Array<Dynamic> = Std.isOfType(uniforms[i], Array) ? cast(uniforms[i], Array<Dynamic>) : [uniforms[i]];

			for (j in 0...uniformArray.length) {
				var uniform:Dynamic = uniformArray[j];

				if (hasUniformChanged(uniform, i, j, cache)) {
					var offset:Int = uniform.__offset;

					var values:Array<Dynamic> = Std.isOfType(uniform.value, Array) ? cast(uniform.value, Array<Dynamic>) : [uniform.value];

					var arrayOffset:Int = 0;

					for (k in 0...values.length) {
						var value:Dynamic = values[k];

						var info:Dynamic = getUniformSize(value);

						// TODO add integer and struct support
						if (Std.isOfType(value, Float) || Std.isOfType(value, Bool)) {
							uniform.__data[0] = value;
							gl.bufferSubData(gl.UNIFORM_BUFFER, offset + arrayOffset, uniform.__data);
						} else if (Std.isOfType(value, Matrix3)) {
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
		var value:Dynamic = uniform.value;
		var indexString:String = index + '_' + indexArray;

		if (cache[indexString] == null) {
			// cache entry does not exist so far

			if (Std.isOfType(value, Float) || Std.isOfType(value, Bool)) {
				cache[indexString] = value;
			} else {
				cache[indexString] = value.clone();
			}

			return true;
		} else {
			var cachedObject:Dynamic = cache[indexString];

			// compare current value with cached entry

			if (Std.isOfType(value, Float) || Std.isOfType(value, Bool)) {
				if (cachedObject != value) {
					cache[indexString] = value;
					return true;
				}
			} else {
				if (!cachedObject.equals(value)) {
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

		var uniforms:Array<Dynamic> = uniformsGroup.uniforms;

		var offset:Int = 0; // global buffer offset in bytes
		var chunkSize:Int = 16; // size of a chunk in bytes

		for (i in 0...uniforms.length) {
			var uniformArray:Array<Dynamic> = Std.isOfType(uniforms[i], Array) ? cast(uniforms[i], Array<Dynamic>) : [uniforms[i]];

			for (j in 0...uniformArray.length) {
				var uniform:Dynamic = uniformArray[j];

				var values:Array<Dynamic> = Std.isOfType(uniform.value, Array) ? cast(uniform.value, Array<Dynamic>) : [uniform.value];

				for (k in 0...values.length) {
					var value:Dynamic = values[k];

					var info:Dynamic = getUniformSize(value);

					// Calculate the chunk offset
					var chunkOffsetUniform:Int = offset % chunkSize;

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

		var chunkOffset:Int = offset % chunkSize;

		if (chunkOffset > 0) offset += (chunkSize - chunkOffset);

		//

		uniformsGroup.__size = offset;
		uniformsGroup.__cache = new Map<String, Dynamic>();
	}

	public function getUniformSize(value:Dynamic):Dynamic {
		var info:Dynamic = {
			boundary: 0, // bytes
			storage: 0 // bytes
		};

		// determine sizes according to STD140

		if (Std.isOfType(value, Float) || Std.isOfType(value, Bool)) {
			// float/int/bool

			info.boundary = 4;
			info.storage = 4;
		} else if (Std.isOfType(value, Vector2)) {
			// vec2

			info.boundary = 8;
			info.storage = 8;
		} else if (Std.isOfType(value, Vector3) || Std.isOfType(value, Color)) {
			// vec3

			info.boundary = 16;
			info.storage = 12; // evil: vec3 must start on a 16-byte boundary but it only consumes 12 bytes
		} else if (Std.isOfType(value, Vector4)) {
			// vec4

			info.boundary = 16;
			info.storage = 16;
		} else if (Std.isOfType(value, Matrix3)) {
			// mat3 (in STD140 a 3x3 matrix is represented as 3x4)

			info.boundary = 48;
			info.storage = 48;
		} else if (Std.isOfType(value, Matrix4)) {
			// mat4

			info.boundary = 64;
			info.storage = 64;
		} else if (Std.isOfType(value, Texture)) {
			console.warn('THREE.WebGLRenderer: Texture samplers can not be part of an uniforms group.');
		} else {
			console.warn('THREE.WebGLRenderer: Unsupported uniform value type.', value);
		}

		return info;
	}

	public function onUniformsGroupsDispose(event:Dynamic):Void {
		var uniformsGroup:Dynamic = event.target;

		uniformsGroup.removeEventListener('dispose', onUniformsGroupsDispose);

		var index:Int = allocatedBindingPoints.indexOf(uniformsGroup.__bindingPointIndex);
		allocatedBindingPoints.splice(index, 1);

		gl.deleteBuffer(buffers.get(uniformsGroup.id));

		buffers.remove(uniformsGroup.id);
		updateList.remove(uniformsGroup.id);
	}

	public function dispose():Void {
		for (id in buffers.keys()) {
			gl.deleteBuffer(buffers.get(id));
		}

		allocatedBindingPoints = new Array<Int>();
		buffers = new Map<Int, WebGLBuffer>();
		updateList = new Map<Int, Int>();
	}

}