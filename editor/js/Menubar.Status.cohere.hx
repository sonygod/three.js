import js.three.Three;

import ui.UIPanel;
import ui.UIText;
import ui.three.UIBoolean;

function menubarStatus(editor:Editor) : UIPanel {
    var strings = editor.strings;
    var container = new UIPanel();
    container.setClass('menu right');
    var autosave = new UIBoolean(editor.config.getKey('autosave'), strings.getKey('menubar/status/autosave'));
    autosave.text.setColor('#888');
    autosave.onChange(function() {
        var value = this.getValue();
        editor.config.setKey('autosave', value);
        if (value) {
            editor.signals.sceneGraphChanged.dispatch();
        }
    });
    container.add(autosave);
    editor.signals.savingStarted.add(function() {
        autosave.text.setTextDecoration('underline');
    });
    editor.signals.savingFinished.add(function() {
        autosave.text.setTextDecoration('none');
    });
    var version = new UIText('r' + Three.REVISION);
    version.setClass('title');
    version.setOpacity(0.5);
    container.add(version);
    return container;
}

class MenubarStatus {
    public static init(editor:Editor) : Void {
        editor.menubar.addEntry(new Menu(editor.strings.getKey('menubar/status'), function() {
            this.addEntry(new MenuEntry(editor.strings.getKey('menubar/status/autosave'), function() {
                editor.config.setKey('autosave', !editor.config.getKey('autosave'));
            }).setChecked(editor.config.getKey('autosave')));
        }));
    }
}