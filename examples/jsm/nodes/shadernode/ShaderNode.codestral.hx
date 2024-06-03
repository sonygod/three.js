import Node from '../core/Node';
import ArrayElementNode from '../utils/ArrayElementNode';
import ConvertNode from '../utils/ConvertNode';
import JoinNode from '../utils/JoinNode';
import SplitNode from '../utils/SplitNode';
import SetNode from '../utils/SetNode';
import ConstNode from '../core/ConstNode';
import NodeUtils from '../core/NodeUtils';

class ShaderNodeHandler {
    public static setup(NodeClosure:Class<Node>, params:Array<Dynamic>):Node {
        var inputs:Dynamic = params.shift();
        return Type.createInstance(NodeClosure, [nodeObjects(inputs), ...params]);
    }

    public static get(node:Dynamic, prop:Dynamic, nodeObj:Node):Dynamic {
        if (Std.is(prop, String) && Reflect.hasField(node, prop) == false) {
            if (Reflect.hasField(node, 'isStackNode') == false && prop == 'assign') {
                return function(...params:Array<Dynamic>):Node {
                    ShaderNode.currentStack.assign(nodeObj, ...params);
                    return nodeObj;
                };
            } else if (ShaderNode.NodeElements.exists(prop)) {
                var nodeElement:Class<Node> = ShaderNode.NodeElements.get(prop);
                return Reflect.hasField(node, 'isStackNode') ? function(...params:Array<Dynamic>):Node { return nodeObj.add(Type.createInstance(nodeElement, params)); } : function(...params:Array<Dynamic>):Node { return Type.createInstance(nodeElement, [nodeObj, ...params]); };
            } else if (prop == 'self') {
                return node;
            } else if (Std.is(prop, String) && prop.endsWith('Assign') && ShaderNode.NodeElements.exists(prop.substring(0, prop.length - 'Assign'.length))) {
                var nodeElement:Class<Node> = ShaderNode.NodeElements.get(prop.substring(0, prop.length - 'Assign'.length));
                return Reflect.hasField(node, 'isStackNode') ? function(...params:Array<Dynamic>):Node { return nodeObj.assign(params[0], Type.createInstance(nodeElement, params)); } : function(...params:Array<Dynamic>):Node { return nodeObj.assign(Type.createInstance(nodeElement, [nodeObj, ...params])); };
            } else if (Std.is(prop, String) && /^[xyzwrgbastpq]{1,4}$/.match(prop)) {
                prop = parseSwizzle(prop);
                return nodeObject(new SplitNode(nodeObj, prop));
            } else if (Std.is(prop, String) && /^set[XYZWRGBASTPQ]{1,4}$/.match(prop)) {
                prop = parseSwizzle(prop.substring(3).toLowerCase());
                prop = prop.split('').sort().join('');
                return function(value:Dynamic):Node {
                    return nodeObject(new SetNode(node, prop, value));
                };
            } else if (prop == 'width' || prop == 'height' || prop == 'depth') {
                if (prop == 'width') prop = 'x';
                else if (prop == 'height') prop = 'y';
                else if (prop == 'depth') prop = 'z';
                return nodeObject(new SplitNode(node, prop));
            } else if (Std.is(prop, String) && /^\d+$/.match(prop)) {
                return nodeObject(new ArrayElementNode(nodeObj, new ConstNode(Std.parseInt(prop), 'uint')));
            }
        }
        return Reflect.field(node, prop);
    }

    public static set(node:Dynamic, prop:Dynamic, value:Dynamic, nodeObj:Node):Bool {
        if (Std.is(prop, String) && Reflect.hasField(node, prop) == false) {
            if (/^[xyzwrgbastpq]{1,4}$/.match(prop) || prop == 'width' || prop == 'height' || prop == 'depth' || /^\d+$/.match(prop)) {
                nodeObj[prop].assign(value);
                return true;
            }
        }
        return Reflect.setField(node, prop, value);
    }
}

class ShaderNodeInternal extends Node {
    public var jsFunc:Dynamic;
    public var layout:Dynamic;

    public function new(jsFunc:Dynamic) {
        super();
        this.jsFunc = jsFunc;
        this.layout = null;
    }

