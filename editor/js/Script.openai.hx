package three.js.editor.js;

import ui.UIElement;
import ui.UIPanel;
import ui.UIText;

import commands.SetScriptValueCommand;
import commands.SetMaterialValueCommand;

class Script {
    private var editor:Dynamic;
    private var container:UIPanel;
    private var title:UIText;
    private var close:UIElement;
    private var codemirror:CodeMirror;
    private var delay:Float;
    private var currentMode:String;
    private var currentScript:Dynamic;
    private var currentObject:Dynamic;
    private var renderer:Dynamic;

    public function new(editor:Dynamic) {
        this.editor = editor;
        var signals = editor.signals;

        container = new UIPanel();
        container.setId('script');
        container.setPosition('absolute');
        container.setBackgroundColor('#272822');
        container.setDisplay('none');

        var header = new UIPanel();
        header.setPadding('10px');
        container.add(header);

        title = new UIText();
        title.setColor('#fff');
        header.add(title);

        var buttonSVG:Xml = createButtonSVG();
        close = new UIElement(buttonSVG);
        close.setPosition('absolute');
        close.setTop('3px');
        close.setRight('1px');
        close.setCursor('pointer');
        close.onClick(function() {
            container.setDisplay('none');
        });
        header.add(close);

        signals.rendererCreated.add(function(newRenderer:Dynamic) {
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
            if (!codemirror.state.focused) return;
            clearTimeout(delay);
            delay = setTimeout(function() {
                var value = codemirror.getValue();
                if (!validate(value)) return;
                if (typeof(currentScript) == 'object') {
                    if (value != currentScript.source) {
                        editor.execute(new SetScriptValueCommand(editor, currentObject, currentScript, 'source', value));
                    }
                    return;
                }
                if (currentScript != 'programInfo') return;
                var json = Json.parse(value);
                if (Json.stringify(currentObject.material.defines) != Json.stringify(json.defines)) {
                    var cmd = new SetMaterialValueCommand(editor, currentObject, 'defines', json.defines);
                    cmd.updatable = false;
                    editor.execute(cmd);
                }
                if (Json.stringify(currentObject.material.uniforms) != Json.stringify(json.uniforms)) {
                    var cmd = new SetMaterialValueCommand(editor, currentObject, 'uniforms', json.uniforms);
                    cmd.updatable = false;
                    editor.execute(cmd);
                }
                if (Json.stringify(currentObject.material.attributes) != Json.stringify(json.attributes)) {
                    var cmd = new SetMaterialValueCommand(editor, currentObject, 'attributes', json.attributes);
                    cmd.updatable = false;
                    editor.execute(cmd);
                }
            }, 300);
        });

        // prevent backspace from deleting objects
        var wrapper = codemirror.getWrapperElement();
        wrapper.addEventListener('keydown', function(event:Dynamic) {
            event.stopPropagation();
        });

        // validate
        var errorLines:Array<Int> = [];
        var widgets:Array<Dynamic> = [];

        var validate = function(value:String):Bool {
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
                        try {
                            var syntax = esprima.parse(value, { tolerant: true });
                            errors = syntax.errors;
                        } catch (error:Dynamic) {
                            errors.push({
                                lineNumber: error.lineNumber - 1,
                                message: error.message
                            });
                        }
                        for (i in 0...errors.length) {
                            var error = errors[i];
                            error.message = error.message.replace(/Line [0-9]+: /, '');
                        }
                        break;

                    case 'json':
                        errors = [];
                        jsonlint.parseError = function(message:String, info:Dynamic) {
                            message = message.split('\n')[3];
                            errors.push({
                                lineNumber: info.loc.first_line - 1,
                                message: message
                            });
                        };
                        try {
                            jsonlint.parse(value);
                        } catch (error:Dynamic) {
                            // ignore failed error recovery
                        }
                        break;

                    case 'glsl':
                        currentObject.material[currentScript] = value;
                        currentObject.material.needsUpdate = true;
                        signals.materialChanged.dispatch(currentObject, 0); // TODO: Add multi-material support

                        var programs:Array<Dynamic> = renderer.info.programs;

                        valid = true;
                        var parseMessage:EReg = ~/^(?:ERROR|WARNING): \d+:(\d+): (.*)/g;

                        for (i in 0...programs.length) {
                            var diagnostics = programs[i].diagnostics;

                            if (diagnostics == null || diagnostics.material != currentObject.material) continue;

                            if (!diagnostics.runnable) valid = false;

                            var shaderInfo = diagnostics[currentScript];
                            var lineOffset = shaderInfo.prefix.split(/\r\n|\r|\n/).length;

                            while (true) {
                                var parseResult = parseMessage.exec(shaderInfo.log);
                                if (parseResult == null) break;

                                errors.push({
                                    lineNumber: parseResult[1] - lineOffset,
                                    message: parseResult[2]
                                });
                            } // messages

                            break;
                        } // programs
                } // mode switch

                for (i in 0...errors.length) {
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

                return valid != null ? valid : errors.length == 0;
            });
        };

        // tern js autocomplete
        var server = new CodeMirror.TernServer({
            caseInsensitive: true,
            plugins: { threejs: null }
        });

        codemirror.setOption('extraKeys', {
            'Ctrl-Space': function(cm:Dynamic) {
                server.complete(cm);
            },
            'Ctrl-I': function(cm:Dynamic) {
                server.showType(cm);
            },
            'Ctrl-O': function(cm:Dynamic) {
                server.showDocs(cm);
            },
            'Alt-.': function(cm:Dynamic) {
                server.jumpToDef(cm);
            },
            'Alt-,': function(cm:Dynamic) {
                server.jumpBack(cm);
            },
            'Ctrl-Q': function(cm:Dynamic) {
                server.rename(cm);
            },
            'Ctrl-.': function(cm:Dynamic) {
                server.selectName(cm);
            }
        });

        codemirror.on('cursorActivity', function(cm:Dynamic) {
            if (currentMode != 'javascript') return;
            server.updateArgHints(cm);
        });

        codemirror.on('keypress', function(cm:Dynamic, kb:Dynamic) {
            if (currentMode != 'javascript') return;
            if (/[\w\.]/.exec(kb.key)) {
                server.complete(cm);
            }
        });

        signals.editorCleared.add(function() {
            container.setDisplay('none');
        });

        signals.editScript.add(function(object:Dynamic, script:Dynamic) {
            var mode:String, name:String, source:String;

            if (typeof(script) == 'object') {
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

                    case 'fragmentShader':
                        mode = 'glsl';
                        name = 'Fragment Shader';
                        source = object.material.fragmentShader || '';

                    case 'programInfo':
                        mode = 'json';
                        name = 'Program Properties';
                        var json = {
                            defines: object.material.defines,
                            uniforms: object.material.uniforms,
                            attributes: object.material.attributes
                        };
                        source = Json.stringify(json, null, '\t');
                }
                title.setValue(object.material.name + ' / ' + name);
            }

            currentMode = mode;
            currentScript = script;
            currentObject = object;

            container.setDisplay('');
            codemirror.setValue(source);
            codemirror.clearHistory();
            if (mode == 'json') mode = { name: 'javascript', json: true };
            codemirror.setOption('mode', mode);
        });

        signals.scriptRemoved.add(function(script:Dynamic) {
            if (currentScript == script) {
                container.setDisplay('none');
            }
        });
    }

    private function createButtonSVG():Xml {
        var svg = Xml.createElement('svg');
        svg.setAttribute('width', '32');
        svg.setAttribute('height', '32');
        var path = Xml.createElement('path');
        path.setAttribute('d', 'M 12,12 L 22,22 M 22,12 12,22');
        path.setAttribute('stroke', '#fff');
        svg.appendChild(path);
        return svg;
    }
}