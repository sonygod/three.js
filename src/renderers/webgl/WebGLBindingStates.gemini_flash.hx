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
    this.defaultState = this.createBindingState(null);
    this.currentState = this.defaultState;
  }

  public function setup(object: Object, material: Material, program: Program, geometry: Geometry, index: Int): Void {

    var updateBuffers: Bool = false;

    var state: BindingState = this.getBindingState(geometry, program, material);

    if (this.currentState != state) {
      this.currentState = state;
      this.bindVertexArrayObject(state.object);
    }

    updateBuffers = this.needsUpdate(object, geometry, program, index);

    if (updateBuffers) {
      this.saveCache(object, geometry, program, index);
    }

    if (index != null) {
      this.attributes.update(index, gl.ELEMENT_ARRAY_BUFFER);
    }

    if (updateBuffers || this.forceUpdate) {
      this.forceUpdate = false;
      this.setupVertexAttributes(object, material, program, geometry);
      if (index != null) {
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.attributes.get(index).buffer);
      }
    }

  }

  public function createVertexArrayObject(): WebGLVertexArrayObject {
    return gl.createVertexArray();
  }

  public function bindVertexArrayObject(vao: WebGLVertexArrayObject): Void {
    return gl.bindVertexArray(vao);
  }

  public function deleteVertexArrayObject(vao: WebGLVertexArrayObject): Void {
    return gl.deleteVertexArray(vao);
  }

  public function getBindingState(geometry: Geometry, program: Program, material: Material): BindingState {
    var wireframe: Bool = material.wireframe;
    var programMap: Map<Int, Map<Bool, BindingState>> = this.bindingStates.get(geometry.id);
    if (programMap == null) {
      programMap = new Map();
      this.bindingStates.set(geometry.id, programMap);
    }
    var stateMap: Map<Bool, BindingState> = programMap.get(program.id);
    if (stateMap == null) {
      stateMap = new Map();
      programMap.set(program.id, stateMap);
    }
    var state: BindingState = stateMap.get(wireframe);
    if (state == null) {
      state = this.createBindingState(this.createVertexArrayObject());
      stateMap.set(wireframe, state);
    }
    return state;
  }

  public function createBindingState(vao: WebGLVertexArrayObject): BindingState {
    var newAttributes: Array<Int> = new Array(this.maxVertexAttributes);
    var enabledAttributes: Array<Int> = new Array(this.maxVertexAttributes);
    var attributeDivisors: Array<Int> = new Array(this.maxVertexAttributes);
    for (i in 0...this.maxVertexAttributes) {
      newAttributes[i] = 0;
      enabledAttributes[i] = 0;
      attributeDivisors[i] = 0;
    }
    return new BindingState(
      null,
      null,
      false,
      newAttributes,
      enabledAttributes,
      attributeDivisors,
      vao,
      new Map(),
      null
    );
  }

  public function needsUpdate(object: Object, geometry: Geometry, program: Program, index: Int): Bool {
    var cachedAttributes: Map<String, AttributeData> = this.currentState.attributes;
    var geometryAttributes: Map<String, Attribute> = geometry.attributes;

    var attributesNum: Int = 0;

    var programAttributes: Map<String, Attribute> = program.getAttributes();

    for (name in programAttributes) {
      var programAttribute: Attribute = programAttributes[name];
      if (programAttribute.location >= 0) {
        var cachedAttribute: AttributeData = cachedAttributes.get(name);
        var geometryAttribute: Attribute = geometryAttributes.get(name);

        if (geometryAttribute == null) {
          if (name == "instanceMatrix" && object.instanceMatrix != null) {
            geometryAttribute = object.instanceMatrix;
          }
          if (name == "instanceColor" && object.instanceColor != null) {
            geometryAttribute = object.instanceColor;
          }
        }

        if (cachedAttribute == null) {
          return true;
        }

        if (cachedAttribute.attribute != geometryAttribute) {
          return true;
        }

        if (geometryAttribute != null && cachedAttribute.data != geometryAttribute.data) {
          return true;
        }

        attributesNum++;
      }
    }

    if (this.currentState.attributesNum != attributesNum) {
      return true;
    }

    if (this.currentState.index != index) {
      return true;
    }

    return false;
  }

  public function saveCache(object: Object, geometry: Geometry, program: Program, index: Int): Void {
    var cache: Map<String, AttributeData> = new Map();
    var attributes: Map<String, Attribute> = geometry.attributes;
    var attributesNum: Int = 0;

    var programAttributes: Map<String, Attribute> = program.getAttributes();

    for (name in programAttributes) {
      var programAttribute: Attribute = programAttributes[name];
      if (programAttribute.location >= 0) {
        var attribute: Attribute = attributes.get(name);
        if (attribute == null) {
          if (name == "instanceMatrix" && object.instanceMatrix != null) {
            attribute = object.instanceMatrix;
          }
          if (name == "instanceColor" && object.instanceColor != null) {
            attribute = object.instanceColor;
          }
        }

        var data: AttributeData = new AttributeData(attribute, null);
        if (attribute != null && attribute.data != null) {
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

  public function initAttributes(): Void {
    var newAttributes: Array<Int> = this.currentState.newAttributes;
    for (i in 0...newAttributes.length) {
      newAttributes[i] = 0;
    }
  }

  public function enableAttribute(attribute: Int): Void {
    this.enableAttributeAndDivisor(attribute, 0);
  }

  public function enableAttributeAndDivisor(attribute: Int, meshPerAttribute: Int): Void {
    var newAttributes: Array<Int> = this.currentState.newAttributes;
    var enabledAttributes: Array<Int> = this.currentState.enabledAttributes;
    var attributeDivisors: Array<Int> = this.currentState.attributeDivisors;

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
    var newAttributes: Array<Int> = this.currentState.newAttributes;
    var enabledAttributes: Array<Int> = this.currentState.enabledAttributes;

    for (i in 0...enabledAttributes.length) {
      if (enabledAttributes[i] != newAttributes[i]) {
        gl.disableVertexAttribArray(i);
        enabledAttributes[i] = 0;
      }
    }
  }

  public function vertexAttribPointer(index: Int, size: Int, type: Int, normalized: Bool, stride: Int, offset: Int, integer: Bool): Void {
    if (integer) {
      gl.vertexAttribIPointer(index, size, type, stride, offset);
    } else {
      gl.vertexAttribPointer(index, size, type, normalized, stride, offset);
    }
  }

  public function setupVertexAttributes(object: Object, material: Material, program: Program, geometry: Geometry): Void {
    this.initAttributes();

    var geometryAttributes: Map<String, Attribute> = geometry.attributes;

    var programAttributes: Map<String, Attribute> = program.getAttributes();

    var materialDefaultAttributeValues: Map<String, Array<Float>> = material.defaultAttributeValues;

    for (name in programAttributes) {
      var programAttribute: Attribute = programAttributes[name];
      if (programAttribute.location >= 0) {
        var geometryAttribute: Attribute = geometryAttributes.get(name);
        if (geometryAttribute == null) {
          if (name == "instanceMatrix" && object.instanceMatrix != null) {
            geometryAttribute = object.instanceMatrix;
          }
          if (name == "instanceColor" && object.instanceColor != null) {
            geometryAttribute = object.instanceColor;
          }
        }
        if (geometryAttribute != null) {
          var normalized: Bool = geometryAttribute.normalized;
          var size: Int = geometryAttribute.itemSize;

          var attribute: Attribute = this.attributes.get(geometryAttribute);

          if (attribute == null) {
            continue;
          }

          var buffer: WebGLBuffer = attribute.buffer;
          var type: Int = attribute.type;
          var bytesPerElement: Int = attribute.bytesPerElement;

          var integer: Bool = type == gl.INT || type == gl.UNSIGNED_INT || geometryAttribute.gpuType == IntType;

          if (geometryAttribute.isInterleavedBufferAttribute) {
            var data: InterleavedBuffer = geometryAttribute.data;
            var stride: Int = data.stride;
            var offset: Int = geometryAttribute.offset;

            if (data.isInstancedInterleavedBuffer) {
              for (i in 0...programAttribute.locationSize) {
                this.enableAttributeAndDivisor(programAttribute.location + i, data.meshPerAttribute);
              }

              if (object.isInstancedMesh != true && geometry._maxInstanceCount == null) {
                geometry._maxInstanceCount = data.meshPerAttribute * data.count;
              }
            } else {
              for (i in 0...programAttribute.locationSize) {
                this.enableAttribute(programAttribute.location + i);
              }
            }

            gl.bindBuffer(gl.ARRAY_BUFFER, buffer);

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
              if (object.isInstancedMesh != true && geometry._maxInstanceCount == null) {
                geometry._maxInstanceCount = geometryAttribute.meshPerAttribute * geometryAttribute.count;
              }
            } else {
              for (i in 0...programAttribute.locationSize) {
                this.enableAttribute(programAttribute.location + i);
              }
            }

            gl.bindBuffer(gl.ARRAY_BUFFER, buffer);

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
        } else if (materialDefaultAttributeValues != null) {
          var value: Array<Float> = materialDefaultAttributeValues.get(name);
          if (value != null) {
            switch (value.length) {
              case 2:
                gl.vertexAttrib2fv(programAttribute.location, value);
              case 3:
                gl.vertexAttrib3fv(programAttribute.location, value);
              case 4:
                gl.vertexAttrib4fv(programAttribute.location, value);
              default:
                gl.vertexAttrib1fv(programAttribute.location, value);
            }
          }
        }
      }
    }

    this.disableUnusedAttributes();
  }

  public function dispose(): Void {
    this.reset();
    for (geometryId in this.bindingStates) {
      var programMap: Map<Int, Map<Bool, BindingState>> = this.bindingStates.get(geometryId);
      for (programId in programMap) {
        var stateMap: Map<Bool, BindingState> = programMap.get(programId);
        for (wireframe in stateMap) {
          this.deleteVertexArrayObject(stateMap.get(wireframe).object);
          stateMap.remove(wireframe);
        }
        programMap.remove(programId);
      }
      this.bindingStates.remove(geometryId);
    }
  }

  public function releaseStatesOfGeometry(geometry: Geometry): Void {
    if (this.bindingStates.get(geometry.id) == null) {
      return;
    }
    var programMap: Map<Int, Map<Bool, BindingState>> = this.bindingStates.get(geometry.id);
    for (programId in programMap) {
      var stateMap: Map<Bool, BindingState> = programMap.get(programId);
      for (wireframe in stateMap) {
        this.deleteVertexArrayObject(stateMap.get(wireframe).object);
        stateMap.remove(wireframe);
      }
      programMap.remove(programId);
    }
    this.bindingStates.remove(geometry.id);
  }

  public function releaseStatesOfProgram(program: Program): Void {
    for (geometryId in this.bindingStates) {
      var programMap: Map<Int, Map<Bool, BindingState>> = this.bindingStates.get(geometryId);
      if (programMap.get(program.id) == null) {
        continue;
      }
      var stateMap: Map<Bool, BindingState> = programMap.get(program.id);
      for (wireframe in stateMap) {
        this.deleteVertexArrayObject(stateMap.get(wireframe).object);
        stateMap.remove(wireframe);
      }
      programMap.remove(program.id);
    }
  }

  public function reset(): Void {
    this.resetDefaultState();
    this.forceUpdate = true;

    if (this.currentState == this.defaultState) {
      return;
    }
    this.currentState = this.defaultState;
    this.bindVertexArrayObject(this.currentState.object);
  }

  public function resetDefaultState(): Void {
    this.defaultState.geometry = null;
    this.defaultState.program = null;
    this.defaultState.wireframe = false;
  }

}

class BindingState {
  public var geometry: Geometry;
  public var program: Program;
  public var wireframe: Bool;
  public var newAttributes: Array<Int>;
  public var enabledAttributes: Array<Int>;
  public var attributeDivisors: Array<Int>;
  public var object: WebGLVertexArrayObject;
  public var attributes: Map<String, AttributeData>;
  public var index: Int;
  public var attributesNum: Int;

  public function new(
    geometry: Geometry,
    program: Program,
    wireframe: Bool,
    newAttributes: Array<Int>,
    enabledAttributes: Array<Int>,
    attributeDivisors: Array<Int>,
    object: WebGLVertexArrayObject,
    attributes: Map<String, AttributeData>,
    index: Int
  ) {
    this.geometry = geometry;
    this.program = program;
    this.wireframe = wireframe;
    this.newAttributes = newAttributes;
    this.enabledAttributes = enabledAttributes;
    this.attributeDivisors = attributeDivisors;
    this.object = object;
    this.attributes = attributes;
    this.index = index;
    this.attributesNum = 0;
  }
}

class AttributeData {
  public var attribute: Attribute;
  public var data: Dynamic;

  public function new(attribute: Attribute, data: Dynamic) {
    this.attribute = attribute;
    this.data = data;
  }
}