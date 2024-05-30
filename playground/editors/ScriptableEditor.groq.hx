package three.js.playground.editors;

import BaseNodeEditor;
import elements.CodeEditorElement;
import NodeEditorUtils;
import three.nodes.Global;
import three.nodes.Scriptable;
import three.nodes.Js;
import DataTypeLib;

class ScriptableEditor extends BaseNodeEditor {
    private var scriptableNode:Scriptable;
    private var editorCodeNode:Js;
    private var editorOutput:Dynamic;
    private var editorOutputAdded:Dynamic;
    private var layout:Dynamic;
    private var editorElement:CodeEditorElement;
    private var layoutJSON:String;
    private var initCacheKey:String;
    private var initId:Int;
    private var waitToLayoutJSON:Null<String>;
    private var hasInternalEditor:Bool;
    private var _updating:Bool;

    public function new(source:Null<Js> = null, enableEditor:Bool = true) {
        super(defaultTitle, scriptableNode, defaultWidth);

        if (source != null && source.isCodeNode) {
            codeNode = source;
        } else {
            codeNode = js(source || '');
        }

        scriptableNode = scriptable(codeNode);

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

        onValidElement = function() {};

        if (enableEditor) {
            title.setSerializable(true);

            _initExternalConnection();

            _toInternal();
        }

        const defaultOutput = scriptableNode.getDefaultOutput();
        defaultOutput.events.addEventListener('refresh', function() {
            update();
        });

        update();
    }

    public function getColor():Null<String> {
        const color = getColorFromType(layout ? layout.outputType : null);
        return color != null ? color + 'BB' : null;
    }

    public function hasJSON():Bool {
        return true;
    }

    public function exportJSON():Dynamic {
        return scriptableNode.toJSON();
    }

    public function setSource(source:String):ScriptableEditor {
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
            var object:Dynamic = scriptableNode.getObject();
            layout = scriptableNode.getLayout();

            updateLayout(layout, force);

            scriptableValueOutput = scriptableNode.getDefaultOutput();

            const initCacheKey = if (object.init != null && Reflect.isFunction(object.init)) object.init.toString() else '';

            if (initCacheKey != this.initCacheKey) {
                this.initCacheKey = initCacheKey;

                const initId = ++this.initId;

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

        const editorOutput = scriptableValueOutput != null ? scriptableValueOutput.value : null;

        value = if (isGPUNode(editorOutput)) scriptableNode else scriptableValueOutput;
        this.layout = layout;
        this.editorOutput = editorOutput;

        updateOutputInEditor();
        updateOutputConnection();

        invalidate();

        _updating = false;
    }

    public function updateOutputConnection():Void {
        const layout = this.layout;

        if (layout != null) {
            const outputType = layout.outputType;

            setOutputAestheticsFromType(title, outputType);
        } else {
            title.setOutput(0);
        }
    }

    public function updateOutputInEditor():Void {
        const {editor, editorOutput, editorOutputAdded} = this;

        if (editor != null && editorOutput == editorOutputAdded) return;

        const scene:Dynamic = Global.get('scene');
        const composer:Dynamic = Global.get('composer');

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

            editorOutputAdded = editorOutput;
        } else {
            if (editorOutputAdded != null && editorOutputAdded.isObject3D) {
                editorOutputAdded.removeFromParent();
                disposeScene(editorOutputAdded);
            } else if (composer != null && editorOutputAdded != null && editorOutputAdded.isPass) {
                composer.removePass(editorOutputAdded);
            }

            editorOutputAdded = null;
        }
    }

    public function setEditor(editor:Dynamic):Void {
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

    public function addElementFromJSON(json:Dynamic):CodeEditorElement {
        const {id, element, inputNode, outputType} = createElementFromJSON(json);

        add(element);

        scriptableNode.setParameter(id, inputNode);

        if (outputType != null) {
            element.setObjectCallback(function() {
                return scriptableNode.getOutput(id);
            });
        }

        const onUpdate = function() {
            const value = element.value;
            const paramValue = value != null && value.isScriptableValueNode ? value : scriptableValue(value);

            scriptableNode.setParameter(id, paramValue);

            update();
        };

        element.addEventListener('changeInput', onUpdate);
        element.onConnect(onUpdate, true);

        //element.onConnect(() -> getScriptable().call('onDeepChange'), true);

        return element;
    }

    public function updateLayout(layout:Dynamic = null, force:Bool = false):Void {
        const needsUpdateWidth = hasExternalEditor || editorElement == null;

        if (waitToLayoutJSON != null) {
            if (waitToLayoutJSON == JSON.stringify(layout || '{}')) {
                waitToLayoutJSON = null;

                if (needsUpdateWidth) setWidth(layout.width);
            } else {
                return;
            }
        }

        if (layout != null) {
            const layoutCacheKey = JSON.stringify(layout);

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

    public function get_codeNode():Js {
        return hasExternalEditor ? title.getLinkedObject() : editorCodeNode;
    }

    private function _initExternalConnection():Void {
        setInputAestheticsFromType(title, 'CodeNode').onValid(onValidType('CodeNode')).onConnect(function() {
            if (hasExternalEditor) _toExternal() else _toInternal();

            update();
        }, true);
    }

    private function _toInternal():Void {
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

    private function _toExternal():Void {
        if (!hasInternalEditor) return;

        editorElement.setVisible(false);

        setResizable(false);

        hasInternalEditor = false;

        update(/*true*/);
    }

    override public function serialize(data:Dynamic):Void {
        super.serialize(data);

        data.layoutJSON = this.layoutJSON;
    }

    override public function deserialize(data:Dynamic):Void {
        updateLayout(JSON.parse(data.layoutJSON || '{}'), true);

        waitToLayoutJSON = data.layoutJSON;

        super.deserialize(data);
    }
}