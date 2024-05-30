package three.js.examples.jsm.loaders;

import haxe.ds.StringMap;

class TextParser {
    private var nodeStack:Array<Dynamic>;
    private var currentIndent:Int;
    private var allNodes:FBXTree;
    private var currentProp:Array<Dynamic>;
    private var currentPropName:String;

    public function new() {}

    public function getPrevNode():Dynamic {
        return nodeStack[currentIndent - 2];
    }

    public function getCurrentNode():Dynamic {
        return nodeStack[currentIndent - 1];
    }

    public function getCurrentProp():Array<Dynamic> {
        return currentProp;
    }

    public function pushStack(node:Dynamic) {
        nodeStack.push(node);
        currentIndent++;
    }

    public function popStack() {
        nodeStack.pop();
        currentIndent--;
    }

    public function setCurrentProp(val:Array<Dynamic>, name:String) {
        currentProp = val;
        currentPropName = name;
    }

    public function parse(text:String):FBXTree {
        currentIndent = 0;
        allNodes = new FBXTree();
        nodeStack = [];
        currentProp = [];
        currentPropName = '';

        var split:Array<String> = text.split~/[\r\n]+/;

        for (i in 0...split.length) {
            var line:String = split[i];
            var matchComment:Array<Dynamic> = ~/^[\s\t]*;/.match(line);
            var matchEmpty:Array<Dynamic> = ~/^[\s\t]*$/.match(line);

            if (matchComment != null || matchEmpty != null) continue;

            var matchBeginning:Array<Dynamic> = ~/^\\t{${currentIndent}}(\\w+):(.*){/.exec(line);
            var matchProperty:Array<Dynamic> = ~/^\\t{${currentIndent}}(\\w+):(.*$/.exec(line);
            var matchEnd:Array<Dynamic> = ~/^\\t{${currentIndent - 1}}}/.exec(line);

            if (matchBeginning != null) {
                parseNodeBegin(line, matchBeginning);
            } else if (matchProperty != null) {
                parseNodeProperty(line, matchProperty, split[i + 1]);
            } else if (matchEnd != null) {
                popStack();
            } else if (!~/^[^\s\t}]$/.test(line)) {
                parseNodePropertyContinued(line);
            }
        }

        return allNodes;
    }

    private function parseNodeBegin(line:String, property:Array<Dynamic>) {
        var nodeName:String = property[1].trim().replace(/^"/, '').replace(/"$/, '');
        var nodeAttrs:Array<Dynamic> = property[2].split(',');

        for (attr in nodeAttrs) {
            attr = attr.trim().replace(/^"/, '').replace(/"$/, '');
        }

        var node:Dynamic = { name: nodeName };
        var attrs:Dynamic = parseNodeAttr(nodeAttrs);

        var currentNode:Dynamic = getCurrentNode();

        if (currentIndent == 0) {
            allNodes.add(nodeName, node);
        } else {
            if (!Reflect.hasField(currentNode, nodeName)) {
                if (nodeName == 'PoseNode') {
                    Reflect.setField(currentNode, nodeName, [node]);
                } else {
                    Reflect.setField(currentNode, nodeName, node);
                }
            } else {
                if (nodeName == 'PoseNode') {
                    Reflect.field(currentNode, nodeName).push(node);
                } else if (Reflect.hasField(currentNode, nodeName) && Reflect.field(currentNode, nodeName) != null) {
                    if (Reflect.getField(currentNode, nodeName).id != null) {
                        Reflect.setField(currentNode, nodeName, Reflect.getField(currentNode, nodeName));
                    } else {
                        Reflect.setField(currentNode, nodeName, node);
                    }
                } else {
                    Reflect.setField(currentNode, nodeName, node);
                }
            }

            if (attrs.id != '') {
                Reflect.setField(node, 'id', attrs.id);
            }
            if (attrs.name != '') {
                Reflect.setField(node, 'attrName', attrs.name);
            }
            if (attrs.type != '') {
                Reflect.setField(node, 'attrType', attrs.type);
            }

            pushStack(node);
        }
    }

