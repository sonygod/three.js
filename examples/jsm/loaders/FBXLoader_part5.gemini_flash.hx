import haxe.Json;
import haxe.ds.StringMap;

class TextParser {
	public var allNodes:StringMap<Dynamic>;
	public var nodeStack:Array<Dynamic>;
	public var currentIndent:Int;
	public var currentProp:Dynamic;
	public var currentPropName:String;

	public function new() {
		
	}

	public function getPrevNode():Dynamic {
		return this.nodeStack[this.currentIndent - 2];
	}

	public function getCurrentNode():Dynamic {
		return this.nodeStack[this.currentIndent - 1];
	}

	public function getCurrentProp():Dynamic {
		return this.currentProp;
	}

	public function pushStack(node:Dynamic):Void {
		this.nodeStack.push(node);
		this.currentIndent++;
	}

	public function popStack():Void {
		this.nodeStack.pop();
		this.currentIndent--;
	}

	public function setCurrentProp(val:Dynamic, name:String):Void {
		this.currentProp = val;
		this.currentPropName = name;
	}

	public function parse(text:String):StringMap<Dynamic> {
		this.currentIndent = 0;

		this.allNodes = new StringMap<Dynamic>();
		this.nodeStack = [];
		this.currentProp = null;
		this.currentPropName = "";

		var scope = this;

		var split = text.split(/\r\n|\n|\r/);

		for (i in 0...split.length) {
			var line = split[i];
			if (line.match(/^\s*;/) || line.match(/^\s*$/)) {
				continue;
			}

			var matchBeginning = line.match(new EReg('^\\t{' + this.currentIndent + '}(\\w+):(.*){', ''));
			var matchProperty = line.match(new EReg('^\\t{' + this.currentIndent + '}(\\w+):[\\s\\t\\r\\n](.*)', ''));
			var matchEnd = line.match(new EReg('^\\t{' + (this.currentIndent - 1) + '}}', ''));

			if (matchBeginning != null) {
				this.parseNodeBegin(line, matchBeginning);
			} else if (matchProperty != null) {
				this.parseNodeProperty(line, matchProperty, split[i + 1]);
				i++; // Skip next line
			} else if (matchEnd != null) {
				this.popStack();
			} else if (line.match(/^[^\s\t]/)) {
				this.parseNodePropertyContinued(line);
			}
		}

		return this.allNodes;
	}

	function parseNodeBegin(line:String, property:ERegExec):Void {
		var nodeName:String = property.matched(1).trim().replace(/^"|"$/g, "");

		var nodeAttrs:Array<String> = property.matched(2).split(",").map(function(attr) {
			return attr.trim().replace(/^"|"$/g, "");
		});

		var node:Dynamic = {name: nodeName};
		var attrs:Dynamic = this.parseNodeAttr(nodeAttrs);

		var currentNode:Dynamic = this.getCurrentNode();

		if (this.currentIndent == 0) {
			this.allNodes.set(nodeName, node);
		} else {
			if (Reflect.hasField(currentNode, nodeName)) {
				if (nodeName == "PoseNode") {
					Reflect.field(currentNode, nodeName).push(node);
				} else if (Reflect.hasField(currentNode[nodeName], "id")) {
					currentNode[nodeName] = {};
					currentNode[nodeName][Std.string(currentNode[nodeName].id)] = currentNode[nodeName];
				}

				if (attrs.id != "")
					currentNode[nodeName][Std.string(attrs.id)] = node;
			} else if (Std.isOfType(attrs.id, Int)) {
				currentNode[nodeName] = {};
				currentNode[nodeName][Std.string(attrs.id)] = node;
			} else if (nodeName != "Properties70") {
				if (nodeName == "PoseNode")
					currentNode[nodeName] = [node];
				else
					currentNode[nodeName] = node;
			}
		}

		if (Std.isOfType(attrs.id, Int))
			node.id = attrs.id;
		if (attrs.name != "")
			node.attrName = attrs.name;
		if (attrs.type != "")
			node.attrType = attrs.type;

		this.pushStack(node);
	}

