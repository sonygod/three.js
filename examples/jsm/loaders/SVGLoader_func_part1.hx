import three.math.Box2;
import three.math.Matrix3;
import three.math.Path;
import three.math.Shape;
import three.math.ShapePath;
import three.math.Vector2;
import three.math.Vector3;
import openfl._legacy.utils.Float32Buffer;
import openfl._legacy.utils.getNativeUrl;
import js.Browser;
import js.Js;
import js.Node;
import js.NodeList;
import js.XMLDocument;
import js.typedarrays.Float32Array;

class SVGLoader extends Loader {

	public var defaultDPI:Int;
	public var defaultUnit:String;

	public function new(manager:dynamic) {
		super(manager);
		defaultDPI = 90;
		defaultUnit = "px";
	}

	override public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		var loader = new FileLoader(manager);
		loader.setPath(path);
		loader.setRequestHeader(requestHeader);
		loader.setWithCredentials(withCredentials);
		loader.load(url, function(text) {
			try {
				onLoad(parse(text));
			} catch(e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(text:String):Dynamic {
		var xmlDoc = new XMLDocument();
		xmlDoc.loadXml(text);
		var data = parseNode(xmlDoc.documentElement, {
			fill: "#000",
			fillOpacity: 1,
			strokeOpacity: 1,
			strokeWidth: 1,
			strokeLineJoin: "miter",
			strokeLineCap: "butt",
			strokeMiterLimit: 4
		});
		return data;
	}

	private function parseNode(node:Node, style:Dynamic):Dynamic {
		if (node.nodeType != 1) return;
		var transform = getNodeTransform(node);
		var isDefsNode = false;
		var path:ShapePath = null;
		switch (node.nodeName) {
			case "svg":
				style = parseStyle(node, style);
				break;
			case "style":
				parseCSSStylesheet(node);
				break;
			case "g":
				style = parseStyle(node, style);
				break;
			case "path":
				style = parseStyle(node, style);
				if (node.hasAttribute("d")) path = parsePathNode(node);
				break;
			case "rect":
				style = parseStyle(node, style);
				path = parseRectNode(node);
				break;
			case "polygon":
				style = parseStyle(node, style);
				path = parsePolygonNode(node);
				break;
			case "polyline":
				style = parseStyle(node, style);
				path = parsePolylineNode(node);
				break;
			case "circle":
				style = parseStyle(node, style);
				path = parseCircleNode(node);
				break;
			case "ellipse":
				style = parseStyle(node, style);
				path = parseEllipseNode(node);
				break;
			case "line":
				style = parseStyle(node, style);
				path = parseLineNode(node);
				break;
			case "defs":
				isDefsNode = true;
				break;
			case "use":
				style = parseStyle(node, style);
				var href = node.getAttributeNS("http://www.w3.org/1999/xlink", "href") || "";
				var usedNodeId = href.substring(1);
				var usedNode = node.viewportElement.getElementById(usedNodeId);
				if (usedNode != null) {
					parseNode(usedNode, style);
				} else {
					console.warn("SVGLoader: 'use node' references non-existent node id: " + usedNodeId);
				}
				break;
			default:
				// console.log(node);
		}
		if (path != null) {
			if (style.fill != undefined && style.fill != "none") {
				path.color.setStyle(style.fill, COLOR_SPACE_SVG);
			}
			transformPath(path, currentTransform);
			paths.push(path);
			path.userData = { node: node, style: style };
		}
		if (!isDefsNode) {
			var childNodes = node.childNodes;
			for (var i = 0; i < childNodes.length; i++) {
				var node = childNodes[i];
				if (isDefsNode && node.nodeName != "style" && node.nodeName != "defs") {
					continue;
				}
				parseNode(node, style);
			}
		}
		if (transform) {
			transformStack.pop();
			if (transformStack.length > 0) {
				currentTransform.copy(transformStack[transformStack.length - 1]);
			} else {
				currentTransform.identity();
			}
		}
	}

	// Rest of the functions remain the same as in the JavaScript code

}