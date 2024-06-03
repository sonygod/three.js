import flow.StringInput;
import flow.NumberInput;
import flow.ColorInput;
import flow.Element;
import flow.LabelElement;

import three.nodes.StringNode;
import three.nodes.FloatNode;
import three.nodes.Vec2Node;
import three.nodes.Vec3Node;
import three.nodes.Vec4Node;
import three.nodes.ColorNode;

import DataTypeLib.setInputAestheticsFromType;
import DataTypeLib.setOutputAestheticsFromType;

class NodeEditorUtils {

    static public function exportJSON(object:Dynamic, name:String) {
        var json = Json.stringify(object);

        var a = js.Browser.document.createElement("a");
        var file = new js.html.Blob([json], {type: 'text/plain'});

        a.href = js.Browser.window.URL.createObjectURL(file);
        a.download = name + '.json';
        a.click();
    }

    static public function disposeScene(scene:Dynamic) {
        scene.traverse((object:Dynamic) => {
            if (!object.isMesh) return;

            object.geometry.dispose();

            if (object.material.isMaterial) {
                disposeMaterial(object.material);
            } else {
                for (material in object.material) {
                    disposeMaterial(material);
                }
            }
        });
    }

    static public function disposeMaterial(material:Dynamic) {
        material.dispose();

        for (key in Reflect.fields(material)) {
            var value = Reflect.field(material, key);

            if (value != null && js.Boot.isOfType(value, js.lang.IHxObject) && Reflect.isFunction(value.dispose)) {
                value.dispose();
            }
        }
    }

    static public function createColorInput(node:Dynamic, element:Element):Void {
        var input = new ColorInput();
        input.onChange(function() {
            node.value.setHex(input.getValue());
            element.dispatchEvent(new js.html.Event('changeInput'));
        });
        element.add(input);
    }

    static public function createFloatInput(node:Dynamic, element:Element):Void {
        var input = new NumberInput();
        input.onChange(function() {
            node.value = input.getValue();
            element.dispatchEvent(new js.html.Event('changeInput'));
        });
        element.add(input);
    }

    static public function createStringInput(node:Dynamic, element:Element, settings:Dynamic = null):Void {
        var input = new StringInput();
        input.onChange(function() {
            var value = input.getValue();

            if (settings != null && settings.hasOwnProperty('transform')) {
                switch(settings.transform) {
                    case 'lowercase':
                        value = value.toLowerCase();
                        break;
                    case 'uppercase':
                        value = value.toUpperCase();
                        break;
                }
            }

            node.value = value;
            element.dispatchEvent(new js.html.Event('changeInput'));
        });

        element.add(input);

        if (settings != null && settings.hasOwnProperty('options')) {
            for (option in settings.options) {
                input.addOption(option);
            }
        }

        var field = input.getInput();

        if (settings != null && settings.hasOwnProperty('allows')) {
            field.addEventListener('input', function() {
                field.value = field.value.replace(new EReg('[^\\s' + settings.allows + ']', 'gi'), '');
            });
        }

        if (settings != null && settings.hasOwnProperty('maxLength')) {
            field.maxLength = settings.maxLength;
        }

        if (settings != null && settings.hasOwnProperty('transform')) {
            field.style['text-transform'] = settings.transform;
        }
    }

    static public function createVector2Input(node:Dynamic, element:Element):Void {
        var onUpdate = function() {
            node.value.x = fieldX.getValue();
            node.value.y = fieldY.getValue();
            element.dispatchEvent(new js.html.Event('changeInput'));
        };

        var fieldX = new NumberInput().setTagColor('red').onChange(onUpdate);
        var fieldY = new NumberInput().setTagColor('green').onChange(onUpdate);

        element.add(fieldX).add(fieldY);
    }

    static public function createVector3Input(node:Dynamic, element:Element):Void {
        var onUpdate = function() {
            node.value.x = fieldX.getValue();
            node.value.y = fieldY.getValue();
            node.value.z = fieldZ.getValue();
            element.dispatchEvent(new js.html.Event('changeInput'));
        };

        var fieldX = new NumberInput().setTagColor('red').onChange(onUpdate);
        var fieldY = new NumberInput().setTagColor('green').onChange(onUpdate);
        var fieldZ = new NumberInput().setTagColor('blue').onChange(onUpdate);

        element.add(fieldX).add(fieldY).add(fieldZ);
    }

