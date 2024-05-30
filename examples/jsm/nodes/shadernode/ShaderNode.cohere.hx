import Node from '../core/Node.hx';
import ArrayElementNode from '../utils/ArrayElementNode.hx';
import ConvertNode from '../utils/ConvertNode.hx';
import JoinNode from '../utils/JoinNode.hx';
import SplitNode from '../utils/SplitNode.hx';
import SetNode from '../utils/SetNode.hx';
import ConstNode from '../core/ConstNode.hx';
import { getValueFromType, getValueType } from '../core/NodeUtils.hx';

var currentStack = null;

var NodeElements = new Map(); // @TODO: Currently only a few nodes are added, probably also add others

function addNodeElement(name: String, nodeElement: Function) {
    if (NodeElements.exists(name)) {
        trace("Redefinition of node element " + name);
        return;
    }
    if (typeof nodeElement != 'function') {
        throw new Error("Node element " + name + " is not a function");
    }
    NodeElements.set(name, nodeElement);
}

function parseSwizzle(props: String) {
    return props.replace(/r|s/g, 'x').replace(/g|t/g, 'y').replace(/b|p/g, 'z').replace(/a|q/g, 'w');
}

var shaderNodeHandler = {
    setup: function(NodeClosure, params) {
        var inputs = params.shift();
        return NodeClosure(nodeObjects(inputs), ...params);
    },
    get: function(node, prop, nodeObj) {
        if (typeof prop == 'string' && node.__fields__[prop] == null) {
            if (node.isStackNode != true && prop == 'assign') {
                return function(...params) {
                    currentStack.assign(nodeObj, ...params);
                    return nodeObj;
                };
            } else if (NodeElements.exists(prop)) {
                var nodeElement = NodeElements.get(prop);
                return node.isStackNode ? function(...params) {
                    return nodeObj.add(nodeElement(...params));
                } : function(...params) {
                    return nodeElement(nodeObj, ...params);
                };
            } else if (prop == 'self') {
                return node;
            } else if (prop.endsWith('Assign') && NodeElements.exists(prop.slice(0, -'Assign'.length))) {
                var nodeElement = NodeElements.get(prop.slice(0, -'Assign'.length));
                return node.isStackNode ? function(...params) {
                    return nodeObj.assign(params[0], nodeElement(...params));
                } : function(...params) {
                    return nodeObj.assign(nodeElement(nodeObj, ...params));
                };
            } else if (/(^[xyzwrgbastpq]{1,4}$)/.match(prop) != null) {
                // accessing properties ( swizzle )
                prop = parseSwizzle(prop);
                return nodeObject(new SplitNode(nodeObj, prop));
            } else if (/(^set[XYZWRGBASTPQ]{1,4}$)/.match(prop) != null) {
                // set properties ( swizzle )
                prop = parseSwizzle(prop.slice(3).toLowerCase());
                // sort to xyzw sequence
                prop = prop.split('').sort().join('');
                return function(value) {
                    return nodeObject(new SetNode(node, prop, value));
                };
            } else if (prop == 'width' || prop == 'height' || prop == 'depth') {
                // accessing property
                if (prop == 'width') prop = 'x';
                else if (prop == 'height') prop = 'y';
                else if (prop == 'depth') prop = 'z';
                return nodeObject(new SplitNode(node, prop));
            } else if (/(^\d+$)/.match(prop) != null) {
                // accessing array
                return nodeObject(new ArrayElementNode(nodeObj, new ConstNode(Std.parseInt(prop), 'uint')));
            }
        }
        return Reflect.field(node, prop, nodeObj);
    },
    set: function(node, prop, value, nodeObj) {
        if (typeof prop == 'string' && node.__fields__[prop] == null) {
            // setting properties
            if (/(^[xyzwrgbastpq]{1,4}$)/.match(prop) != null || prop == 'width' || prop == 'height' || prop == 'depth' || /(^\d+$)/.match(prop) != null) {
                nodeObj[prop].assign(value);
                return true;
            }
        }
        return Reflect.setField(node, prop, value, nodeObj);
    }
};

var nodeObjectsCacheMap = new WeakMap();
var nodeBuilderFunctionsCacheMap = new WeakMap();

