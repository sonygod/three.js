import js.html.UIButton;
import js.html.UIRow;
import js.html.UIText;

class SidebarMaterialProgram {

	var editor:Dynamic;
	var property:String;

	var signals:Dynamic;
	var strings:Dynamic;

	var object:Dynamic = null;
	var materialSlot:Dynamic = null;
	var material:Dynamic = null;

	var container:UIRow = new UIRow();

	public function new(editor:Dynamic, property:String) {

		this.editor = editor;
		this.property = property;

		signals = editor.signals;
		strings = editor.strings;

		container.add(new UIText(strings.getKey('sidebar/material/program')).setClass('Label'));

		var programInfo = new UIButton(strings.getKey('sidebar/material/info'));
		programInfo.setMarginRight('4px');
		programInfo.onClick(function() {
			signals.editScript.dispatch(object, 'programInfo');
		});
		container.add(programInfo);

		var programVertex = new UIButton(strings.getKey('sidebar/material/vertex'));
		programVertex.setMarginRight('4px');
		programVertex.onClick(function() {
			signals.editScript.dispatch(object, 'vertexShader');
		});
		container.add(programVertex);

		var programFragment = new UIButton(strings.getKey('sidebar/material/fragment'));
		programFragment.setMarginRight('4px');
		programFragment.onClick(function() {
			signals.editScript.dispatch(object, 'fragmentShader');
		});
		container.add(programFragment);

		signals.objectSelected.add(update);
		signals.materialChanged.add(update);
	}

	function update(currentObject:Dynamic, currentMaterialSlot:Dynamic = 0) {
		object = currentObject;
		materialSlot = currentMaterialSlot;

		if (object == null) return;
		if (object.material == null) return;

		material = editor.getObjectMaterial(object, materialSlot);

		if (js.Boot.hasField(material, property)) {
			container.setDisplay('');
		} else {
			container.setDisplay('none');
		}
	}
}