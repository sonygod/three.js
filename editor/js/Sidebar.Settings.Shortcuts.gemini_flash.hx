import dat.bakery.signals.Signal0;
import dat.bakery.signals.Signal1;
import js.Browser;
import js.html.Document;
import js.html.Element;
import ui.UIInput;
import ui.UIPanel;
import ui.UIRow;
import ui.UIText;

class SidebarSettingsShortcuts extends UIPanel {

    public function new(editor:Editor) {
        super();

        var strings = editor.strings;
        var config = editor.config;
        var signals = editor.signals;

        var headerRow = new UIRow();
        headerRow.add(new UIText(strings.getKey('sidebar/settings/shortcuts').toUpperCase()));
        add(headerRow);

        var shortcuts = ['translate', 'rotate', 'scale', 'undo', 'focus'];

        for (i in 0...shortcuts.length) {
            createShortcutInput(shortcuts[i], config, strings);
        }

        Browser.document.addEventListener("keydown", function(event:Dynamic) {
            var key = event.key.toLowerCase();

            switch (key) {
                case 'backspace', 'delete':
                    var object = editor.selected;
                    if (object != null) {
                        var parent = object.parent;
                        if (parent != null) editor.execute(new RemoveObjectCommand(editor, object));
                    }
                    event.preventDefault(); // prevent browser back on backspace
                case config.getKey('settings/shortcuts/translate'):
                    signals.transformModeChanged.dispatch("translate");
                case config.getKey('settings/shortcuts/rotate'):
                    signals.transformModeChanged.dispatch("rotate");
                case config.getKey('settings/shortcuts/scale'):
                    signals.transformModeChanged.dispatch("scale");
                case config.getKey('settings/shortcuts/undo'):
                    var isMac = Browser.navigator.platform.toUpperCase().indexOf("MAC") >= 0;
                    if ((isMac && event.metaKey) || (!isMac && event.ctrlKey)) {
                        event.preventDefault();
                        if (event.shiftKey) {
                            editor.redo();
                        } else {
                            editor.undo();
                        }
                    }
                case config.getKey('settings/shortcuts/focus'):
                    if (editor.selected != null) {
                        editor.focus(editor.selected);
                    }
            }
        });
    }

    function isValidKeyBinding(key:String) : Bool {
        return ~/^[A-Za-z0-9]$/i.match(key); // Can't use z currently due to undo/redo
    }

    function createShortcutInput(name:String, config:Dynamic, strings:Dynamic) {
        var configName = 'settings/shortcuts/' + name;
        var shortcutRow = new UIRow();

        var shortcutInput = new UIInput()
            .setWidth('15px')
            .setFontSize('12px')
            .setTextAlign('center')
            .setTextTransform('lowercase');

        shortcutInput.setValue(config.getKey(configName));

        shortcutInput.onChange(function(value:String) {
            if (isValidKeyBinding(value)) {
                config.setKey(configName, value);
                shortcutInput.dom.blur();
            }
        });

        shortcutInput.dom.addEventListener("click", function(_) {
            shortcutInput.dom.select();
        });

        shortcutInput.dom.addEventListener("blur", function(_) {
            if (!isValidKeyBinding(shortcutInput.getValue())) {
                shortcutInput.setValue(config.getKey(configName));
            }
        });

        shortcutInput.dom.maxLength = 1;

        shortcutRow.add(
            new UIText(strings.getKey('sidebar/settings/shortcuts/' + name))
                .setTextTransform('capitalize')
                .setClass('Label')
        );
        shortcutRow.add(shortcutInput);

        add(shortcutRow);
    }
}