import js.Browser.window;
import js.html.Event;
import js.html.InputElement;
import js.html.KeyboardEvent;

class SidebarSettingsShortcuts {
    function new(editor:Editor) {
        var strings = editor.strings;
        var IS_MAC = window.navigator.platform.toUpperCase().indexOf('MAC') >= 0;
        function isValidKeyBinding(key:String):Bool {
            return key.match(/^[$A-Z]$/);
        }
        var config = editor.config;
        var signals = editor.signals;
        var container = new UIPanel();
        var headerRow = new UIRow();
        headerRow.add(new UIText(strings.getKey('sidebar/settings/shortcuts').toUpperCase()));
        container.add(headerRow);
        var shortcuts = ['translate', 'rotate', 'scale', 'undo', 'focus'];
        function createShortcutInput(name:String) {
            var configName = 'settings/shortcuts/' + name;
            var shortcutRow = new UIRow();
            var shortcutInput = new UIInput().setWidth('15px').setFontSize('12px');
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
            shortcutInput.dom.addEventListener('keyup', function(event:KeyboardEvent) {
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
        for (i in 0...shortcuts.length) {
            createShortcutInput(shortcuts[i]);
        }
        window.document.addEventListener('keydown', function(event:KeyboardEvent) {
            switch (event.key.toLowerCase()) {
                case 'backspace':
                    event.preventDefault();
                    // fall-through
                    case 'delete':
                        var object = editor.selected;
                        if (object == null) {
                            return;
                        }
                        var parent = object.parent;
                        if (parent != null) {
                            editor.execute(new RemoveObjectCommand(editor, object));
                        }
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
                        if (IS_MAC && event.metaKey || !IS_MAC && event.ctrlKey) {
                            event.preventDefault();
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
        });
        return container;
    }
}