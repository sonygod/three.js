package three.js.editor.js;

import ui.UIRow;
import ui.UIText;
import ui.UIColor;
import ui.UINumber;
import commands.SetMaterialColorCommand;
import commands.SetMaterialValueCommand;

class SidebarMaterialColorProperty {
  public function new(editor:Editor, property:String, name:String) {
    var signals = editor.signals;
    var container = new UIRow();
    container.add(new UIText(name).setClass('Label'));

    var color = new UIColor();
    color.onInput(onChange);
    container.add(color);

    var intensity:UINumber;

    if (property == 'emissive') {
      intensity = new UINumber(1);
      intensity.setWidth('30px');
      intensity.setRange(0, Math.POSITIVE_INFINITY);
      intensity.onChange(onChange);
      container.add(intensity);
    }

    var object:Object3D = null;
    var materialSlot:Int = 0;
    var material:Material = null;

    function onChange() {
      if (material != null && material[property] != null && material[property].getHexString() != color.getHexValue()) {
        editor.execute(new SetMaterialColorCommand(editor, object, property, color.getHexValue(), materialSlot));
      }

      if (intensity != null && material != null && material[(property + 'Intensity')] != intensity.getValue()) {
        editor.execute(new SetMaterialValueCommand(editor, object, property + 'Intensity', intensity.getValue(), materialSlot));
      }
    }

    function update(currentObject:Object3D, currentMaterialSlot:Int = 0) {
      object = currentObject;
      materialSlot = currentMaterialSlot;

      if (object == null) return;
      if (object.material == null) return;

      material = editor.getObjectMaterial(object, materialSlot);

      if (material != null && Reflect.hasField(material, property)) {
        color.setHexValue(material[property].getHexString());

        if (intensity != null) {
          intensity.setValue(material[(property + 'Intensity')]);
        }

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