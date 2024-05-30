import js.Browser.window;

import js.html.Element;
import js.html.Input;
import js.html.InputElement;
import js.html.ButtonElement;

class SidebarScript {
    var container:Element;
    var scriptsContainer:Element;
    var editor:Editor;
    var strings:StringMap<String>;
    var signals:EditorSignals;

    function new(e:Editor) {
        editor = e;
        strings = e.strings;
        signals = e.signals;

        container = window.document.createElement('div');
        container.style.borderTop = '0';
        container.style.paddingTop = '20px';
        container.style.display = 'none';

        scriptsContainer = window.document.createElement('div');
        container.appendChild(scriptsContainer);

        var newScript = window.document.createElement('button');
        newScript.innerHTML = strings.get('sidebar/script/new');
        newScript.onclick = function() {
            var script = { 'name': '', 'source': 'function update( event ) {}' };
            editor.execute(new AddScriptCommand(editor, editor.selected, script));
        };
        container.appendChild(newScript);

        signals.objectSelected.add(function(object:Object3D) {
            if (object != null && editor.camera != object) {
                container.style.display = 'block';
                update();
            } else {
                container.style.display = 'none';
            }
        });

        signals.scriptAdded.add(update);
        signals.scriptRemoved.add(update);
        signals.scriptChanged.add(update);
    }

    function update() {
        scriptsContainer.innerHTML = '';
        scriptsContainer.style.display = 'none';

        var object = editor.selected;
        if (object == null) return;

        var scripts = editor.scripts.get(object.uuid);
        if (scripts != null && scripts.length > 0) {
            scriptsContainer.style.display = 'block';

            for (script in scripts) {
                var name = window.document.createElement('input');
                name.value = script.name;
                name.style.width = '130px';
                name.style.fontSize = '12px';
                name.onchange = function() {
                    editor.execute(new SetScriptValueCommand(editor, editor.selected, script, 'name', name.value));
                };
                scriptsContainer.appendChild(name);

                var edit = window.document.createElement('button');
                edit.innerHTML = strings.get('sidebar/script/edit');
                edit.style.marginLeft = '4px';
                edit.onclick = function() {
                    signals.editScript.dispatch(object, script);
                };
                scriptsContainer.appendChild(edit);

                var remove = window.document.createElement('button');
                remove.innerHTML = strings.get('sidebar/script/remove');
                remove.style.marginLeft = '4px';
                remove.onclick = function() {
                    if (window.confirm(strings.get('prompt/script/remove'))) {
                        editor.execute(new RemoveScriptCommand(editor, editor.selected, script));
                    }
                };
                scriptsContainer.appendChild(remove);

                scriptsContainer.appendChild(window.document.createElement('hr'));
            }
        }
    }
}

class AddScriptCommand {
    var editor:Editor;
    var object:Object3D;
    var script:Script;

    function new(e:Editor, o:Object3D, s:Script) {
        editor = e;
        object = o;
        script = s;
    }

    function execute() {
        editor.addScript(object, script);
    }

    function undo() {
        editor.removeScript(object, script);
    }
}

class SetScriptValueCommand {
    var editor:Editor;
    var object:Object3D;
    var script:Script;
    var name:String;
    var value:Dynamic;

    function new(e:Editor, o:Object3D, s:Script, n:String, v:Dynamic) {
        editor = e;
        object = o;
        script = s;
        name = n;
        value = v;
    }

    function execute() {
        script.setValue(name, value);
    }

    function undo() {
        script.setValue(name, script.original[name]);
    }
}

class RemoveScriptCommand {
    var editor:Editor;
    var object:Object3D;
    var script:Script;

    function new(e:Editor, o:Object3D, s:Script) {
        editor = e;
        object = o;
        script = s;
    }

    function execute() {
        editor.removeScript(object, script);
    }

    function undo() {
        editor.addScript(object, script);
    }
}