class TextParser {
	var currentIndent:Int;
	var allNodes:FBXTree;
	var nodeStack:Array<Dynamic>;
	var currentProp:Array<Dynamic>;
	var currentPropName:String;

	public function parse(text:String):FBXTree {
		currentIndent = 0;
		allNodes = new FBXTree();
		nodeStack = [];
		currentProp = [];
		currentPropName = "";

		var split = text.split(["\r\n", "\r", "\n"], "");

		for (i in 0...split.length) {
			var line = split[i];
			var matchComment = line.match(/^[\s\t]*;/);
			var matchEmpty = line.match(/^[\s\t]*$/);

			if (matchComment != null || matchEmpty != null) continue;

			var matchBeginning = line.match("^\\t{" + currentIndent + "}(\\w+):(.*)\\{");
			var matchProperty = line.match("^\\t{" + (currentIndent) + "}(\\w+):[\\s\\t\\r\\n](.*)");
			var matchEnd = line.match("^\\t{" + (currentIndent - 1) + "}\\}");

			if (matchBeginning != null) {
				parseNodeBegin(line, matchBeginning);
			} else if (matchProperty != null) {
				parseNodeProperty(line, matchProperty, split[i + 1]);
			} else if (matchEnd != null) {
				popStack();
			} else if (line.match(/^[^\s\t}]/)) {
				parseNodePropertyContinued(line);
			}
		}

		return allNodes;
	}

	function parseNodeBegin(line:String, property:Array<String>) {
		var nodeName = property[1].trim().replace(/^"/, "").replace(/"$/, "");
		var nodeAttrs = property[2].split(",").map(function(attr) {
			return attr.trim().replace(/^"/, "").replace(/"$/, "");
		});

		var node = { name: nodeName };
		var attrs = parseNodeAttr(nodeAttrs);

		var currentNode = getCurrentNode();

		if (currentIndent == 0) {
			allNodes.add(nodeName, node);
		} else {
			if (nodeName in currentNode) {
				if (nodeName == "PoseNode") {
					currentNode.PoseNode.push(node);
				} else if (currentNode[nodeName].id != null) {
					currentNode[nodeName] = { };
					currentNode[nodeName][currentNode[nodeName].id] = currentNode[nodeName];
				}

				if (attrs.id != "") currentNode[nodeName][attrs.id] = node;
			} else if (Std.is(attrs.id, Int)) {
				currentNode[nodeName] = { };
				currentNode[nodeName][attrs.id] = node;
			} else if (nodeName != "Properties70") {
				if (nodeName == "PoseNode") currentNode[nodeName] = [node];
				else currentNode[nodeName] = node;
			}
		}

		if (Std.is(attrs.id, Int)) node.id = attrs.id;
		if (attrs.name != "") node.attrName = attrs.name;
		if (attrs.type != "") node.attrType = attrs.type;

		pushStack(node);
	}

	function parseNodeAttr(attrs:Array<String>):Dynamic {
		var id = attrs[0];

		if (attrs[0] != "") {
			id = Std.parseInt(attrs[0]);

			if (Std.isNaN(id)) {
				id = attrs[0];
			}
		}

		var name = "";
		var type = "";

		if (attrs.length > 1) {
			name = attrs[1].replace(/^(\w+)::/, "");
			type = attrs[2];
		}

		return { id: id, name: name, type: type };
	}

	function parseNodeProperty(line:String, property:Array<String>, contentLine:String) {
		var propName = property[1].replace(/^"/, "").replace(/"$/, "").trim();
		var propValue = property[2].replace(/^"/, "").replace(/"$/, "").trim();

		if (propName == "Content" && propValue == ",") {
			propValue = contentLine.replace(/"/g, "").replace(/,$/, "").trim();
		}

		var currentNode = getCurrentNode();
		var parentName = currentNode.name;

		if (parentName == "Properties70") {
			parseNodeSpecialProperty(line, propName, propValue);
			return;
		}

		if (propName == "C") {
			var connProps = propValue.split(",").slice(1, null);
			var from = Std.parseInt(connProps[0]);
			var to = Std.parseInt(connProps[1]);

			var rest = propValue.split(",").slice(3, null);

			rest = rest.map(function(elem) {
				return elem.trim().replace(/^"/, "");
			});

			propName = "connections";
			propValue = [from, to];
			Array.prototype.push.apply(propValue, rest);

			if (currentNode[propName] == null) {
				currentNode[propName] = [];
			}
		}

		if (propName == "Node") currentNode.id = propValue;

		if (propName in currentNode && currentNode[propName] is Array) {
			currentNode[propName].push(propValue);
		} else {
			if (propName != "a") currentNode[propName] = propValue;
			else currentNode.a = propValue;
		}

		setCurrentProp(currentNode, propName);

		if (propName == "a" && propValue.slice(-1) != ",") {
			currentNode.a = parseNumberArray(propValue);
		}
	}

	function parseNodePropertyContinued(line:String) {
		var currentNode = getCurrentNode();
		currentNode.a += line;

		if (line.slice(-1) != ",") {
			currentNode.a = parseNumberArray(currentNode.a);
		}
	}

	function parseNodeSpecialProperty(line:String, propName:String, propValue:String) {
		var props = propValue.split('",').map(function(prop) {
			return prop.trim().replace(/^\"/, "").replace(/\s/, '_');
		});

		var innerPropName = props[0];
		var innerPropType1 = props[1];
		var innerPropType2 = props[2];
		var innerPropFlag = props[3];
		var innerPropValue = props[4];

		switch (innerPropType1) {
			case "int":
			case "enum":
			case "bool":
			case "ULongLong":
			case "double":
			case "Number":
			case "FieldOfView":
				innerPropValue = Std.parseFloat(innerPropValue);
				break;

			case "Color":
			case "ColorRGB":
			case "Vector3D":
			case "Lcl_Translation":
			case "Lcl_Rotation":
			case "Lcl_Scaling":
				innerPropValue = parseNumberArray(innerPropValue);
				break;
		}

		getPrevNode()[innerPropName] = {
			type: innerPropType1,
			type2: innerPropType2,
			flag: innerPropFlag,
			value: innerPropValue
		};

		setCurrentProp(getPrevNode(), innerPropName);
	}

	function getPrevNode():Dynamic {
		return nodeStack[currentIndent - 2];
	}

	function getCurrentNode():Dynamic {
		return nodeStack[currentIndent - 1];
	}

	function getCurrentProp():Dynamic {
		return currentProp;
	}

	function pushStack(node:Dynamic) {
		nodeStack.push(node);
		currentIndent += 1;
	}

	function popStack() {
		nodeStack.pop();
		currentIndent -= 1;
	}

	function setCurrentProp(val:Dynamic, name:String) {
		currentProp = val;
		currentPropName = name;
	}
}