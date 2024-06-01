import three.THREE;

import ui.UIPanel;
import ui.UIText;
import ui.three.UIBoolean;

class MenubarStatus extends UIPanel {

	public function new(editor:Dynamic) { // Replace 'Dynamic' with the actual type of 'editor'

		super();

		this.setClass('menu right');

		var autosave = new UIBoolean(editor.config.getKey('autosave'), editor.strings.getKey('menubar/status/autosave'));
		autosave.text.setColor('#888');
		autosave.onChange(function() {
			var value = autosave.getValue();
			editor.config.setKey('autosave', value);
			if (value == true) {
				editor.signals.sceneGraphChanged.dispatch();
			}
		});
		this.add(autosave);

		editor.signals.savingStarted.add(function() {
			autosave.text.setTextDecoration('underline');
		});

		editor.signals.savingFinished.add(function() {
			autosave.text.setTextDecoration('none');
		});

		var version = new UIText('r' + THREE.REVISION);
		version.setClass('title');
		version.setOpacity(0.5);
		this.add(version);
	}
}