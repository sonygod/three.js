import js.three.nodes.Nodes;
import js.three.nodes.BaseNodeEditor;
import js.three.nodes.DataTypeLib;
import js.flow.LabelElement;
import js.three.Color;
import js.three.Vector2;
import js.three.Vector3;
import js.three.Vector4;
import js.three.nodes.NodeEditorUtils;

class CustomNodeEditor extends BaseNodeEditor {
    public function new(settings:Dynamic) {
        var shaderNode = Reflect.field(Nodes, $getString(settings.shaderNode));
        var node:Dynamic;
        var elements:Array<Dynamic> = [];

        if (Reflect.hasField(settings, 'properties')) {
            node = shaderNode();
            var properties = settings.properties as Array<Dynamic>;
            for (property in properties) {
                elements.push(createElementFromProperty(node, property));
            }
        } else {
            node = shaderNode;
        }

        node.nodeType = node.nodeType ?? $getString(settings.nodeType);

        super(settings.name, node, 300);
        this.title.setIcon('ti ti-' + $getString(settings.icon));

        for (element in elements) {
            this.add(element);
        }
    }
}

inline function createElementFromProperty(node:Dynamic, property:Dynamic):Dynamic {
    var nodeType = $getString(property.nodeType);
    var defaultValue = uniform(Reflect.hasField(js.three.nodes.typeToValue, nodeType) ? Reflect.field(js.three.nodes.typeToValue, nodeType) : 0);

    var label = $getString(property.label);
    if (label == null) {
        label = $getString(property.name);
        if (StringTools.endsWith(label, 'Node')) {
            label = StringTools.substr(label, 0, -4);
        }
    }

    node[$getString(property.name)] = defaultValue;

    var element = DataTypeLib.setInputAestheticsFromType(new LabelElement(label), nodeType);

    if (Reflect.hasField(NodeEditorUtils.createInputLib, nodeType)) {
        NodeEditorUtils.createInputLib[nodeType](defaultValue, element);
    }

    element.onConnect(function(elmt:Dynamic) {
        elmt.setEnabledInputs(!elmt.getLinkedObject());
        node[$getString(property.name)] = elmt.getLinkedObject() ?? defaultValue;
    });

    return element;
}

var js = js || {};
js.three = js.three || {};
js.three.nodes = js.three.nodes || {};
js.three.nodes.typeToValue = { 'color': Color, 'vec2': Vector2, 'vec3': Vector3, 'vec4': Vector4 };