import js.Browser.window;
import js.html.Blob;
import js.html.Document;
import js.html.Event;
import js.html.HTMLElement;
import js.html.HTMLInputElement;
import js.html.HTMLLinkElement;
import js.html.InputKind;
import js.html.URL;

class DataTypeLib {
    public static function setInputAestheticsFromType(element: Element, inputType: String) {
        // ... implementation ...
    }

    public static function setOutputAestheticsFromType(element: Element, outputType: String) {
        // ... implementation ...
    }
}

function exportJSON(object: Dynamic, name: String) {
    var json = Std.string(JSON.stringify(object));
    var a = window.document.createElement("a");
    var file = new Blob([json], {"type": "text/plain"});
    a.href = URL.createObjectURL(file);
    a.download = name + ".json";
    a.click();
}

function disposeScene(scene: Dynamic) {
    scene.traverse($dynamic({
        object: Dynamic -> {
            if (!object.isMesh) {
                return;
            }
            object.geometry.dispose();
            if (Reflect.hasField(object, "material")) {
                var material = Reflect.field(object, "material");
                if (Reflect.hasField(material, "isMaterial")) {
                    disposeMaterial(material);
                } else {
                    var materials = Reflect.field(object, "material");
                    for (material in materials) {
                        disposeMaterial(material);
                    }
                }
            }
        }
    }));
}

function disposeMaterial(material: Dynamic) {
    material.dispose();
    for (key in material) {
        var value = Reflect.field(material, key);
        if (value != null && Std.is(value, Dynamic) && Reflect.hasField(value, "dispose")) {
            value.dispose();
        }
    }
}

function createColorInput(node: Dynamic, element: Element) {
    var input = new ColorInput();
    input.onChange = function() {
        node.value.setHex(input.getValue());
        element.dispatchEvent(new Event("changeInput"));
    };
    element.add(input);
}

function createFloatInput(node: Dynamic, element: Element) {
    var input = new NumberInput();
    input.onChange = function() {
        node.value = input.getValue();
        element.dispatchEvent(new Event("changeInput"));
    };
    element.add(input);
}

function createStringInput(node: Dynamic, element: Element, ?settings: { transform: String, allows: String, maxLength: Int, options: Array<String> }) {
    var input = new StringInput();
    input.onChange = function() {
        var value = input.getValue();
        if (settings != null && settings.transform != null) {
            if (settings.transform == "lowercase") {
                value = value.toLowerCase();
            } else if (settings.transform == "uppercase") {
                value = value.toUpperCase();
            }
        }
        node.value = value;
        element.dispatchEvent(new Event("changeInput"));
    };
    element.add(input);
    if (settings != null && settings.options != null) {
        for (option in settings.options) {
            input.addOption(option);
        }
    }
    var field = input.getInput();
    if (settings != null) {
        if (settings.allows != null) {
            field.onInput = function() {
                field.value = field.value.replace(new EReg("[^" + settings.allows + "]", "g"), "");
            };
        }
        if (settings.maxLength != null) {
            field.maxLength = settings.maxLength;
        }
        if (settings.transform != null) {
            field.style.textTransform = settings.transform;
        }
    }
}

function createVector2Input(node: Dynamic, element: Element) {
    var onUpdate = function() {
        node.value.x = fieldX.getValue();
        node.value.y = fieldY.getValue();
        element.dispatchEvent(new Event("changeInput"));
    };
    var fieldX = new NumberInput();
    fieldX.setTagColor("red");
    fieldX.onChange = onUpdate;
    var fieldY = new NumberInput();
    fieldY.setTagColor("green");
    fieldY.onChange = onUpdate;
    element.add(fieldX);
    element.add(fieldY);
}

function createVector3Input(node: Dynamic, element: Element) {
    var onUpdate = function() {
        node.value.x = fieldX.getValue();
        node.value.y = fieldY.getValue();
        node.value.z = fieldZ.getValue();
        element.dispatchEvent(new Event("changeInput"));
    };
    var fieldX = new NumberInput();
    fieldX.setTagColor("red");
    fieldX.onChange = onUpdate;
    var fieldY = new NumberInput();
    fieldY.setTagColor("green");
    fieldY.onChange = onUpdate;
    var fieldZ = new NumberInput();
    fieldZ.setTagColor("blue");
    fieldZ.onChange = onUpdate;
    element.add(fieldX);
    element.add(fieldY);
    element.add(fieldZ);
}

