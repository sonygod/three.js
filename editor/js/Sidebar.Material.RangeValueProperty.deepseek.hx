import three.js.editor.js.libs.ui.UINumber;
import three.js.editor.js.libs.ui.UIRow;
import three.js.editor.js.libs.ui.UIText;
import three.js.editor.js.commands.SetMaterialRangeCommand;

class SidebarMaterialRangeValueProperty {

    public function new(editor:Dynamic, property:String, name:String, isMin:Bool, range:Array<Float> = [ -Infinity, Infinity ], precision:Float = 2, step:Float = 1, nudge:Float = 0.01, unit:String = '') {

        var signals = editor.signals;

        var container = new UIRow();
        container.add(new UIText(name).setClass('Label'));

        var number = new UINumber().setWidth('60px').setRange(range[0], range[1]).setPrecision(precision).setStep(step).setNudge(nudge).setUnit(unit).onChange(onChange);
        container.add(number);

        var object:Dynamic = null;
        var materialSlot:Dynamic = null;
        var material:Dynamic = null;

        function onChange() {

            if (material[property][if (isMin) 0 else 1] !== number.getValue()) {

                var minValue = if (isMin) number.getValue() else material[property][0];
                var maxValue = if (isMin) material[property][1] else number.getValue();

                editor.execute(new SetMaterialRangeCommand(editor, object, property, minValue, maxValue, materialSlot));

            }

        }

        function update(currentObject:Dynamic, currentMaterialSlot:Dynamic = 0) {

            object = currentObject;
            materialSlot = currentMaterialSlot;

            if (object == null) return;
            if (object.material == null) return;

            material = editor.getObjectMaterial(object, materialSlot);

            if (property in material) {

                number.setValue(material[property][if (isMin) 0 else 1]);
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