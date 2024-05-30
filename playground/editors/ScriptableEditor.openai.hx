package three.js.playground.editors;

import three.js.nodes.BaseNodeEditor;
import three.js.elements.CodeEditorElement;
import three.js.NodeEditorUtils;
import three.DataTypeLib;

class ScriptableEditor extends BaseNodeEditor {
    public var scriptableNode:ScriptableNode;
    public var editorCodeNode:CodeNode;
    public var editorOutput:Dynamic;
    public var editorOutputAdded:Dynamic;
    public var layout:Dynamic;
    public var editorElement:CodeEditorElement;
    public var layoutJSON:String;
    public var initCacheKey:String;
    public var initId:Int;
    public var waitToLayoutJSON:Dynamic;
    public var hasInternalEditor:Bool;

    public function new(source:Dynamic = null, enableEditor:Bool = true) {
        super(defaultTitle, scriptableNode, defaultWidth);

        if (source != null && source.isCodeNode) {
            codeNode = source;
        } else {
            codeNode = Js.createCodeNode(source || '');
        }

        scriptableNode = ScriptableNode.create(codeNode);

        this.scriptableNode = scriptableNode;
        this.editorCodeNode = codeNode;
        this.editorOutput = null;
        this.editorOutputAdded = null;

        this.layout = null;
        this.editorElement = null;

        this.layoutJSON = '';
        this.initCacheKey = '';
        this.initId = 0;
        this.waitToLayoutJSON = null;

        this.hasInternalEditor = false;

        this._updating = false;

        this.onValidElement = function() {};

        if (enableEditor) {
            this.title.setSerializable(true);

            this._initExternalConnection();

            this._toInternal();
        }

        var defaultOutput = scriptableNode.getDefaultOutput();
        defaultOutput.addEventListener('refresh', function() {
            update();
        });

        update();
    }

    override public function getColor():String {
        var color = DataTypeLib.getColorFromType(layout ? layout.outputType : null);
        return color != null ? color + 'BB' : null;
    }

    public function hasJSON():Bool {
        return true;
    }

    public function exportJSON():Dynamic {
        return scriptableNode.toJSON();
    }

    public function setSource(source:Dynamic):ScriptableEditor {
        editorCodeNode.code = source;

        update();

        return this;
    }

    public function update(force:Bool = false):Void {
        if (_updating) return;

        _updating = true;

        scriptableNode.codeNode = codeNode;
        scriptableNode.needsUpdate = true;

        var layout:Dynamic = null;
        var scriptableValueOutput:Dynamic = null;

        try {
            var object = scriptableNode.getObject();

            layout = scriptableNode.getLayout();

            updateLayout(layout, force);

            scriptableValueOutput = scriptableNode.getDefaultOutput();

            var initCacheKey = typeof object.init === 'function' ? object.init.toString() : '';

            if (initCacheKey != this.initCacheKey) {
                this.initCacheKey = initCacheKey;

                var initId = ++this.initId;

                scriptableNode.callAsync('init').then(function() {
                    if (initId == this.initId) {
                        update();

                        if (editor != null) editor.tips.message('ScriptEditor: Initialized.');
                    }
                });
            }
        } catch (e:Dynamic) {
            console.error(e);

            if (editor != null) editor.tips.error(e.message);
        }

        var editorOutput = scriptableValueOutput != null ? scriptableValueOutput.value : null;

        this.value = isGPUNode(editorOutput) ? scriptableNode : scriptableValueOutput;
        this.layout = layout;
        this.editorOutput = editorOutput;

        updateOutputInEditor();
        updateOutputConnection();

        invalidate();

        _updating = false;
    }

    public function updateOutputConnection():Void {
        var layout:Dynamic = this.layout;

        if (layout != null) {
            var outputType = layout.outputType;

            setOutputAestheticsFromType(title, outputType);
        } else {
            title.setOutput(0);
        }
    }

