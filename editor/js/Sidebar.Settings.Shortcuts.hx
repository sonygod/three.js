package three.js.editor.js;

import js.html.Document;
import js.Browser;
import three.js.editor.js.libs.ui.UIPanel;
import three.js.editor.js.libs.ui.UIText;
import three.js.editor.js.libs.ui.UIRow;
import three.js.editor.js.libs.ui.UIInput;
import three.js.editor.js.commands.RemoveObjectCommand;

class SidebarSettingsShortcuts {
    private var editor:Dynamic;
    private var strings:Dynamic;
    private var IS_MAC:Bool;
    private var config:Dynamic;
    private var signals:Dynamic;
    private var container:UIPanel;

    public function new(editor:Dynamic) {
        this.editor = editor;
        this.strings = editor.strings;
        this.IS_MAC = Browser.navigator.platform.toUpperCase().indexOf('MAC') >= 0;
        this.config = editor.config;
        this.signals = editor.signals;

        container = new UIPanel();

        var headerRow = new UIRow();
        headerRow.add(new UIText(strings.getKey('sidebar/settings/shortcuts').toUpperCase()));
        container.add(headerRow);

        var shortcuts:Array<String> = ['translate', 'rotate', 'scale', 'undo', 'focus'];

        for (i in 0...shortcuts.length) {
            createShortcutInput(shortcuts[i]);
        }

        Browser.document.addEventListener('keydown', onKeyDown);

        return container;
    }

    private function isValidKeyBinding(key:String):Bool {
        return ~/^[A-Za-z0-9]$/.match(key); // Can't use z currently due to undo/redo
    }

    private function createShortcutInput(name:String):Void {
        var configName = 'settings/shortcuts/' + name;
        var shortcutRow = new UIRow();

        var shortcutInput = new UIInput();
        shortcutInput.setWidth('15px');
        shortcutInput.setFontSize('12px');
        shortcutInput.setTextAlign('center');
        shortcutInput.setTextTransform('lowercase');
        shortcutInput.onChange(function() {
            var value = shortcutInput.getValue().toLowerCase();

            if (isValidKeyBinding(value)) {
                config.setKey(configName, value);
            }
        });

        shortcutInput.dom.addEventListener('click', function() {
            shortcutInput.dom.select();
        });

        shortcutInput.dom.addEventListener('blur', function() {
            if (!isValidKeyBinding(shortcutInput.getValue())) {
                shortcutInput.setValue(config.getKey(configName));
            }
        });

        shortcutInput.dom.addEventListener('keyup', function(event) {
            if (isValidKeyBinding(event.key)) {
                shortcutInput.dom.blur();
            }
        });

        if (config.getKey(configName) != null) {
            shortcutInput.setValue(config.getKey(configName));
        }

        shortcutInput.dom.maxLength = 1;

        shortcutRow.add(new UIText(strings.getKey('sidebar/settings/shortcuts/' + name)).setTextTransform('capitalize').setClass('Label'));
        shortcutRow.add(shortcutInput);

        container.add(shortcutRow);
    }

    private function onKeyDown(event:KeyboardEvent):Void {
        switch (event.key.toLowerCase()) {
            case 'backspace':
                event.preventDefault(); // prevent browser back
                // fall-through
            case 'delete':
                var object = editor.selected;
                if (object == null) return;
                var parent = object.parent;
                if (parent != null) editor.execute(new RemoveObjectCommand(editor, object));
                break;
            case config.getKey('settings/shortcuts/translate'):
                signals.transformModeChanged.dispatch('translate');
                break;
            case config.getKey('settings/shortcuts/rotate'):
                signals.transformModeChanged.dispatch('rotate');
                break;
            case config.getKey('settings/shortcuts/scale'):
                signals.transformModeChanged.dispatch('scale');
                break;
            case config.getKey('settings/shortcuts/undo'):
                if (IS_MAC ? event.metaKey : event.ctrlKey) {
                    event.preventDefault(); // Prevent browser specific hotkeys
                    if (event.shiftKey) {
                        editor.redo();
                    } else {
                        editor.undo();
                    }
                }
                break;
            case config.getKey('settings/shortcuts/focus'):
                if (editor.selected != null) {
                    editor.focus(editor.selected);
                }
                break;
        }
    }
}