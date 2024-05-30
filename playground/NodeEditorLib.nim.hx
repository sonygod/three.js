import NodePrototypeEditor.NodePrototypeEditor;
import ScriptableEditor.ScriptableEditor;
import BasicMaterialEditor.BasicMaterialEditor;
import StandardMaterialEditor.StandardMaterialEditor;
import PointsMaterialEditor.PointsMaterialEditor;
import FloatEditor.FloatEditor;
import Vector2Editor.Vector2Editor;
import Vector3Editor.Vector3Editor;
import Vector4Editor.Vector4Editor;
import SliderEditor.SliderEditor;
import ColorEditor.ColorEditor;
import TextureEditor.TextureEditor;
import UVEditor.UVEditor;
import PreviewEditor.PreviewEditor;
import TimerEditor.TimerEditor;
import SplitEditor.SplitEditor;
import SwizzleEditor.SwizzleEditor;
import JoinEditor.JoinEditor;
import StringEditor.StringEditor;
import FileEditor.FileEditor;
import CustomNodeEditor.CustomNodeEditor;

class ClassLib {
	public static var BasicMaterialEditor:Class<BasicMaterialEditor> = BasicMaterialEditor;
	public static var StandardMaterialEditor:Class<StandardMaterialEditor> = StandardMaterialEditor;
	public static var PointsMaterialEditor:Class<PointsMaterialEditor> = PointsMaterialEditor;
	public static var FloatEditor:Class<FloatEditor> = FloatEditor;
	public static var Vector2Editor:Class<Vector2Editor> = Vector2Editor;
	public static var Vector3Editor:Class<Vector3Editor> = Vector3Editor;
	public static var Vector4Editor:Class<Vector4Editor> = Vector4Editor;
	public static var SliderEditor:Class<SliderEditor> = SliderEditor;
	public static var ColorEditor:Class<ColorEditor> = ColorEditor;
	public static var TextureEditor:Class<TextureEditor> = TextureEditor;
	public static var UVEditor:Class<UVEditor> = UVEditor;
	public static var TimerEditor:Class<TimerEditor> = TimerEditor;
	public static var SplitEditor:Class<SplitEditor> = SplitEditor;
	public static var SwizzleEditor:Class<SwizzleEditor> = SwizzleEditor;
	public static var JoinEditor:Class<JoinEditor> = JoinEditor;
	public static var StringEditor:Class<StringEditor> = StringEditor;
	public static var FileEditor:Class<FileEditor> = FileEditor;
	public static var ScriptableEditor:Class<ScriptableEditor> = ScriptableEditor;
	public static var PreviewEditor:Class<PreviewEditor> = PreviewEditor;
	public static var NodePrototypeEditor:Class<NodePrototypeEditor> = NodePrototypeEditor;
}

var nodeList:Dynamic;
var nodeListLoading:Bool = false;

class NodeEditor {
	public static function getNodeList():Future<Dynamic> {
		if (nodeList == null) {
			if (!nodeListLoading) {
				nodeListLoading = true;
				return Future.async(function(res) {
					var response = sys.net.HTTP.get('Nodes.json');
					nodeList = haxe.Json.parse(response.responseText);
					res(nodeList);
				});
			} else {
				return Future.async(function(res) {
					while (nodeList == null) {
						Sys.sleep(0.1);
					}
					res(nodeList);
				});
			}
		}
		return Future.of(nodeList);
	}

	public static function init():Void {
		getNodeList().handle(function(nodeList) {
			traverseNodeEditors(nodeList.nodes);
		});
	}

	public static function getNodeEditorClass(nodeData:Dynamic):Future<Dynamic> {
		var editorClass = nodeData.editorClass || nodeData.name.replace(/ /g, '');
		var nodeClass:Dynamic = nodeData.nodeClass || ClassLib[editorClass];
		if (nodeClass != null) {
			if (nodeData.editorClass != null) {
				nodeClass.prototype.icon = nodeData.icon;
			}
			return Future.of(nodeClass);
		}
		if (nodeData.editorURL != null) {
			return Future.async(function(res) {
				var moduleEditor = haxe.Resource.getModule(nodeData.editorURL);
				var moduleName = nodeData.editorClass || Reflect.fields(moduleEditor)[0];
				nodeClass = Reflect.field(moduleEditor, moduleName);
				res(nodeClass);
			});
		} else if (nodeData.shaderNode != null) {
			nodeClass = createNodeEditorClass(nodeData);
		}
		if (nodeClass != null) {
			ClassLib[editorClass] = nodeClass;
		}
		return Future.of(nodeClass);
	}

	private static function createNodeEditorClass(nodeData:Dynamic):Class<CustomNodeEditor> {
		return Type.createInstance(CustomNodeEditor, [nodeData]);
	}

	private static function traverseNodeEditors(list:Array<Dynamic>):Void {
		for (node in list) {
			getNodeEditorClass(node);
			if (Reflect.hasField(node, 'children')) {
				traverseNodeEditors(Reflect.field(node, 'children'));
			}
		}
	}
}