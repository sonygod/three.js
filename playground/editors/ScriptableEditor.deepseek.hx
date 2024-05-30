import three.BaseNodeEditor;
import three.elements.CodeEditorElement;
import three.NodeEditorUtils.*;
import three.nodes.*;
import three.DataTypeLib.*;

class ScriptableEditor extends BaseNodeEditor {

    public var scriptableNode:ScriptableNode;
    public var editorCodeNode:CodeNode;
    public var editorOutput:OutputNode;
    public var editorOutputAdded:OutputNode;
    public var layout:LayoutNode;
    public var editorElement:CodeEditorElement;
    public var layoutJSON:String;
    public var initCacheKey:String;
    public var initId:Int;
    public var waitToLayoutJSON:String;
    public var hasInternalEditor:Bool;
    public var _updating:Bool;
    public var onValidElement:Void->Void;

    public function new(source:Null<SourceNode> = null, enableEditor:Bool = true) {

        var codeNode:CodeNode = null;
        var scriptableNode:ScriptableNode = null;

        if (source != null && source.isCodeNode) {

            codeNode = source;

        } else {

            codeNode = js(source || '');

        }

        scriptableNode = scriptable(codeNode);

        super('Scriptable', scriptableNode, 500);

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

            this._initExternalConnection();

            this._toInternal();

        }

        var defaultOutput:OutputNode = this.scriptableNode.getDefaultOutput();
        defaultOutput.events.addEventListener('refresh', () -> {

            this.update();

        });

