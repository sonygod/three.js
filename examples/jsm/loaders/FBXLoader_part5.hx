package three.js.examples.javascript.loaders;

import FBXTree;

class TextParser {
    var nodeStack:Array<Dynamic>;
    var currentIndent:Int;
    var allNodes:FBXTree;
    var currentProp:Array<Dynamic>;
    var currentPropName:String;

    public function new() {}

    function getPrevNode():Dynamic {
        return nodeStack[currentIndent - 2];
    }

    function getCurrentNode():Dynamic {
        return nodeStack[currentIndent - 1];
    }

    function getCurrentProp():Array<Dynamic> {
        return currentProp;
    }

    function pushStack(node:Dynamic) {
        nodeStack.push(node);
        currentIndent++;
    }

    function popStack() {
        nodeStack.pop();
        currentIndent--;
    }

    function setCurrentProp(val:Array<Dynamic>, name:String) {
        currentProp = val;
        currentPropName = name;
    }

    function parse(text:String):FBXTree {
        currentIndent = 0;
        allNodes = new FBXTree();
        nodeStack = [];
        currentProp = [];
        currentPropName = '';

        var split:Array<String> = text.split(~/\r\n+/);

        for (i in 0...split.length) {
            var line:String = split[i];
            var matchComment:EReg = ~/^[\s\t]*;/;
            var matchEmpty:EReg = ~/^[\s\t]*$/;

            if (matchComment.match(line) || matchEmpty.match(line)) continue;

            var matchBeginning:EReg = ~/^[\t]{$currentIndent}(\w+):(.*){/;
            var matchProperty:EReg = ~/^[\t]{$currentIndent}(\w+):[\s\t\r\n](.*)/;
            var matchEnd:EReg = ~/^[\t]{$currentIndent - 1}}/;

            if (matchBeginning.match(line)) {
                parseNodeBegin(line, matchBeginning);
            } else if (matchProperty.match(line)) {
                parseNodeProperty(line, matchProperty, split[i + 1]);
            } else if (matchEnd.match(line)) {
                popStack();
            } else if (~/^[\s\t]*[^\s\t]/.match(line)) {
                parseNodePropertyContinued(line);
            }
        }

        return allNodes;
    }

    function parseNodeBegin(line:String, property:EReg) {
        var nodeName:String = property.matched(1).trim().replace(/^"/, '').replace(/"$/, '');
        var nodeAttrs:Array<String> = property.matched(2).split(',').map(function(attr:String) {
            return attr.trim().replace(/^"/, '').replace(/"$/, '');
        });

        var node:Dynamic = { name: nodeName };
        var attrs:Dynamic = parseNodeAttr(nodeAttrs);

        var currentNode:Dynamic = getCurrentNode();

        if (currentIndent == 0) {
            allNodes.add(nodeName, node);
        } else {
            if (nodeName in currentNode) {
                if (nodeName == 'PoseNode') {
                    currentNode.PoseNode.push(node);
                } else if (Reflect.hasField(currentNode, nodeName) && Reflect.field(currentNode, nodeName).id != null) {
                    currentNode[nodeName] = {};
                    currentNode[nodeName][Reflect.field(currentNode, nodeName).id] = Reflect.field(currentNode, nodeName);
                }

                if (attrs.id != '') currentNode[nodeName][attrs.id] = node;
            } else if (Std.isOfType(attrs.id, Int)) {
                currentNode[nodeName] = {};
                currentNode[nodeName][attrs.id] = node;
            } else if (nodeName != 'Properties70') {
                if (nodeName == 'PoseNode') currentNode[nodeName] = [node];
                else currentNode[nodeName] = node;
            }
        }

        if (Std.isOfType(attrs.id, Int)) node.id = attrs.id;
        if (attrs.name != '') node.attrName = attrs.name;
        if (attrs.type != '') node.attrType = attrs.type;

        pushStack(node);
    }

