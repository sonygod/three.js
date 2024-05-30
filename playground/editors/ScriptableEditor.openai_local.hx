import three.js.playground.editors.BaseNodeEditor;
import three.js.playground.editors.elements.CodeEditorElement;
import three.js.playground.editors.NodeEditorUtils;
import three.nodes.global;
import three.nodes.scriptable;
import three.nodes.js;
import three.nodes.scriptableValue;
import three.js.playground.editors.DataTypeLib;

class ScriptableEditor extends BaseNodeEditor {

    var scriptableNode:Dynamic;
    var editorCodeNode:Dynamic;
    var editorOutput:Dynamic;
    var editorOutputAdded:Dynamic;
    var layout:Dynamic;
    var editorElement:Dynamic;
    var layoutJSON:String;
    var initCacheKey:String;
    var initId:Int;
    var waitToLayoutJSON:Dynamic;
    var hasInternalEditor:Bool;
    var _updating:Bool;
    var onValidElement:Void -> Void;

    public function new(source:Dynamic = null, enableEditor:Bool = true) {
        var codeNode = source != null && source.isCodeNode ? source : js(source != null ? source : '');
        scriptableNode = scriptable(codeNode);

        super(defaultTitle, scriptableNode, defaultWidth);

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
        this.onValidElement = () -> {};

        if (enableEditor) {
            this.title.setSerializable(true);
            _initExternalConnection();
            _toInternal();
        }

        var defaultOutput = this.scriptableNode.getDefaultOutput();
        defaultOutput.events.addEventListener('refresh', () -> update());

        update();
    }

    public function getColor():String {
        var color = getColorFromType(this.layout != null ? this.layout.outputType : null);
        return color != null ? color + 'BB' : null;
    }

    public function hasJSON():Bool {
        return true;
    }

    public function exportJSON():Dynamic {
        return this.scriptableNode.toJSON();
    }

    public function setSource(source:String):ScriptableEditor {
        this.editorCodeNode.code = source;
        update();
        return this;
    }

    public function update(force:Bool = false):Void {
        if (this._updating) return;

        this._updating = true;

        this.scriptableNode.codeNode = this.codeNode;
        this.scriptableNode.needsUpdate = true;

        var layout = null;
        var scriptableValueOutput = null;

        try {
            var object = this.scriptableNode.getObject();
            layout = this.scriptableNode.getLayout();
            updateLayout(layout, force);
            scriptableValueOutput = this.scriptableNode.getDefaultOutput();

            var initCacheKey = Reflect.hasField(object, 'init') ? object.init.toString() : '';

            if (initCacheKey != this.initCacheKey) {
                this.initCacheKey = initCacheKey;
                var initId = ++this.initId;

                this.scriptableNode.callAsync('init').then(() -> {
                    if (initId == this.initId) {
                        update();
                        if (this.editor != null) this.editor.tips.message('ScriptEditor: Initialized.');
                    }
                });
            }

        } catch (e:Dynamic) {
            trace(e);
            if (this.editor != null) this.editor.tips.error(e.message);
        }

        var editorOutput = scriptableValueOutput != null ? scriptableValueOutput.value : null;

        this.value = isGPUNode(editorOutput) ? this.scriptableNode : scriptableValueOutput;
        this.layout = layout;
        this.editorOutput = editorOutput;

        updateOutputInEditor();
        updateOutputConnection();

        invalidate();

        this._updating = false;
    }

    public function updateOutputConnection():Void {
        var layout = this.layout;

        if (layout != null) {
            var outputType = layout.outputType;
            setOutputAestheticsFromType(this.title, outputType);
        } else {
            this.title.setOutput(0);
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
            if (editorOutputAdded != null && Reflect.hasField(editorOutputAdded, 'isObject3D')) {
                editorOutputAdded.removeFromParent();
                disposeScene(editorOutputAdded);
            } else if (composer != null && editorOutputAdded != null && Reflect.hasField(editorOutputAdded, 'isPass')) {
                composer.removePass(editorOutputAdded);
            }

            if (editorOutput != null && Reflect.hasField(editorOutput, 'isObject3D')) {
                scene.add(editorOutput);
            } else if (composer != null && editorOutput != null && Reflect.hasField(editorOutput, 'isPass')) {
                composer.addPass(editorOutput);
            }

            this.editorOutputAdded = editorOutput;
        } else {
            if (editorOutputAdded != null && Reflect.hasField(editorOutputAdded, 'isObject3D')) {
                editorOutputAdded.removeFromParent();
                disposeScene(editorOutputAdded);
            } else if (composer != null && editorOutputAdded != null && Reflect.hasField(editorOutputAdded, 'isPass')) {
                composer.removePass(editorOutputAdded);
            }

            this.editorOutputAdded = null;
        }
    }

