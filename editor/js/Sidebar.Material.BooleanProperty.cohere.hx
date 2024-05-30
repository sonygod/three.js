import js.UICheckbox;
import js.UIRow;
import js.UIText;
import js.SetMaterialValueCommand;

function sidebarMaterialBooleanProperty(editor:Editor, prop:String, name:String):UIRow {
    var signals = editor.signals;
    var container = new UIRow();
    container.add(new UIText(name).setClass('Label'));
    var boolean = new UICheckbox().setLeft('100px').onChange(onChange);
    container.add(boolean);
    var obj:Dynamic = null;
    var materialSlot:Int = 0;
    var mat:Dynamic = null;
    function onChange() {
        if (mat[prop] != boolean.getValue()) {
            editor.execute(new SetMaterialValueCommand(editor, obj, prop, boolean.getValue(), materialSlot));
        }
    }
    function update(currentObject:Dynamic, currentMaterialSlot:Int = 0) {
        obj = currentObject;
        materialSlot = currentMaterialSlot;
        if (obj == null) return;
        if (Reflect.hasField(obj, 'material') == false) return;
        mat = editor.getObjectMaterial(obj, materialSlot);
        if (Reflect.hasField(mat, prop)) {
            boolean.setValue(mat[prop]);
            container.setDisplay('');
        } else {
            container.setDisplay('none');
        }
    }
    signals.objectSelected.add(update);
    signals.materialChanged.add(update);
    return container;
}
class SidebarMaterialBooleanProperty {
    public static sidebarMaterialBooleanProperty(editor:Editor, prop:String, name:String):UIRow {
        return sidebarMaterialBooleanProperty(editor, prop, name);
    }
}