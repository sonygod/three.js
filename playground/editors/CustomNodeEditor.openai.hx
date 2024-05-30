package three.js.playground.editors;

import three.LabelElement;
import three.Color;
import three.Vector2;
import three.Vector3;
import three.Vector4;
import three.nodes.Nodes;
import three.nodes.uniform;
import BaseNodeEditor;

class CustomNodeEditor extends BaseNodeEditor {
  static var createInputLib:Dynamic<Dynamic> = createInputLib();
  static var typeToValue:Map<String, Dynamic> = [
    'color' => Color,
    'vec2' => Vector2,
    'vec3' => Vector3,
    'vec4' => Vector4
  ];

  static function createElementFromProperty(node:Dynamic, property:Dynamic) {
    var nodeType = property.nodeType;
    var defaultValue:Dynamic = uniform(typeToValue[nodeType] != null ? Type.createInstance(typeToValue[nodeType]) : 0);
    var label = property.label;
    if (label == null) {
      label = property.name;
      if (label.endsWith('Node')) {
        label = label.substr(0, label.length - 4);
      }
    }
    node.set(property.name, defaultValue);
    var element = setInputAestheticsFromType(new LabelElement(label), nodeType);
    if (createInputLib[nodeType] != null) {
      createInputLib[nodeType](defaultValue, element);
    }
    element.onConnect(function(elmt:Dynamic) {
      elmt.setEnabledInputs(!elmt.getLinkedObject());
      node.set(property.name, elmt.getLinkedObject() != null ? elmt.getLinkedObject() : defaultValue);
    });
    return element;
  }

  public function new(settings:Dynamic) {
    var shaderNode = Nodes[settings.shaderNode];
    var node:Dynamic = null;
    var elements:Array<Dynamic> = [];
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
}