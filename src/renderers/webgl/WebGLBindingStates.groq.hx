package three.js.src.renderers.webgl;

import three.js.constants.IntType;

class WebGLBindingStates {
    private var gl:GL;
    private var attributes:Attributes;
    private var maxVertexAttributes:Int;
    private var bindingStates:Map<String, Dynamic>;
    private var defaultState:BindingState;
    private var currentState:BindingState;
    private var forceUpdate:Bool;

    public function new(gl:GL, attributes:Attributes) {
        this.gl = gl;
        this.attributes = attributes;
        this.maxVertexAttributes = gl.getParameter(gl.MAX_VERTEX_ATTRIBS);

        this.bindingStates = new Map<String, Dynamic>();
        this.defaultState = createBindingState(null);
        this.currentState = this.defaultState;
        this.forceUpdate = false;
    }

    private function setup(object:Object3D, material:Material, program:Program, geometry:Geometry, index:Int):Void {
        var updateBuffers:Bool = false;

        var state:BindingState = getBindingState(geometry, program, material);

        if (currentState != state) {
            currentState = state;
            bindVertexArrayObject(currentState.object);
        }

        updateBuffers = needsUpdate(object, geometry, program, index);

        if (updateBuffers) {
            saveCache(object, geometry, program, index);
        }

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

    private function createVertexArrayObject():GLArrayBuffer {
        return gl.createVertexArray();
    }

    private function bindVertexArrayObject(vao:GLArrayBuffer):Void {
        gl.bindVertexArray(vao);
    }

    private function deleteVertexArrayObject(vao:GLArrayBuffer):Void {
        gl.deleteVertexArray(vao);
    }

    private function getBindingState(geometry:Geometry, program:Program, material:Material):BindingState {
        var wireframe:Bool = material.wireframe;

        var programMap:Map<String, Dynamic> = bindingStates[geometry.id];

        if (programMap == null) {
            programMap = new Map<String, Dynamic>();
            bindingStates[geometry.id] = programMap;
        }

        var stateMap:Map<String, BindingState> = programMap[program.id];

        if (stateMap == null) {
            stateMap = new Map<String, BindingState>();
            programMap[program.id] = stateMap;
        }

        var state:BindingState = stateMap[wireframe];

        if (state == null) {
            state = createBindingState(createVertexArrayObject());
            stateMap[wireframe] = state;
        }

        return state;
    }

    private function createBindingState(vao:GLArrayBuffer):BindingState {
        var newAttributes:Array<Int> = [];
        var enabledAttributes:Array<Int> = [];
        var attributeDivisors:Array<Int> = [];

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
            attributes: {},
            index: null
        };
    }

