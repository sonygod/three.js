import ui.UIButton;
import ui.UIPanel;
import ui.UIBreak;
import ui.UIText;
import ui.three.UIBoolean;
import ui.three.UIOutliner;

class SidebarSettingsHistory {
    private var editor: Editor;
    private var strings: Strings;
    private var signals: Signals;
    private var config: Config;
    private var history: History;
    private var container: UIPanel;
    private var persistent: UIBoolean;
    private var outliner: UIOutliner;
    private var ignoreObjectSelectedSignal: Bool;

    public function new(editor: Editor) {
        this.editor = editor;
        this.strings = editor.strings;
        this.signals = editor.signals;
        this.config = editor.config;
        this.history = editor.history;

        this.container = new UIPanel();

        this.container.add(new UIText(this.strings.getKey('sidebar/history').toUpperCase()));

        this.persistent = new UIBoolean(this.config.getKey('settings/history'), this.strings.getKey('sidebar/history/persistent'));
        this.persistent.setPosition('absolute').setRight('8px');
        this.persistent.onChange(function() {
            var value = this.getValue();
            this.config.setKey('settings/history', value);

            if (value) {
                js.Browser.alert(this.strings.getKey('prompt/history/preserve'));

                var lastUndoCmd = this.history.undos[this.history.undos.length - 1];
                var lastUndoId = (lastUndoCmd !== null) ? lastUndoCmd.id : 0;
                this.editor.history.enableSerialization(lastUndoId);
            } else {
                this.signals.historyChanged.dispatch();
            }
        }, this);
        this.container.add(this.persistent);

        this.container.add(new UIBreak(), new UIBreak());

        this.ignoreObjectSelectedSignal = false;

        this.outliner = new UIOutliner(this.editor);
        this.outliner.onChange(function() {
            this.ignoreObjectSelectedSignal = true;

            this.editor.history.goToState(Std.parseInt(this.outliner.getValue()));

            this.ignoreObjectSelectedSignal = false;
        }, this);
        this.container.add(this.outliner);

        this.container.add(new UIBreak());

        var option = new UIButton(this.strings.getKey('sidebar/history/clear'));
        option.onClick(function() {
            if (js.Browser.confirm(this.strings.getKey('prompt/history/clear'))) {
                this.editor.history.clear();
            }
        }, this);
        this.container.add(option);

        this.refreshUI();

        this.signals.editorCleared.add(this.refreshUI, this);
        this.signals.historyChanged.add(this.refreshUI, this);
        this.signals.historyChanged.add(function(cmd) {
            if (this.ignoreObjectSelectedSignal) return;

            this.outliner.setValue((cmd !== null) ? cmd.id : null);
        }, this);
    }

    private function refreshUI(): Void {
        var options = new Array<Dynamic>();

        function buildOption(object: Dynamic): Dynamic {
            var option = js.Browser.document.createElement('div');
            option.value = object.id;

            return option;
        }

        function addObjects(objects: Array<Dynamic>): Void {
            for (i in 0...objects.length) {
                var object = objects[i];

                var option = buildOption(object);
                option.innerHTML = '&nbsp;' + object.name;

                options.push(option);
            }
        }

        addObjects(this.history.undos);

        function addObjectsReversed(objects: Array<Dynamic>): Void {
            for (i in (objects.length - 1)...-1...-1) {
                var object = objects[i];

                var option = buildOption(object);
                option.innerHTML = '&nbsp;' + object.name;
                option.style.opacity = 0.3;

                options.push(option);
            }
        }

        addObjectsReversed(this.history.redos);

        this.outliner.setOptions(options);
    }
}