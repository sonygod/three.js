package three.js.editor.js;

import js.Browser;
import js.html.DivElement;
import js.react.React;
import js.react.ReactDOM;

class SidebarMaterialConstantProperty {
  var editor:Dynamic;
  var property:String;
  var name:String;
  var options:Array<Dynamic>;

  var container:DivElement;
  var constant:React;

  var object:Dynamic;
  var materialSlot:Int;
  var material:Dynamic;

  public function new(editor:Dynamic, property:String, name:String, options:Array<Dynamic>) {
    this.editor = editor;
    this.property = property;
    this.name = name;
    this.options = options;

    container = ReactDOM.render(
      React.DOM.div({ className: 'SidebarMaterialConstantProperty' },
        React.DOM.span({ className: 'Label' }, name),
        constant = React.DOM.select({ onChange: onChange, options: options })
      ),
      Browser.document.getElementById('sidebar-material-constant-property')
    );

    object = null;
    materialSlot = 0;
    material = null;
  }

  function onChange(e:Dynamic) {
    var value:Int = Std.parseInt(constant.getValue());

    if (material[property] != value) {
      editor.execute(new SetMaterialValueCommand(editor, object, property, value, materialSlot));
    }
  }

  function update(currentObject:Dynamic, currentMaterialSlot:Int = 0) {
    object = currentObject;
    materialSlot = currentMaterialSlot;

    if (object == null) return;
    if (object.material == null) return;

    material = editor.getObjectMaterial(object, materialSlot);

    if (Reflect.hasField(material, property)) {
      constant.setValue(material[property]);
      container.style.display = '';
    } else {
      container.style.display = 'none';
    }
  }

  public function new() {
    editor.signals.objectSelected.add(update);
    editor.signals.materialChanged.add(update);
  }
}