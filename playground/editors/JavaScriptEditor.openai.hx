package three.js.playground.editors;

import three.nodes.Js;
import three.elements.CodeEditorElement;
import BaseNodeEditor;

class JavaScriptEditor extends BaseNodeEditor {
  
  public var codeNode:Js;
  public var editorElement:CodeEditorElement;

  public function new(source:String = '') {
    codeNode = Js.create(source);

    super('JavaScript', codeNode, 500);

    setResizable(true);

    editorElement = new CodeEditorElement(source);
    editorElement.addEventListener('change', function() {
      codeNode.code = editorElement.source;
      invalidate();
      editorElement.focus();
    });

    add(editorElement);
  }

  public function set_source(value:String):Void {
    codeNode.code = value;
  }

  public function get_source():String {
    return codeNode.code;
  }

  public function get_codeNode():Js {
    return value;
  }
}