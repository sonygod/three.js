import js.three.SetMaterialValueCommand;
import ui.UINumber;
import ui.UIRow;
import ui.UIText;

class SidebarMaterialNumberProperty extends UIRow {

	public function new(editor:Dynamic, property:String, name:String, ?range:Array<Float>, ?precision:Int) {
		super();

		if (range == null) range = [-Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY];
		if (precision == null) precision = 2;

		this.add(new UIText(name).setClass('Label'));

		var number = new UINumber().setWidth('60px').setRange(range[0], range[1]).setPrecision(precision).onChange(onChange);
		this.add(number);

		var object:Dynamic = null;
		var materialSlot:Int = 0;
		var material:Dynamic = null;

		function onChange():Void {
			if (material[property] != number.getValue()) {
				editor.execute(new SetMaterialValueCommand(editor, object, property, number.getValue(), materialSlot));
			}
		}

		public function update(currentObject:Dynamic, ?currentMaterialSlot:Int):Void {
			if (currentMaterialSlot == null) currentMaterialSlot = 0;

			object = currentObject;
			materialSlot = currentMaterialSlot;

			if (object == null || object.material == null) {
				return;
			}

			material = editor.getObjectMaterial(object, materialSlot);

			if (Reflect.hasField(material, property)) {
				number.setValue(Reflect.field(material, property));
				this.setDisplay('');
			} else {
				this.setDisplay('none');
			}
		}

		editor.signals.objectSelected.add(update);
		editor.signals.materialChanged.add(update);
	}
}