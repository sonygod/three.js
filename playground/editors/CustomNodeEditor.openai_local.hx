import flow.LabelElement;
import three.Color;
import three.Vector2;
import three.Vector3;
import three.Vector4;
import three.nodes.Nodes;
import three.nodes.uniform;
import threejs.playground.editors.BaseNodeEditor;
import threejs.playground.editors.NodeEditorUtils.createInputLib;
import threejs.playground.editors.DataTypeLib.setInputAestheticsFromType;

class CustomNodeEditor extends BaseNodeEditor {

    public function new(settings:Dynamic) {
        var shaderNode = Reflect.field(Nodes, settings.shaderNode);

        var node:Dynamic = null;

        var elements:Array<LabelElement> = [];

        if (settings.properties != null) {
            node = shaderNode();

            for (property in settings.properties) {
                elements.push(createElementFromProperty(node, property));
            }
        } else {
            node = shaderNode;
        }

        node.nodeType = node.nodeType != null ? node.nodeType : settings.nodeType;

        super(settings.name, node, 300);

        this.title.setIcon('ti ti-' + settings.icon);

        for (element in elements) {
            this.add(element);
        }
    }

    static var typeToValue:Map<String, Dynamic> = [
        'color' => Color,
        'vec2' => Vector2,
        'vec3' => Vector3,
        'vec4' => Vector4
    ];

    static function createElementFromProperty(node:Dynamic, property:Dynamic):LabelElement {
        var nodeType = property.nodeType;
        var defaultValue = uniform(typeToValue.exists(nodeType) ? Type.createInstance(typeToValue[nodeType], []) : 0);

        var label:String = property.label;

        if (label == null) {
            label = property.name;

            if (label.endsWith('Node')) {
                label = label.substr(0, label.length - 4);
            }
        }

        Reflect.setField(node, property.name, defaultValue);

        var element:LabelElement = setInputAestheticsFromType(new LabelElement(label), nodeType);

        if (Reflect.hasField(createInputLib, nodeType)) {
            Reflect.callMethod(createInputLib, Reflect.field(createInputLib, nodeType), [defaultValue, element]);
        }

        element.onConnect(function(elmt:LabelElement) {
            elmt.setEnabledInputs(!elmt.getLinkedObject());
            Reflect.setField(node, property.name, elmt.getLinkedObject() != null ? elmt.getLinkedObject() : defaultValue);
        });

        return element;
    }

}