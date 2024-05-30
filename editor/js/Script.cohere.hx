import js.npm.codemirror.CodeMirror;
import js.npm.codemirror.Editor;
import js.npm.codemirror.EditorConfiguration;
import js.npm.codemirror.EditorFromTextArea;
import js.npm.codemirror.HintOptions;
import js.npm.codemirror.LineHandle;
import js.npm.codemirror.LineWidget;
import js.npm.codemirror.ModeInfo;
import js.npm.codemirror.TextMarker;
import js.npm.codemirror.addon.Edit.MatchBrackets;
import js.npm.codemirror.addon.Edit.MatchBracketsOptions;
import js.npm.codemirror.addon.Edit.ShowMatchBrackets;
import js.npm.codemirror.addon.Hint.AnyHint;
import js.npm.codemirror.addon.Hint.AnyHintOptions;
import js.npm.codemirror.addon.Hint.ShowHint;
import js.npm.codemirror.types.EditorChange;

import js.npm.jsonlint.ParseError;
import js.npm.jsonlint.parse;
import js.npm.jsonlint.parseError;

import js.npm.esprima.Error as EsprimaError;
import js.npm.esprima.parse;

class Script {
    public var container:UIPanel;
    public var codemirror:Editor;
    public var wrapper:HTMLElement;
    public var server:CodeMirror.TernServer;
    public var currentMode:String;
    public var currentScript:Dynamic;
    public var currentObject:Dynamic;
    public var errorLines:Array<Int>;
    public var widgets:Array<LineWidget>;
    public var renderer:Dynamic;
    public var delay:Dynamic;

