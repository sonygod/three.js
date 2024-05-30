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
    public function new(editor:Editor) {
        var strings = editor.strings;
        var signals = editor.signals;

        var container = new UIPanel();
        container.setBorderTop('0');
        container.setPaddingTop('20px');
        container.setDisplay('none');

        var scriptsContainer = new UIRow();
        container.add(scriptsContainer);

        var newScript = new UIButton(strings.getKey('sidebar/script/new'));
        newScript.onClick(function() {
            var script = { name: '', source: 'function update( event ) {}' };
            editor.execute(new AddScriptCommand(editor, editor.selected, script));
        });
        container.add(newScript);

        // loadScript code is commented out, so I'll leave it out for now
        // let loadScript = ...

        function update() {
            scriptsContainer.clear();
            scriptsContainer.setDisplay('none');

            var object = editor.selected;

            if (object === null) {
                return;
            }

            var scripts = editor.scripts[object.uuid];

            if (scripts != null && scripts.length > 0) {
                scriptsContainer.setDisplay('block');

                for (i in 0...scripts.length) {
                    var script = scripts[i];
                    var name = new UIInput(script.name).setWidth('130px').setFontSize('12px');
                    name.onChange(function() {
                        editor.execute(new SetScriptValueCommand(editor, editor.selected, script, 'name', name.getValue()));
                    });
                    scriptsContainer.add(name);

                    var edit = new UIButton(strings.getKey('sidebar/script/edit'));
                    edit.setMarginLeft('4px');
                    edit.onClick(function() {
                        signals.editScript.dispatch(object, script);
                    });
                    scriptsContainer.add(edit);

                    var remove = new UIButton(strings.getKey('sidebar/script/remove'));
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

        // signals
        signals.objectSelected.add(function(object) {
            if (object != null && editor.camera != object) {
                container.setDisplay('block');
                update();
            } else {
                container.setDisplay('none');
            }
        });

        signals.scriptAdded.add(update);
        signals.scriptRemoved.add(update);
        signals.scriptChanged.add(update);

        return container;
    }
}