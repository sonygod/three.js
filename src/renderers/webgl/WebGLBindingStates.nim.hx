import IntType from '../../constants.js';

class WebGLBindingStates {
    var maxVertexAttributes:Int;
    var bindingStates:Map<Int, Map<Int, Map<Bool, WebGLBindingState>>>;
    var defaultState:WebGLBindingState;
    var currentState:WebGLBindingState;
    var forceUpdate:Bool;

    public function new(gl:WebGLRenderingContext, attributes:WebGLAttributes) {
        this.maxVertexAttributes = gl.getParameter(gl.MAX_VERTEX_ATTRIBS);
        this.bindingStates = new Map();
        this.defaultState = createBindingState(null);
        this.currentState = this.defaultState;
        this.forceUpdate = false;
    }

    public function setup(object:Object3D, material:Material, program:WebGLProgram, geometry:BufferGeometry, index:Dynamic) {
        var updateBuffers:Bool = false;
        var state:WebGLBindingState = getBindingState(geometry, program, material);
        if (this.currentState !== state) {
            this.currentState = state;
            bindVertexArrayObject(this.currentState.object);
        }
        updateBuffers = needsUpdate(object, geometry, program, index);
        if (updateBuffers) saveCache(object, geometry, program, index);
        if (index !== null) {
            attributes.update(index, gl.ELEMENT_ARRAY_BUFFER);
        }
        if (updateBuffers || this.forceUpdate) {
            this.forceUpdate = false;
            setupVertexAttributes(object, material, program, geometry);
            if (index !== null) {
                gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, attributes.get(index).buffer);
            }
        }
    }

    public function createVertexArrayObject():WebGLVertexArrayObject {
        return gl.createVertexArray();
    }

    public function bindVertexArrayObject(vao:WebGLVertexArrayObject):Void {
        return gl.bindVertexArray(vao);
    }

    public function deleteVertexArrayObject(vao:WebGLVertexArrayObject):Void {
        return gl.deleteVertexArray(vao);
    }

    public function getBindingState(geometry:BufferGeometry, program:WebGLProgram, material:Material):WebGLBindingState {
        var wireframe:Bool = (material.wireframe === true);
        var programMap:Map<Int, Map<Bool, WebGLBindingState>> = this.bindingStates.get(geometry.id);
        if (programMap === null) {
            programMap = new Map();
            this.bindingStates.set(geometry.id, programMap);
        }
        var stateMap:Map<Bool, WebGLBindingState> = programMap.get(program.id);
        if (stateMap === null) {
            stateMap = new Map();
            programMap.set(program.id, stateMap);
        }
        var state:WebGLBindingState = stateMap.get(wireframe);
        if (state === null) {
            state = createBindingState(createVertexArrayObject());
            stateMap.set(wireframe, state);
        }
        return state;
    }

    public function createBindingState(vao:WebGLVertexArrayObject):WebGLBindingState {
        var newAttributes:Array<Int> = [];
        var enabledAttributes:Array<Int> = [];
        var attributeDivisors:Array<Int> = [];
        for (i in 0...this.maxVertexAttributes) {
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
            attributes: new Map(),
            index: null
        };
    }

    public function needsUpdate(object:Object3D, geometry:BufferGeometry, program:WebGLProgram, index:Dynamic):Bool {
        var cachedAttributes:Map<String, WebGLAttributeCache> = this.currentState.attributes;
        var geometryAttributes:Map<String, BufferAttribute> = geometry.attributes;
        var attributesNum:Int = 0;
        var programAttributes:Map<String, WebGLAttribute> = program.getAttributes();
        for (name in programAttributes.keys()) {
            var programAttribute:WebGLAttribute = programAttributes.get(name);
            if (programAttribute.location >= 0) {
                var cachedAttribute:WebGLAttributeCache = cachedAttributes.get(name);
                var geometryAttribute:BufferAttribute = geometryAttributes.get(name);
                if (geometryAttribute === null) {
                    if (name === 'instanceMatrix' && object.instanceMatrix) geometryAttribute = object.instanceMatrix;
                    if (name === 'instanceColor' && object.instanceColor) geometryAttribute = object.instanceColor;
                }
                if (cachedAttribute === null) return true;
                if (cachedAttribute.attribute !== geometryAttribute) return true;
                if (geometryAttribute && cachedAttribute.data !== geometryAttribute.data) return true;
                attributesNum++;
            }
        }
        if (this.currentState.attributesNum !== attributesNum) return true;
        if (this.currentState.index !== index) return true;
        return false;
    }

    public function saveCache(object:Object3D, geometry:BufferGeometry, program:WebGLProgram, index:Dynamic):Void {
        var cache:Map<String, WebGLAttributeCache> = new Map();
        var attributes:Map<String, BufferAttribute> = geometry.attributes;
        var attributesNum:Int = 0;
        var programAttributes:Map<String, WebGLAttribute> = program.getAttributes();
        for (name in programAttributes.keys()) {
            var programAttribute:WebGLAttribute = programAttributes.get(name);
            if (programAttribute.location >= 0) {
                var attribute:BufferAttribute = attributes.get(name);
                if (attribute === null) {
                    if (name === 'instanceMatrix' && object.instanceMatrix) attribute = object.instanceMatrix;
                    if (name === 'instanceColor' && object.instanceColor) attribute = object.instanceColor;
                }
                var data:WebGLAttributeCache = new WebGLAttributeCache();
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

    public function initAttributes():Void {
        var newAttributes:Array<Int> = this.currentState.newAttributes;
        for (i in 0...newAttributes.length) {
            newAttributes[i] = 0;
        }
    }

    public function enableAttribute(attribute:Int):Void {
        enableAttributeAndDivisor(attribute, 0);
    }

    public function enableAttributeAndDivisor(attribute:Int, meshPerAttribute:Int):Void {
        var newAttributes:Array<Int> = this.currentState.newAttributes;
        var enabledAttributes:Array<Int> = this.currentState.enabledAttributes;
        var attributeDivisors:Array<Int> = this.currentState.attributeDivisors;
        newAttributes[attribute] = 1;
        if (enabledAttributes[attribute] === 0) {
            gl.enableVertexAttribArray(attribute);
            enabledAttributes[attribute] = 1;
        }
        if (attributeDivisors[attribute] !== meshPerAttribute) {
            gl.vertexAttribDivisor(attribute, meshPerAttribute);
            attributeDivisors[attribute] = meshPerAttribute;
        }
    }

    public function disableUnusedAttributes():Void {
        var newAttributes:Array<Int> = this.currentState.newAttributes;
        var enabledAttributes:Array<Int> = this.currentState.enabledAttributes;
        for (i in 0...enabledAttributes.length) {
            if (enabledAttributes[i] !== newAttributes[i]) {
                gl.disableVertexAttribArray(i);
                enabledAttributes[i] = 0;
            }
        }
    }

    public function vertexAttribPointer(index:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:Int, integer:Bool):Void {
        if (integer) {
            gl.vertexAttribIPointer(index, size, type, stride, offset);
        } else {
            gl.vertexAttribPointer(index, size, type, normalized, stride, offset);
        }
    }

    public function setupVertexAttributes(object:Object3D, material:Material, program:WebGLProgram, geometry:BufferGeometry):Void {
        initAttributes();
        var geometryAttributes:Map<String, BufferAttribute> = geometry.attributes;
        var programAttributes:Map<String, WebGLAttribute> = program.getAttributes();
        var materialDefaultAttributeValues:Map<String, Array<Float>> = material.defaultAttributeValues;
        for (name in programAttributes.keys()) {
            var programAttribute:WebGLAttribute = programAttributes.get(name);
            if (programAttribute.location >= 0) {
                var geometryAttribute:BufferAttribute = geometryAttributes.get(name);
                if (geometryAttribute === null) {
                    if (name === 'instanceMatrix' && object.instanceMatrix) geometryAttribute = object.instanceMatrix;
                    if (name === 'instanceColor' && object.instanceColor) geometryAttribute = object.instanceColor;
                }
                if (geometryAttribute !== null) {
                    var normalized:Bool = geometryAttribute.normalized;
                    var size:Int = geometryAttribute.itemSize;
                    var attribute:WebGLAttribute = attributes.get(geometryAttribute);
                    if (attribute === null) continue;
                    var buffer:WebGLBuffer = attribute.buffer;
                    var type:Int = attribute.type;
                    var bytesPerElement:Int = attribute.bytesPerElement;
                    var integer:Bool = (type === gl.INT || type === gl.UNSIGNED_INT || geometryAttribute.gpuType === IntType);
                    if (geometryAttribute.isInterleavedBufferAttribute) {
                        var data:InterleavedBufferAttribute = geometryAttribute.data;
                        var stride:Int = data.stride;
                        var offset:Int = geometryAttribute.offset;
                        if (data.isInstancedInterleavedBuffer) {
                            for (i in 0...programAttribute.locationSize) {
                                enableAttributeAndDivisor(programAttribute.location + i, data.meshPerAttribute);
                            }
                            if (object.isInstancedMesh !== true && geometry._maxInstanceCount === null) {
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
                            if (object.isInstancedMesh !== true && geometry._maxInstanceCount === null) {
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
                } else if (materialDefaultAttributeValues !== null) {
                    var value:Array<Float> = materialDefaultAttributeValues.get(name);
                    if (value !== null) {
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

    public function dispose():Void {
        reset();
        for (geometryId in this.bindingStates.keys()) {
            var programMap:Map<Int, Map<Bool, WebGLBindingState>> = this.bindingStates.get(geometryId);
            for (programId in programMap.keys()) {
                var stateMap:Map<Bool, WebGLBindingState> = programMap.get(programId);
                for (wireframe in stateMap.keys()) {
                    deleteVertexArrayObject(stateMap.get(wireframe).object);
                    stateMap.remove(wireframe);
                }
                programMap.remove(programId);
            }
            this.bindingStates.remove(geometryId);
        }
    }

    public function releaseStatesOfGeometry(geometry:BufferGeometry):Void {
        if (this.bindingStates.get(geometry.id) === null) return;
        var programMap:Map<Int, Map<Bool, WebGLBindingState>> = this.bindingStates.get(geometry.id);
        for (programId in programMap.keys()) {
            var stateMap:Map<Bool, WebGLBindingState> = programMap.get(programId);
            for (wireframe in stateMap.keys()) {
                deleteVertexArrayObject(stateMap.get(wireframe).object);
                stateMap.remove(wireframe);
            }
            programMap.remove(programId);
        }
        this.bindingStates.remove(geometry.id);
    }

    public function releaseStatesOfProgram(program:WebGLProgram):Void {
        for (geometryId in this.bindingStates.keys()) {
            var programMap:Map<Int, Map<Bool, WebGLBindingState>> = this.bindingStates.get(geometryId);
            if (programMap.get(program.id) === null) continue;
            var stateMap:Map<Bool, WebGLBindingState> = programMap.get(program.id);
            for (wireframe in stateMap.keys()) {
                deleteVertexArrayObject(stateMap.get(wireframe).object);
                stateMap.remove(wireframe);
            }
            programMap.remove(program.id);
        }
    }

    public function reset():Void {
        resetDefaultState();
        this.forceUpdate = true;
        if (this.currentState === this.defaultState) return;
        this.currentState = this.defaultState;
        bindVertexArrayObject(this.currentState.object);
    }

    public function resetDefaultState():Void {
        this.defaultState.geometry = null;
        this.defaultState.program = null;
        this.defaultState.wireframe = false;
    }
}

class WebGLBindingState {
    public var geometry:BufferGeometry;
    public var program:WebGLProgram;
    public var wireframe:Bool;
    public var newAttributes:Array<Int>;
    public var enabledAttributes:Array<Int>;
    public var attributeDivisors:Array<Int>;
    public var object:WebGLVertexArrayObject;
    public var attributes:Map<String, WebGLAttributeCache>;
    public var index:Dynamic;
}

class WebGLAttributeCache {
    public var attribute:BufferAttribute;
    public var data:Dynamic;
}