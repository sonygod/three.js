class UIElement {
    function new(element) {}
    function setPosition(position) {}
    function setTop(top) {}
    function setRight(right) {}
    function setCursor(cursor) {}
    function onClick(handler) {}
    function add(element) {}
}

class UIPanel extends UIElement {
    function setId(id) {}
    function setBackgroundColor(color) {}
    function setDisplay(display) {}
    function setPadding(padding) {}
}

class UIText extends UIElement {
    function setColor(color) {}
    function setValue(value) {}
}

class Signal {
    function add(handler) {}
}

class Signals {
    var rendererCreated:Signal;
    var editorCleared:Signal;
    var editScript:Signal;
    var scriptRemoved:Signal;
}

class Editor {
    var signals:Signals;
    function execute(command) {}
}

class SetScriptValueCommand {
    function new(editor, object, script, property, value) {}
}

class SetMaterialValueCommand {
    function new(editor, object, property, value) {}
    var updatable:Bool;
}

class Script {
    var container:UIPanel;
    var codemirror:Dynamic;
    var currentMode:String;
    var currentScript:Dynamic;
    var currentObject:Dynamic;
    var renderer:Dynamic;
    var delay:Dynamic;
    var errorLines:Array<Int>;
    var widgets:Array<Dynamic>;
    var server:Dynamic;

    function new(editor:Editor) {
        var signals = editor.signals;

        container = new UIPanel();
        container.setId('script');
        container.setPosition('absolute');
        container.setBackgroundColor('#272822');
        container.setDisplay('none');

        var header = new UIPanel();
        header.setPadding('10px');
        container.add(header);

        var title = new UIText().setColor('#fff');
        header.add(title);

        var close = new UIElement(createButtonSVG());
        close.setPosition('absolute');
        close.setTop('3px');
        close.setRight('1px');
        close.setCursor('pointer');
        close.onClick(function() {
            container.setDisplay('none');
        });
        header.add(close);

        signals.rendererCreated.add(function(newRenderer) {
            renderer = newRenderer;
        });

        codemirror = CodeMirror(container.dom, {
            value: '',
            lineNumbers: true,
            matchBrackets: true,
            indentWithTabs: true,
            tabSize: 4,
            indentUnit: 4,
            hintOptions: {
                completeSingle: false
            }
        });
        codemirror.setOption('theme', 'monokai');
        codemirror.on('change', function() {
            if (codemirror.state.focused === false) return;

            clearTimeout(delay);
            delay = setTimeout(function() {
                var value = codemirror.getValue();

                if (!validate(value)) return;

                if (Std.is(currentScript, Object)) {
                    if (value !== currentScript.source) {
                        editor.execute(new SetScriptValueCommand(editor, currentObject, currentScript, 'source', value));
                    }
                    return;
                }

                if (currentScript !== 'programInfo') return;

                var json = JSON.parse(value);

                if (JSON.stringify(currentObject.material.defines) !== JSON.stringify(json.defines)) {
                    var cmd = new SetMaterialValueCommand(editor, currentObject, 'defines', json.defines);
                    cmd.updatable = false;
                    editor.execute(cmd);
                }

                if (JSON.stringify(currentObject.material.uniforms) !== JSON.stringify(json.uniforms)) {
                    var cmd = new SetMaterialValueCommand(editor, currentObject, 'uniforms', json.uniforms);
                    cmd.updatable = false;
                    editor.execute(cmd);
                }

                if (JSON.stringify(currentObject.material.attributes) !== JSON.stringify(json.attributes)) {
                    var cmd = new SetMaterialValueCommand(editor, currentObject, 'attributes', json.attributes);
                    cmd.updatable = false;
                    editor.execute(cmd);
                }
            }, 300);
        });

        var wrapper = codemirror.getWrapperElement();
        wrapper.addEventListener('keydown', function(event) {
            event.stopPropagation();
        });

        server = new CodeMirror.TernServer({
            caseInsensitive: true,
            plugins: { threejs: null }
        });

        codemirror.setOption('extraKeys', {
            'Ctrl-Space': function(cm) {
                server.complete(cm);
            },
            'Ctrl-I': function(cm) {
                server.showType(cm);
            },
            'Ctrl-O': function(cm) {
                server.showDocs(cm);
            },
            'Alt-.': function(cm) {
                server.jumpToDef(cm);
            },
            'Alt-,': function(cm) {
                server.jumpBack(cm);
            },
            'Ctrl-Q': function(cm) {
                server.rename(cm);
            },
            'Ctrl-.': function(cm) {
                server.selectName(cm);
            }
        });

        codemirror.on('cursorActivity', function(cm) {
            if (currentMode !== 'javascript') return;
            server.updateArgHints(cm);
        });

        codemirror.on('keypress', function(cm, kb) {
            if (currentMode !== 'javascript') return;
            if (/[\w\.]/.exec(kb.key) != null) {
                server.complete(cm);
            }
        });

        signals.editorCleared.add(function() {
            container.setDisplay('none');
        });

        signals.editScript.add(function(object, script) {
            var mode:String;
            var name:String;
            var source:String;

            if (Std.is(script, Object)) {
                mode = 'javascript';
                name = script.name;
                source = script.source;
                title.setValue(object.name + ' / ' + name);
            } else {
                switch (script) {
                    case 'vertexShader':
                        mode = 'glsl';
                        name = 'Vertex Shader';
                        source = object.material.vertexShader || '';
                        break;
                    case 'fragmentShader':
                        mode = 'glsl';
                        name = 'Fragment Shader';
                        source = object.material.fragmentShader || '';
                        break;
                    case 'programInfo':
                        mode = 'json';
                        name = 'Program Properties';
                        var json = {
                            defines: object.material.defines,
                            uniforms: object.material.uniforms,
                            attributes: object.material.attributes
                        };
                        source = JSON.stringify(json, null, '\t');
                }

                title.setValue(object.material.name + ' / ' + name);
            }

            currentMode = mode;
            currentScript = script;
            currentObject = object;

            container.setDisplay('');
            codemirror.setValue(source);
            codemirror.clearHistory();
            if (mode === 'json') mode = { name: 'javascript', json: true };
            codemirror.setOption('mode', mode);
        });

        signals.scriptRemoved.add(function(script) {
            if (currentScript === script) {
                container.setDisplay('none');
            }
        });
    }

