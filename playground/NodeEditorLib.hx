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
    public static var PreviewEditor:Dynamic;
    public static var TimerEditor:Dynamic;
    public static var SplitEditor:Dynamic;
    public static var SwizzleEditor:Dynamic;
    public static var JoinEditor:Dynamic;
    public static var StringEditor:Dynamic;
    public static var FileEditor:Dynamic;
    public static var ScriptableEditor:Dynamic;
    public static var NodePrototypeEditor:Dynamic;
}

class NodeEditorLib {
    private static var nodeList:Dynamic = null;
    private static var nodeListLoading:Bool = false;

    public static function getNodeList():Promise<Dynamic> {
        if (nodeList == null) {
            if (!nodeListLoading) {
                nodeListLoading = true;
                return fetch('./Nodes.json')
                    .then(response -> response.json())
                    .then(nodeList -> {
                        nodeList = nodeList;
                        return nodeList;
                    });
            } else {
                return new Promise(res -> {
                    var verifyNodeList = function() {
                        if (nodeList != null) {
                            res(nodeList);
                        } else {
                            haxe.Timer.delay(verifyNodeList, 0);
                        }
                    };
                    verifyNodeList();
                });
            }
        } else {
            return Promise.resolve(nodeList);
        }
    }

    public static function init():Promise<Void> {
        return getNodeList().then(nodeList -> {
            traverseNodeEditors(nodeList.nodes);
        });
    }

    private static function traverseNodeEditors(list:Array<Dynamic>):Void {
        for (node in list) {
            getNodeEditorClass(node);
            if (node.children != null && node.children.length > 0) {
                traverseNodeEditors(node.children);
            }
        }
    }

    public static function getNodeEditorClass(nodeData:Dynamic):Promise<Class<Dynamic>> {
        var editorClass:String = nodeData.editorClass != null ? nodeData.editorClass : nodeData.name.replace(/ /g, '');
        var nodeClass:Class<Dynamic> = nodeData.nodeClass != null ? nodeData.nodeClass : ClassLib[editorClass];

        if (nodeClass != null) {
            if (nodeData.editorClass != null) {
                nodeClass.prototype.icon = nodeData.icon;
            }
            return Promise.resolve(nodeClass);
        }

        if (nodeData.editorURL != null) {
            return Promise.deferred().promise.then(_ -> {
                return js.Browser.import_(nodeData.editorURL);
            }).then(moduleEditor -> {
                var moduleName:String = nodeData.editorClass != null ? nodeData.editorClass : Reflect.fields(moduleEditor)[0];
                nodeClass = Reflect.field(moduleEditor, moduleName);
                return nodeClass;
            });
        } else if (nodeData.shaderNode) {
            nodeClass = createNodeEditorClass(nodeData);
            return Promise.resolve(nodeClass);
        }

        if (nodeClass != null) {
            ClassLib[editorClass] = nodeClass;
        }
        return Promise.resolve(nodeClass);
    }

    private static function createNodeEditorClass(nodeData:Dynamic):Class<Dynamic> {
        return Type.createEnum(CustomNodeEditor, {
            constructor: function() {
                super(nodeData);
            },
            get_className: function() {
                return editorClass;
            }
        });
    }
}