    function parseNodeAttr(attrs:Array<String>):Dynamic {
        var id:Dynamic = attrs[0];
        if (attrs[0] != '') {
            id = Std.parseInt(attrs[0]);
            if (Math.isNaN(id)) id = attrs[0];
        }

        var name:String = '';
        var type:String = '';

        if (attrs.length > 1) {
            name = attrs[1].replace(/^(\w+)::/, '');
            type = attrs[2];
        }

        return { id: id, name: name, type: type };
    }

    function parseNodeProperty(line:String, property:EReg, contentLine:String) {
        var propName:String = property.matched(1).replace(/^"/, '').replace(/"$/, '').trim();
        var propValue:String = property.matched(2).replace(/^"/, '').replace(/"$/, '').trim();

        if (propName == 'Content' && propValue == ',') {
            propValue = contentLine.replace(/"/g, '').replace(/,$/, '').trim();
        }

        var currentNode:Dynamic = getCurrentNode();
        var parentName:String = currentNode.name;

        if (parentName == 'Properties70') {
            parseNodeSpecialProperty(line, propName, propValue);
            return;
        }

        if (propName == 'C') {
            var connProps:Array<String> = propValue.split(',').slice(1);
            var from:Int = Std.parseInt(connProps[0]);
            var to:Int = Std.parseInt(connProps[1]);

            var rest:Array<String> = propValue.split(',').slice(3);

            rest = rest.map(function(elem:String) {
                return elem.trim().replace(/^"/, '');
            });

            propName = 'connections';
            propValue = [from, to];
            append(propValue, rest);

            if (currentNode[propName] == null) {
                currentNode[propName] = [];
            }
        }

        if (propName == 'Node') currentNode.id = propValue;

        if (Reflect.hasField(currentNode, propName) && Std.isOfType(currentNode[propName], Array)) {
            currentNode[propName].push(propValue);
        } else {
            if (propName != 'a') currentNode[propName] = propValue;
            else currentNode.a = propValue;
        }

        setCurrentProp(currentNode, propName);

        if (propName == 'a' && propValue.charAt(propValue.length - 1) != ',') {
            currentNode.a = parseNumberArray(propValue);
        }
    }

    function parseNodePropertyContinued(line:String) {
        var currentNode:Dynamic = getCurrentNode();

        currentNode.a += line;

        if (line.charAt(line.length - 1) != ',') {
            currentNode.a = parseNumberArray(currentNode.a);
        }
    }

    function parseNodeSpecialProperty(line:String, propName:String, propValue:String) {
        var props:Array<String> = propValue.split('",').map(function(prop:String) {
            return prop.trim().replace(/^"/, '').replace(/\s/, '_');
        });

        var innerPropName:String = props[0];
        var innerPropType1:String = props[1];
        var innerPropType2:String = props[2];
        var innerPropFlag:String = props[3];
        var innerPropValue:String = props[4];

        switch (innerPropType1) {
            case 'int', 'enum', 'bool', 'ULongLong', 'double', 'Number', 'FieldOfView':
                innerPropValue = Std.parseFloat(innerPropValue);
                break;
            case 'Color', 'ColorRGB', 'Vector3D', 'Lcl_Translation', 'Lcl_Rotation', 'Lcl_Scaling':
                innerPropValue = parseNumberArray(innerPropValue);
                break;
        }

        getPrevNode()[innerPropName] = {
            'type': innerPropType1,
            'type2': innerPropType2,
            'flag': innerPropFlag,
            'value': innerPropValue
        };

        setCurrentProp(getPrevNode(), innerPropName);
    }

    function parseNumberArray(str:String):Array<Float> {
        var array:Array<Float> = [];
        var parts:Array<String> = str.split(',');
        for (part in parts) {
            array.push(Std.parseFloat(part));
        }
        return array;
    }

    function append(array:Array<Dynamic>, rest:Array<Dynamic>) {
        for (elem in rest) {
            array.push(elem);
        }
    }
}