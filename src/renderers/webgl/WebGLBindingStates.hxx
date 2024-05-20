import three.constants.IntType;

class WebGLBindingStates {

	var gl:GL;
	var attributes:Attributes;
	var maxVertexAttributes:Int;
	var bindingStates:Map<String, Map<String, Map<Bool, BindingState>>>;
	var defaultState:BindingState;
	var currentState:BindingState;
	var forceUpdate:Bool;

	public function new(gl:GL, attributes:Attributes) {
		this.gl = gl;
		this.attributes = attributes;
		this.maxVertexAttributes = gl.getParameter(gl.MAX_VERTEX_ATTRIBS);
		this.bindingStates = new Map();
		this.defaultState = this.createBindingState(null);
		this.currentState = this.defaultState;
		this.forceUpdate = false;
	}

	public function setup(object:Dynamic, material:Dynamic, program:Dynamic, geometry:Dynamic, index:Dynamic) {
		var updateBuffers:Bool = false;
		var state:BindingState = this.getBindingState(geometry, program, material);
		if (this.currentState !== state) {
			this.currentState = state;
			this.bindVertexArrayObject(this.currentState.object);
		}
		updateBuffers = this.needsUpdate(object, geometry, program, index);
		if (updateBuffers) this.saveCache(object, geometry, program, index);
		if (index !== null) {
			this.attributes.update(index, this.gl.ELEMENT_ARRAY_BUFFER);
		}
		if (updateBuffers || this.forceUpdate) {
			this.forceUpdate = false;
			this.setupVertexAttributes(object, material, program, geometry);
			if (index !== null) {
				this.gl.bindBuffer(this.gl.ELEMENT_ARRAY_BUFFER, this.attributes.get(index).buffer);
			}
		}
	}

	public function createVertexArrayObject():Dynamic {
		return this.gl.createVertexArray();
	}

	public function bindVertexArrayObject(vao:Dynamic):Dynamic {
		return this.gl.bindVertexArray(vao);
	}

	public function deleteVertexArrayObject(vao:Dynamic):Dynamic {
		return this.gl.deleteVertexArray(vao);
	}

	public function getBindingState(geometry:Dynamic, program:Dynamic, material:Dynamic):BindingState {
		var wireframe:Bool = (material.wireframe === true);
		var programMap:Map<String, BindingState> = this.bindingStates.get(geometry.id);
		if (programMap === undefined) {
			programMap = new Map();
			this.bindingStates.set(geometry.id, programMap);
		}
		var stateMap:Map<Bool, BindingState> = programMap.get(program.id);
		if (stateMap === undefined) {
			stateMap = new Map();
			programMap.set(program.id, stateMap);
		}
		var state:BindingState = stateMap.get(wireframe);
		if (state === undefined) {
			state = this.createBindingState(this.createVertexArrayObject());
			stateMap.set(wireframe, state);
		}
		return state;
	}

	public function createBindingState(vao:Dynamic):BindingState {
		var newAttributes:Array<Int> = [];
		var enabledAttributes:Array<Int> = [];
		var attributeDivisors:Array<Int> = [];
		for (i in 0...this.maxVertexAttributes) {
			newAttributes.push(0);
			enabledAttributes.push(0);
			attributeDivisors.push(0);
		}
		return {
			geometry: null,
			program: null,
			wireframe: false,
			newAttributes: newAttributes,
			enabledAttributes: enabledAttributes,
			attributeDivisors: attributeDivisors,
			object: vao,
			attributes: new Map(),
			index: null
		};
	}

	public function needsUpdate(object:Dynamic, geometry:Dynamic, program:Dynamic, index:Dynamic):Bool {
		var cachedAttributes:Map<String, Dynamic> = this.currentState.attributes;
		var geometryAttributes:Map<String, Dynamic> = geometry.attributes;
		var attributesNum:Int = 0;
		var programAttributes:Map<String, Dynamic> = program.getAttributes();
		for (name in programAttributes.keys()) {
			var programAttribute:Dynamic = programAttributes.get(name);
			if (programAttribute.location >= 0) {
				var cachedAttribute:Dynamic = cachedAttributes.get(name);
				var geometryAttribute:Dynamic = geometryAttributes.get(name);
				if (geometryAttribute === undefined) {
					if (name === 'instanceMatrix' && object.instanceMatrix) geometryAttribute = object.instanceMatrix;
					if (name === 'instanceColor' && object.instanceColor) geometryAttribute = object.instanceColor;
				}
				if (cachedAttribute === undefined) return true;
				if (cachedAttribute.attribute !== geometryAttribute) return true;
				if (geometryAttribute && cachedAttribute.data !== geometryAttribute.data) return true;
				attributesNum++;
			}
		}
		if (this.currentState.attributesNum !== attributesNum) return true;
		if (this.currentState.index !== index) return true;
		return false;
	}