    public function new(editor:Editor) {
        var signals = editor.signals;

        container = UIPanel_obj();
        container.setId('script');
        container.setPosition('absolute');
        container.setBackgroundColor('#272822');
        container.setDisplay('none');

        var header = UIPanel_obj();
        header.setPadding('10px');
        container.add(header);

        var title = UIText_obj();
        title.setColor('#fff');
        header.add(title);

        var buttonSVG = createButtonSVG();

        var close = UIElement_obj(buttonSVG);
        close.setPosition('absolute');
        close.setTop('3px');
        close.setRight('1px');
        close.setCursor('pointer');
        close.onClick(function() {
            container.setDisplay('none');
        });
        header.add(close);

        renderer = null;
        signals.rendererCreated.add(function(newRenderer) {
            renderer = newRenderer;
        });

        delay = null;
        currentMode = null;
        currentScript = null;
        currentObject = null;

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
        } as EditorConfiguration);
        codemirror.setOption('theme', 'monokai');
        codemirror.on('change', onChange);

        wrapper = codemirror.getWrapperElement();
        wrapper.addEventListener('keydown', function(event) {
            event.stopPropagation();
        });

        errorLines = [];
        widgets = [];

        signals.editorCleared.add(onEditorCleared);
        signals.editScript.add(onEditScript);
        signals.scriptRemoved.add(onScriptRemoved);
    }

    function createButtonSVG():HTMLElement {
        var svg = cast HTMLElement(dom.createElementNS('http://www.w3.org/2000/svg', 'svg'));
        svg.setAttribute('width', 32);
        svg.setAttribute('height', 32);
        var path = cast HTMLElement(dom.createElementNS('http://www.w3.org/2Multiplier000/svg', 'path'));
        path.setAttribute('d', 'M 12,12 L 22,22 M 22,12 12,22');
        path.setAttribute('stroke', '#fff');
        svg.appendChild(path);
        return svg;
    }

    function onChange(codemirror:Editor, change:EditorChange) {
        if (!codemirror.state.focused) return;

        clearTimeout(delay);
        delay = js.Lib.setTimeout(function() {
            var value = codemirror.getValue();

            if (!validate(value)) return;

            if (js.Boot.getClass(currentScript) != null) {
                if (value != currentScript.source) {
                    editor.execute(SetScriptValueCommand(editor, currentObject, currentScript, 'source', value));
                }
            } else if (currentScript != 'programInfo') {
                var json = js.Json.parse(value);

                if (js.Json.stringify(currentObject.material.defines) != js.Json.stringify(json.defines)) {
                    var cmd = SetMaterialValueCommand(editor, currentObject, 'defines', json.defines);
                    cmd.updatable = false;
                    editor.execute(cmd);
                }

                if (js.Json.stringify(currentObject.material.uniforms) != js.Json.stringify(json.uniforms)) {
                    var cmd = SetMaterialValueCommand(editor, currentObject, 'uniforms', json.uniforms);
                    cmd.updatable = false;
                    editor.execute(cmd);
                }

                if (js.Json.stringify(currentObject.material.attributes) != js.Json.stringify(json.attributes)) {
                    var cmd = SetMaterialValueCommand(editor, currentObject, 'attributes', json.attributes);
                    cmd.updatable = false;
                    editor.execute(cmd);
                }
            }
        }, 300);
    }

    function validate(string:String):Bool {
        var valid:Bool;
        var errors:Array<Dynamic>;

        return codemirror.operation(function() {
            while (errorLines.length > 0) {
                codemirror.removeLineClass(errorLines.shift(), 'background', 'errorLine');
            }

            while (widgets.length > 0) {
                codemirror.removeLineWidget(widgets.shift());
            }

            switch (currentMode) {
                case 'javascript':
                    try {
                        var syntax = parse(string, { tolerant: true });
                        errors = syntax.errors;
                    } catch (error) {
                        errors = [cast Dynamic(error)];
                    }

                    for (error in errors) {
                        error.lineNumber--;
                        error.message = error.message.replace(/Line [0-9]+: /, '');
                    }

                    break;

                case 'json':
                    errors = [];
                    parseError = function(message:String, info:Dynamic) {
                        message = message.split('\n')[3];
                        errors.push({
                            lineNumber: info.loc.first_line - 1,
                            message: message
                        });
                    };

                    try {
                        parse(string);
                    } catch (_) {
                        // ignore failed error recovery
                    }

                    break;

                case 'glsl':
                    currentObject.material[$currentScript] = string;
                    currentObject.material.needsUpdate = true;
                    signals.materialChanged.dispatch(currentObject, 0); // TODO: Add multi-material support

                    var programs = renderer.info.programs;
                    valid = true;
                    var parseMessage = /^(?:ERROR|WARNING): \d+:(\d+): (.*)/g;

                    for (program in programs) {
                        var diagnostics = programs[program].diagnostics;

                        if (diagnostics == null || diagnostics.material != currentObject.material) continue;

                        if (!diagnostics.runnable) valid = false;

                        var shaderInfo = diagnostics[$currentScript];
                        var lineOffset = shaderInfo.prefix.split(/\r\n|\r|\n/).length;

                        while (true) {
                            var parseResult = parseMessage.exec(shaderInfo.log);
                            if (parseResult == null) break;

                            errors.push({
                                lineNumber: Std.parseInt(parseResult[1]) - lineOffset,
                                message: parseResult[2]
                            });
                        } // messages

                        break;
                    } // programs

            } // mode switch

            for (error in errors) {
                var error = errors[error];

                var message = dom.createElement('div');
                message.className = 'esprima-error';
                message.textContent = error.message;

                var lineNumber = error.lineNumber;
                if (lineNumber < 0) lineNumber = 0;
                errorLines.push(lineNumber);

                codemirror.addLineClass(lineNumber, 'background', 'errorLine');

                var widget = codemirror.addLineWidget(lineNumber, message);

                widgets.push(widget);
            }

            return valid != null ? valid : errors.length == 0;
        });
    }

    // tern js autocomplete

    server = CodeMirror.TernServer({
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
        if (currentMode != 'javascript') return;
        server.updateArgHints(cm);
    });

    codemirror.on('keypress', function(cm, kb) {
        if (currentMode != 'javascript') return;
        if (Std.is(kb.key, String) && kb.key.match(/[\w\.]/)) {
            server.complete(cm);
        }
    });

    function onEditorCleared() {
        container.setDisplay('none');
    }

    function onEditScript(object:Dynamic, script:Dynamic) {
        var mode:Dynamic;
        var name:String;
        var source:String;

        if (js.Boot.getClass(script) != null) {
            mode = 'javascript';
            name = script.name;
            source = script.source;
            title.setValue(object.name + ' / ' + name);
        } else {
            switch (script) {
                case 'vertexShader':
                    mode = 'glsl';
                    name = 'Vertex Shader';
                    source = object.material.vertexShader;

                    break;

                case 'fragmentShader':
                    mode = 'glsl';
                    name = 'Fragment Shader';
                    source = object.material.fragmentShader;

                    break;

                case 'programInfo':
                    mode = 'json';
                    name = 'Program Properties';
                    var json = {
                        defines: object.material.defines,
                        uniforms: object.material.uniforms,
                        attributes: object.material.attributes
                    };
                    source = js.Json.stringify(json, null, '\t');
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
    }

    function onScriptRemoved(script:Dynamic) {
        if (currentScript == script) {
            container.setDisplay('none');
        }
    }
}

class_obj(Script);