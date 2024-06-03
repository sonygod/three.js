package three.js.playground;

import three.js.playground.editors.NodePrototypeEditor;
import three.js.playground.editors.ScriptableEditor;
import three.js.playground.editors.BasicMaterialEditor;
import three.js.playground.editors.StandardMaterialEditor;
import three.js.playground.editors.PointsMaterialEditor;
import three.js.playground.editors.FloatEditor;
import three.js.playground.editors.Vector2Editor;
import three.js.playground.editors.Vector3Editor;
import three.js.playground.editors.Vector4Editor;
import three.js.playground.editors.SliderEditor;
import three.js.playground.editors.ColorEditor;
import three.js.playground.editors.TextureEditor;
import three.js.playground.editors.UVEditor;
import three.js.playground.editors.PreviewEditor;
import three.js.playground.editors.TimerEditor;
import three.js.playground.editors.SplitEditor;
import three.js.playground.editors.SwizzleEditor;
import three.js.playground.editors.JoinEditor;
import three.js.playground.editors.StringEditor;
import three.js.playground.editors.FileEditor;
import three.js.playground.editors.CustomNodeEditor;

import haxe.Http;
import haxe.Json;
import haxe.ds.StringMap;
import haxe.remoting.HttpAsync;

class NodeEditorLib {

    static var ClassLib: StringMap<Class<Dynamic>> = new StringMap();

    static function __static__() {
        ClassLib.set("BasicMaterialEditor", BasicMaterialEditor);
        ClassLib.set("StandardMaterialEditor", StandardMaterialEditor);
        ClassLib.set("PointsMaterialEditor", PointsMaterialEditor);
        ClassLib.set("FloatEditor", FloatEditor);
        ClassLib.set("Vector2Editor", Vector2Editor);
        ClassLib.set("Vector3Editor", Vector3Editor);
        ClassLib.set("Vector4Editor", Vector4Editor);
        ClassLib.set("SliderEditor", SliderEditor);
        ClassLib.set("ColorEditor", ColorEditor);
        ClassLib.set("TextureEditor", TextureEditor);
        ClassLib.set("UVEditor", UVEditor);
        ClassLib.set("TimerEditor", TimerEditor);
        ClassLib.set("SplitEditor", SplitEditor);
        ClassLib.set("SwizzleEditor", SwizzleEditor);
        ClassLib.set("JoinEditor", JoinEditor);
        ClassLib.set("StringEditor", StringEditor);
        ClassLib.set("FileEditor", FileEditor);
        ClassLib.set("ScriptableEditor", ScriptableEditor);
        ClassLib.set("PreviewEditor", PreviewEditor);
        ClassLib.set("NodePrototypeEditor", NodePrototypeEditor);
    }

    static var nodeList: Array<Dynamic> = null;
    static var nodeListLoading: Bool = false;

    static function getNodeList(onComplete: (Array<Dynamic>) -> Void) {
        if (nodeList == null) {
            if (!nodeListLoading) {
                nodeListLoading = true;
                var req = new HttpAsync("./Nodes.json");
                req.onData = function(data) {
                    nodeList = Json.parse(data);
                    nodeListLoading = false;
                    onComplete(nodeList);
                };
                req.onError = function(msg) {
                    trace("Error: " + msg);
                };
                req.request(false);
            } else {
                var verifyNodeList = function() {
                    if (nodeList != null) {
                        onComplete(nodeList);
                    } else {
                        callLater(verifyNodeList);
                    }
                };
                verifyNodeList();
            }
        } else {
            onComplete(nodeList);
        }
    }

    static function init(onComplete: () -> Void) {
        getNodeList(function(nodeList) {
            var traverseNodeEditors = function(list: Array<Dynamic>) {
                for (node in list) {
                    getNodeEditorClass(node, onComplete);
                    if (Std.is(node.children, Array<Dynamic>)) {
                        traverseNodeEditors(node.children);
                    }
                }
            };
            traverseNodeEditors(nodeList.nodes);
        });
    }

    static function getNodeEditorClass(nodeData: Dynamic, onComplete: (Class<Dynamic>) -> Void) {
        var editorClass: String = nodeData.editorClass != null ? nodeData.editorClass : nodeData.name.replace(/ /g, '');
        var nodeClass: Class<Dynamic> = nodeData.nodeClass != null ? nodeData.nodeClass : ClassLib.get(editorClass);

        if (nodeClass != null) {
            if (nodeData.editorClass != null) {
                nodeClass.prototype.icon = nodeData.icon;
            }
            onComplete(nodeClass);
        } else {
            if (nodeData.editorURL != null) {
                // Dynamic import is not supported in Haxe, you may need to refactor your code to include all necessary classes at compile time.
            } else if (nodeData.shaderNode != null) {
                var createNodeEditorClass = function(nodeData: Dynamic): Class<Dynamic> {
                    return type("CustomNodeEditor" + editorClass, function() {
                        this.super(nodeData);
                    }, [CustomNodeEditor]);
                };
                nodeClass = createNodeEditorClass(nodeData);
            }

            if (nodeClass != null) {
                ClassLib.set(editorClass, nodeClass);
            }
            onComplete(nodeClass);
        }
    }
}