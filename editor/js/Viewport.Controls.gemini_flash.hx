import ui.UIPanel;
import ui.UISelect;
import ui.three.UIBoolean;

class ViewportControls {

	public function new(editor) {

		var signals = editor.signals;
		var strings = editor.strings;

		var container = new UIPanel();
		container.setPosition('absolute');
		container.setRight('10px');
		container.setTop('10px');
		container.setColor('#ffffff');

		// grid

		var gridCheckbox = new UIBoolean(true, strings.getKey('viewport/controls/grid'));
		gridCheckbox.onChange(function(_) {
			signals.showGridChanged.dispatch(gridCheckbox.getValue());
		});
		container.add(gridCheckbox);

		// helpers

		var helpersCheckbox = new UIBoolean(true, strings.getKey('viewport/controls/helpers'));
		helpersCheckbox.onChange(function(_) {
			signals.showHelpersChanged.dispatch(helpersCheckbox.getValue());
		});
		container.add(helpersCheckbox);

		// camera

		var cameraSelect = new UISelect();
		cameraSelect.setMarginLeft('10px');
		cameraSelect.setMarginRight('10px');
		cameraSelect.onChange(function(_) {
			editor.setViewportCamera(cameraSelect.getValue());
		});
		container.add(cameraSelect);

		signals.cameraAdded.add(update);
		signals.cameraRemoved.add(update);
		signals.objectChanged.add(function(object) {
			if (object.isCamera) {
				update();
			}
		});

		// shading

		var shadingSelect = new UISelect();
		shadingSelect.setOptions({
			'realistic': 'realistic',
			'solid': 'solid',
			'normals': 'normals',
			'wireframe': 'wireframe'
		});
		shadingSelect.setValue('solid');
		shadingSelect.onChange(function(_) {
			editor.setViewportShading(shadingSelect.getValue());
		});
		container.add(shadingSelect);

		signals.editorCleared.add(function(_) {
			editor.setViewportCamera(editor.camera.uuid);
			shadingSelect.setValue('solid');
			editor.setViewportShading(shadingSelect.getValue());
		});

		signals.cameraResetted.add(update);

		update();

		//

		function update() {
			var options = {};
			var cameras = editor.cameras;

			for (key in cameras.keys()) {
				var camera = cameras.get(key);
				options[camera.uuid] = camera.name;
			}

			cameraSelect.setOptions(options);

			var selectedCamera = (cameras.exists(editor.viewportCamera.uuid)) ? editor.viewportCamera : editor.camera;

			cameraSelect.setValue(selectedCamera.uuid);
			editor.setViewportCamera(selectedCamera.uuid);
		}

		return container;
	}
}