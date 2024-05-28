import js.Browser.Window;
import js.gl.WebGLRenderingContext as GL;

class WebGLBindingStates {
    var maxVertexAttributes:Int;
    var bindingStates:Map<Int, Map<Int, Map<Bool, WebGLVertexArrayObject>>> = Map();
    var defaultState:WebGLBindingState;
    var currentState:WebGLBindingState;
    var forceUpdate:Bool;

    public function new(gl:GL, attributes:OpenFLWebGLAttributes) {
        maxVertexAttributes = gl.getParameter(gl.MAX_VERTEX_ATTRIBS);
        defaultState = createBindingState(null);
        currentState = defaultState;
        forceUpdate = false;
    }

    public function setup(object:Dynamic, material:Dynamic, program:Dynamic, geometry:Dynamic, index:Dynamic) {
        var updateBuffers = false;
        var state = getBindingState(geometry, program, material);

        if (currentState != state) {
            currentState = state;
            bindVertexArrayObject(currentState.object);
        }

        updateBuffers = needsUpdate(object, geometry, program, index);

        if (updateBuffers) saveCache(object, geometry, program, index);

        if (index != null) {
            attributes.update(index, GL.ELEMENT_ARRAY_BUFFER);
        }

        if (updateBuffers || forceUpdate) {
            forceUpdate = false;
            setupVertexAttributes(object, material, program, geometry);

            if (index != null) {
                gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, attributes.get(index).buffer);
            }
        }
    }

    private function createVertexArrayObject():WebGLVertexArrayObject {
        return gl.createVertexArray();
    }

    private function bindVertexArrayObject(vao:WebGLVertexArrayObject) {
        return gl.bindVertexArray(vao);
    }

    private function deleteVertexArrayObject(vao:WebGLVertexArrayObject) {
        return gl.deleteVertexArray(vao);
    }

    private function getBindingState(geometry:Dynamic, program:Dynamic, material:Dynamic) {
        var wireframe = material.wireframe;

        var programMap = bindingStates.get(geometry.id);
        if (programMap == null) {
            programMap = Map();
            bindingStates[geometry.id] = programMap;
        }

        var stateMap = programMap.get(program.id);
        if (stateMap == null) {
            stateMap = Map();
            programMap[program.id] = stateMap;
        }

        var state = stateMap.get(wireframe);
        if (state == null) {
            state = createBindingState(createVertexArrayObject());
            stateMap[wireframe] = state;
        }

        return state;
    }

    private function createBindingState(vao:WebGLVertexArrayObject) {
        var newAttributes = [];
        var enabledAttributes = [];
        var attributeDivisors = [];

        for (i in 0...maxVertexAttributes) {
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
            attributes: Map(),
            index: null
        };
    }

    private function needsUpdate(object:Dynamic, geometry:Dynamic, program:Dynamic, index:Dynamic) {
        var cachedAttributes = currentState.attributes;
        var geometryAttributes = geometry.attributes;

        var attributesNum = 0;

        var programAttributes = program.getAttributes();

        for (name in programAttributes) {
            var programAttribute = programAttributes[name];

            if (programAttribute.location >= 0) {
                var cachedAttribute = cachedAttributes.get(name);
                var geometryAttribute = geometryAttributes.get(name);

                if (geometryAttribute == null) {
                    if (name == "instanceMatrix" && object.instanceMatrix != null) geometryAttribute = object.instanceMatrix;
                    if (name == "instanceColor" && object.instanceColor != null) geometryAttribute = object.instanceColor;
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

    private function saveCache(object:Dynamic, geometry:Dynamic, program:Dynamic, index:Dynamic) {
        var cache = Map();
        var attributes = geometry.attributes;
        var attributesNum = 0;

        var programAttributes = program.getAttributes();

        for (name in programAttributes) {
            var programAttribute = programAttributes[name];

            if (programAttribute.location >= 0) {
                var attribute = attributes.get(name);

                if (attribute == null) {
                    if (name == "instanceMatrix" && object.instanceMatrix != null) attribute = object.instanceMatrix;
                    if (name == "instanceColor" && object.instanceColor != null) attribute = object.instanceColor;
                }

                var data = { attribute: attribute };

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

    public function initAttributes() {
        var newAttributes = currentState.newAttributes;

        for (i in 0...newAttributes.length) {
            newAttributes[i] = 0;
        }
    }

    public function enableAttribute(attribute:Int) {
        enableAttributeAndDivisor(attribute, 0);
    }

    public function enableAttributeAndDivisor(attribute:Int, meshPerAttribute:Int) {
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

    public function disableUnusedAttributes() {
        var newAttributes = currentState.newAttributes;
        var enabledAttributes = currentState.enabledAttributes;

        for (i in 0...enabledAttributes.length) {
            if (enabledAttributes[i] != newAttributes[i]) {
                gl.disableVertexAttribArray(i);
                enabledAttributes[i] = 0;
            }
        }
    }

    public function vertexAttribPointer(index:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:Int, integer:Bool) {
        if (integer) {
            gl.vertexAttribIPointer(index, size, type, stride, offset);
        } else {
            gl.vertexAttribPointer(index, size, type, normalized, stride, offset);
        }
    }

    public function setupVertexAttributes(object:Dynamic, material:Dynamic, program:Dynamic, geometry:Dynamic) {
        initAttributes();

        var geometryAttributes = geometry.attributes;

        var programAttributes = program.getAttributes();

        var materialDefaultAttributeValues = material.defaultAttributeValues;

        for (name in programAttributes) {
            var programAttribute = programAttributes[name];

            if (programAttribute.location >= 0) {
                var geometryAttribute = geometryAttributes.get(name);

                if (geometryAttribute == null) {
                    if (name == "instanceMatrix" && object.instanceMatrix != null) geometryAttribute = object.instanceMatrix;
                    if (name == "instanceColor" && object.instanceColor != null) geometryAttribute = object.instanceColor;
                }

                if (geometryAttribute != null) {
                    var normalized = geometryAttribute.normalized;
                    var size = geometryAttribute.itemSize;

                    var attribute = attributes.get(geometryAttribute);

                    if (attribute == null) continue;

                    var buffer = attribute.buffer;
                    var type = attribute.type;
                    var bytesPerElement = attribute.bytesPerElement;

                    var integer = (type == GL.INT || type == GL.UNSIGNED_INT || geometryAttribute.gpuType == IntType);

                    if (geometryAttribute.isInterleavedBufferAttribute) {
                        var data = geometryAttribute.data;
                        var stride = data.stride;
                        var offset = geometryAttribute.offset;

                        if (data.isInstancedInterleavedBuffer) {
                            var i = 0;
                            while (i < programAttribute.locationSize) {
                                enableAttributeAndDivisor(programAttribute.location + i, data.meshPerAttribute);
                                i++;
                            }

                            if (object.isInstancedMesh != true && geometry._maxInstanceCount == null) {
                                geometry._maxInstanceCount = data.meshPerAttribute * data.count;
                            }
                        } else {
                            var i = 0;
                            while (i < programAttribute.locationSize) {
                                enableAttribute(programAttribute.location + i);
                                i++;
                            }
                        }

                        gl.bindBuffer(GL.ARRAY_BUFFER, buffer);

                        var i = 0;
                        while (i < programAttribute.locationSize) {
                            vertexAttribPointer(
                                programAttribute.location + i,
                                size / programAttribute.locationSize,
                                type,
                                normalized,
                                stride * bytesPerElement,
                                (offset + (size / programAttribute.locationSize) * i) * bytesPerElement,
                                integer
                            );
                            i++;
                        }
                    } else {
                        if (geometryAttribute.isInstancedBufferAttribute) {
                            var i = 0;
                            while (i < programAttribute.locationSize) {
                                enableAttributeAndDivisor(programAttribute.location + i, geometryAttribute.meshPerAttribute);
                                i++;
                            }

                            if (object.isInstancedMesh != true && geometry._maxInstanceCount == null) {
                                geometry._maxInstanceCount = geometryAttribute.meshPerAttribute * geometryAttribute.count;
                            }
                        } else {
                            var i = 0;
                            while (i < programAttribute.locationSize) {
                                enableAttribute(programAttribute.location + i);
                                i++;
                            }
                        }

                        gl.bindBuffer(GL.ARRAY_BUFFER, buffer);

                        var i = 0;
                        while (i < programAttribute.locationSize) {
                            vertexAttribPointer(
                                programAttribute.location + i,
                                size / programAttribute.locationSize,
                                type,
                                normalized,
                                size * bytesPerElement,
                                (size / programAttribute.locationSize) * i * bytesPerElement,
                                integer
                            );
                            i++;
                        }
                    }
                } else if (materialDefaultAttributeValues != null) {
                    var value = materialDefaultAttributeValues.get(name);

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

    public function dispose() {
        reset();

        for (geometryId in bindingStates) {
            var programMap = bindingStates[geometryId];

            for (programId in programMap) {
                var stateMap = programMap[programId];

                for (wireframe in stateMap) {
                    deleteVertexArrayObject(stateMap[wireframe].object);
                    delete stateMap[wireframe];
                }

                delete programMap[programId];
            }

            delete bindingStates[geometryId];
        }
    }

    public function releaseStatesOfGeometry(geometry:Dynamic) {
        if (bindingStates.get(geometry.id) == null) return;

        var programMap = bindingStates[geometry.id];

        for (programId in programMap) {
            var stateMap = programMap[programId];

            for (wireframe in stateMap) {
                deleteVertexArrayObject(stateMap[wireframe].object);
                delete stateMap[wireframe];
            }

            delete programMap[programId];
        }

        delete bindingStates[geometry.id];
    }

    public function releaseStatesOfProgram(program:Dynamic) {
        for (geometryId in bindingStates) {
            var programMap = bindingStates[geometryId];

            if (programMap.get(program.id) == null) continue;

            var stateMap = programMap[program.id];

            for (wireframe in stateMap) {
                deleteVertexArrayObject(stateMap[wireframe].object);
                delete stateMap[wireframe];
            }

            delete programMap[program.id];
        }
    }

    public function reset() {
        resetDefaultState();
        forceUpdate = true;

        if (currentState == defaultState) return;

        currentState = defaultState;
        bindVertexArrayObject(currentState.object);
    }

    public function resetDefaultState() {
        defaultState.geometry = null;
        defaultState.program = null;
        defaultState.wireframe = false;
    }
}