import js.three.Box3;
import js.three.Vector3;

import js.ui.UIPanel;
import js.ui.UIRow;
import js.ui.UIHorizontalRule;

import js.commands.AddObjectCommand;
import js.commands.RemoveObjectCommand;
import js.commands.SetPositionCommand;
import js.utils.SkeletonUtils.clone;

class MenubarEdit {
    public function new(editor:Editor) {
        var container = UIPanel.create().setClass('menu');
        var title = UIPanel.create().setClass('title').setTextContent(editor.strings.getKey('menubar/edit'));
        container.add(title);

        var options = UIPanel.create().setClass('options');
        container.add(options);

        function undo_click() {
            editor.undo();
        }

        function redo_click() {
            editor.redo();
        }

        var undo = UIRow.create().setClass('option').setTextContent(editor.strings.getKey('menubar/edit/undo')).onClick(undo_click);
        options.add(undo);

        var redo = UIRow.create().setClass('option').setTextContent(editor.strings.getKey('menubar/edit/redo')).onClick(redo_click);
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

        editor.signals.historyChanged.add($bind(onHistoryChanged));
        onHistoryChanged();

        options.add(UIHorizontalRule.create());

        function center_click() {
            var object = editor.selected;
            if (object == null || object.parent == null) {
                return; // avoid centering the camera or scene
            }

            var aabb = Box3.create().setFromObject(object);
            var center = aabb.getCenter(Vector3.create());
            var newPosition = Vector3.create();

            newPosition.x = object.position.x - center.x;
            newPosition.y = object.position.y - center.y;
            newPosition.z = object.position.z - center.z;

            editor.execute(SetPositionCommand.create(editor, object, newPosition));
        }

        var centerOption = UIRow.create().setClass('option').setTextContent(editor.strings.getKey('menubar/edit/center')).onClick(center_click);
        options.add(centerOption);

        function clone_click() {
            var object = editor.selected;
            if (object == null || object.parent == null) {
                return; // avoid cloning the camera or scene
            }

            object = clone(object);
            editor.execute(AddObjectCommand.create(editor, object));
        }

        var cloneOption = UIRow.create().setClass('option').setTextContent(editor.strings.getKey('menubar/edit/clone')).onClick(clone_click);
        options.add(cloneOption);

        function delete_click() {
            var object = editor.selected;
            if (object != null && object.parent != null) {
                editor.execute(RemoveObjectCommand.create(editor, object));
            }
        }

        var deleteOption = UIRow.create().setClass('option').setTextContent(editor.strings.getKey('menubar/edit/delete')).onClick(delete_click);
        options.add(deleteOption);

        return container;
    }
}

class js.MenubarEdit {
    public static function create(editor:Editor) {
        return MenubarEdit.new(editor);
    }
}