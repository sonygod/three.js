package three.js.playground.editors;

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
  static var typeToValue = [
    'color' => Color,
    'vec2' => Vector2,
    'vec3' => Vector3,
    'vec4' => Vector4
  ];

  static function createElementFromProperty(node:Dynamic, property:Dynamic):LabelElement {
    var nodeType = property.nodeType;
    var defaultValue:Dynamic = uniform(typeToValue[nodeType] != null ? Type.createInstance(typeToValue[nodeType]) : 0);

    var label:String = property.label;
    if (label == null) {
      label = property.name;
      if (label.endsWith('Node')) {
        label = label.substr(0, label.length - 4);
      }
    }

    Reflect.setField(node, property.name, defaultValue);

    var element:LabelElement = setInputAestheticsFromType(new LabelElement(label), nodeType);
    if (createInputLib[nodeType] != null) {
      createInputLib[nodeType](defaultValue, element);
    }

    element.onConnect(function(elmt:LabelElement) {
      elmt.setEnabledInputs(!elmt.getLinkedObject());
      Reflect.setField(node, property.name, elmt.getLinkedObject() || defaultValue);
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

    node.nodeType = node.nodeType != null ? node.nodeType : settings.nodeType;

    super(settings.name, node, 300);

    title.setIcon('ti ti-' + settings.icon);

    for (element in elements) {
      add(element);
    }
  }
}