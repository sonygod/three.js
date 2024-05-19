package three.js.editor.js;

import ui.UIPanel;
import ui.UIBreak;
import ui.UIButton;
import ui.UIRow;
import ui.UIInput;

import commands.AddScriptCommand;
import commands.SetScriptValueCommand;
import commands.RemoveScriptCommand;

class SidebarScript {
    private var editor:Dynamic;
    private var strings:Dynamic;
    private var signals:Dynamic;
    private var container:UIPanel;
    private var scriptsContainer:UIRow;

    public function new(editor:Dynamic) {
        this.editor = editor;
        this.strings = editor.strings;
        this.signals = editor.signals;

        container = new UIPanel();
        container.setBorderTop('0');
        container.setPaddingTop('20px');
        container.setDisplay('none');

        scriptsContainer = new UIRow();
        container.add(scriptsContainer);

        var newScript:UIButton = new UIButton(strings.getKey('sidebar/script/new'));
        newScript.onClick(function() {
            var script:Dynamic = { name: '', source: 'function update( event ) {}' };
            editor.execute(new AddScriptCommand(editor, editor.selected, script));
        });
        container.add(newScript);

        // loadScript code is commented out in the original JavaScript code, so I'll leave it out for now
        // let loadScript = new UI.Button('Load');
        // loadScript.setMarginLeft('4px');
        // container.add(loadScript);

        signals.objectSelected.add(function(object:Dynamic) {
            if (object !== null && editor.camera !== object) {
                container.setDisplay('block');
                update();
            } else {
                container.setDisplay('none');
            }
        });

        signals.scriptAdded.add(update);
        signals.scriptRemoved.add(update);
        signals.scriptChanged.add(update);
    }

    private function update():Void {
        scriptsContainer.clear();
        scriptsContainer.setDisplay('none');

        var object:Dynamic = editor.selected;

        if (object === null) {
            return;
        }

        var scripts:Array<Dynamic> = editor.scripts[object.uuid];

        if (scripts !== null && scripts.length > 0) {
            scriptsContainer.setDisplay('block');

            for (i in 0...scripts.length) {
                var script:Dynamic = scripts[i];
                var name:UIInput = new UIInput(script.name);
                name.setWidth('130px');
                name.setFontSize('12px');
                name.onChange(function() {
                    editor.execute(new SetScriptValueCommand(editor, editor.selected, script, 'name', this.getValue()));
                });
                scriptsContainer.add(name);

                var edit:UIButton = new UIButton(strings.getKey('sidebar/script/edit'));
                edit.setMarginLeft('4px');
                edit.onClick(function() {
                    signals.editScript.dispatch(object, script);
                });
                scriptsContainer.add(edit);

                var remove:UIButton = new UIButton(strings.getKey('sidebar/script/remove'));
                remove.setMarginLeft('4px');
                remove.onClick(function() {
                    if (confirm(strings.getKey('prompt/script/remove'))) {
                        editor.execute(new RemoveScriptCommand(editor, editor.selected, script));
                    }
                });
                scriptsContainer.add(remove);

                scriptsContainer.add(new UIBreak());
            }
        }
    }
}