import flow.LabelElement;
import three.Color;
import three.Vector2;
import three.Vector3;
import three.Vector4;
import three.nodes.Nodes;
import three.nodes.uniform;
import BaseNodeEditor.BaseNodeEditor;
import NodeEditorUtils.createInputLib;
import DataTypeLib.setInputAestheticsFromType;

class CustomNodeEditor extends BaseNodeEditor {

    static var typeToValue = {
        'color': Color,
        'vec2': Vector2,
        'vec3': Vector3,
        'vec4': Vector4
    };

    public function new(settings:Dynamic) {

        var shaderNode = Reflect.field(Nodes, settings.shaderNode).call();

        var node = null;

        var elements = [];

        if (settings.properties !== undefined) {

            node = shaderNode();

            for (property in settings.properties) {

                elements.push(createElementFromProperty(node, property));

            }

        } else {

            node = shaderNode;

        }

        node.nodeType = node.nodeType || settings.nodeType;

        super(settings.name, node, 300);

        this.title.setIcon('ti ti-' + settings.icon);

        for (element in elements) {

            this.add(element);

        }

    }

    static function createElementFromProperty(node:Dynamic, property:Dynamic):LabelElement {

        var nodeType = property.nodeType;
        var defaultValue = uniform(typeToValue[nodeType] ? new typeToValue[nodeType]() : 0);

        var label = property.label;

        if (label === undefined) {

            label = property.name;

            if (label.endsWith('Node') === true) {

                label = label.slice(0, label.length - 4);

            }

        }

        node[property.name] = defaultValue;

        var element = setInputAestheticsFromType(new LabelElement(label), nodeType);

        if (createInputLib[nodeType] !== undefined) {

            createInputLib[nodeType](defaultValue, element);

        }

        element.onConnect(function(elmt) {

            elmt.setEnabledInputs(!elmt.getLinkedObject());

            node[property.name] = elmt.getLinkedObject() || defaultValue;

        });

        return element;

    }

}