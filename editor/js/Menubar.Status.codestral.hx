import three.THREE;
import ui.UIPanel;
import ui.UIText;
import ui.three.UIBoolean;

class MenubarStatus {
    public function new(editor:Dynamic) {
        var strings:Dynamic = editor.strings;
        var container:UIPanel = new UIPanel();
        container.setClass('menu right');

        var autosave:UIBoolean = new UIBoolean(editor.config.getKey('autosave'), strings.getKey('menubar/status/autosave'));
        autosave.text.setColor('#888');
        autosave.onChange(function() {
            var value:Bool = this.getValue();
            editor.config.setKey('autosave', value);

            if (value === true) {
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

        var version:UIText = new UIText('r' + THREE.REVISION);
        version.setClass('title');
        version.setOpacity(0.5);
        container.add(version);

        return container;
    }
}