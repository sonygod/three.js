import js.Browser.alert;
import js.Browser.confirm;

class SidebarSettingsHistory {
    public var container:UIPanel;
    public var editor:Editor;
    public var strings:StringMap<String>;
    public var signals:EditorSignals;
    public var config:Config;
    public var history:History;

    public function new(editor:Editor) {
        this.editor = editor;
        this.strings = editor.strings;
        this.signals = editor.signals;
        this.config = editor.config;
        this.history = editor.history;

        container = new UIPanel();
        container.add(new UIText(strings.get('sidebar/history').toUpperCase()));

        var persistent = new UIBoolean(config.getKey('settings/history'), strings.get('sidebar/history/persistent'));
        persistent.setPosition('absolute').setRight('8px');
        persistent.onChange(function() {
            var value = persistent.getValue();

            config.setKey('settings/history', value);

            if (value) {
                alert(strings.get('prompt/history/preserve'));
                var lastUndoCmd = history.undos[history.undos.length - 1];
                var lastUndoId = (lastUndoCmd != null) ? lastUndoCmd.id : 0;
                history.enableSerialization(lastUndoId);
            } else {
                signals.historyChanged.dispatch();
            }
        });
        container.add(persistent);

        container.add(new UIBreak());
        container.add(new UIBreak());

        var ignoreObjectSelectedSignal = false;

        var outliner = new UIOutliner(editor);
        outliner.onChange(function() {
            ignoreObjectSelectedSignal = true;
            history.goToState(Std.parseInt(outliner.getValue()));
            ignoreObjectSelectedSignal = false;
        });
        container.add(outliner);

        container.add(new UIBreak());

        var option = new UIButton(strings.get('sidebar/history/clear'));
        option.onClick(function() {
            if (confirm(strings.get('prompt/history/clear'))) {
                history.clear();
            }
        });
        container.add(option);

        var refreshUI = function() {
            var options = [];

            function buildOption(object:Dynamic) {
                var option = { value: object.id };
                return option;
            }

            function addObjects(objects:Array<Dynamic>) {
                for (obj in objects) {
                    var object = objects[obj];
                    var option = buildOption(object);
                    option.innerHTML = '&nbsp;' + object.name;
                    options.push(option);
                }
            }

            addObjects(history.undos);
            addObjects(history.redos);

            outliner.setOptions(options);
        };

        refreshUI();

        signals.editorCleared.add(refreshUI);
        signals.historyChanged.add(refreshUI);
        signals.historyChanged.add(function(cmd) {
            if (ignoreObjectSelectedSignal) return;
            outliner.setValue(cmd != null ? cmd.id : null);
        });
    }
}