package three.js.playground;

import NodePrototypeEditor;
import ScriptableEditor;
import BasicMaterialEditor;
import StandardMaterialEditor;
import PointsMaterialEditor;
import FloatEditor;
import Vector2Editor;
import Vector3Editor;
import Vector4Editor;
import SliderEditor;
import ColorEditor;
import TextureEditor;
import UVEditor;
import PreviewEditor;
import TimerEditor;
import SplitEditor;
import SwizzleEditor;
import JoinEditor;
import StringEditor;
import FileEditor;
import CustomNodeEditor;

class ClassLib {
    public static var BasicMaterialEditor:Class<BasicMaterialEditor>;
    public static var StandardMaterialEditor:Class<StandardMaterialEditor>;
    public static var PointsMaterialEditor:Class<PointsMaterialEditor>;
    public static var FloatEditor:Class<FloatEditor>;
    public static var Vector2Editor:Class<Vector2Editor>;
    public static var Vector3Editor:Class<Vector3Editor>;
    public static var Vector4Editor:Class<Vector4Editor>;
    public static var SliderEditor:Class<SliderEditor>;
    public static var ColorEditor:Class<ColorEditor>;
    public static var TextureEditor:Class<TextureEditor>;
    public static var UVEditor:Class<UVEditor>;
    public static var PreviewEditor:Class<PreviewEditor>;
    public static var TimerEditor:Class<TimerEditor>;
    public static var SplitEditor:Class<SplitEditor>;
    public static var SwizzleEditor:Class<SwizzleEditor>;
    public static var JoinEditor:Class<JoinEditor>;
    public static var StringEditor:Class<StringEditor>;
    public static var FileEditor:Class<FileEditor>;
    public static var ScriptableEditor:Class<ScriptableEditor>;
    public static var PreviewEditor:Class<PreviewEditor>;
    public static var NodePrototypeEditor:Class<NodePrototypeEditor>;
}

class NodeEditorLib {
    private static var nodeList:Dynamic = null;
    private static var nodeListLoading:Bool = false;

    public static function getNodeList():Promise<Dynamic> {
        if (nodeList == null) {
            if (!nodeListLoading) {
                nodeListLoading = true;
                var request:JsPromise<Dynamic> = fetch('./Nodes.json').then(response -> response.json());
                request.then(data -> nodeList = data);
                return request;
            } else {
                return new Promiseresolved( function(resolve) {
                    var verifyNodeList:Void->Void = function() {
                        if (nodeList != null) {
                            resolve(nodeList);
                        } else {
                            window.requestAnimationFrame(verifyNodeList);
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
        getNodeList().then(nodeList -> {
            traverseNodeEditors(nodeList.nodes);
        });
        return Promise.resolve(null);
    }

    private static function traverseNodeEditors(list:Array<Dynamic>):Void {
        for (node in list) {
            getNodeEditorClass(node);
            if (node.children != null) {
                traverseNodeEditors(node.children);
            }
        }
    }

    public static function getNodeEditorClass(nodeData:Dynamic):Class<Dynamic> {
        var editorClass:String = nodeData.editorClass != null ? nodeData.editorClass : Std.string(nodeData.name).replace(' ', '');
        var nodeClass:Class<Dynamic> = nodeData.nodeClass != null ? nodeData.nodeClass : ClassLib.resolveClass(editorClass);
        if (nodeClass != null) {
            if (nodeData.editorClass != null) {
                nodeClass.prototype.icon = nodeData.icon;
            }
            return nodeClass;
        }
        if (nodeData.editorURL != null) {
            var moduleEditor:JsPromise<Dynamic> = import(nodeData.editorURL);
            moduleEditor.then(module -> {
                var moduleName:String = nodeData.editorClass != null ? nodeData.editorClass : Object.keys(module)[0];
                nodeClass = module[moduleName];
            });
        } else if (nodeData.shaderNode) {
            nodeClass = createNodeEditorClass(nodeData);
        }
        if (nodeClass != null) {
            ClassLib.resolveClass(editorClass) = nodeClass;
        }
        return nodeClass;
    }

    private static function createNodeEditorClass(nodeData:Dynamic):Class<Dynamic> {
        return class NodeEditor extends CustomNodeEditor {
            public function new() {
                super(nodeData);
            }

            public var className(get, never):String {
                return editorClass;
            }
        };
    }
}