        this.update();

    }

    public function getColor():Null<String> {

        var color:Null<String> = getColorFromType(this.layout ? this.layout.outputType : null);

        return color != null ? color + 'BB' : null;

    }

    public function hasJSON():Bool {

        return true;

    }

    public function exportJSON():OutputNode {

        return this.scriptableNode.toJSON();

    }

    public function setSource(source:String):ScriptableEditor {

        this.editorCodeNode.code = source;

        this.update();

        return this;

    }

    public function update(force:Bool = false):Void {

        if (this._updating) return;

        this._updating = true;

        this.scriptableNode.codeNode = this.codeNode;
        this.scriptableNode.needsUpdate = true;

        var layout:LayoutNode = null;
        var scriptableValueOutput:OutputNode = null;

        try {

            var object:ObjectNode = this.scriptableNode.getObject();

            layout = this.scriptableNode.getLayout();

            this.updateLayout(layout, force);

            scriptableValueOutput = this.scriptableNode.getDefaultOutput();

            var initCacheKey:String = typeof object.init == 'function' ? object.init.toString() : '';

            if (initCacheKey != this.initCacheKey) {

                this.initCacheKey = initCacheKey;

                var initId:Int = ++this.initId;

                this.scriptableNode.callAsync('init').then(() -> {

                    if (initId == this.initId) {

                        this.update();

                        if (this.editor) this.editor.tips.message('ScriptEditor: Initialized.');

                    }

                });

            }

        } catch (e:Dynamic) {

            trace(e);

            if (this.editor) this.editor.tips.error(e.message);

        }

        var editorOutput:OutputNode = scriptableValueOutput ? scriptableValueOutput.value : null;

        this.value = isGPUNode(editorOutput) ? this.scriptableNode : scriptableValueOutput;
        this.layout = layout;
        this.editorOutput = editorOutput;

        this.updateOutputInEditor();
        this.updateOutputConnection();

        this.invalidate();

        this._updating = false;

    }

    public function updateOutputConnection():Void {

        var layout:LayoutNode = this.layout;

        if (layout) {

            var outputType:OutputType = layout.outputType;

            setOutputAestheticsFromType(this.title, outputType);

        } else {

            this.title.setOutput(0);

        }

    }

    public function updateOutputInEditor():Void {

        var editor:EditorNode = this.editor;
        var editorOutput:OutputNode = this.editorOutput;
        var editorOutputAdded:OutputNode = this.editorOutputAdded;

        if (editor && editorOutput == editorOutputAdded) return;

        var scene:SceneNode = global.get('scene');
        var composer:ComposerNode = global.get('composer');

        if (editor) {

            if (editorOutputAdded && editorOutputAdded.isObject3D) {

                editorOutputAdded.removeFromParent();

                disposeScene(editorOutputAdded);

            } else if (composer && editorOutputAdded && editorOutputAdded.isPass) {

                composer.removePass(editorOutputAdded);

            }

            if (editorOutput && editorOutput.isObject3D) {

                scene.add(editorOutput);

            } else if (composer && editorOutput && editorOutput.isPass) {

                composer.addPass(editorOutput);

            }

            this.editorOutputAdded = editorOutput;

        } else {

            if (editorOutputAdded && editorOutputAdded.isObject3D) {

                editorOutputAdded.removeFromParent();

                disposeScene(editorOutputAdded);

            } else if (composer && editorOutputAdded && editorOutputAdded.isPass) {

                composer.removePass(editorOutputAdded);

            }

            this.editorOutputAdded = null;

        }

    }

    public function setEditor(editor:EditorNode):Void {

        super.setEditor(editor);

        this.updateOutputInEditor();

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

    public function addElementFromJSON(json:JsonNode):ElementNode {

        var id:String = json.id;
        var element:ElementNode = json.element;
        var inputNode:InputNode = json.inputNode;
        var outputType:OutputType = json.outputType;

        this.add(element);

        this.scriptableNode.setParameter(id, inputNode);

        if (outputType) {

            element.setObjectCallback(() -> {

                return this.scriptableNode.getOutput(id);

            });

        }

        var onUpdate:Void->Void = () -> {

            var value:ValueNode = element.value;
            var paramValue:ValueNode = value && value.isScriptableValueNode ? value : scriptableValue(value);

            this.scriptableNode.setParameter(id, paramValue);

            this.update();

        };

        element.addEventListener('changeInput', onUpdate);
        element.onConnect(onUpdate, true);

        //element.onConnect(() -> this.getScriptable().call('onDeepChange'), true);

        return element;

    }

    public function updateLayout(layout:Null<LayoutNode> = null, force:Bool = false):Void {

        var needsUpdateWidth:Bool = this.hasExternalEditor || this.editorElement == null;

        if (this.waitToLayoutJSON != null) {

            if (this.waitToLayoutJSON == JSON.stringify(layout || '{}')) {

                this.waitToLayoutJSON = null;

                if (needsUpdateWidth) this.setWidth(layout.width);

            } else {

                return;

            }

        }

        if (layout) {

            var layoutCacheKey:String = JSON.stringify(layout);

            if (this.layoutJSON != layoutCacheKey || force) {

                this.clearParameters();

                if (layout.name) {

                    this.setName(layout.name);

                }

                if (layout.icon) {

                    this.setIcon(layout.icon);

                }

                if (needsUpdateWidth) {

                    if (layout.width != undefined) {

                        this.setWidth(layout.width);

                    } else {

                        this.setWidth(500);

                    }

                }

                if (layout.elements) {

                    for (element in layout.elements) {

                        this.addElementFromJSON(element);

                    }

                    if (this.editorElement) {

                        this.remove(this.editorElement);
                        this.add(this.editorElement);

                    }

                }

                this.layoutJSON = layoutCacheKey;

            }

        } else {

            this.setName('Scriptable');
            this.setIcon(null);
            this.setWidth(500);

            this.clearParameters();

        }

        this.updateOutputConnection();

    }

    public function get hasExternalEditor():Bool {

        return this.title.getLinkedObject() != null;

    }

    public function get codeNode():CodeNode {

        return this.hasExternalEditor ? this.title.getLinkedObject() : this.editorCodeNode;

    }

    public function _initExternalConnection():Void {

        setInputAestheticsFromType(this.title, 'CodeNode').onValid(onValidType('CodeNode')).onConnect(() -> {

            this.hasExternalEditor ? this._toExternal() : this._toInternal();

            this.update();

        }, true);

    }

    public function _toInternal():Void {

        if (this.hasInternalEditor) return;

        if (this.editorElement == null) {

            this.editorElement = new CodeEditorElement(this.editorCodeNode.code);
            this.editorElement.addEventListener('change', () -> {

                this.setSource(this.editorElement.source);

                this.editorElement.focus();

            });

            this.add(this.editorElement);

        }

        this.setResizable(true);

        this.editorElement.setVisible(true);

        this.hasInternalEditor = true;

        this.update();

    }

    public function _toExternal():Void {

        if (!this.hasInternalEditor) return;

        this.editorElement.setVisible(false);

        this.setResizable(false);

        this.hasInternalEditor = false;

        this.update();

    }

    public function serialize(data:DataNode):Void {

        super.serialize(data);

        data.layoutJSON = this.layoutJSON;

    }

    public function deserialize(data:DataNode):Void {

        this.updateLayout(JSON.parse(data.layoutJSON || '{}'), true);

        this.waitToLayoutJSON = data.layoutJSON;

        super.deserialize(data);

    }

}