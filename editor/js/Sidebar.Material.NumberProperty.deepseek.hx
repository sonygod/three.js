import three.js.editor.js.libs.ui.UINumber;
import three.js.editor.js.libs.ui.UIRow;
import three.js.editor.js.libs.ui.UIText;
import three.js.editor.js.commands.SetMaterialValueCommand;

class SidebarMaterialNumberProperty {

    public function new(editor:Dynamic, property:String, name:String, range:Array<Float> = [ -Infinity, Infinity ], precision:Float = 2.0) {

        var signals = editor.signals;

        var container = new UIRow();
        container.add(new UIText(name).setClass('Label'));

        var number = new UINumber().setWidth('60px').setRange(range[0], range[1]).setPrecision(precision).onChange(onChange);
        container.add(number);

        var object:Dynamic = null;
        var materialSlot:Dynamic = null;
        var material:Dynamic = null;

        function onChange() {

            if (material[property] !== number.getValue()) {

                editor.execute(new SetMaterialValueCommand(editor, object, property, number.getValue(), materialSlot));

            }

        }

        function update(currentObject:Dynamic, currentMaterialSlot:Dynamic = 0) {

            object = currentObject;
            materialSlot = currentMaterialSlot;

            if (object == null) return;
            if (object.material == null) return;

            material = editor.getObjectMaterial(object, materialSlot);

            if (property in material) {

                number.setValue(Std.parseFloat(material[property]));
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