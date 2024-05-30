import js.Browser.window;
import js.Lib.{UIButton, UIBreak, UIPanel, UIRow, UIInput};
import js.Lib.commands.{AddScriptCommand, SetScriptValueCommand, RemoveScriptCommand};

class SidebarScript {

    var strings:Dynamic;
    var signals:Dynamic;
    var container:UIPanel;

    public function new(editor:Dynamic) {

        strings = editor.strings;
        signals = editor.signals;

        container = new UIPanel();
        container.setBorderTop('0');
        container.setPaddingTop('20px');
        container.setDisplay('none');

        var scriptsContainer = new UIRow();
        container.add(scriptsContainer);

        var newScript = new UIButton(strings.getKey('sidebar/script/new'));
        newScript.onClick(function () {

            var script = {name: '', source: 'function update( event ) {}'};
            editor.execute(new AddScriptCommand(editor, editor.selected, script));

        });
        container.add(newScript);

        function update() {

            scriptsContainer.clear();
            scriptsContainer.setDisplay('none');

            var object = editor.selected;

            if (object === null) {
                return;
            }

            var scripts = editor.scripts[object.uuid];

            if (scripts !== undefined && scripts.length > 0) {

                scriptsContainer.setDisplay('block');

                for (i in scripts) {

                    var script = scripts[i];

                    var name = new UIInput(script.name).setWidth('130px').setFontSize('12px');
                    name.onChange(function () {

                        editor.execute(new SetScriptValueCommand(editor, editor.selected, script, 'name', this.getValue()));

                    });
                    scriptsContainer.add(name);

                    var edit = new UIButton(strings.getKey('sidebar/script/edit'));
                    edit.setMarginLeft('4px');
                    edit.onClick(function () {

                        signals.editScript.dispatch(object, script);

                    });
                    scriptsContainer.add(edit);

                    var remove = new UIButton(strings.getKey('sidebar/script/remove'));
                    remove.setMarginLeft('4px');
                    remove.onClick(function () {

                        if (window.confirm(strings.getKey('prompt/script/remove'))) {

                            editor.execute(new RemoveScriptCommand(editor, editor.selected, script));

                        }

                    });
                    scriptsContainer.add(remove);

                    scriptsContainer.add(new UIBreak());

                }

            }

        }

        signals.objectSelected.add(function (object) {

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

    public function getContainer():UIPanel {
        return container;
    }

}