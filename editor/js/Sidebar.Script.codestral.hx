import js.Browser.window;
import js.Browser.document;
import js.Browser.confirm;

import ui.UIPanel;
import ui.UIBreak;
import ui.UIButton;
import ui.UIRow;
import ui.UIInput;

import commands.AddScriptCommand;
import commands.SetScriptValueCommand;
import commands.RemoveScriptCommand;

class SidebarScript {

    var editor: dynamic;
    var strings: dynamic;
    var signals: dynamic;
    var container: UIPanel;
    var scriptsContainer: UIRow;
    var newScript: UIButton;

    public function new(editor: dynamic) {
        this.editor = editor;
        this.strings = editor.strings;
        this.signals = editor.signals;

        this.container = new UIPanel();
        this.container.setBorderTop('0');
        this.container.setPaddingTop('20px');
        this.container.setDisplay('none');

        this.scriptsContainer = new UIRow();
        this.container.add(this.scriptsContainer);

        this.newScript = new UIButton(this.strings.getKey('sidebar/script/new'));
        this.newScript.onClick(function() {
            var script = { name: '', source: 'function update( event ) {}' };
            editor.execute(new AddScriptCommand(editor, editor.selected, script));
        });
        this.container.add(this.newScript);

        this.signals.objectSelected.add(function(object: dynamic) {
            if (object !== null && editor.camera !== object) {
                container.setDisplay('block');
                update();
            } else {
                container.setDisplay('none');
            }
        });

        this.signals.scriptAdded.add(update);
        this.signals.scriptRemoved.add(update);
        this.signals.scriptChanged.add(update);
    }

    function update() {
        this.scriptsContainer.clear();
        this.scriptsContainer.setDisplay('none');

        var object = this.editor.selected;

        if (object === null) {
            return;
        }

        var scripts = this.editor.scripts[object.uuid];

        if (scripts !== null && scripts.length > 0) {
            this.scriptsContainer.setDisplay('block');

            for (var i = 0; i < scripts.length; i++) {
                var script = scripts[i];

                var name = new UIInput(script.name);
                name.setWidth('130px');
                name.setFontSize('12px');
                name.onChange(function() {
                    editor.execute(new SetScriptValueCommand(editor, editor.selected, script, 'name', this.getValue()));
                });
                this.scriptsContainer.add(name);

                var edit = new UIButton(this.strings.getKey('sidebar/script/edit'));
                edit.setMarginLeft('4px');
                edit.onClick(function() {
                    signals.editScript.dispatch(object, script);
                });
                this.scriptsContainer.add(edit);

                var remove = new UIButton(this.strings.getKey('sidebar/script/remove'));
                remove.setMarginLeft('4px');
                remove.onClick(function() {
                    if (confirm(strings.getKey('prompt/script/remove'))) {
                        editor.execute(new RemoveScriptCommand(editor, editor.selected, script));
                    }
                });
                this.scriptsContainer.add(remove);

                this.scriptsContainer.add(new UIBreak());
            }
        }
    }
}