import js.Node;
import js.NodeEditor;
import js.NodeEditorUtils;
import js.NodeEditorElements.CodeEditorElement;
import js.Three.DataTypeLib;
import js.Three.Nodes.*;

class ScriptableEditor extends BaseNodeEditor {
    var codeNode:CodeNode;
    var scriptableNode:Scriptable;
    var editorCodeNode:CodeNode;
    var editorOutput:ScriptableValue;
    var editorOutputAdded:ScriptableValue;
    var layout:Dynamic;
    var editorElement:CodeEditorElement;
    var layoutJSON:String;
    var initCacheKey:String;
    var initId:Int;
    var waitToLayoutJSON:String;
    var _updating:Bool;
    var onValidElement:Void->Void;

    public function new(source:Dynamic = null, enableEditor:Bool = true) {
        super(defaultTitle, null, defaultWidth);

        if (source != null && Type.enumIndex(source, CodeNode) != -1) {
            codeNode = source as CodeNode;
        } else {
            codeNode = js.Code(source as String);
        }

        scriptableNode = js.Scriptable(codeNode);

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
        defaultOutput.events.addEventListener('refresh', function() {
            this.update();
        });

        this.update();
    }

    public function getColor():String {
        var color = DataTypeLib.getColorFromType(layout != null ? layout.outputType : null);
        return color != null ? color + 'BB' : null;
    }

    public function hasJSON():Bool {
        return true;
    }

    public function exportJSON():Dynamic {
        return scriptableNode.toJSON();
    }

    public function setSource(source:String):Void {
        editorCodeNode.code = source;
        this.update();
    }

    public function update(force:Bool = false):Void {
        if (_updating == true) return;

        _updating = true;

        scriptableNode.codeNode = codeNode;
        scriptableNode.needsUpdate = true;

        var layout:Dynamic;
        var scriptableValueOutput:ScriptableValue;

        try {
            var object = scriptableNode.getObject();
            layout = scriptableNode.getLayout();
            this.updateLayout(layout, force);
            scriptableValueOutput = scriptableNode.getDefaultOutput();

            var initCacheKey = typeof(object.init) == 'function' ? Std.string(object.init) : '';

            if (initCacheKey != initCacheKey) {
                initCacheKey = initCacheKey;

                var initId = ++initId;

                scriptableNode.callAsync('init').then(function() {
                    if (initId == initId) {
                        this.update();
                        if (editor != null) editor.tips.message('ScriptEditor: Initialized.');
                    }
                });
            }
        } catch (e:Dynamic) {
            trace(e);
            if (editor != null) editor.tips.error(Std.string(e));
        }

        var editorOutput = scriptableValueOutput != null ? scriptableValueOutput.value : null;

        value = editorOutput != null && Type.enumIndex(editorOutput, GpuNode) != -1 ? scriptableNode : scriptableValueOutput;
        layout = layout;
        editorOutput = editorOutput;

        updateOutputInEditor();
        updateOutputConnection();

        invalidate();

        _updating = false;
    }

    public function updateOutputConnection():Void {
        var layout = this.layout;

        if (layout != null) {
            var outputType = layout.outputType;
            DataTypeLib.setOutputAestheticsFromType(title, outputType);
        } else {
            title.setOutput(0);
        }
    }

    public function updateOutputInEditor():Void {
        var editor = this.editor;
        var editorOutput = this.editorOutput;
        var editorOutputAdded = this.editorOutputAdded;

        if (editor != null && editorOutput == editorOutputAdded) return;

        var scene = global.get('scene');
        var composer = global.get('composer');

        if (editor != null) {
            if (editorOutputAdded != null && editorOutputAdded.isObject3D) {
                editorOutputAdded.removeFromParent();
                NodeEditorUtils.disposeScene(editorOutputAdded);
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
                NodeEditorUtils.disposeScene(editorOutputAdded);
            } else if (composer != null && editorOutputAdded != null && editorOutputAdded.isPass) {
                composer.removePass(editorOutputAdded);
            }

            editorOutputAdded = null;
        }
    }

    public function setEditor(editor:NodeEditor):Void {
        super.setEditor(editor);
        updateOutputInEditor();
    }

    public function clearParameters():Void {
        layoutJSON = '';
        scriptableNode.clearParameters();

        for (element in elements.copy()) {
            if (element != editorElement && element != title) {
                remove(element);
            }
        }
    }

    public function addElementFromJSON(json:Dynamic):NodeEditorElements.UIElement {
        var id = json.id;
        var element = NodeEditorUtils.createElementFromJSON(json);
        var inputNode = json.inputNode;
        var outputType = json.outputType;

        add(element);

        scriptableNode.setParameter(id, inputNode);

        if (outputType != null) {
            element.setObjectCallback(function() {
                return scriptableNode.getOutput(id);
            });
        }

        var onUpdate = function() {
            var value = element.value;
            var paramValue = value != null && Type.enumIndex(value, ScriptableValue) != -1 ? value : js.ScriptableValue(value);
            scriptableNode.setParameter(id, paramValue);
            update();
        };

        element.addEventListener('changeInput', onUpdate);
        element.onConnect(onUpdate, true);

        return element;
    }

    public function updateLayout(layout:Dynamic = null, force:Bool = false):Void {
        var needsUpdateWidth = hasExternalEditor || editorElement == null;

        if (waitToLayoutJSON != null) {
            if (waitToLayoutJSON == Std.string(layout) || layout == null) {
                waitToLayoutJSON = null;

                if (needsUpdateWidth) setWidth(layout != null ? layout.width : defaultWidth);
            } else {
                return;
            }
        }

        if (layout != null) {
            var layoutCacheKey = Std.string(layout);

            if (layoutJSON != layoutCacheKey || force == true) {
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

    public function get hasExternalEditor():Bool {
        return title.getLinkedObject() != null;
    }

    public function get codeNode():CodeNode {
        return hasExternalEditor ? title.getLinkedObject() : editorCodeNode;
    }

    public function _initExternalConnection():Void {
        DataTypeLib.setInputAestheticsFromType(title, 'CodeNode').onValid(DataTypeLib.onValidType('CodeNode')).onConnect(function() {
            hasExternalEditor ? _toExternal() : _toInternal();
            update();
        }, true);
    }

    public function _toInternal():Void {
        if (hasInternalEditor) return;

        if (editorElement == null) {
            editorElement = CodeEditorElement(editorCodeNode.code);
            editorElement.addEventListener('change', function() {
                setSource(editorElement.source);
                editorElement.focus();
            });

            add(editorElement);
        }

        setResizable(true);

        editorElement.setVisible(true);

        hasInternalEditor = true;

        update();
    }

    public function _toExternal():Void {
        if (!hasInternalEditor) return;

        editorElement.setVisible(false);

        setResizable(false);

        hasInternalEditor = false;

        update();
    }

    public override function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.layoutJSON = layoutJSON;
    }

    public override function deserialize(data:Dynamic):Void {
        updateLayout(Json.parse(data.layoutJSON), true);
        waitToLayoutJSON = data.layoutJSON;
        super.deserialize(data);
    }
}