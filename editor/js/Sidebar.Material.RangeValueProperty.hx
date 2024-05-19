package three.js.editor.js;

import js.ui.UINumber;
import js.ui.UIRow;
import js.ui.UIText;
import js.commands.SetMaterialRangeCommand;

class SidebarMaterialRangeValueProperty {
    public function new(editor:Dynamic, property:String, name:String, isMin:Bool, ?range:Array<Float> = [-Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY], ?precision:Int = 2, ?step:Float = 1, ?nudge:Float = 0.01, ?unit:String = '') {
        var signals = editor.signals;

        var container = new UIRow();
        container.add(new UIText(name).setClass('Label'));

        var number = new UINumber().setWidth('60px').setRange(range[0], range[1]).setPrecision(precision).setStep(step).setNudge(nudge).setUnit(unit).onChange(onChange);
        container.add(number);

        var object:Dynamic = null;
        var materialSlot:Dynamic = null;
        var material:Dynamic = null;

        function onChange() {
            if (material != null && property in material) {
                var currentValue = isMin ? material[property][0] : material[property][1];
                if (currentValue != number.getValue()) {
                    var minValue = isMin ? number.getValue() : material[property][0];
                    var maxValue = isMin ? material[property][1] : number.getValue();

                    editor.execute(new SetMaterialRangeCommand(editor, object, property, minValue, maxValue, materialSlot));
                }
            }
        }

        function update(currentObject:Dynamic, ?currentMaterialSlot:Int = 0) {
            object = currentObject;
            materialSlot = currentMaterialSlot;

            if (object == null) return;
            if (object.material == null) return;

            material = editor.getObjectMaterial(object, materialSlot);

            if (material != null && property in material) {
                number.setValue(isMin ? material[property][0] : material[property][1]);
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

// Export the class
extern class SidebarMaterialRangeValueProperty {}