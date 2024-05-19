package three.js.editor.js;

import ui.UIButton;
import ui.UIPanel;
import ui.UIBreak;
import ui.UIText;
import ui.UIBoolean;
import ui.UIOutliner;

class SidebarSettingsHistory {
    public function new(editor:Editor) {
        var strings = editor.strings;
        var signals = editor.signals;
        var config = editor.config;
        var history = editor.history;

        var container = new UIPanel();

        container.add(new UIText(strings.getKey('sidebar/history').toUpperCase()));

        var persistent = new UIBoolean(config.getKey('settings/history'), strings.getKey('sidebar/history/persistent'));
        persistent.setPosition('absolute').setRight('8px');
        persistent.onChange(function() {
            var value = this.getValue();

            config.setKey('settings/history', value);

            if (value) {
                alert(strings.getKey('prompt/history/preserve'));

                var lastUndoCmd = history.undos[history.undos.length - 1];
                var lastUndoId = (lastUndoCmd != null) ? lastUndoCmd.id : 0;
                editor.history.enableSerialization(lastUndoId);

            } else {
                signals.historyChanged.dispatch();
            }
        });
        container.add(persistent);

        container.add(new UIBreak(), new UIBreak());

        var ignoreObjectSelectedSignal = false;

        var outliner = new UIOutliner(editor);
        outliner.onChange(function() {
            ignoreObjectSelectedSignal = true;

            editor.history.goToState(Std.parseInt(outliner.getValue()));

            ignoreObjectSelectedSignal = false;
        });
        container.add(outliner);

        container.add(new UIBreak());

        // Clear History

        var option = new UIButton(strings.getKey('sidebar/history/clear'));
        option.onClick(function() {
            if (confirm(strings.getKey('prompt/history/clear'))) {
                editor.history.clear();
            }
        });
        container.add(option);

        var refreshUI = function() {
            var options = [];

            function buildOption(object) {
                var option = document.createElement('div');
                option.value = object.id;

                return option;
            }

            function addObjects(objects) {
                for (i in 0...objects.length) {
                    var object = objects[i];

                    var option = buildOption(object);
                    option.innerHTML = '&nbsp;' + object.name;

                    options.push(option);
                }
            }

            addObjects(history.undos);

            function addObjects(objects) {
                for (i in objects.length - 1...0) {
                    var object = objects[i];

                    var option = buildOption(object);
                    option.innerHTML = '&nbsp;' + object.name;
                    option.style.opacity = 0.3;

                    options.push(option);
                }
            }

            addObjects(history.redos);

            outliner.setOptions(options);
        };

        refreshUI();

        // events

        signals.editorCleared.add(refreshUI);
        signals.historyChanged.add(refreshUI);
        signals.historyChanged.add(function(cmd) {
            if (ignoreObjectSelectedSignal) return;

            outliner.setValue(cmd != null ? cmd.id : null);
        });

        return container;
    }
}