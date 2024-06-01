import three.Box3;
import three.Vector3;

import ui.UIPanel;
import ui.UIRow;
import ui.UIHorizontalRule;

import commands.AddObjectCommand;
import commands.RemoveObjectCommand;
import commands.SetPositionCommand;

import utils.SkeletonUtils.clone; // Assuming the path is correct

class MenubarEdit {

	public function new(editor:Editor) {

		var strings = editor.strings;

		var container = new UIPanel();
		container.setClass('menu');

		var title = new UIPanel();
		title.setClass('title');
		title.setTextContent(strings.getKey('menubar/edit'));
		container.add(title);

		var options = new UIPanel();
		options.setClass('options');
		container.add(options);

		// Undo

		var undo = new UIRow();
		undo.setClass('option');
		undo.setTextContent(strings.getKey('menubar/edit/undo'));
		undo.onClick(function() {
			editor.undo();
		});
		options.add(undo);

		// Redo

		var redo = new UIRow();
		redo.setClass('option');
		redo.setTextContent(strings.getKey('menubar/edit/redo'));
		redo.onClick(function() {
			editor.redo();
		});
		options.add(redo);

		function onHistoryChanged() {

			var history = editor.history;

			undo.setClass('option');
			redo.setClass('option');

			if (history.undos.length == 0) {
				undo.setClass('inactive');
			}

			if (history.redos.length == 0) {
				redo.setClass('inactive');
			}

		}

		editor.signals.historyChanged.add(onHistoryChanged);
		onHistoryChanged();

		// ---

		options.add(new UIHorizontalRule());

		// Center

		var option = new UIRow();
		option.setClass('option');
		option.setTextContent(strings.getKey('menubar/edit/center'));
		option.onClick(function() {
			var object = editor.selected;

			if (object == null || object.parent == null)
				return; // avoid centering the camera or scene

			var aabb = new Box3().setFromObject(object);
			var center = aabb.getCenter(new Vector3());
			var newPosition = new Vector3();

			newPosition.x = object.position.x - center.x;
			newPosition.y = object.position.y - center.y;
			newPosition.z = object.position.z - center.z;

			editor.execute(new SetPositionCommand(editor, object, newPosition));
		});
		options.add(option);

		// Clone

		option = new UIRow();
		option.setClass('option');
		option.setTextContent(strings.getKey('menubar/edit/clone'));
		option.onClick(function() {
			var object = editor.selected;

			if (object == null || object.parent == null)
				return; // avoid cloning the camera or scene

			object = clone(object);

			editor.execute(new AddObjectCommand(editor, object));
		});
		options.add(option);

		// Delete

		option = new UIRow();
		option.setClass('option');
		option.setTextContent(strings.getKey('menubar/edit/delete'));
		option.onClick(function() {
			var object = editor.selected;

			if (object != null && object.parent != null) {
				editor.execute(new RemoveObjectCommand(editor, object));
			}
		});
		options.add(option);

		return container;

	}
}