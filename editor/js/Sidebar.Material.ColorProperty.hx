package three.js.editor.js;

import js.lib.ui.UIColor;
import js.lib.ui.UINumber;
import js.lib.ui.UIRow;
import js.lib.ui.UIText;
import commands.SetMaterialColorCommand;
import commands.SetMaterialValueCommand;

class SidebarMaterialColorProperty {
    public function new(editor:Dynamic, property:String, name:String) {
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

        var object:Dynamic = null;
        var materialSlot:Int = 0;
        var material:Dynamic = null;

        function onChange() {
            if (material[property].getHex() != color.getHexValue()) {
                editor.execute(new SetMaterialColorCommand(editor, object, property, color.getHexValue(), materialSlot));
            }

            if (intensity != null) {
                if (material[property + 'Intensity'] != intensity.getValue()) {
                    editor.execute(new SetMaterialValueCommand(editor, object, property + 'Intensity', intensity.getValue(), materialSlot));
                }
            }
        }

        function update(currentObject:Dynamic, currentMaterialSlot:Int = 0) {
            object = currentObject;
            materialSlot = currentMaterialSlot;

            if (object == null) return;
            if (object.material == undefined) return;

            material = editor.getObjectMaterial(object, materialSlot);

            if (Reflect.hasField(material, property)) {
                color.setHexValue(material[property].getHexString());

                if (intensity != null) {
                    intensity.setValue(material[property + 'Intensity']);
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