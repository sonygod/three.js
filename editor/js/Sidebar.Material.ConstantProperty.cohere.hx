import js.js_null;
import js.Browser.window;

import ui.UIRow;
import ui.UISelect;
import ui.UIText;

import commands.SetMaterialValueCommand;

class SidebarMaterialConstantProperty {
    public var container:UIRow;
    public var constant:UISelect;
    public var object:Dynamic;
    public var materialSlot:Int;
    public var material:Dynamic;

    public function new(editor:Dynamic, property:String, name:String, options:Array<String>) {
        container = new UIRow();
        container.add(new UIText(name).setClass('Label'));

        constant = new UISelect();
        constant.setOptions(options);
        constant.onChange(onChange);
        container.add(constant);

        let onChangeFunction = function() -> Void {
            var value = Std.parseInt(constant.getValue());

            if (material[property] != value) {
                editor.execute(new SetMaterialValueCommand(editor, object, property, value, materialSlot));
            }
        };

        let updateFunction = function(currentObject:Dynamic, currentMaterialSlot:Int = 0) -> Void {
            object = currentObject;
            materialSlot = currentMaterialSlot;

            if (js.js_null.isNull(object) || js.js_null.isUndefined(object.material)) {
                return;
            }

            material = editor.getObjectMaterial(object, materialSlot);

            if (material.hasOwnProperty(property)) {
                constant.setValue(material[property]);
                container.setDisplay('');
            } else {
                container.setDisplay('none');
            }
        };

        editor.signals.objectSelected.add(updateFunction);
        editor.signals.materialChanged.add(updateFunction);
    }
}

export { SidebarMaterialConstantProperty };