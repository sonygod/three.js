class TextParser {

    var nodeStack:Array<Dynamic>;
    var currentIndent:Int;
    var allNodes:Dynamic;
    var currentProp:Array<String>;
    var currentPropName:String;

    public function getPrevNode():Dynamic {
        return nodeStack[currentIndent - 2];
    }

    public function getCurrentNode():Dynamic {
        return nodeStack[currentIndent - 1];
    }

    public function getCurrentProp():Array<String> {
        return currentProp;
    }

    public function pushStack(node:Dynamic):Void {
        nodeStack.push(node);
        currentIndent += 1;
    }

    public function popStack():Void {
        nodeStack.pop();
        currentIndent -= 1;
    }

    public function setCurrentProp(val:Array<String>, name:String):Void {
        currentProp = val;
        currentPropName = name;
    }

    public function parse(text:String):Dynamic {
        currentIndent = 0;
        allNodes = new Dynamic();
        nodeStack = new Array<Dynamic>();
        currentProp = new Array<String>();
        currentPropName = '';

        var split:Array<String> = text.split(/\r\n+/);

        for (line in split) {
            var matchComment:EReg = line.match(/^[\s\t]*;/);
            var matchEmpty:EReg = line.match(/^[\s\t]*$/);

            if (matchComment != null || matchEmpty != null) continue;

            var matchBeginning:EReg = line.match('^\\t{' + currentIndent + '}(\\w+):(.*){', '');
            var matchProperty:EReg = line.match('^\\t{' + (currentIndent) + '}(\\w+):[\\s\\t\\r\\n](.*)');
            var matchEnd:EReg = line.match('^\\t{' + (currentIndent - 1) + '}}');

            if (matchBeginning != null) {
                parseNodeBegin(line, matchBeginning);
            } else if (matchProperty != null) {
                parseNodeProperty(line, matchProperty, split[split.indexOf(line) + 1]);
            } else if (matchEnd != null) {
                popStack();
            } else if (line.match(/^[^\s\t}]/) != null) {
                parseNodePropertyContinued(line);
            }
        }

        return allNodes;
    }

    private function parseNodeBegin(line:String, property:EReg):Void {
        var nodeName:String = property.matched(1).trim().replace(/^"/, '').replace(/"$/, '');
        var nodeAttrs:Array<String> = property.matched(2).split(',').map(function(attr:String):String {
            return attr.trim().replace(/^"/, '').replace(/"$/, '');
        });

        var node:Dynamic = { name: nodeName };
        var attrs:Dynamic = parseNodeAttr(nodeAttrs);
        var currentNode:Dynamic = getCurrentNode();

        if (currentIndent == 0) {
            allNodes[nodeName] = node;
        } else {
            if (nodeName in currentNode) {
                if (nodeName == 'PoseNode') {
                    currentNode.PoseNode.push(node);
                } else if ('id' in currentNode[nodeName]) {
                    currentNode[nodeName] = { 'id': currentNode[nodeName].id };
                }

                if ('id' in attrs) currentNode[nodeName][attrs.id] = node;
            } else if (Std.isOfType(attrs.id, Int)) {
                currentNode[nodeName] = { attrs.id: node };
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

    private function parseNodeAttr(attrs:Array<String>):Dynamic {
        var id:Dynamic = attrs[0];

        if (attrs[0] != '') {
            id = Std.parseInt(attrs[0]);

            if (Std.isNaN(id)) {
                id = attrs[0];
            }
        }

        var name:String = '', type:String = '';

        if (attrs.length > 1) {
            name = attrs[1].replace(/^(\w+)::/, '');
            type = attrs[2];
        }

        return { id: id, name: name, type: type };
    }

    private function parseNodeProperty(line:String, property:EReg, contentLine:String):Void {
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
            var rest:Array<String> = propValue.split(',').slice(3).map(function(elem:String):String {
                return elem.trim().replace(/^"/, '');
            });

            propName = 'connections';
            propValue = [from, to];
            propValue.concat(rest);

            if (!(propName in currentNode)) {
                currentNode[propName] = [];
            }
        }

        if (propName == 'Node') currentNode.id = propValue;

        if (propName in currentNode && Std.isOfType(currentNode[propName], Array)) {
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

    private function parseNodePropertyContinued(line:String):Void {
        var currentNode:Dynamic = getCurrentNode();

        currentNode.a += line;

        if (line.charAt(line.length - 1) != ',') {
            currentNode.a = parseNumberArray(currentNode.a);
        }
    }

    private function parseNodeSpecialProperty(line:String, propName:String, propValue:String):Void {
        var props:Array<String> = propValue.split('",').map(function(prop:String):String {
            return prop.trim().replace(/^\"/, '').replace(/\s/, '_');
        });

        var innerPropName:String = props[0];
        var innerPropType1:String = props[1];
        var innerPropType2:String = props[2];
        var innerPropFlag:String = props[3];
        var innerPropValue:Dynamic = props[4];

        switch (innerPropType1) {
            case 'int':
            case 'enum':
            case 'bool':
            case 'ULongLong':
            case 'double':
            case 'Number':
            case 'FieldOfView':
                innerPropValue = Std.parseFloat(innerPropValue);
                break;

            case 'Color':
            case 'ColorRGB':
            case 'Vector3D':
            case 'Lcl_Translation':
            case 'Lcl_Rotation':
            case 'Lcl_Scaling':
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

    private function parseNumberArray(value:String):Array<Float> {
        return value.split(',').map(Std.parseFloat);
    }
}