	public function saveCache(object:Dynamic, geometry:Dynamic, program:Dynamic, index:Dynamic) {
		var cache:Map<String, Dynamic> = new Map();
		var attributes:Map<String, Dynamic> = geometry.attributes;
		var attributesNum:Int = 0;
		var programAttributes:Map<String, Dynamic> = program.getAttributes();
		for (name in programAttributes.keys()) {
			var programAttribute:Dynamic = programAttributes.get(name);
			if (programAttribute.location >= 0) {
				var attribute:Dynamic = attributes.get(name);
				if (attribute === undefined) {
					if (name === 'instanceMatrix' && object.instanceMatrix) attribute = object.instanceMatrix;
					if (name === 'instanceColor' && object.instanceColor) attribute = object.instanceColor;
				}
				var data:Dynamic = {};
				data.attribute = attribute;
				if (attribute && attribute.data) {
					data.data = attribute.data;
				}
				cache.set(name, data);
				attributesNum++;
			}
		}
		this.currentState.attributes = cache;
		this.currentState.attributesNum = attributesNum;
		this.currentState.index = index;
	}

	public function initAttributes() {
		var newAttributes:Array<Int> = this.currentState.newAttributes;
		for (i in 0...newAttributes.length) {
			newAttributes[i] = 0;
		}
	}

	public function enableAttribute(attribute:Int) {
		this.enableAttributeAndDivisor(attribute, 0);
	}

	public function enableAttributeAndDivisor(attribute:Int, meshPerAttribute:Int) {
		var newAttributes:Array<Int> = this.currentState.newAttributes;
		var enabledAttributes:Array<Int> = this.currentState.enabledAttributes;
		var attributeDivisors:Array<Int> = this.currentState.attributeDivisors;
		newAttributes[attribute] = 1;
		if (enabledAttributes[attribute] === 0) {
			this.gl.enableVertexAttribArray(attribute);
			enabledAttributes[attribute] = 1;
		}
		if (attributeDivisors[attribute] !== meshPerAttribute) {
			this.gl.vertexAttribDivisor(attribute, meshPerAttribute);
			attributeDivisors[attribute] = meshPerAttribute;
		}
	}

	public function disableUnusedAttributes() {
		var newAttributes:Array<Int> = this.currentState.newAttributes;
		var enabledAttributes:Array<Int> = this.currentState.enabledAttributes;
		for (i in 0...enabledAttributes.length) {
			if (enabledAttributes[i] !== newAttributes[i]) {
				this.gl.disableVertexAttribArray(i);
				enabledAttributes[i] = 0;
			}
		}
	}

	public function vertexAttribPointer(index:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:Int, integer:Bool) {
		if (integer) {
			this.gl.vertexAttribIPointer(index, size, type, stride, offset);
		} else {
			this.gl.vertexAttribPointer(index, size, type, normalized, stride, offset);
		}
	}

