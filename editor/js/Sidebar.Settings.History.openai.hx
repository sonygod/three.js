package three.js.editor.js;

import ui.UIButton;
import ui.UIPanel;
import ui.UIBreak;
import ui.UIText;
import ui.UIBoolean;
import ui.UIOutliner;

class SidebarSettingsHistory {
    private var editor:Sandbox;
    private var strings:Dynamic;
    private var signals:Dynamic;
    private var config:Dynamic;
    private var history:Dynamic;
    private var container:UIPanel;

    public function new(editor:Sandbox) {
        strings = editor.strings;
        signals = editor.signals;
        config = editor.config;
        history = editor.history;

        container = new UIPanel();
        container.add(new UIText(strings.getKey('sidebar/history').toUpperCase()));

        // Persistent
        var persistent:UIBoolean = new UIBoolean(config.getKey('settings/history'), strings.getKey('sidebar/history/persistent'));
        persistent.setPosition('absolute').setRight('8px');
        persistent.onChange = function() {
            var value:Bool = persistent.getValue();
            config.setKey('settings/history', value);
            if (value) {
                js.Browser.alert(strings.getKey('prompt/history/preserve'));
                var lastUndoCmd:Dynamic = history.undos[history.undos.length - 1];
                var lastUndoId:Int = (lastUndoCmd != null) ? lastUndoCmd.id : 0;
                editor.history.enableSerialization(lastUndoId);
            } else {
                signals.historyChanged.dispatch();
            }
        };
        container.add(persistent);

        container.add(new UIBreak(), new UIBreak());

        var ignoreObjectSelectedSignal:Bool = false;

        var outliner:UIOutliner = new UIOutliner(editor);
        outliner.onChange = function() {
            ignoreObjectSelectedSignal = true;
            editor.history.goToState(Std.parseInt(outliner.getValue()));
            ignoreObjectSelectedSignal = false;
        };
        container.add(outliner);

        container.add(new UIBreak());

        // Clear History
        var option:UIButton = new UIButton(strings.getKey('sidebar/history/clear'));
        option.onClick = function() {
            if (js.Browser.confirm(strings.getKey('prompt/history/clear'))) {
                editor.history.clear();
            }
        };
        container.add(option);

        // Refresh UI
        var refreshUI:Void->Void = function() {
            var options:Array<Dynamic> = [];
            function buildOption(object:Dynamic):Dynamic {
                var option:Dynamic = js.Browser.document.createElement('div');
                option.value = object.id;
                return option;
            }
            function addObjects(objects:Array<Dynamic>) {
                for (i in 0...objects.length) {
                    var object:Dynamic = objects[i];
                    var option:Dynamic = buildOption(object);
                    option.innerHTML = '&nbsp;' + object.name;
                    options.push(option);
                }
            }
            addObjects(history.undos);
            function addObjects(objects:Array<Dynamic>) {
                for (i in objects.length - 1...0--) {
                    var object:Dynamic = objects[i];
                    var option:Dynamic = buildOption(object);
                    option.innerHTML = '&nbsp;' + object.name;
                    option.style.opacity = 0.3;
                    options.push(option);
                }
            }
            addObjects(history.redos);
            outliner.setOptions(options);
        };
        refreshUI();

        // Events
        signals.editorCleared.add(refreshUI);
        signals.historyChanged.add(refreshUI);
        signals.historyChanged.add(function(cmd:Dynamic) {
            if (ignoreObjectSelectedSignal) return;
            outliner.setValue(cmd != null ? cmd.id : null);
        });
    }
}