    static public function createVector4Input(node:Dynamic, element:Element):Void {
        var onUpdate = function() {
            node.value.x = fieldX.getValue();
            node.value.y = fieldY.getValue();
            node.value.z = fieldZ.getValue();
            node.value.w = fieldW.getValue();
            element.dispatchEvent(new js.html.Event('changeInput'));
        };

        var fieldX = new NumberInput().setTagColor('red').onChange(onUpdate);
        var fieldY = new NumberInput().setTagColor('green').onChange(onUpdate);
        var fieldZ = new NumberInput().setTagColor('blue').onChange(onUpdate);
        var fieldW = new NumberInput(1).setTagColor('white').onChange(onUpdate);

        element.add(fieldX).add(fieldY).add(fieldZ).add(fieldW);
    }

    static public var createInputLib:Dynamic = {
        string: createStringInput,
        float: createFloatInput,
        vec2: createVector2Input,
        vec3: createVector3Input,
        vec4: createVector4Input,
        color: createColorInput,
        Number: createFloatInput,
        String: createStringInput,
        Vector2: createVector2Input,
        Vector3: createVector3Input,
        Vector4: createVector4Input,
        Color: createColorInput
    };

    static public var inputNodeLib:Dynamic = {
        string: StringNode,
        float: FloatNode,
        vec2: Vec2Node,
        vec3: Vec3Node,
        vec4: Vec4Node,
        color: ColorNode,
        Number: FloatNode,
        String: StringNode,
        Vector2: Vec2Node,
        Vector3: Vec3Node,
        Vector4: Vec4Node,
        Color: ColorNode
    };

    static public function createElementFromJSON(json:Dynamic):Dynamic {
        var inputType = json.inputType;
        var outputType = json.outputType;
        var nullable = json.nullable;

        var id = json.id != null ? json.id : json.name;
        var element = json.name != null ? new LabelElement(json.name) : new Element();
        var field = nullable !== true && json.field !== false;

        var inputNode = null;

        if (nullable !== true && inputNodeLib.hasOwnProperty(inputType)) {
            inputNode = Type.createInstance(inputNodeLib[inputType], []);
        }

        element.value = inputNode;

        if (json.height != null) {
            element.setHeight(json.height);
        }

        if (inputType != null) {
            if (field && createInputLib.hasOwnProperty(inputType)) {
                createInputLib[inputType](inputNode, element, json);
            }

            element.onConnect(function() {
                var externalNode = element.getLinkedObject();
                element.setEnabledInputs(externalNode == null);
                element.value = externalNode != null ? externalNode : inputNode;
            });
        }

        if (inputType != null && json.inputConnection !== false) {
            setInputAestheticsFromType(element, inputType);
            element.onValid(onValidType(inputType));
        }

        if (outputType != null) {
            setOutputAestheticsFromType(element, outputType);
        }

        return {id: id, element: element, inputNode: inputNode, inputType: inputType, outputType: outputType};
    }

    static public function isGPUNode(object:Dynamic):Bool {
        return object != null && object.isNode === true && object.isCodeNode !== true && object.nodeType !== 'string' && object.nodeType !== 'ArrayBuffer';
    }

    static public function isValidTypeToType(sourceType:String, targetType:String):Bool {
        return sourceType === targetType;
    }

    static public var onValidNode:Dynamic = onValidType();

    static public function onValidType(types:String = 'node', node:Dynamic = null):Dynamic {
        return function(source:Dynamic, target:Dynamic, stage:String) {
            var targetObject = target.getObject();

            if (targetObject != null) {
                for (type in types.split('|')) {
                    var object = targetObject;

                    if (object.isScriptableValueNode) {
                        if (object.outputType != null) {
                            if (isValidTypeToType(object.outputType, type)) {
                                return true;
                            }
                        }

                        object = object.value;
                    }

                    if (object == null || object == undefined) {
                        continue;
                    }

                    var isValid = false;

                    if (type === 'any') {
                        isValid = true;
                    } else if (type === 'node') {
                        isValid = isGPUNode(object);
                    } else if (type === 'string' || type === 'String') {
                        isValid = object.nodeType === 'string';
                    } else if (type === 'Number') {
                        isValid = object.isInputNode && js.Boot.isOfType(object.value, js.lang.IHxObject);
                    } else if (type === 'URL') {
                        isValid = object.nodeType === 'string' || object.nodeType === 'ArrayBuffer';
                    } else if (Reflect.hasField(object, 'is' + type) && Reflect.field(object, 'is' + type) === true) {
                        isValid = true;
                    }

                    if (isValid) {
                        return true;
                    }
                }

                if (node != null && stage === 'dragged') {
                    var name = target.node.getName();
                    node.editor.tips.error(`"${name}" is not a "${types}".`);
                }
            }

            return false;
        };
    }
}