    function createButtonSVG():Dynamic {
        var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        svg.setAttribute('width', 32);
        svg.setAttribute('height', 32);
        var path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        path.setAttribute('d', 'M 12,12 L 22,22 M 22,12 12,22');
        path.setAttribute('stroke', '#fff');
        svg.appendChild(path);
        return svg;
    }

    function validate(string:String):Bool {
        var valid:Bool;
        var errors:Array<Dynamic> = [];

        codemirror.operation(function() {
            while (errorLines.length > 0) {
                codemirror.removeLineClass(errorLines.shift(), 'background', 'errorLine');
            }

            while (widgets.length > 0) {
                codemirror.removeLineWidget(widgets.shift());
            }

            switch (currentMode) {
                case 'javascript':
                    // You would need to implement the equivalent of esprima.parse and jsonlint.parse in Haxe
                    break;
                case 'json':
                    // You would need to implement the equivalent of jsonlint.parse in Haxe
                    break;
                case 'glsl':
                    currentObject.material[currentScript] = string;
                    currentObject.material.needsUpdate = true;
                    // signals.materialChanged.dispatch(currentObject, 0); // TODO: Add multi-material support

                    var programs = renderer.info.programs;

                    valid = true;
                    var parseMessage = new EReg(/\^(?:ERROR|WARNING): \d+:(\d+): (.*)/g);

                    for (var i = 0, n = programs.length; i !== n; ++i) {
                        var diagnostics = programs[i].diagnostics;

                        if (diagnostics == null || diagnostics.material !== currentObject.material) continue;

                        if (!diagnostics.runnable) valid = false;

                        var shaderInfo = diagnostics[currentScript];
                        var lineOffset = shaderInfo.prefix.split(/\r\n|\r|\n/).length;

                        while (true) {
                            var parseResult = parseMessage.exec(shaderInfo.log);
                            if (parseResult == null) break;

                            errors.push({
                                lineNumber: parseResult[1].toInt() - lineOffset,
                                message: parseResult[2]
                            });
                        }

                        break;
                    }
            }

            for (var i = 0; i < errors.length; i++) {
                var error = errors[i];

                var message = document.createElement('div');
                message.className = 'esprima-error';
                message.textContent = error.message;

                var lineNumber = Math.max(error.lineNumber, 0);
                errorLines.push(lineNumber);

                codemirror.addLineClass(lineNumber, 'background', 'errorLine');

                var widget = codemirror.addLineWidget(lineNumber, message);

                widgets.push(widget);
            }

            return valid != null ? valid : errors.length === 0;
        });
    }
}