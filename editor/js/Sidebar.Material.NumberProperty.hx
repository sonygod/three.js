package three.js.editor.js;

import js.html.UIRow;
import js.html.UIText;
import js.html.UINumber;
import three.js.editor.commands.SetMaterialValueCommand;

class SidebarMaterialNumberProperty {
  private var editor:Dynamic;
  private var property:String;
  private var name:String;
  private var range:Array<Float> = [-Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY];
  private var precision:Int = 2;

  private var container:UIRow;
  private var number:UINumber;
  private var object:Dynamic;
  private var materialSlot:Int;
  private var material:Dynamic;

  public function new(editor:Dynamic, property:String, name:String, ?range:Array<Float>, ?precision:Int) {
    this.editor = editor;
    this.property = property;
    this.name = name;
    if (range != null) this.range = range;
    if (precision != null) this.precision = precision;

    var signals = editor.signals;

    container = new UIRow();
    container.add(new UIText(name).setClass('Label'));

    number = new UINumber();
    number.setWidth('60px');
    number.setRange(range[0], range[1]);
    number.setPrecision(precision);
    number.onChange = onChange;
    container.add(number);

    signals.objectSelected.add(update);
    signals.materialChanged.add(update);
  }

  private function onChange() {
    if (material != null && material[property] != number.getValue()) {
      editor.execute(new SetMaterialValueCommand(editor, object, property, number.getValue(), materialSlot));
    }
  }

  private function update(currentObject:Dynamic, currentMaterialSlot:Int = 0) {
    object = currentObject;
    materialSlot = currentMaterialSlot;

    if (object == null) return;
    if (object.material == null) return;

    material = editor.getObjectMaterial(object, materialSlot);

    if (Reflect.hasField(material, property)) {
      number.setValue(material[property]);
      container.setDisplay('');
    } else {
      container.setDisplay('none');
    }
  }
}