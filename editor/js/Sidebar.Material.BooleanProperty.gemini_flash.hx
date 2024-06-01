package ;

import ui.UICheckbox;
import ui.UIRow;
import ui.UIText;
import commands.SetMaterialValueCommand;

class SidebarMaterialBooleanProperty extends UIRow {

	public function new(editor : Editor, property : String, name : String) {
		super();

		this.add(new UIText(name).setClass("Label"));

		var boolean = new UICheckbox().setLeft("100px").onChange(onChange);
		this.add(boolean);

		var object : Dynamic = null;
		var materialSlot : Int = 0;
		var material : Dynamic = null;

		function onChange() {
			if (material[property] != boolean.getValue()) {
				editor.execute(new SetMaterialValueCommand(editor, object, property, boolean.getValue(), materialSlot));
			}
		}

		function update(currentObject : Dynamic, currentMaterialSlot : Int = 0) {
			object = currentObject;
			materialSlot = currentMaterialSlot;

			if (object == null || Reflect.hasField(object, "material") == false) {
				return;
			}

			material = editor.getObjectMaterial(object, materialSlot);

			if (Reflect.hasField(material, property)) {
				boolean.setValue(material[property]);
				this.setDisplay("");
			} else {
				this.setDisplay("none");
			}
		}

		editor.signals.objectSelected.add(update);
		editor.signals.materialChanged.add(update);
	}
}