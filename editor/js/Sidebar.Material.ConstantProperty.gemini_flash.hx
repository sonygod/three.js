import js.Lib;
import ui.UIRow;
import ui.UISelect;
import ui.UIText;
import commands.SetMaterialValueCommand;

class SidebarMaterialConstantProperty extends UIRow {

	public function new(editor:Editor, property:String, name:String, options:Array<Dynamic>) {
		super();

		this.add(new UIText(name).setClass("Label"));

		var constant = new UISelect().setOptions(options).onChange(onChange);
		this.add(constant);

		var object:Dynamic = null;
		var materialSlot:Int = 0;
		var material:Dynamic = null;

		function onChange() {
			var value = Std.parseInt(constant.getValue());

			if (material[property] != value) {
				editor.execute(new SetMaterialValueCommand(editor, object, property, value, materialSlot));
			}
		}

		function update(currentObject:Dynamic, currentMaterialSlot:Int = 0) {
			object = currentObject;
			materialSlot = currentMaterialSlot;

			if (object == null || !Reflect.hasField(object, "material")) {
				return;
			}

			material = editor.getObjectMaterial(object, materialSlot);

			if (Reflect.hasField(material, property)) {
				constant.setValue(material[property]);
				this.setDisplay("");
			} else {
				this.setDisplay("none");
			}
		}

		editor.signals.objectSelected.add(update);
		editor.signals.materialChanged.add(update);
	}
}


**Explanation:**

1. **Import Statements:**  The required classes from `ui.js` and `SetMaterialValueCommand.js` are imported. 
2. **Class Definition:**  The JavaScript function is converted to a Haxe class named `SidebarMaterialConstantProperty` that extends the `UIRow` class.
3. **Constructor:**  The constructor initializes the UI elements and sets up event listeners.
4. **onChange Function:**  This function is called when the UISelect value changes. It updates the material property using the `SetMaterialValueCommand`.
5. **update Function:**  This function is called when the selected object or material changes. It updates the UI based on the current object and material properties.
6. **Event Listeners:**  The `objectSelected` and `materialChanged` signals are connected to the `update` function.
7. **Type Annotations (Optional):**  You can add type annotations to the code for better type safety and readability. For example:


object:Dynamic = null;  // Dynamic type to handle any object
materialSlot:Int = 0; 
material:Dynamic = null;