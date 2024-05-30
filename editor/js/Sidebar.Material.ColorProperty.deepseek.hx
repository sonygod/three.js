import three.js.editor.js.libs.ui.UIColor;
import three.js.editor.js.libs.ui.UINumber;
import three.js.editor.js.libs.ui.UIRow;
import three.js.editor.js.libs.ui.UIText;
import three.js.editor.js.commands.SetMaterialColorCommand;
import three.js.editor.js.commands.SetMaterialValueCommand;

class SidebarMaterialColorProperty {

    public function new(editor:Dynamic, property:String, name:String) {

        var signals = editor.signals;

        var container = new UIRow();
        container.add(new UIText(name).setClass('Label'));

        var color = new UIColor().onInput(onChange);
        container.add(color);

        var intensity:UINumber;

        if (property == 'emissive') {

            intensity = new UINumber(1).setWidth('30px').setRange(0, Infinity).onChange(onChange);
            container.add(intensity);

        }

        var object:Dynamic = null;
        var materialSlot:Dynamic = null;
        var material:Dynamic = null;

        function onChange() {

            if (material[property].getHex() !== color.getHexValue()) {

                editor.execute(new SetMaterialColorCommand(editor, object, property, color.getHexValue(), materialSlot));

            }

            if (intensity !== undefined) {

                if (material[`${property}Intensity`] !== intensity.getValue()) {

                    editor.execute(new SetMaterialValueCommand(editor, object, `${property}Intensity`, intensity.getValue(), materialSlot));

                }

            }

        }

        function update(currentObject:Dynamic, currentMaterialSlot:Dynamic = 0) {

            object = currentObject;
            materialSlot = currentMaterialSlot;

            if (object == null) return;
            if (object.material == undefined) return;

            material = editor.getObjectMaterial(object, materialSlot);

            if (property in material) {

                color.setHexValue(material[property].getHexString());

                if (intensity !== undefined) {

                    intensity.setValue(material[`${property}Intensity`]);

                }

                container.setDisplay('');

            } else {

                container.setDisplay('none');

            }

        }

        //

        signals.objectSelected.add(update);
        signals.materialChanged.add(update);

        return container;

    }

}