    public function get isArrayInput():Bool {
        return /^\((\s+)?\[/.match(this.jsFunc.toString());
    }

    public function setLayout(layout:Dynamic):ShaderNodeInternal {
        this.layout = layout;
        return this;
    }

    public function call(inputs:Array<Dynamic> = null):Node {
        nodeObjects(inputs);
        return nodeObject(new ShaderCallNodeInternal(this, inputs));
    }

    public function setup():Node {
        return this.call();
    }
}

class ShaderNode {
    public static var currentStack:Node = null;
    public static var NodeElements:Map<String, Class<Node>> = new Map();

    public static function addNodeElement(name:String, nodeElement:Class<Node>):Void {
        if (ShaderNode.NodeElements.exists(name)) {
            trace('Redefinition of node element ${name}');
            return;
        }
        if (Std.is(nodeElement, Class) == false) throw new Error('Node element ${name} is not a class');
        ShaderNode.NodeElements.set(name, nodeElement);
    }

    public function new(jsFunc:Dynamic):Dynamic {
        return Proxy.create({
            get: ShaderNodeHandler.get,
            set: ShaderNodeHandler.set
        }, new ShaderNodeInternal(jsFunc));
    }
}

function parseSwizzle(props:String):String {
    return props.replace(/r|s/g, 'x').replace(/g|t/g, 'y').replace(/b|p/g, 'z').replace(/a|q/g, 'w');
}

function nodeObject(val:Dynamic, altType:String = null):Node {
    var type:String = NodeUtils.getValueType(val);
    if (type == 'node') {
        var nodeObject:Node = nodeObjectsCacheMap.get(val);
        if (nodeObject == null) {
            nodeObject = Proxy.create({
                get: ShaderNodeHandler.get,
                set: ShaderNodeHandler.set
            }, val);
            nodeObjectsCacheMap.set(val, nodeObject);
            nodeObjectsCacheMap.set(nodeObject, nodeObject);
        }
        return nodeObject;
    } else if ((altType == null && (type == 'float' || type == 'boolean')) || (type != null && type != 'shader' && type != 'string')) {
        return nodeObject(getConstNode(val, altType));
    } else if (type == 'shader') {
        return tslFn(val);
    }
    return val;
}

function nodeObjects(objects:Dynamic, altType:String = null):Dynamic {
    for (key in Reflect.fields(objects)) {
        objects[key] = nodeObject(objects[key], altType);
    }
    return objects;
}

function nodeArray(array:Array<Dynamic>, altType:String = null):Array<Dynamic> {
    for (i in 0...array.length) {
        array[i] = nodeObject(array[i], altType);
    }
    return array;
}

function nodeProxy(NodeClass:Class<Node>, scope:Node = null, factor:Dynamic = null, settings:Dynamic = null):Dynamic {
    function assignNode(node:Node):Node {
        return settings != null ? nodeObject(Reflect.setProperties(node, settings)) : nodeObject(node);
    }

    if (scope == null) {
        return function(...params:Array<Dynamic>):Node {
            return assignNode(Type.createInstance(NodeClass, nodeArray(params)));
        };
    } else if (factor != null) {
        factor = nodeObject(factor);
        return function(...params:Array<Dynamic>):Node {
            return assignNode(Type.createInstance(NodeClass, [scope, ...nodeArray(params), factor]));
        };
    } else {
        return function(...params:Array<Dynamic>):Node {
            return assignNode(Type.createInstance(NodeClass, [scope, ...nodeArray(params)]));
        };
    }
}

function nodeImmutable(NodeClass:Class<Node>, ...params:Array<Dynamic>):Node {
    return nodeObject(Type.createInstance(NodeClass, nodeArray(params)));
}

var nodeObjectsCacheMap:WeakMap<Dynamic, Node> = new WeakMap();
var nodeBuilderFunctionsCacheMap:WeakMap<Dynamic, Node> = new WeakMap();

function getConstNode(value:Dynamic, type:String = null):ConstNode {
    if (constNodesCacheMap.exists(value)) {
        return constNodesCacheMap.get(value);
    } else if (Reflect.hasField(value, 'isNode') && value.isNode) {
        return value;
    } else {
        return new ConstNode(value, type);
    }
}

function safeGetNodeType(node:Node):String {
    try {
        return node.getNodeType();
    } catch (_:Dynamic) {
        return null;
    }
}

function ConvertType(type:String, cacheMap:Map<Dynamic, Node> = null):Dynamic {
    return function(...params:Array<Dynamic>):Node {
        if (params.length == 0 || (!['bool', 'float', 'int', 'uint'].includes(type) && params.every(param => Std.is(param, Dynamic) == false))) {
            params = [NodeUtils.getValueFromType(type, ...params)];
        }
        if (params.length == 1 && cacheMap != null && cacheMap.exists(params[0])) {
            return nodeObject(cacheMap.get(params[0]));
        }
        if (params.length == 1) {
            var node:ConstNode = getConstNode(params[0], type);
            if (safeGetNodeType(node) == type) return nodeObject(node);
            return nodeObject(new ConvertNode(node, type));
        }
        var nodes:Array<ConstNode> = params.map(param => getConstNode(param));
        return nodeObject(new JoinNode(nodes, type));
    };
}

function defined(value:Dynamic):Dynamic {
    return value && value.value;
}

function getConstNodeType(value:Dynamic):String {
    if (value != null) {
        if (Reflect.hasField(value, 'nodeType')) return value.nodeType;
        if (Reflect.hasField(value, 'convertTo')) return value.convertTo;
        if (Std.is(value, String)) return value;
    }
    return null;
}

function tslFn(jsFunc:Dynamic):Dynamic {
    var shaderNode:Dynamic = new ShaderNode(jsFunc);
    function fn(...params:Array<Dynamic>):Node {
        var inputs:Array<Dynamic> = null;
        nodeObjects(params);
        if (params[0] != null && Reflect.hasField(params[0], 'isNode') && params[0].isNode) {
            inputs = params;
        } else {
            inputs = params[0];
        }
        return shaderNode.call(inputs);
    }
    fn.shaderNode = shaderNode;
    fn.setLayout = function(layout:Dynamic):Dynamic {
        shaderNode.setLayout(layout);
        return fn;
    };
    return fn;
}

function setCurrentStack(stack:Node):Void {
    if (ShaderNode.currentStack == stack) {
        //throw new Error('Stack already defined.');
    }
    ShaderNode.currentStack = stack;
}

function getCurrentStack():Node {
    return ShaderNode.currentStack;
}

function If(...params:Array<Dynamic>):Node {
    return ShaderNode.currentStack.if(...params);
}

function append(node:Node):Node {
    if (ShaderNode.currentStack != null) ShaderNode.currentStack.add(node);
    return node;
}

ShaderNode.addNodeElement('append', append);

// types
var color:Dynamic = new ConvertType('color');
var float:Dynamic = new ConvertType('float');
var int:Dynamic = new ConvertType('int');
var uint:Dynamic = new ConvertType('uint');
var bool:Dynamic = new ConvertType('bool');
var vec2:Dynamic = new ConvertType('vec2');
var ivec2:Dynamic = new ConvertType('ivec2');
var uvec2:Dynamic = new ConvertType('uvec2');
var bvec2:Dynamic = new ConvertType('bvec2');
var vec3:Dynamic = new ConvertType('vec3');
var ivec3:Dynamic = new ConvertType('ivec3');
var uvec3:Dynamic = new ConvertType('uvec3');
var bvec3:Dynamic = new ConvertType('bvec3');
var vec4:Dynamic = new ConvertType('vec4');
var ivec4:Dynamic = new ConvertType('ivec4');
var uvec4:Dynamic = new ConvertType('uvec4');
var bvec4:Dynamic = new ConvertType('bvec4');
var mat2:Dynamic = new ConvertType('mat2');
var imat2:Dynamic = new ConvertType('imat2');
var umat2:Dynamic = new ConvertType('umat2');
var bmat2:Dynamic = new ConvertType('bmat2');
var mat3:Dynamic = new ConvertType('mat3');
var imat3:Dynamic = new ConvertType('imat3');
var umat3:Dynamic = new ConvertType('umat3');
var bmat3:Dynamic = new ConvertType('bmat3');
var mat4:Dynamic = new ConvertType('mat4');
var imat4:Dynamic = new ConvertType('imat4');
var umat4:Dynamic = new ConvertType('umat4');
var bmat4:Dynamic = new ConvertType('bmat4');

function string(value:String = ''):Node {
    return nodeObject(new ConstNode(value, 'string'));
}

function arrayBuffer(value:Dynamic):Node {
    return nodeObject(new ConstNode(value, 'ArrayBuffer'));
}

ShaderNode.addNodeElement('toColor', color);
ShaderNode.addNodeElement('toFloat', float);
ShaderNode.addNodeElement('toInt', int);
ShaderNode.addNodeElement('toUint', uint);
ShaderNode.addNodeElement('toBool', bool);
ShaderNode.addNodeElement('toVec2', vec2);
ShaderNode.addNodeElement('toIvec2', ivec2);
ShaderNode.addNodeElement('toUvec2', uvec2);
ShaderNode.addNodeElement('toBvec2', bvec2);
ShaderNode.addNodeElement('toVec3', vec3);
ShaderNode.addNodeElement('toIvec3', ivec3);
ShaderNode.addNodeElement('toUvec3', uvec3);
ShaderNode.addNodeElement('toBvec3', bvec3);
ShaderNode.addNodeElement('toVec4', vec4);
ShaderNode.addNodeElement('toIvec4', ivec4);
ShaderNode.addNodeElement('toUvec4', uvec4);
ShaderNode.addNodeElement('toBvec4', bvec4);
ShaderNode.addNodeElement('toMat2', mat2);
ShaderNode.addNodeElement('toImat2', imat2);
ShaderNode.addNodeElement('toUmat2', umat2);
ShaderNode.addNodeElement('toBmat2', bmat2);
ShaderNode.addNodeElement('toMat3', mat3);
ShaderNode.addNodeElement('toImat3', imat3);
ShaderNode.addNodeElement('toUmat3', umat3);
ShaderNode.addNodeElement('toBmat3', bmat3);
ShaderNode.addNodeElement('toMat4', mat4);
ShaderNode.addNodeElement('toImat4', imat4);
ShaderNode.addNodeElement('toUmat4', umat4);
ShaderNode.addNodeElement('toBmat4', bmat4);

// basic nodes
function element(node:Node, channels:String):Node {
    return nodeObject(new ArrayElementNode(nodeObject(node), channels));
}

function convert(node:Node, types:String):Node {
    return nodeObject(new ConvertNode(nodeObject(node), types));
}

function split(node:Node, channels:String):Node {
    return nodeObject(new SplitNode(nodeObject(node), channels));
}

ShaderNode.addNodeElement('element', element);
ShaderNode.addNodeElement('convert', convert);