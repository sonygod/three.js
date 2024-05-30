import three.constants.IntType;

class WebGLBindingStates {
  var gl:Dynamic;
  var attributes:Dynamic;
  var maxVertexAttributes:Int;
  var bindingStates:Map<Int, Map<Int, Map<Bool, Dynamic>>>;

  var defaultState:Dynamic;
  var currentState:Dynamic;
  var forceUpdate:Bool = false;

  public function new(gl:Dynamic, attributes:Dynamic) {
    this.gl = gl;
    this.attributes = attributes;
    this.maxVertexAttributes = gl.getParameter(gl.MAX_VERTEX_ATTRIBS);
    this.bindingStates = new Map();

    this.defaultState = createBindingState(null);
    this.currentState = this.defaultState;
  }

  function setup(object:Dynamic, material:Dynamic, program:Dynamic, geometry:Dynamic, index:Dynamic) {
    var updateBuffers:Bool = false;
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

  function createVertexArrayObject():Dynamic {
    return gl.createVertexArray();
  }

  function bindVertexArrayObject(vao:Dynamic):Void {
    gl.bindVertexArray(vao);
  }

  function deleteVertexArrayObject(vao:Dynamic):Void {
    gl.deleteVertexArray(vao);
  }

  function getBindingState(geometry:Dynamic, program:Dynamic, material:Dynamic):Dynamic {
    var wireframe = (material.wireframe == true);

    var programMap = bindingStates.get(geometry.id);

    if (programMap == null) {
      programMap = new Map();
      bindingStates.set(geometry.id, programMap);
    }

    var stateMap = programMap.get(program.id);

    if (stateMap == null) {
      stateMap = new Map();
      programMap.set(program.id, stateMap);
    }

    var state = stateMap.get(wireframe);

    if (state == null) {
      state = createBindingState(createVertexArrayObject());
      stateMap.set(wireframe, state);
    }

    return state;
  }

  function createBindingState(vao:Dynamic):Dynamic {
    var newAttributes = [];
    var enabledAttributes = [];
    var attributeDivisors = [];

    for (i in 0...maxVertexAttributes) {
      newAttributes[i] = 0;
      enabledAttributes[i] = 0;
      attributeDivisors[i] = 0;
    }

    return {
      geometry: null,
      program: null,
      wireframe: false,
      newAttributes: newAttributes,
      enabledAttributes: enabledAttributes,
      attributeDivisors: attributeDivisors,
      object: vao,
      attributes: new Map<String, Dynamic>(),
      index: null
    };
  }

  function needsUpdate(object:Dynamic, geometry:Dynamic, program:Dynamic, index:Dynamic):Bool {
    var cachedAttributes = currentState.attributes;
    var geometryAttributes = geometry.attributes;

    var attributesNum = 0;
    var programAttributes = program.getAttributes();

    for (name in programAttributes.keys()) {
      var programAttribute = programAttributes.get(name);

      if (programAttribute.location >= 0) {
        var cachedAttribute = cachedAttributes.get(name);
        var geometryAttribute = geometryAttributes.get(name);

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

  function saveCache(object:Dynamic, geometry:Dynamic, program:Dynamic, index:Dynamic):Void {
    var cache = new Map<String, Dynamic>();
    var attributes = geometry.attributes;
    var attributesNum = 0;
    var programAttributes = program.getAttributes();

    for (name in programAttributes.keys()) {
      var programAttribute = programAttributes.get(name);

      if (programAttribute.location >= 0) {
        var attribute = attributes.get(name);

        if (attribute == null) {
          if (name == 'instanceMatrix' && object.instanceMatrix != null) attribute = object.instanceMatrix;
          if (name == 'instanceColor' && object.instanceColor != null) attribute = object.instanceColor;
        }

        var data = { attribute: attribute };

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

  function initAttributes():Void {
    var newAttributes = currentState.newAttributes;

    for (i in 0...newAttributes.length) {
      newAttributes[i] = 0;
    }
  }

  function enableAttribute(attribute:Int):Void {
    enableAttributeAndDivisor(attribute, 0);
  }

  function enableAttributeAndDivisor(attribute:Int, meshPerAttribute:Int):Void {
    var newAttributes = currentState.newAttributes;
    var enabledAttributes = currentState.enabledAttributes;
    var attributeDivisors = currentState.attributeDivisors;

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

  function disableUnusedAttributes():Void {
    var newAttributes = currentState.newAttributes;
    var enabledAttributes = currentState.enabledAttributes;

    for (i in 0...enabledAttributes.length) {
      if (enabledAttributes[i] != newAttributes[i]) {
        gl.disableVertexAttribArray(i);
        enabledAttributes[i] = 0;
      }
    }
  }

  function vertexAttribPointer(index:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:Int, integer:Bool):Void {
    if (integer) {
      gl.vertexAttribIPointer(index, size, type, stride, offset);
    } else {
      gl.vertexAttribPointer(index, size, type, normalized, stride, offset);
    }
  }

  function setupVertexAttributes(object:Dynamic, material:Dynamic, program:Dynamic, geometry:Dynamic):Void {
    initAttributes();

    var geometryAttributes = geometry.attributes;
    var programAttributes = program.getAttributes();
    var materialDefaultAttributeValues = material.defaultAttributeValues;

    for (name in programAttributes.keys()) {
      var programAttribute = programAttributes.get(name);

      if (programAttribute.location >= 0) {
        var geometryAttribute = geometryAttributes.get(name);

        if (geometryAttribute == null) {
          if (name == 'instanceMatrix' && object.instanceMatrix != null) geometryAttribute = object.instanceMatrix;
          if (name == 'instanceColor' && object.instanceColor != null) geometryAttribute = object.instanceColor;
        }

        if (geometryAttribute != null) {
          var normalized = geometryAttribute.normalized;
          var size = geometryAttribute.itemSize;
          var attribute = attributes.get(geometryAttribute);

          if (attribute == null) continue;

          var buffer = attribute.buffer;
          var type = attribute.type;
          var bytesPerElement = attribute.bytesPerElement;
          var integer = (type == gl.INT || type == gl.UNSIGNED_INT || geometryAttribute.gpuType == IntType);

          if (geometryAttribute.isInterleavedBufferAttribute) {
            var data = geometryAttribute.data;
            var stride = data.stride;
            var offset = geometryAttribute.offset;

            if (data.isInstancedInterleavedBuffer) {
              for (i in 0...programAttribute.locationSize) {
                enableAttributeAndDivisor(programAttribute.location + i, data.meshPerAttribute);
              }

              if (!object.isInstancedMesh && geometry._maxInstanceCount == null) {
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

              if (!object.isInstancedMesh && geometry._maxInstanceCount == null) {
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
          var value = materialDefaultAttributeValues[name];

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

  function dispose():Void {
    reset();

    for (geometryId in bindingStates.keys()) {
      var programMap = bindingStates.get(geometryId);

      for (programId in programMap.keys()) {
        var stateMap = programMap.get(programId);

        for (wireframe in stateMap.keys()) {
          deleteVertexArrayObject(stateMap.get(wireframe).object);
          stateMap.remove(wireframe);
        }

        programMap.remove(programId);
      }

      bindingStates.remove(geometryId);
    }
  }

  function releaseStatesOfGeometry(geometry:Dynamic):Void {
    if (bindingStates.get(geometry.id) == null) return;

    var programMap = bindingStates.get(geometry.id);

    for (programId in programMap.keys()) {
      var stateMap = programMap.get(programId);

      for (wireframe in stateMap.keys()) {
        deleteVertexArrayObject(stateMap.get(wireframe).object);
        stateMap.remove(wireframe);
      }

      programMap.remove(programId);
    }

    bindingStates.remove(geometry.id);
  }

  function releaseStatesOfProgram(program:Dynamic):Void {
    for (geometryId in bindingStates.keys()) {
      var programMap = bindingStates.get(geometryId);

      if (programMap.get(program.id) == null) continue;

      var stateMap = programMap.get(program.id);

      for (wireframe in stateMap.keys()) {
        deleteVertexArrayObject(stateMap.get(wireframe).object);
        stateMap.remove(wireframe);
      }

      programMap.remove(program.id);
    }
  }

  function reset():Void {
    resetDefaultState();
    forceUpdate = true;

    if (currentState == defaultState) return;

    currentState = defaultState;
    bindVertexArrayObject(currentState.object);
  }

  function resetDefaultState():Void {
    defaultState.geometry = null;
    defaultState.program = null;
    defaultState.wireframe = false;
  }
}