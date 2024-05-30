import js.Browser.fetch;
import js.Promise;

class NodeEditorLib {
    static var ClassLib:Map<String, Dynamic> = {
        'BasicMaterialEditor': BasicMaterialEditor,
        'StandardMaterialEditor': StandardMaterialEditor,
        'PointsMaterialEditor': PointsMaterialEditor,
        'FloatEditor': FloatEditor,
        'Vector2Editor': Vector2Editor,
        'Vector3Editor': Vector3Editor,
        'Vector4Editor': Vector4Editor,
        'SliderEditor': SliderEditor,
        'ColorEditor': ColorEditor,
        'TextureEditor': TextureEditor,
        'UVEditor': UVEditor,
        'TimerEditor': TimerEditor,
        'SplitEditor': SplitEditor,
        'SwizzleEditor': SwizzleEditor,
        'JoinEditor': JoinEditor,
        'StringEditor': StringEditor,
        'FileEditor': FileEditor,
        'ScriptableEditor': ScriptableEditor,
        'PreviewEditor': PreviewEditor,
        'NodePrototypeEditor': NodePrototypeEditor
    };

    static var nodeList:Dynamic = null;
    static var nodeListLoading:Bool = false;

    static function getNodeList():Promise<Dynamic> {
        if (nodeList == null) {
            if (nodeListLoading == false) {
                nodeListLoading = true;
                return fetch('./Nodes.json').then(function(response) {
                    return response.json();
                }).then(function(json) {
                    nodeList = json;
                    return nodeList;
                });
            } else {
                return new Promise(function(resolve) {
                    function verifyNodeList() {
                        if (nodeList != null) {
                            resolve(nodeList);
                        } else {
                            js.Browser.window.requestAnimationFrame(verifyNodeList);
                        }
                    }
                    verifyNodeList();
                });
            }
        }
        return Promise.resolve(nodeList);
    }

    static function init():Promise<Void> {
        return getNodeList().then(function(nodeList) {
            function traverseNodeEditors(list) {
                for (node in list) {
                    getNodeEditorClass(node);
                    if (haxe.ds.List.isArray(node.children)) {
                        traverseNodeEditors(node.children);
                    }
                }
            }
            traverseNodeEditors(nodeList.nodes);
        });
    }

    static function getNodeEditorClass(nodeData:Dynamic):Promise<Dynamic> {
        var editorClass = nodeData.editorClass != null ? nodeData.editorClass : nodeData.name.replace(/ /g, '');
        var nodeClass = nodeData.nodeClass != null ? nodeData.nodeClass : ClassLib[editorClass];
        if (nodeClass != null) {
            if (nodeData.editorClass != null) {
                nodeClass.prototype.icon = nodeData.icon;
            }
            return Promise.resolve(nodeClass);
        }
        if (nodeData.editorURL != null) {
            return import(nodeData.editorURL).then(function(moduleEditor) {
                var moduleName = nodeData.editorClass != null ? nodeData.editorClass : haxe.ds.StringMap.keys(moduleEditor)[0];
                nodeClass = moduleEditor[moduleName];
                if (nodeClass != null) {
                    ClassLib[editorClass] = nodeClass;
                }
                return nodeClass;
            });
        } else if (nodeData.shaderNode != null) {
            function createNodeEditorClass(nodeData:Dynamic):Dynamic {
                return class extends CustomNodeEditor {
                    public function new() {
                        super(nodeData);
                    }
                    public function get className():String {
                        return editorClass;
                    }
                };
            }
            nodeClass = createNodeEditorClass(nodeData);
            if (nodeClass != null) {
                ClassLib[editorClass] = nodeClass;
            }
        }
        return Promise.resolve(nodeClass);
    }
}