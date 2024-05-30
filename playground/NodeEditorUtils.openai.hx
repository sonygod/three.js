package three.js.playground;

import js.Blob;
import js.html.Document;
import js.html.Element;
import js.html.Event;
import js.html.URL;
import js.html.Window;

import three.nodes.String;
import three.nodes.Float;
import three.nodes.Vec2;
import three.nodes.Vec3;
import three.nodes.Vec4;
import three.nodes.Color;

import flow.StringInput;
import flow.NumberInput;
import flow.ColorInput;
import flow.Element;
import flow.LabelElement;

class NodeEditorUtils {
    public static function exportJSON(object:Dynamic, name:String) {
        var json:String = Json.stringify(object);
        var a:js.html.AnchorElement = Document.createElement('a');
        var file:Blob = new Blob([json], {type: 'text/plain'});
        a.href = URL.createObjectURL(file);
        a.download = name + '.json';
        a.click();
    }

    public static function disposeScene(scene:threescene.Scene) {
        scene.traverse(object -> {
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

    public static function disposeMaterial(material:threematerials.Material) {
        material.dispose();
        for (key in Object.keys(material)) {
            var value:Dynamic = material[key];
            if (value != null && Std.isOfType(value, Object) && Reflect.hasMethod(value, 'dispose')) {
                value.dispose();
            }
        }
    }

    public static function createColorInput(node:Dynamic, element:Element) {
        var input:ColorInput = new ColorInput();
        input.onChange( function() {
            node.value.setHex(input.getValue());
            element.dispatchEvent(new Event('changeInput'));
        });
        element.add(input);
    }

    public static function createFloatInput(node:Dynamic, element:Element) {
        var input:NumberInput = new NumberInput();
        input.onChange( function() {
            node.value = input.getValue();
            element.dispatchEvent(new Event('changeInput'));
        });
        element.add(input);
    }

    public static function createStringInput(node:Dynamic, element:Element, settings:Dynamic = null) {
        var input:StringInput = new StringInput();
        input.onChange( function() {
            var value:String = input.getValue();
            if (settings.transform == 'lowercase') value = value.toLowerCase();
            else if (settings.transform == 'uppercase') value = value.toUpperCase();
            node.value = value;
            element.dispatchEvent(new Event('changeInput'));
        });
        element.add(input);
        if (settings.options) {
            for (option in settings.options) {
                input.addOption(option);
            }
        }
        var field:js.html.InputElement = cast input.getInput();
        if (settings.allows) field.addEventListener('input', function(e) {
            field.value = field.value.replace(new EReg('[^\\s' + settings.allows + ']', 'gi'), '');
        });
        if (settings.maxLength) field.maxLength = settings.maxLength;
        if (settings.transform) field.style.textTransform = settings.transform;
    }

    public static function createVector2Input(node:Dynamic, element:Element) {
        var onUpdate:Void->Void = function() {
            node.value.x = fieldX.getValue();
            node.value.y = fieldY.getValue();
            element.dispatchEvent(new Event('changeInput'));
        };
        var fieldX:NumberInput = new NumberInput().setTagColor('red').onChange(onUpdate);
        var fieldY:NumberInput = new NumberInput().setTagColor('green').onChange(onUpdate);
        element.add(fieldX).add(fieldY);
    }

    public static function createVector3Input(node:Dynamic, element:Element) {
        var onUpdate:Void->Void = function() {
            node.value.x = fieldX.getValue();
            node.value.y = fieldY.getValue();
            node.value.z = fieldZ.getValue();
            element.dispatchEvent(new Event('changeInput'));
        };
        var fieldX:NumberInput = new NumberInput().setTagColor('red').onChange(onUpdate);
        var fieldY:NumberInput = new NumberInput().setTagColor('green').onChange(onUpdate);
        var fieldZ:NumberInput = new NumberInput().setTagColor('blue').onChange(onUpdate);
        element.add(fieldX).add(fieldY).add(fieldZ);
    }

    public static function createVector4Input(node:Dynamic, element:Element) {
        var onUpdate:Void->Void = function() {
            node.value.x = fieldX.getValue();
            node.value.y = fieldY.getValue();
            node.value.z = fieldZ.getValue();
            node.value.w = fieldW.getValue();
            element.dispatchEvent(new Event('changeInput'));
        };
        var fieldX:NumberInput = new NumberInput().setTagColor('red').onChange(onUpdate);
        var fieldY:NumberInput = new NumberInput().setTagColor('green').onChange(onUpdate);
        var fieldZ:NumberInput = new NumberInput().setTagColor('blue').onChange(onUpdate);
        var fieldW:NumberInput = new NumberInput(1).setTagColor('white').onChange(onUpdate);
        element.add(fieldX).add(fieldY).add(fieldZ).add(fieldW);
    }

    public static var createInputLib:Dynamic = {
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
    }

    public static var inputNodeLib:Dynamic = {
        string: String,
        float: Float,
        vec2: Vec2,
        vec3: Vec3,
        vec4: Vec4,
        color: Color,
        Number: Float,
        String: String,
        Vector2: Vec2,
        Vector3: Vec3,
        Vector4: Vec4,
        Color: Color
    }

    public static function createElementFromJSON(json:Dynamic) {
        var id:String = json.id || json.name;
        var element:Element;
        if (json.name) element = new LabelElement(json.name);
        else element = new Element();
        var field:Bool = json.nullable != true && json.field != false;
        var inputNode:Dynamic;
        if (field && inputNodeLib[json.inputType] != null) {
            inputNode = inputNodeLib[json.inputType]();
        }
        element.value = inputNode;
        if (json.height) element.setHeight(json.height);
        if (json.inputType) {
            if (field && createInputLib[json.inputType]) {
                createInputLib[json.inputType](inputNode, element, json);
            }
            element.onConnect(function() {
                var externalNode:Dynamic = element.getLinkedObject();
                element.setEnabledInputs(externalNode == null);
                element.value = externalNode || inputNode;
            });
        }
        if (json.inputType && json.inputConnection != false) {
            setInputAestheticsFromType(element, json.inputType);
            element.onValid(onValidType(json.inputType));
        }
        if (json.outputType) {
            setOutputAestheticsFromType(element, json.outputType);
        }
        return {id: id, element: element, inputNode: inputNode, inputType: json.inputType, outputType: json.outputType};
    }

    public static function isGPUNode(object:Dynamic) {
        return object != null && object.isNode == true && object.isCodeNode != true && object.nodeType != 'string' && object.nodeType != 'ArrayBuffer';
    }

    public static function isValidTypeToType(sourceType:String, targetType:String) {
        return sourceType == targetType;
    }

    public static var onValidNode:Void->Void = onValidType();
    public static function onValidType(types:String = 'node', node:Dynamic = null) {
        return function(source:Dynamic, target:Dynamic, stage:String) {
            var targetObject:Dynamic = target.getObject();
            if (targetObject) {
                for (type in types.split('|')) {
                    var object:Dynamic = targetObject;
                    if (object.isScriptableValueNode) {
                        if (object.outputType) {
                            if (isValidTypeToType(object.outputType, type)) {
                                return true;
                            }
                        }
                        object = object.value;
                    }
                    if (object == null || object == undefined) continue;
                    var isValid:Bool = false;
                    switch (type) {
                        case 'any':
                            isValid = true;
                        case 'node':
                            isValid = isGPUNode(object);
                        case 'string', 'String':
                            isValid = object.nodeType == 'string';
                        case 'Number':
                            isValid = object.isInputNode && Std.isOfType(object.value, Float);
                        case 'URL':
                            isValid = object.nodeType == 'string' || object.nodeType == 'ArrayBuffer';
                        default:
                            isValid = object['is' + type] == true;
                    }
                    if (isValid) return true;
                }
                if (node != null && stage == 'dragged') {
                    var name:String = target.node.getName();
                    node.editor.tips.error('"' + name + '" is not a "' + types + '".');
                }
                return false;
            }
        };
    }
}