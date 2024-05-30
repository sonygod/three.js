package three.js.playground;

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

class ClassLib {
    public static var BasicMaterialEditor:Dynamic;
    public static var StandardMaterialEditor:Dynamic;
    public static var PointsMaterialEditor:Dynamic;
    public static var FloatEditor:Dynamic;
    public static var Vector2Editor:Dynamic;
    public static var Vector3Editor:Dynamic;
    public static var Vector4Editor:Dynamic;
    public static var SliderEditor:Dynamic;
    public static var ColorEditor:Dynamic;
    public static var TextureEditor:Dynamic;
    public static var UVEditor:Dynamic;
    public static var TimerEditor:Dynamic;
    public static var SplitEditor:Dynamic;
    public static var SwizzleEditor:Dynamic;
    public static var JoinEditor:Dynamic;
    public static var StringEditor:Dynamic;
    public static var FileEditor:Dynamic;
    public static var ScriptableEditor:Dynamic;
    public static var PreviewEditor:Dynamic;
    public static var NodePrototypeEditor:Dynamic;
}

class NodeEditorLib {
    private static var nodeList:Dynamic = null;
    private static var nodeListLoading:Bool = false;

    public static function getNodeList():Promise<Dynamic> {
        if (nodeList == null) {
            if (!nodeListLoading) {
                nodeListLoading = true;
                var promise:Promise<Dynamic> = Http.request('Nodes.json');
                promise.then(function(response:Dynamic) {
                    nodeList = response.json();
                });
            } else {
                var promise:Promise<Dynamic> = new Promise(function(resolve:Dynamic) {
                    var verifyNodeList:Void->Void = function() {
                        if (nodeList != null) {
                            resolve(nodeList);
                        } else {
                            haxe.Timer.delay(verifyNodeList, 16);
                        }
                    };
                    verifyNodeList();
                });
            }
            return promise;
        } else {
            var promise:Promise<Dynamic> = new Promise(function(resolve:Dynamic) {
                resolve(nodeList);
            });
            return promise;
        }
    }

    public static function init():Promise<Dynamic> {
        var promise:Promise<Dynamic> = getNodeList();
        promise.then(function(nodeList:Dynamic) {
            traverseNodeEditors(nodeList.nodes);
        });
        return promise;
    }

    public static function traverseNodeEditors(list:Dynamic):Void {
        for (node in list) {
            getNodeEditorClass(node);
            if (Lambda.exists(node.children)) {
                traverseNodeEditors(node.children);
            }
        }
    }

    public static function getNodeEditorClass(nodeData:Dynamic):Class<Dynamic> {
        var editorClass:String = nodeData.editorClass != null ? nodeData.editorClass : nodeData.name.replace(' ', '');
        var nodeClass:Class<Dynamic> = ClassLib.get(editorClass);
        if (nodeClass == null) {
            if (nodeData.editorURL != null) {
                var moduleEditor:Dynamic = Loader.loadModule(nodeData.editorURL);
                var moduleName:String = nodeData.editorClass != null ? nodeData.editorClass : Reflect.fields(moduleEditor)[0];
                nodeClass = Reflect.field(moduleEditor, moduleName);
            } else if (nodeData.shaderNode) {
                nodeClass = Type.createInstance(CustomNodeEditor, [nodeData]);
            }
            if (nodeClass != null) {
                ClassLib.set(editorClass, nodeClass);
            }
        }
        return nodeClass;
    }
}