    public function updateOutputInEditor():Void {
        var editor = this.editor;
        var editorOutput = this.editorOutput;
        var editorOutputAdded = this.editorOutputAdded;

        if (editor != null && editorOutput === editorOutputAdded) return;

        var scene:Scene = global.get('scene');
        var composer:Composer = global.get('composer');

        if (editor != null) {
            if (editorOutputAdded != null && editorOutputAdded.isObject3D) {
                editorOutputAdded.removeFromParent();

                disposeScene(editorOutputAdded);
            } else if (composer != null && editorOutputAdded != null && editorOutputAdded.isPass) {
                composer.removePass(editorOutputAdded);
            }

            if (editorOutput != null && editorOutput.isObject3D) {
                scene.add(editorOutput);
            } else if (composer != null && editorOutput != null && editorOutput.isPass) {
                composer.addPass(editorOutput);
            }

            this.editorOutputAdded = editorOutput;
        } else {
            if (editorOutputAdded != null && editorOutputAdded.isObject3D) {
                editorOutputAdded.removeFromParent();

                disposeScene(editorOutputAdded);
            } else if (composer != null && editorOutputAdded != null && editorOutputAdded.isPass) {
                composer.removePass(editorOutputAdded);
            }

            this.editorOutputAdded = null;
        }
    }

    public function setEditor(editor:Editor):Void {
        super.setEditor(editor);

        updateOutputInEditor();
    }

    public function clearParameters():Void {
        layoutJSON = '';

        scriptableNode.clearParameters();

        for (element in elements.concat()) {
            if (element != editorElement && element != title) {
                remove(element);
            }
        }
    }

    public function addElementFromJSON(json:Dynamic):Element {
        var id:String = json.id;
        var element:Element = createElementFromJSON(json);

        add(element);

        scriptableNode.setParameter(id, element);

        if (json.outputType != null) {
            element.setObjectCallback(function() {
                return scriptableNode.getOutput(id);
            });
        }

        var onUpdate = function() {
            var value = element.value;
            var paramValue = value != null && value.isScriptableValueNode ? value : scriptableValue(value);

            scriptableNode.setParameter(id, paramValue);

            update();
        };

        element.addEventListener('changeInput', onUpdate);
        element.onConnect(onUpdate, true);

        return element;
    }

    public function updateLayout(layout:Dynamic = null, force:Bool = false):Void {
        var needsUpdateWidth:Bool = hasExternalEditor || editorElement == null;

        if (waitToLayoutJSON != null) {
            if (waitToLayoutJSON == JSON.stringify(layout || '{}')) {
                waitToLayoutJSON = null;

                if (needsUpdateWidth) setWidth(layout.width);
            } else {
                return;
            }
        }

        if (layout != null) {
            var layoutCacheKey = JSON.stringify(layout);

            if (layoutJSON != layoutCacheKey || force) {
                clearParameters();

                if (layout.name != null) {
                    setName(layout.name);
                }

                if (layout.icon != null) {
                    setIcon(layout.icon);
                }

                if (needsUpdateWidth) {
                    if (layout.width != null) {
                        setWidth(layout.width);
                    } else {
                        setWidth(defaultWidth);
                    }
                }

                if (layout.elements != null) {
                    for (element in layout.elements) {
                        addElementFromJSON(element);
                    }

                    if (editorElement != null) {
                        remove(editorElement);
                        add(editorElement);
                    }
                }

                layoutJSON = layoutCacheKey;
            }
        } else {
            setName(defaultTitle);
            setIcon(null);
            setWidth(defaultWidth);

            clearParameters();
        }

        updateOutputConnection();
    }

    public function get_hasExternalEditor():Bool {
        return title.getLinkedObject() != null;
    }

    public function get_codeNode():CodeNode {
        return hasExternalEditor ? title.getLinkedObject() : editorCodeNode;
    }

    function _initExternalConnection():Void {
        setInputAestheticsFromType(title, 'CodeNode').onValid(onValidType('CodeNode')).onConnect(function() {
            hasExternalEditor ? _toExternal() : _toInternal();

            update();
        }, true);
    }

    function _toInternal():Void {
        if (hasInternalEditor) return;

        if (editorElement == null) {
            editorElement = new CodeEditorElement(editorCodeNode.code);
            editorElement.addEventListener('change', function() {
                setSource(editorElement.source);

                editorElement.focus();
            });

            add(editorElement);
        }

        setResizable(true);

        editorElement.setVisible(true);

        hasInternalEditor = true;

        update(/*true*/);
    }

    function _toExternal():Void {
        if (!hasInternalEditor) return;

        editorElement.setVisible(false);

        setResizable(false);

        hasInternalEditor = false;

        update(/*true*/);
    }

    override public function serialize(data:Dynamic):Void {
        super.serialize(data);

        data.layoutJSON = layoutJSON;
    }

    override public function deserialize(data:Dynamic):Void {
        updateLayout(JSON.parse(data.layoutJSON || '{}'), true);

        waitToLayoutJSON = data.layoutJSON;

        super.deserialize(data);
    }
}