function createVector4Input(node: Dynamic, element: Element) {
    var onUpdate = function() {
        node.value.x = fieldX.getValue();
        node.value.y = fieldY.getValue();
        node.value.z = fieldZ.getValue();
        node.value.w = fieldZ.getValue();
        element.dispatchEvent(new Event("changeInput"));
    };
    var fieldX = new NumberInput();
    fieldX.setTagColor("red");
    fieldX.onChange = onUpdate;
    var fieldY = new NumberInput();
    fieldY.setTagColor("green");
    fieldY.onChange = onUpdate;
    var fieldZ = new NumberInput();
    fieldZ.setTagColor("blue");
    fieldZ.onChange = onUpdate;
    var fieldW = new NumberInput(1);
    fieldW.setTagColor("white");
    fieldW.onChange = onUpdate;
    element.add(fieldX);
    element.add(fieldY);
    element.add(fieldZ);
    element.add(fieldW);
}

var createInputLib = {
    "gpu": {
        "string": createStringInput,
        "float": createFloatInput,
        "vec2": createVector2Input,
        "vec3": createVector3Input,
        "vec4": createVector4Input,
        "color": createColorInput,
    },
    "cpu": {
        "Number": createFloatInput,
        "String": createStringInput,
        "Vector2": createVector2Input,
        "Vector3": createVector3Input,
        "Vector4": createVector4Input,
        "Color": createColorInput,
    },
};

var inputNodeLib = {
    "gpu": {
        "string": String,
        "float": Float,
        "vec2": Vec2,
        "vec3": Vec3,
        "vec4": Vec4,
        "color": Color,
    },
    "cpu": {
        "Number": Float,
        "String": String,
        "Vector2": Vec2,
        "Vector3": Vec3,
        "Vector4": Vec4,
        "Color": Color,
    },
};

function createElementFromJSON(json: Dynamic) {
    var id = json.id != null ? json.id : json.name;
    var element = json.name != null ? new LabelElement(json.name) : new Element();
    var field = json.nullable != true && json.field != false;
    var inputNode = null;
    if (json.inputType != null && json.nullable != true && inputNodeLib["gpu"][json.inputType] != null) {
        inputNode = inputNodeLib["gpu"][json.inputType]();
    }
    element.value = inputNode;
    if (json.height != null) {
        element.setHeight(json.height);
    }
    if (json.inputType != null) {
        if (field && createInputLib["gpu"][json.inputType] != null) {
            createInputLib["gpu"][json.inputType](inputNode, element, json);
        }
        element.onConnect = function() {
            var externalNode = element.getLinkedObject();
            element.setEnabledInputs(externalNode == null);
            element.value = externalNode != null ? externalNode : inputNode;
        };
    }
    if (json.inputType != null && json.inputConnection != false) {
        DataTypeLib.setInputAestheticsFromType(element, json.inputType);
        element.onValid = onValidType(json.inputType);
    }
    if (json.outputType != null) {
        DataTypeLib.setOutputAestheticsFromType(element, json.outputType);
    }
    return { id: id, element: element, inputNode: inputNode, inputType: json.inputType, outputType: json.outputType };
}

function isGPUNode(object: Dynamic) {
    return object != null && Reflect.hasField(object, "isNode") && Reflect.field(object, "isNode") == true && Reflect.field(object, "isCodeNode") != true && Reflect.field(object, "nodeType") != "string" && Reflect.field(object, "nodeType") != "ArrayBuffer";
}

function isValidTypeToType(sourceType: String, targetType: String) {
    return sourceType == targetType;
}

function onValidType(?types: String, ?node: Dynamic) {
    return function(source: Dynamic, target: Dynamic, stage: String) {
        var targetObject = target.getObject();
        if (targetObject != null) {
            if (types != null) {
                for (type in types.split("|")) {
                    var object = targetObject;
                    if (Reflect.hasField(object, "isScriptableValueNode")) {
                        if (Reflect.hasField(object, "outputType")) {
                            if (isValidTypeToType(object.outputType, type)) {
                                return true;
                            }
                        }
                        object = object.value;
                    }
                    if (object == null) {
                        continue;
                    }
                    var isValid = false;
                    if (type == "any") {
                        isValid = true;
                    } else if (type == "node") {
                        isValid = isGPUNode(object);
                    } else if (type == "string" || type == "String") {
                        isValid = object.nodeType == "string";
                    } else if (type == "Number") {
                        isValid = object.isInputNode && Std.is(object.value, Float);
                    } else if (type == "URL") {
                        isValid = object.nodeType == "string" || object.nodeType == "ArrayBuffer";
                    } else if (Reflect.hasField(object, "is" + type)) {
                        isValid = Reflect.field(object, "is" + type);
                    }
                    if (isValid) {
                        return true;
                    }
                }
            }
            if (node != null && stage == "dragged") {
                var name = target.node.getName();
                node.editor.tips.error("\"" + name + "\" is not a \"" + types + "\".");
            }
        }
        return false;
    };
}

function onValidNode(source: Dynamic, target: Dynamic, stage: String) {
    return onValidType()(source, target, stage);
}