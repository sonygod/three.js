import constants.IntType;

class WebGLBindingStates {

  public var gl: WebGLRenderingContext;
  public var attributes: Attributes;

  public var maxVertexAttributes: Int;
  public var bindingStates: Map<Int, Map<Int, Map<Bool, BindingState>>> = new Map();
  public var defaultState: BindingState;
  public var currentState: BindingState;
  public var forceUpdate: Bool = false;

  public function new(gl: WebGLRenderingContext, attributes: Attributes) {
    this.gl = gl;
    this.attributes = attributes;
    this.maxVertexAttributes = gl.getParameter(gl.MAX_VERTEX_ATTRIBS);
    this.defaultState = createBindingState(null);
    this.currentState = defaultState;
  }

  public function setup(object: Dynamic, material: Dynamic, program: Dynamic, geometry: Dynamic, index: Null<Int>): Void {
    var updateBuffers: Bool = false;

    var state = getBindingState(geometry, program, material);

    if (currentState != state) {
      currentState = state;
      bindVertexArrayObject(currentState.object);
    }

    updateBuffers = needsUpdate(object, geometry, program, index);

    if (updateBuffers) saveCache(object, geometry, program, index);

    if (index != null) {
      attributes.update(index, gl.ELEMENT_ARRAY_BUFFER);
    }

    if (updateBuffers || forceUpdate) {
      forceUpdate = false;
      setupVertexAttributes(object, material, program, geometry);

      if (index != null) {
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, attributes.get(index).buffer);
      }
    }
  }

  public function createVertexArrayObject(): Dynamic {
    return gl.createVertexArray();
  }

  public function bindVertexArrayObject(vao: Dynamic): Dynamic {
    return gl.bindVertexArray(vao);
  }

  public function deleteVertexArrayObject(vao: Dynamic): Void {
    return gl.deleteVertexArray(vao);
  }

  public function getBindingState(geometry: Dynamic, program: Dynamic, material: Dynamic): BindingState {
    var wireframe: Bool = material.wireframe == true;

    var programMap: Map<Int, Map<Bool, BindingState>> = bindingStates.get(geometry.id);

    if (programMap == null) {
      programMap = new Map();
      bindingStates.set(geometry.id, programMap);
    }

    var stateMap: Map<Bool, BindingState> = programMap.get(program.id);

    if (stateMap == null) {
      stateMap = new Map();
      programMap.set(program.id, stateMap);
    }

    var state: BindingState = stateMap.get(wireframe);

    if (state == null) {
      state = createBindingState(createVertexArrayObject());
      stateMap.set(wireframe, state);
    }

    return state;
  }

  public function createBindingState(vao: Null<Dynamic>): BindingState {
    var newAttributes: Array<Int> = new Array(maxVertexAttributes);
    var enabledAttributes: Array<Int> = new Array(maxVertexAttributes);
    var attributeDivisors: Array<Int> = new Array(maxVertexAttributes);

    for (i in 0...maxVertexAttributes) {
      newAttributes[i] = 0;
      enabledAttributes[i] = 0;
      attributeDivisors[i] = 0;
    }

    return {
      // for backward compatibility on non-VAO support browser
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

  public function needsUpdate(object: Dynamic, geometry: Dynamic, program: Dynamic, index: Null<Int>): Bool {
    var cachedAttributes: Map<String, AttributeData> = currentState.attributes;
    var geometryAttributes: Map<String, Dynamic> = geometry.attributes;

    var attributesNum: Int = 0;

    var programAttributes: Map<String, Dynamic> = program.getAttributes();

    for (name in programAttributes) {
      var programAttribute: Dynamic = programAttributes.get(name);

      if (programAttribute.location >= 0) {
        var cachedAttribute: AttributeData = cachedAttributes.get(name);
        var geometryAttribute: Dynamic = geometryAttributes.get(name);

        if (geometryAttribute == null) {
          if (name == 'instanceMatrix' && object.instanceMatrix != null) geometryAttribute = object.instanceMatrix;
          if (name == 'instanceColor' && object.instanceColor != null) geometryAttribute = object.instanceColor;
        }

        if (cachedAttribute == null) return true;

        if (cachedAttribute.attribute != geometryAttribute) return true;

        if (geometryAttribute != null && cachedAttribute.data != geometryAttribute.data) return true;

        attributesNum++;
      }
    }

    if (currentState.attributesNum != attributesNum) return true;

    if (currentState.index != index) return true;

    return false;
  }

  public function saveCache(object: Dynamic, geometry: Dynamic, program: Dynamic, index: Null<Int>): Void {
    var cache: Map<String, AttributeData> = new Map();
    var attributes: Map<String, Dynamic> = geometry.attributes;
    var attributesNum: Int = 0;

    var programAttributes: Map<String, Dynamic> = program.getAttributes();

    for (name in programAttributes) {
      var programAttribute: Dynamic = programAttributes.get(name);

      if (programAttribute.location >= 0) {
        var attribute: Dynamic = attributes.get(name);

        if (attribute == null) {
          if (name == 'instanceMatrix' && object.instanceMatrix != null) attribute = object.instanceMatrix;
          if (name == 'instanceColor' && object.instanceColor != null) attribute = object.instanceColor;
        }

        var data: AttributeData = {
          attribute: attribute,
          data: null
        };

        if (attribute != null && attribute.data != null) {
          data.data = attribute.data;
        }

        cache.set(name, data);

        attributesNum++;
      }
    }

    currentState.attributes = cache;
    currentState.attributesNum = attributesNum;

    currentState.index = index;
  }

  public function initAttributes(): Void {
    var newAttributes: Array<Int> = currentState.newAttributes;

    for (i in 0...newAttributes.length) {
      newAttributes[i] = 0;
    }
  }

  public function enableAttribute(attribute: Int): Void {
    enableAttributeAndDivisor(attribute, 0);
  }

  public function enableAttributeAndDivisor(attribute: Int, meshPerAttribute: Int): Void {
    var newAttributes: Array<Int> = currentState.newAttributes;
    var enabledAttributes: Array<Int> = currentState.enabledAttributes;
    var attributeDivisors: Array<Int> = currentState.attributeDivisors;

    newAttributes[attribute] = 1;

    if (enabledAttributes[attribute] == 0) {
      gl.enableVertexAttribArray(attribute);
      enabledAttributes[attribute] = 1;
    }

    if (attributeDivisors[attribute] != meshPerAttribute) {
      gl.vertexAttribDivisor(attribute, meshPerAttribute);
      attributeDivisors[attribute] = meshPerAttribute;
    }
  }

  public function disableUnusedAttributes(): Void {
    var newAttributes: Array<Int> = currentState.newAttributes;
    var enabledAttributes: Array<Int> = currentState.enabledAttributes;

    for (i in 0...enabledAttributes.length) {
      if (enabledAttributes[i] != newAttributes[i]) {
        gl.disableVertexAttribArray(i);
        enabledAttributes[i] = 0;
      }
    }
  }

  public function vertexAttribPointer(index: Int, size: Int, type: Int, normalized: Bool, stride: Int, offset: Int, integer: Bool): Void {
    if (integer == true) {
      gl.vertexAttribIPointer(index, size, type, stride, offset);
    } else {
      gl.vertexAttribPointer(index, size, type, normalized, stride, offset);
    }
  }

  public function setupVertexAttributes(object: Dynamic, material: Dynamic, program: Dynamic, geometry: Dynamic): Void {
    initAttributes();

    var geometryAttributes: Map<String, Dynamic> = geometry.attributes;

    var programAttributes: Map<String, Dynamic> = program.getAttributes();

    var materialDefaultAttributeValues: Dynamic = material.defaultAttributeValues;

    for (name in programAttributes) {
      var programAttribute: Dynamic = programAttributes.get(name);

      if (programAttribute.location >= 0) {
        var geometryAttribute: Dynamic = geometryAttributes.get(name);

        if (geometryAttribute == null) {
          if (name == 'instanceMatrix' && object.instanceMatrix != null) geometryAttribute = object.instanceMatrix;
          if (name == 'instanceColor' && object.instanceColor != null) geometryAttribute = object.instanceColor;
        }

        if (geometryAttribute != null) {
          var normalized: Bool = geometryAttribute.normalized;
          var size: Int = geometryAttribute.itemSize;

          var attribute: Attribute = attributes.get(geometryAttribute);

          // TODO Attribute may not be available on context restore

          if (attribute == null) continue;

          var buffer: Dynamic = attribute.buffer;
          var type: Int = attribute.type;
          var bytesPerElement: Int = attribute.bytesPerElement;

          // check for integer attributes

          var integer: Bool = type == gl.INT || type == gl.UNSIGNED_INT || geometryAttribute.gpuType == IntType;

          if (geometryAttribute.isInterleavedBufferAttribute) {
            var data: Dynamic = geometryAttribute.data;
            var stride: Int = data.stride;
            var offset: Int = geometryAttribute.offset;

            if (data.isInstancedInterleavedBuffer) {
              for (i in 0...programAttribute.locationSize) {
                enableAttributeAndDivisor(programAttribute.location + i, data.meshPerAttribute);
              }

              if (object.isInstancedMesh != true && geometry._maxInstanceCount == null) {
                geometry._maxInstanceCount = data.meshPerAttribute * data.count;
              }
            } else {
              for (i in 0...programAttribute.locationSize) {
                enableAttribute(programAttribute.location + i);
              }
            }

            gl.bindBuffer(gl.ARRAY_BUFFER, buffer);

            for (i in 0...programAttribute.locationSize) {
              vertexAttribPointer(
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
                enableAttributeAndDivisor(programAttribute.location + i, geometryAttribute.meshPerAttribute);
              }

              if (object.isInstancedMesh != true && geometry._maxInstanceCount == null) {
                geometry._maxInstanceCount = geometryAttribute.meshPerAttribute * geometryAttribute.count;
              }
            } else {
              for (i in 0...programAttribute.locationSize) {
                enableAttribute(programAttribute.location + i);
              }
            }

            gl.bindBuffer(gl.ARRAY_BUFFER, buffer);

            for (i in 0...programAttribute.locationSize) {
              vertexAttribPointer(
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
        } else if (materialDefaultAttributeValues != null) {
          var value: Dynamic = materialDefaultAttributeValues.get(name);

          if (value != null) {
            switch (value.length) {
              case 2:
                gl.vertexAttrib2fv(programAttribute.location, value);
                break;
              case 3:
                gl.vertexAttrib3fv(programAttribute.location, value);
                break;
              case 4:
                gl.vertexAttrib4fv(programAttribute.location, value);
                break;
              default:
                gl.vertexAttrib1fv(programAttribute.location, value);
            }
          }
        }
      }
    }

    disableUnusedAttributes();
  }

  public function dispose(): Void {
    reset();

    for (geometryId in bindingStates.keys()) {
      var programMap: Map<Int, Map<Bool, BindingState>> = bindingStates.get(geometryId);

      for (programId in programMap.keys()) {
        var stateMap: Map<Bool, BindingState> = programMap.get(programId);

        for (wireframe in stateMap.keys()) {
          deleteVertexArrayObject(stateMap.get(wireframe).object);
          stateMap.remove(wireframe);
        }

        programMap.remove(programId);
      }

      bindingStates.remove(geometryId);
    }
  }

  public function releaseStatesOfGeometry(geometry: Dynamic): Void {
    if (bindingStates.get(geometry.id) == null) return;

    var programMap: Map<Int, Map<Bool, BindingState>> = bindingStates.get(geometry.id);

    for (programId in programMap.keys()) {
      var stateMap: Map<Bool, BindingState> = programMap.get(programId);

      for (wireframe in stateMap.keys()) {
        deleteVertexArrayObject(stateMap.get(wireframe).object);
        stateMap.remove(wireframe);
      }

      programMap.remove(programId);
    }

    bindingStates.remove(geometry.id);
  }

  public function releaseStatesOfProgram(program: Dynamic): Void {
    for (geometryId in bindingStates.keys()) {
      var programMap: Map<Int, Map<Bool, BindingState>> = bindingStates.get(geometryId);

      if (programMap.get(program.id) == null) continue;

      var stateMap: Map<Bool, BindingState> = programMap.get(program.id);

      for (wireframe in stateMap.keys()) {
        deleteVertexArrayObject(stateMap.get(wireframe).object);
        stateMap.remove(wireframe);
      }

      programMap.remove(program.id);
    }
  }

  public function reset(): Void {
    resetDefaultState();
    forceUpdate = true;

    if (currentState == defaultState) return;

    currentState = defaultState;
    bindVertexArrayObject(currentState.object);
  }

  // for backward-compatibility

  public function resetDefaultState(): Void {
    defaultState.geometry = null;
    defaultState.program = null;
    defaultState.wireframe = false;
  }

}

typedef AttributeData = {
  attribute: Dynamic,
  data: Null<Dynamic>
};

typedef BindingState = {
  // for backward compatibility on non-VAO support browser
  geometry: Dynamic,
  program: Dynamic,
  wireframe: Bool,

  newAttributes: Array<Int>,
  enabledAttributes: Array<Int>,
  attributeDivisors: Array<Int>,
  object: Dynamic,
  attributes: Map<String, AttributeData>,
  index: Null<Int>,
  attributesNum: Int
};