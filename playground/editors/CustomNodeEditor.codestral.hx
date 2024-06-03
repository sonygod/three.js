import flow.LabelElement;
import three.Color;
import three.Vector2;
import three.Vector3;
import three.Vector4;
import three.nodes.Nodes;
import three.nodes.uniform;
import BaseNodeEditor;
import NodeEditorUtils.createInputLib;
import DataTypeLib.setInputAestheticsFromType;

class CustomNodeEditor extends BaseNodeEditor {
    public function new(settings:Dynamic) {
        super(Std.string(settings.name), 300);

        var shaderNode = Reflect.field(Nodes, Std.string(settings.shaderNode));
        var node = null;
        var elements = new Array<LabelElement>();

        if (Reflect.hasField(settings, "properties")) {
            node = Reflect.callMethod(shaderNode, [], []);

            for (property in Reflect.fields(settings.properties)) {
                elements.push(createElementFromProperty(node, settings.properties[property]));
            }
        } else {
            node = shaderNode;
        }

        if (node.nodeType == null) {
            node.nodeType = settings.nodeType;
        }

        this.title.setIcon("ti ti-" + Std.string(settings.icon));

        for (element in elements) {
            this.add(element);
        }
    }
}

function createElementFromProperty(node:Dynamic, property:Dynamic) {
    var nodeType = property.nodeType;
    var defaultValue;

    switch (nodeType) {
        case "color":
            defaultValue = uniform(new Color());
            break;
        case "vec2":
            defaultValue = uniform(new Vector2());
            break;
        case "vec3":
            defaultValue = uniform(new Vector3());
            break;
        case "vec4":
            defaultValue = uniform(new Vector4());
            break;
        default:
            defaultValue = uniform(0);
    }

    var label = Reflect.hasField(property, "label") ? property.label : property.name;

    if (label == null && label.endsWith("Node")) {
        label = label.substring(0, label.length - 4);
    }

    node[property.name] = defaultValue;

    var element = setInputAestheticsFromType(new LabelElement(label), nodeType);

    if (Reflect.hasField(createInputLib, nodeType)) {
        Reflect.callMethod(createInputLib, [nodeType], [defaultValue, element]);
    }

    element.onConnect((elmt) -> {
        elmt.setEnabledInputs(!elmt.getLinkedObject());
        node[property.name] = elmt.getLinkedObject() != null ? elmt.getLinkedObject() : defaultValue;
    });

    return element;
}