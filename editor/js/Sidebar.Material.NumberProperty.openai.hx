package three.js.editor.js;

import ui.UINumber;
import ui.UIRow;
import ui.UIText;
import commands.SetMaterialValueCommand;

class SidebarMaterialNumberProperty {
  public function new(editor:Editor, property:String, name:String, ?range:Array<Float> = [-Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY], ?precision:Int = 2) {
    var signals = editor.signals;

    var container = new UIRow();
    container.add(new UIText(name).setClass('Label'));

    var number = new UINumber().setWidth('60px').setRange(range[0], range[1]).setPrecision(precision).onChange(onChange);
    container.add(number);

    var object:Object = null;
    var materialSlot:Int = 0;
    var material:Dynamic = null;

    function onChange() {
      if (material[property] != number.getValue()) {
        editor.execute(new SetMaterialValueCommand(editor, object, property, number.getValue(), materialSlot));
      }
    }

    function update(currentObject:Object, ?currentMaterialSlot:Int = 0) {
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

    signals.objectSelected.add(update);
    signals.materialChanged.add(update);

    return container;
  }
}