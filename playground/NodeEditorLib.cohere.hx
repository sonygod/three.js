import NodePrototypeEditor from './editors/NodePrototypeEditor.hx';
import ScriptableEditor from './editors/ScriptableEditor.hx';
import BasicMaterialEditor from './editors/BasicMaterialEditor.hx';
import StandardMaterialEditor from './editors/StandardMaterialEditor.hx';
import PointsMaterialEditor from './editors/PointsMaterialEditor.hx';
import FloatEditor from './editors/FloatEditor.hx';
import Vector2Editor from './editors/Vector2Editor.hx';
import Vector3Editor from './editors/Vector3Editor.hx';
import Vector4Editor from './editors/Vector4Editor.hx';
import SliderEditor from './editors/SliderEditor.hx';
import ColorEditor from './editors/ColorEditor.hx';
import TextureEditor from './editors/TextureEditor.hx';
import UVEditor from './editors/UVEditor.hx';
import PreviewEditor from './editors/PreviewEditor.hx';
import TimerEditor from './editors/TimerEditor.hx';
import SplitEditor from './editors/SplitEditor.hx';
import SwizzleEditor from './editors/SwizzleEditor.hx';
import JoinEditor from './editors/JoinEditor.hx';
import StringEditor from './editors/StringEditor.hx';
import FileEditor from './editors/FileEditor.hx';
import CustomNodeEditor from './editors/CustomNodeEditor.hx';

class ClassLib {
	public static var BasicMaterialEditor:Class;
	public static var StandardMaterialEditor:Class;
	public static var PointsMaterialEditor:Class;
	public static var FloatEditor:Class;
	public static var Vector2Editor:Class;
	public static var Vector3Editor:Class;
	public static var Vector4Editor:Class;
	public static var SliderEditor:Class;
	public static var ColorEditor:Class;
	public static var TextureEditor:Class;
	public static var UVEditor:Class;
	public static var TimerEditor:Class;
	public static var SplitEditor:Class;
	public static var SwizzleEditor:Class;
	public static var JoinEditor:Class;
	public static var StringEditor:Class;
	public static var FileEditor:Class;
	public static var ScriptableEditor:Class;
	public static var PreviewEditor:Class;
	public static var NodePrototypeEditor:Class;
}

private static var nodeList:Null<Dynamic> = null;
private static var nodeListLoading:Bool = false;

public static function getNodeList():Promise<Dynamic> {
	if (nodeList == null) {
		if (!nodeListLoading) {
			nodeListLoading = true;
			return fetch('./Nodes.json').then($it -> $it.json());
		} else {
			return new Promise(res -> {
				function verifyNodeList() {
					if (nodeList != null) {
						res(nodeList);
					} else {
						window.requestAnimationFrame(verifyNodeList);
					}
				}
				verifyNodeList();
			});
		}
	} else {
		return Promise.resolve(nodeList);
	}
}

public static function init():Promise<Void> {
	return getNodeList().then(nodeList -> {
		function traverseNodeEditors(list:Array<Dynamic>) {
			for (node in list) {
				getNodeEditorClass(node);
				if (Array.isArray(node.children)) {
					traverseNodeEditors(node.children);
				}
			}
		}
		traverseNodeEditors(nodeList.nodes);
	});
}

public static function getNodeEditorClass(nodeData:Dynamic):Class {
	var editorClass = nodeData.editorClass ?? nodeData.name.split(' ').join('');
	var nodeClass = nodeData.nodeClass ?? ClassLib[$type(editorClass)];
	if (nodeClass != null) {
		if ($type(nodeData.editorClass) != null) {
			nodeClass.prototype.icon = nodeData.icon;
		}
		return nodeClass;
	}
	if ($type(nodeData.editorURL) != null) {
		var moduleEditor = js.Lib.require(nodeData.editorURL);
		var moduleName = nodeData.editorClass ?? Reflect.fields(moduleEditor).iterator().next();
		nodeClass = moduleEditor[$type(moduleName)];
	} else if ($type(nodeData.shaderNode) != null) {
		var createNodeEditorClass = $bind(null, nodeData);
		nodeClass = createNodeEditorClass();
		class $createNodeEditorClass extends CustomNodeEditor {
			public function new() {
				super(nodeData);
			}
			public function get_className():String {
				return editorClass;
			}
		}
	}
	if (nodeClass != null) {
		ClassLib[$type(editorClass)] = nodeClass;
	}
	return nodeClass;
}