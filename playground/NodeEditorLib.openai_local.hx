import editors.NodePrototypeEditor;
import editors.ScriptableEditor;
import editors.BasicMaterialEditor;
import editors.StandardMaterialEditor;
import editors.PointsMaterialEditor;
import editors.FloatEditor;
import editors.Vector2Editor;
import editors.Vector3Editor;
import editors.Vector4Editor;
import editors.SliderEditor;
import editors.ColorEditor;
import editors.TextureEditor;
import editors.UVEditor;
import editors.PreviewEditor;
import editors.TimerEditor;
import editors.SplitEditor;
import editors.SwizzleEditor;
import editors.JoinEditor;
import editors.StringEditor;
import editors.FileEditor;
import editors.CustomNodeEditor;

class NodeEditorLib {

    public static var ClassLib:Map<String, Dynamic> = [
        "BasicMaterialEditor" => BasicMaterialEditor,
        "StandardMaterialEditor" => StandardMaterialEditor,
        "PointsMaterialEditor" => PointsMaterialEditor,
        "FloatEditor" => FloatEditor,
        "Vector2Editor" => Vector2Editor,
        "Vector3Editor" => Vector3Editor,
        "Vector4Editor" => Vector4Editor,
        "SliderEditor" => SliderEditor,
        "ColorEditor" => ColorEditor,
        "TextureEditor" => TextureEditor,
        "UVEditor" => UVEditor,
        "TimerEditor" => TimerEditor,
        "SplitEditor" => SplitEditor,
        "SwizzleEditor" => SwizzleEditor,
        "JoinEditor" => JoinEditor,
        "StringEditor" => StringEditor,
        "FileEditor" => FileEditor,
        "ScriptableEditor" => ScriptableEditor,
        "PreviewEditor" => PreviewEditor,
        "NodePrototypeEditor" => NodePrototypeEditor
    ];

    static var nodeList:Array<Dynamic> = null;
    static var nodeListLoading:Bool = false;

    public static function getNodeList():Promise<Array<Dynamic>> {
        return new Promise((resolve, reject) -> {
            if (nodeList == null) {
                if (!nodeListLoading) {
                    nodeListLoading = true;
                    js.Browser.window.fetch("./Nodes.json").then((response) -> {
                        return response.json();
                    }).then((data) -> {
                        nodeList = data;
                        resolve(nodeList);
                    }).catch(reject);
                } else {
                    var verifyNodeList = () -> {
                        if (nodeList != null) {
                            resolve(nodeList);
                        } else {
                            js.Browser.window.requestAnimationFrame(verifyNodeList);
                        }
                    };
                    verifyNodeList();
                }
            } else {
                resolve(nodeList);
            }
        });
    }

    public static function init():Void {
        getNodeList().then((nodeList) -> {
            traverseNodeEditors(nodeList.nodes);
        });
    }

    static function traverseNodeEditors(list:Array<Dynamic>):Void {
        for (node in list) {
            getNodeEditorClass(node);
            if (Reflect.isObject(node.children) && Reflect.isFunction(node.children.iterator)) {
                traverseNodeEditors(node.children);
            }
        }
    }

    public static function getNodeEditorClass(nodeData:Dynamic):Promise<Dynamic> {
        return new Promise((resolve, reject) -> {
            var editorClass = if (nodeData.editorClass != null) nodeData.editorClass else nodeData.name.replace(" ", "");
            var nodeClass = if (nodeData.nodeClass != null) nodeData.nodeClass else ClassLib.get(editorClass);

            if (nodeClass != null) {
                if (nodeData.editorClass != null) {
                    Reflect.setField(nodeClass.prototype, "icon", nodeData.icon);
                }
                resolve(nodeClass);
                return;
            }

            if (nodeData.editorURL != null) {
                js.Browser.window.importDynamic(nodeData.editorURL).then((moduleEditor) -> {
                    var moduleName = if (nodeData.editorClass != null) nodeData.editorClass else Reflect.fields(moduleEditor)[0];
                    nodeClass = Reflect.field(moduleEditor, moduleName);
                    if (nodeClass != null) {
                        ClassLib.set(editorClass, nodeClass);
                        resolve(nodeClass);
                    } else {
                        reject(null);
                    }
                }).catch(reject);
            } else if (nodeData.shaderNode != null) {
                nodeClass = createNodeEditorClass(nodeData);
                if (nodeClass != null) {
                    ClassLib.set(editorClass, nodeClass);
                    resolve(nodeClass);
                } else {
                    reject(null);
                }
            } else {
                resolve(null);
            }
        });
    }

    static function createNodeEditorClass(nodeData:Dynamic):Class<Dynamic> {
        return Type.createClass({
            constructor: function() {
                this.super(nodeData);
            },
            get className():String {
                return editorClass;
            }
        }, CustomNodeEditor);
    }
}