function ShaderNodeObject(obj, altType = null) {
    var type = getValueType(obj);
    if (type == 'node') {
        var nodeObject = nodeObjectsCacheMap.get(obj);
        if (nodeObject == null) {
            nodeObject = new Proxy(obj, shaderNodeHandler);
            nodeObjectsCacheMap.set(obj, nodeObject);
            nodeObjectsCacheMap.set(nodeObject, nodeObject);
        }
        return nodeObject;
    } else if ((altType == null && (type == 'float' || type == 'boolean')) || (type != null && type != 'shader' && type != 'string')) {
        return nodeObject(getConstNode(obj, altType));
    } else if (type == 'shader') {
        return tslFn(obj);
    }
    return obj;
}

function ShaderNodeObjects(objects, altType = null) {
    var key;
    for (key in objects) {
        objects[key] = nodeObject(objects[key], altType);
    }
    return objects;
}

function ShaderNodeArray(array, altType = null) {
    var len = array.length;
    var i = 0;
    while (i < len) {
        array[i] = nodeObject(array[i], altType);
        i++;
    }
    return array;
}

function ShaderNodeProxy(NodeClass, scope = null, factor = null, settings = null) {
    function assignNode(node) {
        return nodeObject(settings != null ? $extend(node, settings) : node);
    }
    if (scope == null) {
        return function(...params) {
            return assignNode(new NodeClass(...nodeArray(params)));
        };
    } else if (factor != null) {
        factor = nodeObject(factor);
        return function(...params) {
            return assignNode(new NodeClass(scope, ...nodeArray(params), factor));
        };
    } else {
        return function(...params) {
            return assignNode(new NodeClass(scope, ...nodeArray(params)));
        };
    }
}

function ShaderNodeImmutable(NodeClass, ...params) {
    return nodeObject(new NodeClass(...nodeArray(params)));
}

class ShaderCallNodeInternal extends Node {
    var shaderNode: ShaderNodeInternal;
    var inputNodes: Array<Node>;
    function new(shaderNode, inputNodes) {
        this.shaderNode = shaderNode;
        this.inputNodes = inputNodes;
    }
    function getNodeType(builder) {
        var properties = builder.getNodeProperties(this);
        if (properties.outputNode == null) {
            properties.outputNode = this.setupOutput(builder);
        }
        return properties.outputNode.getNodeType(builder);
    }
    function call(builder) {
        var { shaderNode, inputNodes } = this;
        if (shaderNode.layout != null) {
            var functionNodesCacheMap = nodeBuilderFunctionsCacheMap.get(builder.constructor);
            if (functionNodesCacheMap == null) {
                functionNodesCacheMap = new WeakMap();
                nodeBuilderFunctionsCacheMap.set(builder.constructor, functionNodesCacheMap);
            }
            var functionNode = functionNodesCacheMap.get(shaderNode);
            if (functionNode == null) {
                functionNode = nodeObject(builder.buildFunctionNode(shaderNode));
                functionNodesCacheMap.set(shaderNode, functionNode);
            }
            if (builder.currentFunctionNode != null) {
                builder.currentFunctionNode.includes.push(functionNode);
            }
            return nodeObject(functionNode.call(inputNodes));
        }
        var outputNode = inputNodes != null ? shaderNode.jsFunc(inputNodes, builder.stack, builder) : shaderNode.jsFunc(builder.stack, builder);
        return nodeObject(outputNode);
    }
    function setup(builder) {
        var { outputNode } = builder.getNodeProperties(this);
        return outputNode != null ? outputNode : this.setupOutput(builder);
    }
    function setupOutput(builder) {
        builder.addStack();
        builder.stack.outputNode = this.call(builder);
        return builder.removeStack();
    }
    function generate(builder, output) {
        var { outputNode } = builder.getNodeProperties(this);
        if (outputNode == null) {
            // TSL: It's recommended to use `tslFn` in setup() pass.
            return this.call(builder).build(builder, output);
        }
        return super.generate(builder, output);
    }
}