    private function parseNodeAttr(attrs:Array<Dynamic>):Dynamic {
        var id:Dynamic = attrs[0];
        if (attrs[0] != '') {
            id = Std.parseInt(attrs[0]);
            if (Math.isNaN(id)) {
                id = attrs[0];
            }
        }

        var name:String = '';
        var type:String = '';

        if (attrs.length > 1) {
            name = attrs[1].replace(/^(\w+)::/, '');
            type = attrs[2];
        }

        return { id: id, name: name, type: type };
    }

    private function parseNodeProperty(line:String, property:Array<Dynamic>, contentLine:String) {
        var propName:String = property[1].replace(/^"/, '').replace(/"$/, '').trim();
        var propValue:String = property[2].replace(/^"/, '').replace(/"$/, '').trim();

        if (propName == 'Content' && propValue == ',') {
            propValue = contentLine.replace(/"/g, '').replace(/,$/, '').trim();
        }

        var currentNode:Dynamic = getCurrentNode();
        var parentName:String = currentNode.name;

        if (parentName == 'Properties70') {
            parseNodeSpecialProperty(line, propName, propValue);
            return;
        }

        if (propName == 'connections') {
            var connProps:Array<Dynamic> = propValue.split(',');
            connProps.shift();
            var from:Int = Std.parseInt(connProps[0]);
            var to:Int = Std.parseInt(connProps[1]);

            var rest:Array<Dynamic> = connProps.slice(3);

            for (elem in rest) {
                elem = elem.trim().replace(/^"/, '');
            }

            propName = 'connections';
            propValue = [from, to];
            append(propValue, rest);

            if (!Reflect.hasField(currentNode, propName)) {
                Reflect.setField(currentNode, propName, []);
            }

            Reflect.field(currentNode, propName).push(propValue);
        } else if (propName == 'Node') {
            Reflect.setField(currentNode, 'id', propValue);
        } else {
            if (Reflect.hasField(currentNode, propName) && Reflect.field(currentNode, propName) != null) {
                Reflect.append(Reflect.field(currentNode, propName), propValue);
            } else {
                Reflect.setField(currentNode, propName, propValue);
            }
        }

        setCurrentProp(currentNode, propName);

        if (propName == 'a' && propValue.charAt(propValue.length - 1) != ',') {
            Reflect.setField(currentNode, propName, parseNumberArray(propValue));
        }
    }

    private function parseNodePropertyContinued(line:String) {
        var currentNode:Dynamic = getCurrentNode();

        Reflect.setField(currentNode, 'a', Reflect.field(currentNode, 'a') + line);

        if (line.charAt(line.length - 1) != ',') {
            Reflect.setField(currentNode, 'a', parseNumberArray(Reflect.field(currentNode, 'a')));
        }
    }

    private function parseNodeSpecialProperty(line:String, propName:String, propValue:String) {
        var props:Array<Dynamic> = propValue.split('",').map(function(prop:String) {
            return prop.trim().replace(/^"/, '').replace(/\s/, '_');
        });

        var innerPropName:String = props[0];
        var innerPropType1:String = props[1];
        var innerPropType2:String = props[2];
        var innerPropFlag:String = props[3];
        var innerPropValue:Dynamic = props[4];

        switch (innerPropType1) {
            case 'int', 'enum', 'bool', 'ULongLong', 'double', 'Number', 'FieldOfView':
                innerPropValue = Std.parseFloat(innerPropValue);
            case 'Color', 'ColorRGB', 'Vector3D', 'Lcl_Translation', 'Lcl_Rotation', 'Lcl_Scaling':
                innerPropValue = parseNumberArray(innerPropValue);
        }

        getPrevNode()[innerPropName] = {
            'type': innerPropType1,
            'type2': innerPropType2,
            'flag': innerPropFlag,
            'value': innerPropValue
        };

        setCurrentProp(getPrevNode(), innerPropName);
    }

    private function append(arr:Array<Dynamic>, rest:Array<Dynamic>) {
        for (elem in rest) {
            arr.push(elem);
        }
    }

    private function parseNumberArray(str:String):Array<Float> {
        var arr:Array<Float> = [];

        for (num in str.split(',')) {
            arr.push(Std.parseFloat(num.trim()));
        }

        return arr;
    }
}