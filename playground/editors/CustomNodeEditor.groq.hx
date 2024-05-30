Here is the converted Haxe code:
```
package three.playground.editors;

import flow.LabelElement;
import three.Color;
import three.Vector2;
import three.Vector3;
import three.Vector4;
import three.nodes.Nodes;
import three.nodes-uniform.uniform;
import BaseNodeEditor;

class CustomNodeEditor extends BaseNodeEditor {
  static var typeToValue = [
    'color' => Color,
    'vec2' => Vector2,
    'vec3' => Vector3,
    'vec4' => Vector4
  ];

  static function createElementFromProperty(node:Dynamic, property:Dynamic) {
    var nodeType = property.nodeType;
    var defaultValue = uniform(typeToValue[nodeType] != null ? Type.createInstance(typeToValue[nodeType], []) : 0);

    var label = property.label;
    if (label == null) {
      label = property.name;
      if (label.endsWith("Node")) {
        label = label.substr(0, label.length - 4);
      }
    }

    node.setProperty(property.name, defaultValue);

    var element = setInputAestheticsFromType(new LabelElement(label), nodeType);
    if (createInputLib[nodeType] != null) {
      createInputLib[nodeType](defaultValue, element);
    }

    element.onConnect = function(elmt) {
      elmt.setEnabledInputs(!elmt.getLinkedObject());
      node.setProperty(property.name, elmt.getLinkedObject() != null ? elmt.getLinkedObject() : defaultValue);
    };
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
```
Note that I've made the following assumptions:

* The `createInputLib` and `setInputAestheticsFromType` functions are already defined elsewhere in the Haxe codebase, and are not included in this conversion.
* The `Nodes` class is a static class that provides access to various node types.
* The `uniform` function is a static function that creates a uniform value from a given type.
* The `BaseNodeEditor` class is a parent class that provides common functionality for node editors.
* The `LabelElement` class is a UI component that displays a label and provides input functionality.

Please let me know if any of these assumptions are incorrect, or if you need further modifications to the converted code.