    public function setEditor(editor:Dynamic):Void {
        super.setEditor(editor);
        updateOutputInEditor();
    }

    public function clearParameters():Void {
        this.layoutJSON = '';
        this.scriptableNode.clearParameters();

        for (element in this.elements.concat()) {
            if (element != this.editorElement && element != this.title) {
                this.remove(element);
            }
        }
    }

    public function addElementFromJSON(json:Dynamic):Dynamic {
        var createdElement = createElementFromJSON(json);
        var id = createdElement.id;
        var element = createdElement.element;
        var inputNode = createdElement.inputNode;
        var outputType = createdElement.outputType;

        this.add(element);

        this.scriptableNode.setParameter(id, inputNode);

        if (outputType != null) {
            element.setObjectCallback(() -> this.scriptableNode.getOutput(id));
        }

        var onUpdate = () -> {
            var value = element.value;
            var paramValue = value != null && Reflect.hasField(value, 'isScriptableValueNode') ? value : scriptableValue(value);

            this.scriptableNode.setParameter(id, paramValue);
            update();
        };

        element.addEventListener('changeInput', onUpdate);
        element.onConnect(onUpdate, true);

        return element;
    }

    public function updateLayout(layout:Dynamic = null, force:Bool = false):Void {
        var needsUpdateWidth = this.hasExternalEditor || this.editorElement == null;

        if (this.waitToLayoutJSON != null) {
            if (this.waitToLayoutJSON == Json.stringify(layout != null ? layout : {})) {
                this.waitToLayoutJSON = null;
                if (needsUpdateWidth) this.setWidth(layout.width);
            } else {
                return;
            }
        }

        if (layout != null) {
            var layoutCacheKey = Json.stringify(layout);

            if (this.layoutJSON != layoutCacheKey || force) {
                clearParameters();

                if (layout.name != null) {
                    this.setName(layout.name);
                }

                if (layout.icon != null) {
                    this.setIcon(layout.icon);
                }

                if (needsUpdateWidth) {
                    if (layout.width != null) {
                        this.setWidth(layout.width);
                    } else {
                        this.setWidth(defaultWidth);
                    }
                }

                if (layout.elements != null) {
                    for (element in layout.elements) {
                        addElementFromJSON(element);
                    }

                    if (this.editorElement != null) {
                        this.remove(this.editorElement);
                        this.add(this.editorElement);
                    }
                }

                this.layoutJSON = layoutCacheKey;
            }
        } else {
            this.setName(defaultTitle);
            this.setIcon(null);
            this.setWidth(defaultWidth);
            clearParameters();
        }

        updateOutputConnection();
    }

    public function get hasExternalEditor():Bool {
        return this.title.getLinkedObject() != null;
    }

    public function get codeNode():Dynamic {
        return this.hasExternalEditor ? this.title.getLinkedObject() : this.editorCodeNode;
    }

    function _initExternalConnection():Void {
        setInputAestheticsFromType(this.title, 'CodeNode').onValid(onValidType('CodeNode')).onConnect(() -> {
            this.hasExternalEditor ? _toExternal() : _toInternal();
            update();
        }, true);
    }

    function _toInternal():Void {
        if (this.hasInternalEditor) return;

        if (this.editorElement == null) {
            this.editorElement = new CodeEditorElement(this.editorCodeNode.code);
            this.editorElement.addEventListener('change', () -> {
                setSource(this.editorElement.source);
                this.editorElement.focus();
            });

            this.add(this.editorElement);
        }

        this.setResizable(true);
        this.editorElement.setVisible(true);
        this.hasInternalEditor = true;
        update();
    }

    function _toExternal():Void {
        if (!this.hasInternalEditor) return;

        this.editorElement.setVisible(false);
        this.setResizable(false);
        this.hasInternalEditor = false;
        update();
    }

    override public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.layoutJSON = this.layoutJSON;
    }

    override public function deserialize(data:Dynamic):Void {
        updateLayout(Json.parse(data.layoutJSON != null ? data.layoutJSON : '{}'), true);
        this.waitToLayoutJSON = data.layoutJSON;
        super.deserialize(data);
    }

}