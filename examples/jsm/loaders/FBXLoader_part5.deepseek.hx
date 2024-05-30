class TextParser {

    var nodeStack:Array<Dynamic>;
    var currentIndent:Int;
    var allNodes:FBXTree;
    var currentProp:Array<Dynamic>;
    var currentPropName:String;

    public function new() {
        nodeStack = [];
        currentIndent = 0;
        allNodes = new FBXTree();
        currentProp = [];
        currentPropName = '';
    }

    function getPrevNode():Dynamic {
        return nodeStack[currentIndent - 2];
    }

    function getCurrentNode():Dynamic {
        return nodeStack[currentIndent - 1];
    }

    function getCurrentProp():Array<Dynamic> {
        return currentProp;
    }

    function pushStack(node:Dynamic):Void {
        nodeStack.push(node);
        currentIndent += 1;
    }

    function popStack():Void {
        nodeStack.pop();
        currentIndent -= 1;
    }

    function setCurrentProp(val:Array<Dynamic>, name:String):Void {
        currentProp = val;
        currentPropName = name;
    }

    function parse(text:String):FBXTree {
        currentIndent = 0;
        allNodes = new FBXTree();
        nodeStack = [];
        currentProp = [];
        currentPropName = '';

        var scope = this;

        var split = text.split(/\r\n/);

        for (line in split) {
            var matchComment = line.match(/^[\s\t]*;/);
            var matchEmpty = line.match(/^[\s\t]*$/);

            if (matchComment || matchEmpty) continue;

            var matchBeginning = line.match('^\\t{' + scope.currentIndent + '}(\\w+):(.*){');
            var matchProperty = line.match('^\\t{' + (scope.currentIndent) + '}(\\w+):[\\s\\t\\r\\n](.*)');
            var matchEnd = line.match('^\\t{' + (scope.currentIndent - 1) + '}}');

            if (matchBeginning) {
                scope.parseNodeBegin(line, matchBeginning);
            } else if (matchProperty) {
                scope.parseNodeProperty(line, matchProperty, split[++i]);
            } else if (matchEnd) {
                scope.popStack();
            } else if (line.match(/^[^\s\t}]/)) {
                scope.parseNodePropertyContinued(line);
            }
        }

        return this.allNodes;
    }

    function parseNodeBegin(line:String, property:Array<String>):Void {
        var nodeName = property[1].trim().replace(/^"/, '').replace(/"$/, '');

        var nodeAttrs = property[2].split(',').map(function (attr) {
            return attr.trim().replace(/^"/, '').replace(/"$/, '');
        });

        var node = {name: nodeName};
        var attrs = this.parseNodeAttr(nodeAttrs);

        var currentNode = this.getCurrentNode();

        if (this.currentIndent === 0) {
            this.allNodes.add(nodeName, node);
        } else {
            if (nodeName in currentNode) {
                if (nodeName === 'PoseNode') {
                    currentNode.PoseNode.push(node);
                } else if (currentNode[nodeName].id !== undefined) {
                    currentNode[nodeName] = {};
                    currentNode[nodeName][currentNode[nodeName].id] = currentNode[nodeName];
                }
                if (attrs.id !== '') currentNode[nodeName][attrs.id] = node;
            } else if (typeof attrs.id === 'number') {
                currentNode[nodeName] = {};
                currentNode[nodeName][attrs.id] = node;
            } else if (nodeName !== 'Properties70') {
                if (nodeName === 'PoseNode') currentNode[nodeName] = [node];
                else currentNode[nodeName] = node;
            }
        }

        if (typeof attrs.id === 'number') node.id = attrs.id;
        if (attrs.name !== '') node.attrName = attrs.name;
        if (attrs.type !== '') node.attrType = attrs.type;

        this.pushStack(node);
    }

    function parseNodeAttr(attrs:Array<String>):Dynamic {
        var id = attrs[0];

        if (attrs[0] !== '') {
            id = Std.parseInt(attrs[0]);
            if (isNaN(id)) {
                id = attrs[0];
            }
        }

        var name = '', type = '';

        if (attrs.length > 1) {
            name = attrs[1].replace(/^(\w+)::/, '');
            type = attrs[2];
        }

        return {id: id, name: name, type: type};
    }

    function parseNodeProperty(line:String, property:Array<String>, contentLine:String):Void {
        var propName = property[1].replace(/^"/, '').replace(/"$/, '').trim();
        var propValue = property[2].replace(/^"/, '').replace(/"$/, '').trim();

        if (propName === 'Content' && propValue === ',') {
            propValue = contentLine.replace(/"/g, '').replace(/,$/, '').trim();
        }

        var currentNode = this.getCurrentNode();
        var parentName = currentNode.name;

        if (parentName === 'Properties70') {
            this.parseNodeSpecialProperty(line, propName, propValue);
            return;
        }

        if (propName === 'C') {
            var connProps = propValue.split(',').slice(1);
            var from = Std.parseInt(connProps[0]);
            var to = Std.parseInt(connProps[1]);

            var rest = propValue.split(',').slice(3);

            rest = rest.map(function (elem) {
                return elem.trim().replace(/^"/, '');
            });

            propName = 'connections';
            propValue = [from, to];
            append(propValue, rest);

            if (currentNode[propName] === undefined) {
                currentNode[propName] = [];
            }
        }

        if (propName === 'Node') currentNode.id = propValue;

        if (propName in currentNode && Std.is(currentNode[propName], Array)) {
            currentNode[propName].push(propValue);
        } else {
            if (propName !== 'a') currentNode[propName] = propValue;
            else currentNode.a = propValue;
        }

        this.setCurrentProp(currentNode, propName);

        if (propName === 'a' && propValue.slice(-1) !== ',') {
            currentNode.a = parseNumberArray(propValue);
        }
    }

    function parseNodePropertyContinued(line:String):Void {
        var currentNode = this.getCurrentNode();

        currentNode.a += line;

        if (line.slice(-1) !== ',') {
            currentNode.a = parseNumberArray(currentNode.a);
        }
    }

    function parseNodeSpecialProperty(line:String, propName:String, propValue:String):Void {
        var props = propValue.split('",').map(function (prop) {
            return prop.trim().replace(/^\"/, '').replace(/ /, '_');
        });

        var innerPropName = props[0];
        var innerPropType1 = props[1];
        var innerPropType2 = props[2];
        var innerPropFlag = props[3];
        var innerPropValue = props[4];

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

        this.getPrevNode()[innerPropName] = {
            'type': innerPropType1,
            'type2': innerPropType2,
            'flag': innerPropFlag,
            'value': innerPropValue
        };

        this.setCurrentProp(this.getPrevNode(), innerPropName);
    }
}