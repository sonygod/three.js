import flow.StringInput;
import flow.NumberInput;
import flow.ColorInput;
import flow.Element;
import flow.LabelElement;
import three.nodes.string;
import three.nodes.float;
import three.nodes.vec2;
import three.nodes.vec3;
import three.nodes.vec4;
import three.nodes.color;
import DataTypeLib.setInputAestheticsFromType;
import DataTypeLib.setOutputAestheticsFromType;

function exportJSON(object:Dynamic, name:String):Void {
    var json = haxe.Json.stringify(object);
    var a = js.Browser.document.createElement('a');
    var file = js.html.Blob.fromString(json, 'text/plain');
    a.href = js.Browser.URL.createObjectURL(file);
    a.download = name + '.json';
    a.click();
}

function disposeScene(scene:Dynamic):Void {
    scene.traverse(object => {
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

function disposeMaterial(material:Dynamic):Void {
    material.dispose();
    for (key in js.Reflect.fields(material)) {
        var value = Reflect.field(material, key);
        if (value != null && js.Reflect.hasField(value, 'dispose')) {
            value.dispose();
        }
    }
}

function createColorInput(node:Dynamic, element:Element):Void {
    var input = new ColorInput().onChange(() => {
        node.value.setHex(input.getValue());
        element.dispatchEvent(new Event('changeInput'));
    });
    element.add(input);
}

function createFloatInput(node:Dynamic, element:Element):Void {
    var input = new NumberInput().onChange(() => {
        node.value = input.getValue();
        element.dispatchEvent(new Event('changeInput'));
    });
    element.add(input);
}

function createStringInput(node:Dynamic, element:Element, settings:Dynamic = {}):Void {
    var input = new StringInput().onChange(() => {
        var value = input.getValue();
        if (settings.transform == 'lowercase') value = value.toLowerCase();
        else if (settings.transform == 'uppercase') value = value.toUpperCase();
        node.value = value;
        element.dispatchEvent(new Event('changeInput'));
    });
    element.add(input);
    if (settings.options != null) {
        for (option in settings.options) {
            input.addOption(option);
        }
    }
    var field = input.getInput();
    if (settings.allows != null) field.addEventListener('input', () => field.value = field.value.replace(new RegExp('[^\\s' + settings.allows + ']', 'gi'), ''));
    if (settings.maxLength != null) field.maxLength = settings.maxLength;
    if (settings.transform != null) field.style['text-transform'] = settings.transform;
}

function createVector2Input(node:Dynamic, element:Element):Void {
    var onUpdate = () => {
        node.value.x = fieldX.getValue();
        node.value.y = fieldY.getValue();
        element.dispatchEvent(new Event('changeInput'));
    };
    var fieldX = new NumberInput().setTagColor('red').onChange(onUpdate);
    var fieldY = new NumberInput().setTagColor('green').onChange(onUpdate);
    element.add(fieldX).add(fieldY);
}

function createVector3Input(node:Dynamic, element:Element):Void {
    var onUpdate = () => {
        node.value.x = fieldX.getValue();
        node.value.y = fieldY.getValue();
        node.value.z = fieldZ.getValue();
        element.dispatchEvent(new Event('changeInput'));
    };
    var fieldX = new NumberInput().setTagColor('red').onChange(onUpdate);
    var fieldY = new NumberInput().setTagColor('green').onChange(onUpdate);
    var fieldZ = new NumberInput().setTagColor('blue').onChange(onUpdate);
    element.add(fieldX).add(fieldY).add(fieldZ);
}

function createVector4Input(node:Dynamic, element:Element):Void {
    var onUpdate = () => {
        node.value.x = fieldX.getValue();
        node.value.y = fieldY.getValue();
        node.value.z = fieldZ.getValue();
        node.value.w = fieldZ.getValue();
        element.dispatchEvent(new Event('changeInput'));
    };
    var fieldX = new NumberInput().setTagColor('red').onChange(onUpdate);
    var fieldY = new NumberInput().setTagColor('green').onChange(onUpdate);
    var fieldZ = new NumberInput().setTagColor('blue').onChange(onUpdate);
    var fieldW = new NumberInput(1).setTagColor('white').onChange(onUpdate);
    element.add(fieldX).add(fieldY).add(fieldZ).add(fieldW);
}

var createInputLib = {
    // gpu
    string: createStringInput,
    float: createFloatInput,
    vec2: createVector2Input,
    vec3: createVector3Input,
    vec4: createVector4Input,
    color: createColorInput,
    // cpu
    Number: createFloatInput,
    String: createStringInput,
    Vector2: createVector2Input,
    Vector3: createVector3Input,
    Vector4: createVector4Input,
    Color: createColorInput
};

var inputNodeLib = {
    // gpu
    string: string,
    float: float,
    vec2: vec2,
    vec3: vec3,
    vec4: vec4,
    color: color,
    // cpu
    Number: float,
    String: string,
    Vector2: vec2,
    Vector3: vec3,
    Vector4: vec4,
    Color: color
};

function createElementFromJSON(json:Dynamic):Dynamic {
    var inputType = json.inputType;
    var outputType = json.outputType;
    var nullable = json.nullable;
    var id = json.id != null ? json.id : json.name;
    var element = json.name != null ? new LabelElement(json.name) : new Element();
    var field = nullable != true && json.field != false;
    var inputNode = null;
    if (nullable != true && inputNodeLib[inputType] != null) {
        inputNode = inputNodeLib[inputType]();
    }
    element.value = inputNode;
    if (json.height != null) element.setHeight(json.height);
    if (inputType != null) {
        if (field && createInputLib[inputType] != null) {
            createInputLib[inputType](inputNode, element, json);
        }
        element.onConnect(() => {
            var externalNode = element.getLinkedObject();
            element.setEnabledInputs(externalNode == null);
            element.value = externalNode != null ? externalNode : inputNode;
        });
    }
    if (inputType != null && json.inputConnection != false) {
        setInputAestheticsFromType(element, inputType);
        element.onValid(onValidType(inputType));
    }
    if (outputType != null) {
        setOutputAestheticsFromType(element, outputType);
    }
    return {id: id, element: element, inputNode: inputNode, inputType: inputType, outputType: outputType};
}

function isGPUNode(object:Dynamic):Bool {
    return object != null && object.isNode == true && object.isCodeNode != true && object.nodeType != 'string' && object.nodeType != 'ArrayBuffer';
}

function isValidTypeToType(sourceType:String, targetType:String):Bool {
    return sourceType == targetType;
}

var onValidNode = onValidType();

function onValidType(types:String = 'node', node:Dynamic = null):Dynamic {
    return (source:Dynamic, target:Dynamic, stage:String) => {
        var targetObject = target.getObject();
        if (targetObject != null) {
            for (type in types.split('|')) {
                var object = targetObject;
                if (object.isScriptableValueNode) {
                    if (object.outputType != null && isValidTypeToType(object.outputType, type)) {
                        return true;
                    }
                    object = object.value;
                }
                if (object == null) continue;
                var isValid = false;
                if (type == 'any') {
                    isValid = true;
                } else if (type == 'node') {
                    isValid = isGPUNode(object);
                } else if (type == 'string' || type == 'String') {
                    isValid = object.nodeType == 'string';
                } else if (type == 'Number') {
                    isValid = object.isInputNode && typeof object.value == 'number';
                } else if (type == 'URL') {
                    isValid = object.nodeType == 'string' || object.nodeType == 'ArrayBuffer';
                } else if (object['is' + type] == true) {
                    isValid = true;
                }
                if (isValid) return true;
            }
            if (node != null && stage == 'dragged') {
                var name = target.node.getName();
                node.editor.tips.error('"' + name + '" is not a "' + types + '".');
            }
            return false;
        }
    };
}