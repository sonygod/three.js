package three.js.playground.editors;

import three.js.nodes.Scriptable;
import three.js.nodes.ScriptableNode;
import js.html.DivElement;

class NodePrototypeEditor extends JavaScriptEditor {
  private var nodeClass:WeakMap<Dynamic, Dynamic>;
  private var scriptableNode:ScriptableNode;
  private var instances:Array<Dynamic>;
  private var _prototype:Dynamic;

  public function new(?source:String = defaultCode) {
    super(source);
    setName('Node Prototype');
    this.nodeClass = new WeakMap();
    this.scriptableNode = Scriptable.createNode(this.codeNode);
    this.instances = [];
    this.editorElement.addEventListener('change', updatePrototypes);
    _prototype = null;
    updatePrototypes();
  }

  override public function serialize(data:Dynamic) {
    super.serialize(data);
    data.source = source;
  }

  override public function deserialize(data:Dynamic) {
    super.deserialize(data);
    source = data.source;
  }

  override public function deserializeLib(data:Dynamic, lib:Dynamic) {
    super.deserializeLib(data, lib);
    source = data.source;
    var nodePrototype = createPrototype();
    lib[nodePrototype.name] = nodePrototype.nodeClass;
  }

  public function setEditor(editor:Dynamic) {
    if (editor == null && editor != null) {
      editor.removeClass(_prototype);
    }
    super.setEditor(editor);
    if (editor == null) {
      for (proto in instances) {
        proto.dispose();
      }
      instances = [];
    }
    updatePrototypes();
  }

  private function createPrototype():Dynamic {
    if (_prototype != null) return _prototype;
    var nodePrototype = this;
    var scriptableNode = this.scriptableNode;
    var editorElement = this.editorElement;

    var nodeClass = new ScriptableClass(scriptableNode.codeNode, false);
    nodeClass.serializePriority = -1;
    nodeClass.onCode = nodeClass.onCode.bind(nodeClass);

    nodeClass.onCode = function() {
      this.update();
    }

    nodeClass.setEditor = function(editor:Dynamic) {
      super.setEditor(editor);
      var index = instances.indexOf(this);
      if (editor != null) {
        if (index == -1) instances.push(this);
        editorElement.addEventListener('change', this.onCode);
      } else {
        if (index != -1) instances.splice(index, 1);
        editorElement.removeEventListener('change', this.onCode);
      }
    }

    nodeClass.className = function() {
      return scriptableNode.getLayout().name;
    }

    _prototype = {
      get_name():String {
        return scriptableNode.getLayout().name;
      },
      get_icon():String {
        return scriptableNode.getLayout().icon;
      },
      nodeClass: nodeClass,
      reference: this,
      editor: this.editor
    };
    return _prototype;
  }

  private function updatePrototypes():Void {
    if (_prototype != null && _prototype.editor != null) {
      _prototype.editor.removeClass(_prototype);
    }

    var layout = scriptableNode.getLayout();
    if (layout != null && layout.name != null) {
      if (editor != null) {
        editor.addClass(createPrototype());
      }
    }
  }

  private static var defaultCode:String = "
  // Addition Node Example
  // Enjoy! :)

  // layout must be the first variable.
  layout = {
    name: \"Custom Addition\",
    outputType: 'node',
    icon: 'heart-plus',
    width: 200,
    elements: [
      { name: 'A', inputType: 'node' },
      { name: 'B', inputType: 'node' }
    ]
  };

  // THREE and TSL (Three.js Shading Language) namespaces are available.
  // main code must be in the output function.

  const { add, float } = TSL;

  function main() {
    const nodeA = parameters.get('A') || float();
    const nodeB = parameters.get('B') || float();

    return add(nodeA, nodeB);
  }
";
}