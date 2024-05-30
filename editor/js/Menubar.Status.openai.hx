package three.js.editor.js;

import js.three.THREE;

import ui.UIPanel;
import ui.UIText;
import ui.three.UIBoolean;

class MenubarStatus {
    public function new(editor:Dynamic) {
        var strings = editor.strings;

        var container = new UIPanel();
        container.setClass('menu right');

        var autosave = new UIBoolean(editor.config.getKey('autosave'), strings.getKey('menubar/status/autosave'));
        autosave.text.setColor('#888');
        autosave.onChange = function() {
            var value = autosave.getValue();

            editor.config.setKey('autosave', value);

            if (value) {
                editor.signals.sceneGraphChanged.dispatch();
            }
        };
        container.add(autosave);

        editor.signals.savingStarted.add(function() {
            autosave.text.setTextDecoration('underline');
        });

        editor.signals.savingFinished.add(function() {
            autosave.text.setTextDecoration('none');
        });

        var version = new UIText('r' + THREE.REVISION);
        version.setClass('title');
        version.setOpacity(0.5);
        container.add(version);

        return container;
    }
}