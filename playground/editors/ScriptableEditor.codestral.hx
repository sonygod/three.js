import three.nodes.BaseNodeEditor;
import three.nodes.elements.CodeEditorElement;
import three.nodes.NodeEditorUtils;
import three.nodes.DataTypeLib;
import three.global;
import three.nodes.scriptable;
import three.nodes.js;
import three.nodes.scriptableValue;

class ScriptableEditor extends BaseNodeEditor {
    private var defaultTitle:String = "Scriptable";
    private var defaultWidth:Int = 500;
    private var scriptableNode:Dynamic = null;
    private var editorCodeNode:Dynamic = null;
    private var editorOutput:Dynamic = null;
    private var editorOutputAdded:Dynamic = null;
    private var layout:Dynamic = null;
    private var editorElement:CodeEditorElement = null;
    private var layoutJSON:String = "";
    private var initCacheKey:String = "";
    private var initId:Int = 0;
    private var waitToLayoutJSON:String = null;
    private var hasInternalEditor:Bool = false;
    private var _updating:Bool = false;
    private var onValidElement:Void->Void = () -> {};

    public function new(source:Dynamic = null, enableEditor:Bool = true) {
        if (source != null && source.isCodeNode) {
            editorCodeNode = source;
        } else {
            editorCodeNode = js(source != null ? source : "");
        }

        scriptableNode = scriptable(editorCodeNode);

        super(defaultTitle, scriptableNode, defaultWidth);

        if (enableEditor) {
            title.setSerializable(true);
            _initExternalConnection();
            _toInternal();
        }

        var defaultOutput = scriptableNode.getDefaultOutput();
        defaultOutput.events.addEventListener("refresh", () -> update());

        update();
    }

    public function getColor():String {
        var color = DataTypeLib.getColorFromType(layout != null ? layout.outputType : null);
        return color != null ? color + "BB" : null;
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
            var object = scriptableNode.getObject();

            layout = scriptableNode.getLayout();

            updateLayout(layout, force);

            scriptableValueOutput = scriptableNode.getDefaultOutput();

            var initCacheKey = typeof(object.init) == 'function' ? object.init.toString() : '';

            if (initCacheKey != this.initCacheKey) {
                this.initCacheKey = initCacheKey;

                var initId = ++this.initId;

                scriptableNode.callAsync("init").then(() -> {
                    if (initId == this.initId) {
                        update();

                        if (editor != null) editor.tips.message("ScriptEditor: Initialized.");
                    }
                });
            }
        } catch (e:Dynamic) {
            trace(e);

            if (editor != null) editor.tips.error(e.message);
        }

        var editorOutput = scriptableValueOutput != null ? scriptableValueOutput.value : null;

        value = NodeEditorUtils.isGPUNode(editorOutput) ? scriptableNode : scriptableValueOutput;
        this.layout = layout;
        this.editorOutput = editorOutput;

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
        if (editor != null && editorOutput == editorOutputAdded) return;

        var scene = global.get("scene");
        var composer = global.get("composer");

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

    override public function setEditor(editor:Dynamic):Void {
        super.setEditor(editor);
        updateOutputInEditor();
    }

    public function clearParameters():Void {
        layoutJSON = "";
        scriptableNode.clearParameters();

        for (element in elements) {
            if (element != editorElement && element != title) {
                remove(element);
            }
        }
    }

    public function addElementFromJSON(json:Dynamic):Dynamic {
        var {id, element, inputNode, outputType} = NodeEditorUtils.createElementFromJSON(json);

        add(element);

        scriptableNode.setParameter(id, inputNode);

        if (outputType != null) {
            element.setObjectCallback(() -> scriptableNode.getOutput(id));
        }

        var onUpdate = () -> {
            var value = element.value;
            var paramValue = value != null && value.isScriptableValueNode ? value : scriptableValue(value);

            scriptableNode.setParameter(id, paramValue);

            update();
        };

        element.addEventListener("changeInput", onUpdate);
        element.onConnect(onUpdate, true);

        return element;
    }

    public function updateLayout(layout:Dynamic = null, force:Bool = false):Void {
        var needsUpdateWidth = hasExternalEditor || editorElement == null;

        if (waitToLayoutJSON != null) {
            if (waitToLayoutJSON == (layout != null ? Std.string(layout) : "{}")) {
                waitToLayoutJSON = null;

                if (needsUpdateWidth) setWidth(layout.width);
            } else {
                return;
            }
        }

        if (layout != null) {
            var layoutCacheKey = Std.string(layout);

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

    public function get hasExternalEditor():Bool {
        return title.getLinkedObject() != null;
    }

    public function get codeNode():Dynamic {
        return hasExternalEditor ? title.getLinkedObject() : editorCodeNode;
    }

    private function _initExternalConnection():Void {
        DataTypeLib.setInputAestheticsFromType(title, "CodeNode")
            .onValid(NodeEditorUtils.onValidType("CodeNode"))
            .onConnect(() -> {
                hasExternalEditor ? _toExternal() : _toInternal();
                update();
            }, true);
    }

    private function _toInternal():Void {
        if (hasInternalEditor) return;

        if (editorElement == null) {
            editorElement = new CodeEditorElement(editorCodeNode.code);
            editorElement.addEventListener("change", () -> {
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
        data.layoutJSON = layoutJSON;
    }

    override public function deserialize(data:Dynamic):Void {
        updateLayout(data.layoutJSON != null ? Std.parse(data.layoutJSON) : null, true);
        waitToLayoutJSON = data.layoutJSON;
        super.deserialize(data);
    }
}