package three.js.editor.js;

import ui.UIButton;
import ui.UIRow;
import ui.UIText;

class SidebarMaterialProgram {
  public function new(editor:Editor, property:String) {
    var signals = editor.signals;
    var strings = editor.strings;

    var object:Object = null;
    var materialSlot:Int = 0;
    var material:Material = null;

    var container = new UIRow();
    container.add(new UIText(strings.getKey('sidebar/material/program')).setClass('Label'));

    var programInfo = new UIButton(strings.getKey('sidebar/material/info'));
    programInfo.setMarginRight('4px');
    programInfo.onClick(function() {
      signals.editScript.dispatch(object, 'programInfo');
    });
    container.add(programInfo);

    var programVertex = new UIButton(strings.getKey('sidebar/material/vertex'));
    programVertex.setMarginRight('4px');
    programVertex.onClick(function() {
      signals.editScript.dispatch(object, 'vertexShader');
    });
    container.add(programVertex);

    var programFragment = new UIButton(strings.getKey('sidebar/material/fragment'));
    programFragment.setMarginRight('4px');
    programFragment.onClick(function() {
      signals.editScript.dispatch(object, 'fragmentShader');
    });
    container.add(programFragment);

    function update(currentObject:Object, currentMaterialSlot:Int = 0) {
      object = currentObject;
      materialSlot = currentMaterialSlot;

      if (object == null) return;
      if (object.material == null) return;

      material = editor.getObjectMaterial(object, materialSlot);

      if (Reflect.hasField(material, property)) {
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