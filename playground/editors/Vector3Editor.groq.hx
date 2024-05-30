package three.js.playground.editors;

import js.html.Element;
import js.html.Event;

class Vector3Editor extends BaseNodeEditor {
  public function new() {
    var json = {
      inputType: 'vec3',
      inputConnection: false
    };
    var element:Element = createElementFromJSON(json);
    var inputNode:Node = element.childNodes[0];
    super('Vector 3', inputNode, 325);
    element.addEventListener('changeInput', function(event:Event) {
      this.invalidate();
    });
    this.add(element);
  }
}

extern class BaseNodeEditor {
  public function new(title:String, inputNode:Node, width:Int) {
    // implementation not shown
  }
  public function add(element:Element):Void {
    // implementation not shown
  }
  public function invalidate():Void {
    // implementation not shown
  }
}

extern class Node {
  // implementation not shown
}

extern function createElementFromJSON(json:Dynamic):Element {
  // implementation not shown
}