import js.Browser;
import js.Lib;
import three.THREE;
import three.Editor;
import three.IEditor;
import three.controls.EditorControls;
import three.core.Object3D;
import three.materials.Material;
import three.commands.Command;

// Import from your own libs/ui.js
import UIElement from './libs/ui.js';
import UIPanel from './libs/ui.js';
import UIText from './libs/ui.js';

// Import from your own commands
import SetScriptValueCommand from './commands/SetScriptValueCommand.js';
import SetMaterialValueCommand from './commands/SetMaterialValueCommand.js';

class Script {
    public container:UIPanel;
    public signals:Editor.signals;

    private renderer:Dynamic;
    private delay:Int;
    private currentMode:String;
    private currentScript:Dynamic;
    private currentObject:Dynamic;
    private codemirror:Dynamic;

    public function new(editor:Editor) {
        this.signals = editor.signals;

        this.container = new UIPanel();
        this.container.setId('script');
        this.container.setPosition('absolute');
        this.container.setBackgroundColor('#272822');
        this.container.setDisplay('none');

        var header = new UIPanel();
        header.setPadding('10px');
        this.container.add(header);

        var title = new UIText().setColor('#fff');
        header.add(title);

        // Simplified buttonSVG creation
        var closeSVG = 'M 12,12 L 22,22 M 22,12 12,22';
        var close = new UIElement('<svg width="32" height="32"><path d="${closeSVG}" stroke="#fff"/></svg>');
        close.setPosition('absolute');
        close.setTop('3px');
        close.setRight('1px');
        close.setCursor('pointer');
        close.onClick(function(_) {
            this.container.setDisplay('none');
        });
        header.add(close);

        this.signals.rendererCreated.add(function(newRenderer) {
            this.renderer = newRenderer;
        });

        this.codemirror = Browser.window.CodeMirror(this.container.dom, {
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

        this.codemirror.setOption('theme', 'monokai');
        this.codemirror.on('change', function(_1, _2) { this.onCodeMirrorChange(); });

        // prevent backspace from deleting objects
        var wrapper = this.codemirror.getWrapperElement();
        wrapper.addEventListener('keydown', function(event:Dynamic) {
            event.stopPropagation();
        });

        this.setupTern();

        // Event listeners from the Editor
        this.signals.editorCleared.add(function(_) {
            this.container.setDisplay('none');
        });

        this.signals.editScript.add(function(object:Dynamic, script:Dynamic) {
            this.editScript(object, script);
        });

        this.signals.scriptRemoved.add(function(script:Dynamic) {
            if (this.currentScript == script) {
                this.container.setDisplay('none');
            }
        });
    }

    private function setupTern() {
        var server = new Browser.window.CodeMirror.TernServer({
            caseInsensitive: true,
            plugins: { threejs: null }
        });

        this.codemirror.setOption('extraKeys', {
            'Ctrl-Space': function(cm:Dynamic) { server.complete(cm); },
            'Ctrl-I': function(cm:Dynamic) { server.showType(cm); },
            'Ctrl-O': function(cm:Dynamic) { server.showDocs(cm); },
            'Alt-.': function(cm:Dynamic) { server.jumpToDef(cm); },
            'Alt-,': function(cm:Dynamic) { server.jumpBack(cm); },
            'Ctrl-Q': function(cm:Dynamic) { server.rename(cm); },
            'Ctrl-.': function(cm:Dynamic) { server.selectName(cm); }
        });

        this.codemirror.on('cursorActivity', function(cm:Dynamic) {
            if (this.currentMode != 'javascript') return;
            server.updateArgHints(cm);
        });

        this.codemirror.on('keypress', function(cm:Dynamic, kb:Dynamic) {
            if (this.currentMode != 'javascript') return;
            if (~/[\w\.]/.match(kb.key)) {
                server.complete(cm);
            }
        });
    }

    private function onCodeMirrorChange() {
        if (!this.codemirror.state.focused) return;

        Lib.clearTimeout(this.delay);
        this.delay = Lib.setTimeout(function() {
            var value = this.codemirror.getValue();
            if (!this.validate(value)) return;

            if (Std.isOfType(this.currentScript, Dynamic)) {
                if (value != Reflect.getProperty(this.currentScript, "source")) {
                    var command  = new SetScriptValueCommand(this.signals.editor.get(), this.currentObject, this.currentScript, "source", value);
                    this.signals.editor.get().execute(command);
                }
                return;
            }

            if (this.currentScript != 'programInfo') return;

            var json = JSON.parse(value);
            var material = Reflect.getProperty(this.currentObject, "material");

            if (JSON.stringify(Reflect.getProperty(material, "defines")) != JSON.stringify(json.defines)) {
                var command = new SetMaterialValueCommand(this.signals.editor.get(), this.currentObject, 'defines', json.defines);
                Reflect.setProperty(command, "updatable", false);
                this.signals.editor.get().execute(command);
            }

            if (JSON.stringify(Reflect.getProperty(material, "uniforms")) != JSON.stringify(json.uniforms)) {
                var command = new SetMaterialValueCommand(this.signals.editor.get(), this.currentObject, 'uniforms', json.uniforms);
                Reflect.setProperty(command, "updatable", false);
                this.signals.editor.get().execute(command);
            }

            if (JSON.stringify(Reflect.getProperty(material, "attributes")) != JSON.stringify(json.attributes)) {
                var command = new SetMaterialValueCommand(this.signals.editor.get(), this.currentObject, 'attributes', json.attributes);
                Reflect.setProperty(command, "updatable", false);
                this.signals.editor.get().execute(command);
            }
        }, 300);
    }

    private function validate(string:String):Bool {
        var errorLines:Array<Int> = [];
        var widgets:Array<Dynamic> = [];

        return this.codemirror.operation(function() {
            while (errorLines.length > 0) {
                this.codemirror.removeLineClass(errorLines.shift(), 'background', 'errorLine');
            }

            while (widgets.length > 0) {
                this.codemirror.removeLineWidget(widgets.shift());
            }

            var errors = [];
            switch (this.currentMode) {
                case 'javascript':
                    try {
                        var syntax = Browser.window.esprima.parse(string, { tolerant: true });
                        errors = Reflect.getProperty(syntax, "errors");
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
                case 'json':
                    errors = [];
                    Browser.window.jsonlint.parseError = function(message, info) {
                        message = message.split('\n')[3];
                        errors.push({
                            lineNumber: info.loc.first_line - 1,
                            message: message
                        });
                    };

                    try {
                        Browser.window.jsonlint.parse(string);
                    } catch (error:Dynamic) {
                        // ignore failed error recovery
                    }

                case 'glsl':
                    Reflect.setProperty(this.currentObject.material, this.currentScript, string);
                    this.currentObject.material.needsUpdate = true;
                    this.signals.materialChanged.dispatch(this.currentObject, 0); 

                    var programs = this.renderer.info.programs;
                    var valid = true;
                    var parseMessage = ~/^(?:ERROR|WARNING): \d+:(\d+): (.*)/g;

                    for (i in 0...programs.length) {
                        var diagnostics = Reflect.getProperty(programs[i], "diagnostics");

                        if (diagnostics == null || diagnostics.material != this.currentObject.material) {
                            continue;
                        }

                        if (!diagnostics.runnable) valid = false;

                        var shaderInfo = Reflect.getProperty(diagnostics, this.currentScript);
                        var lineOffset = shaderInfo.prefix.split(/[\r\n]+/).length; 

                        while (true) {
                            var parseResult = parseMessage.exec(shaderInfo.log);
                            if (parseResult == null) break;
                            errors.push({
                                lineNumber: Std.parseInt(parseResult[1]) - lineOffset,
                                message: parseResult[2]
                            });
                        }

                        break;
                    }
            }

            for (i in 0...errors.length) {
                var error = errors[i];
                var message = Browser.document.createElement("div");
                Reflect.setProperty(message, "className", "esprima-error");
                message.textContent = error.message;

                var lineNumber = Math.max(error.lineNumber, 0);
                errorLines.push(lineNumber);
                this.codemirror.addLineClass(lineNumber, 'background', 'errorLine');
                widgets.push(this.codemirror.addLineWidget(lineNumber, message));
            }

            return (valid != null) ? valid : errors.length == 0;
        });
    }

    private function editScript(object:Dynamic, script:Dynamic) {
        var mode:String;
        var name:String;
        var source:String;

        if (Std.isOfType(script, Dynamic)) { 
            mode = 'javascript';
            name = Reflect.getProperty(script, "name");
            source = Reflect.getProperty(script, "source");
            Reflect.getProperty(this.container, "title").setValue(object.name + ' / ' + name);
        } else {
            switch(script) {
                case 'vertexShader':
                    mode = 'glsl';
                    name = 'Vertex Shader';
                    source = object.material.vertexShader; 
                case 'fragmentShader':
                    mode = 'glsl';
                    name = 'Fragment Shader';
                    source = object.material.fragmentShader; 
                case 'programInfo':
                    mode = 'json';
                    name = 'Program Properties';
                    var json = {
                        defines: object.material.defines,
                        uniforms: object.material.uniforms,
                        attributes: object.material.attributes
                    };
                    source = JSON.stringify(json, null, '\t');
                default: 
                    // Handle unknown script type
                    return; 
            }
            Reflect.getProperty(this.container, "title").setValue(object.material.name + ' / ' + name);
        }

        this.currentMode = mode;
        this.currentScript = script;
        this.currentObject = object;

        this.container.setDisplay('');
        this.codemirror.setValue(source);
        this.codemirror.clearHistory();
        if (mode == 'json') mode = 'javascript'; 
        this.codemirror.setOption('mode', mode);
    }
}

export default Script;