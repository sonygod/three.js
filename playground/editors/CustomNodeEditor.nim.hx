import three.nodes.LabelElement;
import three.Color;
import three.Vector2;
import three.Vector3;
import three.Vector4;
import three.nodes.Nodes;
import three.nodes.uniform;
import BaseNodeEditor;
import NodeEditorUtils;
import DataTypeLib;

typedef TypeToValue = Map<String, Dynamic>;

class CustomNodeEditor extends BaseNodeEditor {

	private static var typeToValue:TypeToValue = new Map<String, Dynamic>();
	static {
		typeToValue.set("color", Color);
		typeToValue.set("vec2", Vector2);
		typeToValue.set("vec3", Vector3);
		typeToValue.set("vec4", Vector4);
	}

	private static function createElementFromProperty(node:Dynamic, property:Dynamic):LabelElement {

		var nodeType:String = property.nodeType;
		var defaultValue:Dynamic = uniform(typeToValue.get(nodeType) != null ? Type.createEmptyInstance(typeToValue.get(nodeType)) : 0);

		var label:String = property.label;

		if (label == null) {

			label = property.name;

			if (label.endsWith("Node") == true) {

				label = label.slice(0, label.length - 4);

			}

		}

		node[property.name] = defaultValue;

		var element:LabelElement = setInputAestheticsFromType(new LabelElement(label), nodeType);

		if (createInputLib[nodeType] != null) {

			createInputLib[nodeType](defaultValue, element);

		}

		element.onConnect(function(elmt) {

			elmt.setEnabledInputs(!elmt.getLinkedObject());

			node[property.name] = elmt.getLinkedObject() || defaultValue;

		});

		return element;

	}

	public function new(settings:Dynamic) {

		var shaderNode:Dynamic = Nodes[settings.shaderNode];

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

		node.nodeType = node.nodeType || settings.nodeType;

		super(settings.name, node, 300);

		this.title.setIcon('ti ti-' + settings.icon);

		for (element in elements) {

			this.add(element);

		}

	}

}