	function parseNodeAttr(attrs:Array<String>):Dynamic {
		var id:Dynamic = attrs[0];

		if (attrs[0] != "") {
			id = Std.parseInt(attrs[0]);
			if (Math.isNaN(id)) {
				id = attrs[0];
			}
		}

		var name = "";
		var type = "";

		if (attrs.length > 1) {
			name = attrs[1].replace(/^(\w+)::/, "");
			type = attrs[2];
		}

		return {id: id, name: name, type: type};
	}

	function parseNodeProperty(line:String, property:ERegExec, contentLine:String):Void {
		var propName:String = property.matched(1).trim().replace(/^"|"$/g, "");
		var propValue:String = property.matched(2).trim().replace(/^"|"$/g, "");

		if (propName == "Content" && propValue == ",") {
			propValue = contentLine.replace(/"/g, "").replace(/,$/, "").trim();
		}

		var currentNode:Dynamic = this.getCurrentNode();
		var parentName:String = currentNode.name;

		if (parentName == "Properties70") {
			this.parseNodeSpecialProperty(line, propName, propValue);
			return;
		}

		if (propName == "C") {
			var connProps:Array<String> = propValue.split(",").slice(1);
			var from:Int = Std.parseInt(connProps[0]);
			var to:Int = Std.parseInt(connProps[1]);

			var rest:Array<String> = propValue.split(",").slice(3);

			rest = rest.map(function(elem:String) {
				return elem.trim().replace(/^"/, "");
			});

			propName = "connections";
			propValue = [from, to];
			propValue = propValue.concat(rest);

			if (!Reflect.hasField(currentNode, propName)) {
				currentNode[propName] = [];
			}
		}

		if (propName == "Node")
			currentNode.id = propValue;

		if (Reflect.hasField(currentNode, propName) && Std.isOfType(currentNode[propName], Array)) {
			Reflect.field(currentNode, propName).push(propValue);
		} else {
			if (propName != "a")
				currentNode[propName] = propValue;
			else
				currentNode.a = propValue;
		}

		this.setCurrentProp(currentNode, propName);

		if (propName == "a" && propValue.lastIndexOf(",") != propValue.length - 1) {
			currentNode.a = parseNumberArray(propValue);
		}
	}

	function parseNodePropertyContinued(line:String):Void {
		var currentNode:Dynamic = this.getCurrentNode();

		currentNode.a += line;

		if (line.lastIndexOf(",") != line.length - 1) {
			currentNode.a = parseNumberArray(currentNode.a);
		}
	}

	function parseNodeSpecialProperty(line:String, propName:String, propValue:String):Void {
		var props:Array<String> = propValue.split(",").map(function(prop:String) {
			return prop.trim().replace(/^\"/, "").replace(/\s/g, "_");
		});

		var innerPropName:String = props[0];
		var innerPropType1:String = props[1];
		var innerPropType2:String = props[2];
		var innerPropFlag:String = props[3];
		var innerPropValue:Dynamic = props[4];

		switch (innerPropType1) {
			case "int":
			case "enum":
			case "bool":
			case "ULongLong":
			case "double":
			case "Number":
			case "FieldOfView":
				innerPropValue = Std.parseFloat(innerPropValue);
			case "Color":
			case "ColorRGB":
			case "Vector3D":
			case "Lcl_Translation":
			case "Lcl_Rotation":
			case "Lcl_Scaling":
				innerPropValue = parseNumberArray(innerPropValue);
			default:
		}

		this.getPrevNode()[innerPropName] = {
			type: innerPropType1,
			type2: innerPropType2,
			flag: innerPropFlag,
			value: innerPropValue
		};

		this.setCurrentProp(this.getPrevNode(), innerPropName);
	}
}

function parseNumberArray(value:String):Array<Float> {
	return value.split(",").map(function(val:String) {
		return Std.parseFloat(val.trim());
	});
}