    private function needsUpdate(object:Object3D, geometry:Geometry, program:Program, index:Int):Bool {
        var cachedAttributes:Map<String, Dynamic> = currentState.attributes;
        var geometryAttributes:Map<String, Dynamic> = geometry.attributes;

        var attributesNum:Int = 0;

        var programAttributes:Map<String, Dynamic> = program.getAttributes();

        for (name in programAttributes.keys()) {
            var programAttribute:Dynamic = programAttributes[name];

            if (programAttribute.location >= 0) {
                var cachedAttribute:Dynamic = cachedAttributes[name];
                var geometryAttribute:Dynamic = geometryAttributes[name];

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

    private function saveCache(object:Object3D, geometry:Geometry, program:Program, index:Int):Void {
        var cache:Map<String, Dynamic> = new Map<String, Dynamic>();
        var attributes:Map<String, Dynamic> = geometry.attributes;
        var attributesNum:Int = 0;

        var programAttributes:Map<String, Dynamic> = program.getAttributes();

        for (name in programAttributes.keys()) {
            var programAttribute:Dynamic = programAttributes[name];

            if (programAttribute.location >= 0) {
                var attribute:Dynamic = attributes[name];

                if (attribute == null) {
                    if (name == 'instanceMatrix' && object.instanceMatrix != null) attribute = object.instanceMatrix;
                    if (name == 'instanceColor' && object.instanceColor != null) attribute = object.instanceColor;
                }

                var data:Dynamic = {};
                data.attribute = attribute;

                if (attribute != null && attribute.data != null) {
                    data.data = attribute.data;
                }

                cache[name] = data;

                attributesNum++;
            }
        }

        currentState.attributes = cache;
        currentState.attributesNum = attributesNum;

        currentState.index = index;
    }

    private function initAttributes():Void {
        var newAttributes:Array<Int> = currentState.newAttributes;

        for (i in 0...newAttributes.length) {
            newAttributes[i] = 0;
        }
    }

    private function enableAttribute(attribute:Int):Void {
        enableAttributeAndDivisor(attribute, 0);
    }

    private function enableAttributeAndDivisor(attribute:Int, meshPerAttribute:Int):Void {
        var newAttributes:Array<Int> = currentState.newAttributes;
        var enabledAttributes:Array<Int> = currentState.enabledAttributes;
        var attributeDivisors:Array<Int> = currentState.attributeDivisors;

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

    private function disableUnusedAttributes():Void {
        var newAttributes:Array<Int> = currentState.newAttributes;
        var enabledAttributes:Array<Int> = currentState.enabledAttributes;

        for (i in 0...enabledAttributes.length) {
            if (enabledAttributes[i] != newAttributes[i]) {
                gl.disableVertexAttribArray(i);
                enabledAttributes[i] = 0;
            }
        }
    }

    private function vertexAttribPointer(index:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:Int, integer:Bool):Void {
        if (integer) {
            gl.vertexAttribIPointer(index, size, type, stride, offset);
        } else {
            gl.vertexAttribPointer(index, size, type, normalized, stride, offset);
        }
    }

    private function setupVertexAttributes(object:Object3D, material:Material, program:Program, geometry:Geometry):Void {
        initAttributes();

        var geometryAttributes:Map<String, Dynamic> = geometry.attributes;
        var programAttributes:Map<String, Dynamic> = program.getAttributes();

        var materialDefaultAttributeValues:Map<String, Dynamic> = material.defaultAttributeValues;

        for (name in programAttributes.keys()) {
            var programAttribute:Dynamic = programAttributes[name];

            if (programAttribute.location >= 0) {
                var geometryAttribute:Dynamic = geometryAttributes[name];

                if (geometryAttribute == null) {
                    if (name == 'instanceMatrix' && object.instanceMatrix != null) geometryAttribute = object.instanceMatrix;
                    if (name == 'instanceColor' && object.instanceColor != null) geometryAttribute = object.instanceColor;
                }

                if (geometryAttribute != null) {
                    var normalized:Bool = geometryAttribute.normalized;
                    var size:Int = geometryAttribute.itemSize;

                    var attribute:Dynamic = attributes.get(geometryAttribute);

                    if (attribute == null) continue;

                    var buffer:GLArrayBuffer = attribute.buffer;
                    var type:Int = attribute.type;
                    var bytesPerElement:Int = attribute.bytesPerElement;

                    var integer:Bool = (type == gl.INT || type == gl.UNSIGNED_INT || geometryAttribute.gpuType == IntType);

                    if (geometryAttribute.isInterleavedBufferAttribute) {
                        var data:Dynamic = geometryAttribute.data;
                        var stride:Int = data.stride;
                        var offset:Int = geometryAttribute.offset;

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
                    var value:Dynamic = materialDefaultAttributeValues[name];

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

    public function dispose():Void {
        reset();

        for (geometryId in bindingStates.keys()) {
            var programMap:Map<String, Dynamic> = bindingStates[geometryId];

            for (programId in programMap.keys()) {
                var stateMap:Map<String, BindingState> = programMap[programId];

                for (wireframe in stateMap.keys()) {
                    deleteVertexArrayObject(stateMap[wireframe].object);

                    delete stateMap[wireframe];
                }

                delete programMap[programId];
            }

            delete bindingStates[geometryId];
        }
    }

    public function releaseStatesOfGeometry(geometry:Geometry):Void {
        if (bindingStates[geometry.id] == null) return;

        var programMap:Map<String, Dynamic> = bindingStates[geometry.id];

        for (programId in programMap.keys()) {
            var stateMap:Map<String, BindingState> = programMap[programId];

            for (wireframe in stateMap.keys()) {
                deleteVertexArrayObject(stateMap[wireframe].object);

                delete stateMap[wireframe];
            }

            delete programMap[programId];
        }

        delete bindingStates[geometry.id];
    }

    public function releaseStatesOfProgram(program:Program):Void {
        for (geometryId in bindingStates.keys()) {
            var programMap:Map<String, Dynamic> = bindingStates[geometryId];

            if (programMap[program.id] == null) continue;

            var stateMap:Map<String, BindingState> = programMap[program.id];

            for (wireframe in stateMap.keys()) {
                deleteVertexArrayObject(stateMap[wireframe].object);

                delete stateMap[wireframe];
            }

            delete programMap[program.id];
        }
    }

    public function reset():Void {
        resetDefaultState();
        forceUpdate = true;

        if (currentState == defaultState) return;

        currentState = defaultState;
        bindVertexArrayObject(currentState.object);
    }

    private function resetDefaultState():Void {
        defaultState.geometry = null;
        defaultState.program = null;
        defaultState.wireframe = false;
    }

    public function initAttributes():Void {
        initAttributes();
    }

    public function enableAttribute(attribute:Int):Void {
        enableAttributeAndDivisor(attribute, 0);
    }

    public function disableUnusedAttributes():Void {
        disableUnusedAttributes();
    }
}