	public function setupVertexAttributes(object:Dynamic, material:Dynamic, program:Dynamic, geometry:Dynamic) {
		this.initAttributes();
		var geometryAttributes:Map<String, Dynamic> = geometry.attributes;
		var programAttributes:Map<String, Dynamic> = program.getAttributes();
		var materialDefaultAttributeValues:Map<String, Dynamic> = material.defaultAttributeValues;
		for (name in programAttributes.keys()) {
			var programAttribute:Dynamic = programAttributes.get(name);
			if (programAttribute.location >= 0) {
				var geometryAttribute:Dynamic = geometryAttributes.get(name);
				if (geometryAttribute === undefined) {
					if (name === 'instanceMatrix' && object.instanceMatrix) geometryAttribute = object.instanceMatrix;
					if (name === 'instanceColor' && object.instanceColor) geometryAttribute = object.instanceColor;
				}
				if (geometryAttribute !== undefined) {
					var normalized:Bool = geometryAttribute.normalized;
					var size:Int = geometryAttribute.itemSize;
					var attribute:Dynamic = this.attributes.get(geometryAttribute);
					if (attribute === undefined) continue;
					var buffer:Dynamic = attribute.buffer;
					var type:Int = attribute.type;
					var bytesPerElement:Int = attribute.bytesPerElement;
					var integer:Bool = (type === this.gl.INT || type === this.gl.UNSIGNED_INT || geometryAttribute.gpuType === IntType);
					if (geometryAttribute.isInterleavedBufferAttribute) {
						var data:Dynamic = geometryAttribute.data;
						var stride:Int = data.stride;
						var offset:Int = geometryAttribute.offset;
						if (data.isInstancedInterleavedBuffer) {
							for (i in 0...programAttribute.locationSize) {
								this.enableAttributeAndDivisor(programAttribute.location + i, data.meshPerAttribute);
							}
							if (object.isInstancedMesh !== true && geometry._maxInstanceCount === undefined) {
								geometry._maxInstanceCount = data.meshPerAttribute * data.count;
							}
						} else {
							for (i in 0...programAttribute.locationSize) {
								this.enableAttribute(programAttribute.location + i);
							}
						}
						this.gl.bindBuffer(this.gl.ARRAY_BUFFER, buffer);
						for (i in 0...programAttribute.locationSize) {
							this.vertexAttribPointer(
								programAttribute.location + i,
								size / programAttribute.locationSize,
								type,
								normalized,
								stride * bytesPerElement,
								(offset + (size / programAttribute.locationSize) * i) * bytesPerElement,
								integer
							);
						}
					} else {
						if (geometryAttribute.isInstancedBufferAttribute) {
							for (i in 0...programAttribute.locationSize) {
								this.enableAttributeAndDivisor(programAttribute.location + i, geometryAttribute.meshPerAttribute);
							}
							if (object.isInstancedMesh !== true && geometry._maxInstanceCount === undefined) {
								geometry._maxInstanceCount = geometryAttribute.meshPerAttribute * geometryAttribute.count;
							}
						} else {
							for (i in 0...programAttribute.locationSize) {
								this.enableAttribute(programAttribute.location + i);
							}
						}
						this.gl.bindBuffer(this.gl.ARRAY_BUFFER, buffer);
						for (i in 0...programAttribute.locationSize) {
							this.vertexAttribPointer(
								programAttribute.location + i,
								size / programAttribute.locationSize,
								type,
								normalized,
								size * bytesPerElement,
								(size / programAttribute.locationSize) * i * bytesPerElement,
								integer
							);
						}
					}
				} else if (materialDefaultAttributeValues !== undefined) {
					var value:Dynamic = materialDefaultAttributeValues.get(name);
					if (value !== undefined) {
						switch (value.length) {
							case 2:
								this.gl.vertexAttrib2fv(programAttribute.location, value);
								break;
							case 3:
								this.gl.vertexAttrib3fv(programAttribute.location, value);
								break;
							case 4:
								this.gl.vertexAttrib4fv(programAttribute.location, value);
								break;
							default:
								this.gl.vertexAttrib1fv(programAttribute.location, value);
						}
					}
				}
			}
		}
		this.disableUnusedAttributes();
	}

	public function dispose() {
		this.reset();
		for (geometryId in this.bindingStates.keys()) {
			var programMap:Map<String, Map<Bool, BindingState>> = this.bindingStates.get(geometryId);
			for (programId in programMap.keys()) {
				var stateMap:Map<Bool, BindingState> = programMap.get(programId);
				for (wireframe in stateMap.keys()) {
					this.deleteVertexArrayObject(stateMap.get(wireframe).object);
					stateMap.remove(wireframe);
				}
				programMap.remove(programId);
			}
			this.bindingStates.remove(geometryId);
		}
	}

	public function releaseStatesOfGeometry(geometry:Dynamic) {
		if (this.bindingStates.get(geometry.id) === undefined) return;
		var programMap:Map<String, Map<Bool, BindingState>> = this.bindingStates.get(geometry.id);
		for (programId in programMap.keys()) {
			var stateMap:Map<Bool, BindingState> = programMap.get(programId);
			for (wireframe in stateMap.keys()) {
				this.deleteVertexArrayObject(stateMap.get(wireframe).object);
				stateMap.remove(wireframe);
			}
			programMap.remove(programId);
		}
		this.bindingStates.remove(geometry.id);
	}

	public function releaseStatesOfProgram(program:Dynamic) {
		for (geometryId in this.bindingStates.keys()) {
			var programMap:Map<String, Map<Bool, BindingState>> = this.bindingStates.get(geometryId);
			if (programMap.get(program.id) === undefined) continue;
			var stateMap:Map<Bool, BindingState> = programMap.get(program.id);
			for (wireframe in stateMap.keys()) {
				this.deleteVertexArrayObject(stateMap.get(wireframe).object);
				stateMap.remove(wireframe);
			}
			programMap.remove(program.id);
		}
	}

	public function reset() {
		this.resetDefaultState();
		this.forceUpdate = true;
		if (this.currentState === this.defaultState) return;
		this.currentState = this.defaultState;
		this.bindVertexArrayObject(this.currentState.object);
	}

	public function resetDefaultState() {
		this.defaultState.geometry = null;
		this.defaultState.program = null;
		this.defaultState.wireframe = false;
	}

	public function initAttributes() {
		this.initAttributes();
	}

	public function enableAttribute(attribute:Int) {
		this.enableAttribute(attribute);
	}

	public function disableUnusedAttributes() {
		this.disableUnusedAttributes();
	}

}