class ShaderNodeInternal extends Node {
    var jsFunc: Function;
    var layout: Dynamic;
    function new(jsFunc) {
        this.jsFunc = jsFunc;
        this.layout = null;
    }
    function get_isArrayInput() {
        return /^\(\s?\[/.match(this.jsFunc.toString()) != null;
    }
    function setLayout(layout) {
        this.layout = layout;
        return this;
    }
    function call(inputs = null) {
        nodeObjects(inputs);
        return nodeObject(new ShaderCallNodeInternal(this, inputs));
    }
    function setup() {
        return this.call();
    }
}

var bools = [false, true];
var uints = [0, 1, 2, 3];
var ints = [-1, -2];
var floats = [0.5, 1.5, 1 / 3, 1e-6, 1e6, Math.PI, Math.PI * 2, 1 / Math.PI, 2 / Math.PI, 1 / (Math.PI * 2), Math.PI / 2];

var boolsCacheMap = new Map();
var _g = 0;
while (_g < bools.length) {
    var bool = bools[_g];
    ++_g;
    boolsCacheMap.set(bool, new ConstNode(bool));
}

var uintsCacheMap = new Map();
var _g1 = 0;
while (_g1 < uints.length) {
    var uint = uints[_g1];
    ++_g1;
    uintsCacheMap.set(uint, new ConstNode(uint, 'uint'));
}

var intsCacheMap = new Map();
var _g2 = 0;
while (_g2 < uints.length) {
    var uint1 = uints[_g2];
    ++_g2;
    intsCacheMap.set(uint1, new ConstNode(uint1, 'int'));
}

var _g3 = 0;
while (_g3 < ints.length) {
    var int = ints[_g3];
    ++_g3;
    intsCacheMap.set(int, new ConstNode(int, 'int'));
}

var floatsCacheMap = new Map();
var _g4 = 0;
while (_g4 < floats.length) {
    var float = floats[_g4];
    ++_g4;
    floatsCacheMap.set(float, new ConstNode(float));
}

var _g5 = 0;
while (_g5 < floats.length) {
    var float1 = floats[_g5];
    ++_g5;
    floatsCacheMap.set(-float1, new ConstNode(-float1));
}

var cacheMaps = {
    bool: boolsCacheMap,
    uint: uintsCacheMap,
    ints: intsCacheMap,
    float: floatsCacheMap
};

var constNodesCacheMap = new Map();
var _g6 = 0;
while (_g6 < bools.length) {
    var bool1 = bools[_g6];
    ++_g6;
    constNodesCacheMap.set(bool1, boolsCacheMap.get(bool1));
}

var _g7 = 0;
while (_g7 < floats.length) {
    var float2 = floats[_g7];
    ++_g7;
    constNodesCacheMap.set(float2, floatsCacheMap.get(float2));
}

function getConstNode(value, type = null) {
    if (constNodesCacheMap.exists(value)) {
        return constNodesCacheMap.get(value);
    } else if (value.isNode) {
        return value;
    } else {
        return new ConstNode(value, type);
    }
}

function safeGetNodeType(node) {
    try {
        return node.getNodeType();
    } catch (_) {
        return null;
    }
}

function ConvertType(type, cacheMap = null) {
    return function(...params) {
        if (params.length == 0 || (!['bool', 'float', 'int', 'uint'].includes(type) && params.every(param => typeof param != 'object'))) {
            params = [getValueFromType(type, ...params)];
        }
        if (params.length == 1 && cacheMap != null && cacheMap.exists(params[0])) {
            return nodeObject(cacheMap.get(params[0]));
        }
        if (params.length == 1) {
            var node = getConstNode(params[0], type);
            if (safeGetNodeType(node) == type) return nodeObject(node);
            return nodeObject(new ConvertNode(node, type));
        }
        var nodes = params.map(param => getConstNode(param));
        return nodeObject(new JoinNode(nodes, type));
    };
}

// exports

function defined(value) {
    return value && value.value;
}

// utils

function getConstNodeType(value) {
    if (value != null) {
        return value.nodeType != null ? value.nodeType : value.convertTo != null ? value.convertTo : typeof value == 'string' ? value : null;
    } else {
        return null;
    }
}

// shader node base

function ShaderNode(jsFunc) {
    return new Proxy(new ShaderNodeInternal(jsFunc), shaderNodeHandler);
}

function nodeObject(val, altType = null) {
    return ShaderNodeObject(val, altType);
}
function nodeObjects(val, altType = null) {
    return ShaderNodeObjects(val, altType);
}
function nodeArray(val, altType = null) {
    return ShaderNodeArray(val, altType);
}
function nodeProxy(...params) {
    return ShaderNodeProxy(...params);
}
function nodeImmutable(...params) {
    return ShaderNodeImmutable(...params);
}

function tslFn(jsFunc) {
    var shaderNode = new ShaderNode(jsFunc);
    function fn(...params) {
        var inputs;
        nodeObjects(params);
        if (params[0] != null && params[0].isNode) {
            inputs = params;
        } else {
            inputs = params[0];
        }
        return shaderNode.call(inputs);
    }
    fn.shaderNode = shaderNode;
    fn.setLayout = function(layout) {
        shaderNode.setLayout(layout);
        return fn;
    };
    return fn;
}

addNodeClass('ShaderNode', ShaderNode);

//

function setCurrentStack(stack) {
    if (currentStack == stack) {
        //throw new Error('Stack already defined.');
    }
    currentStack = stack;
}

function getCurrentStack() {
    return currentStack;
}

function If(...params) {
    return currentStack.if(...params);
}

function append(node) {
    if (currentStack != null) currentStack.add(node);
    return node;
}

addNodeElement('append', append);

// types
// @TODO: Maybe export from ConstNode.js?

var color = new ConvertType('color');

var float1 = new ConvertType('float', cacheMaps.float);
var int1 = new ConvertType('int', cacheMaps.ints);
var uint1 = new ConvertType('uint', cacheMaps.uint);
var bool1 = new ConvertType('bool', cacheMaps.bool);

var vec2 = new ConvertType('vec2');
var ivec2 = new ConvertType('ivec2');
var uvec2 = new ConvertType('uvec2');
var bvec2 = new ConvertType('bvec2');

var vec3 = new ConvertType('vec3');
var ivec3 = new ConvertType('ivec3');
var uvec3 = new ConvertType('uvec3');
var bvec3 = new ConvertType('bvec3');

var vec4 = new ConvertType('vec4');
var ivec4 = new ConvertType('ivec4');
var uvec4 = new ConvertType('uvec4');
var bvec4 = new ConvertType('bvec4');

var mat2 = new ConvertType('mat2');
var imat2 = new ConvertType('imat2');
var umat2 = new ConvertType('umat2');
var bmat2 = new ConvertType('bmat2');

var mat3 = new ConvertType('mat
var imat3 = new ConvertType('imat3');
var umat3 = new ConvertType('umat3');
var bmat3 = new ConvertType('bmat3');

var mat4 = new ConvertType('mat4');
var imat4 = new ConvertType('imat4');
var umat4 = new ConvertType('umat4');
var bmat4 = new ConvertType('bmat4');

function string(value = '') {
    return nodeObject(new ConstNode(value, 'string'));
}
function arrayBuffer(value) {
    return nodeObject(new ConstNode(value, 'ArrayBuffer'));
}

addNodeElement('toColor', color);
addNodeElement('toFloat', float1);
addNodeElement('toInt', int1);
addNodeElement('toUint', uint1);
addNodeElement('toBool', bool1);
addNodeElement('toVec2', vec2);
addNodeElement('toIvec2', ivec2);
addNodeElement('toUvec2', uvec2);
addNodeElement('toBvec2', bvec2);
addNodeElement('toVec3', vec3);
addNodeElement('toIvec3', ivec3);
addNodeElement('toUvec3', uvec3);
addNodeElement('toBvec3', bvec3);
addNodeElement('toVec4', vec4);
addNodeElement('toIvec4', ivec4);
addNodeElement('toUvec4', uvec4);
addNodeElement('toBvec4', bvec4);
addNodeElement('toMat2', mat2);
addNodeElement('toImat2', imat2);
addNodeElement('toUmat2', umat2);
addNodeElement('toBmat2', bmat2);
addNodeElement('toMat3', mat3);
addNodeElement('toImat3', imat3);
addNodeElement('toUmat3', umat3);
addNodeElement('toBmat3', bmat3);
addNodeElement('toMat4', mat4);
addNodeElement('toImat4', imat4);
addNodeElement('toUmat4', umat4);
addNodeElement('toBmat4', bmat4);

// basic nodes
// HACK - we cannot export them from the corresponding files because of the cyclic dependency
var element = nodeProxy(ArrayElementNode);
function convert(node, types) {
    return nodeObject(new ConvertNode(nodeObject(node), types));
}
function split(node, channels) {
    return nodeObject(new SplitNode(nodeObject(node), channels));
}

addNodeElement('element', element);
addNodeElement('convert', convert);