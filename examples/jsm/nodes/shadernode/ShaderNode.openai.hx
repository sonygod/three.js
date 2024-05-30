package three.js.examples.jsm.nodes.shader;

import Node;
import ArrayElementNode;
import ConvertNode;
import JoinNode;
import SplitNode;
import SetNode;
import ConstNode;
import NodeUtils;

class ShaderNode {
    static var currentStack:Null<Node>;

    static function addNodeElement(name:String, nodeElement:Node->Void) {
        if (NodeElements.exists(name)) {
            console.warn('Redefinition of node element $name');
            return;
        }
        if (!Reflect.isFunction(nodeElement)) {
            throw new Error('Node element $name is not a function');
        }
        NodeElements.set(name, nodeElement);
    }

    static function parseSwizzle(props:String):String {
        return props.replace~/r|s/g -> 'x'.replace~/g|t/g -> 'y'.replace~/b|p/g -> 'z'.replace~/a|q/g -> 'w';
    }

    static var shaderNodeHandler = {
        setup: function(nodeClosure:Node->Array<Node>, params:Array<Dynamic>) {
            var inputs:Array<Node> = params.shift();
            return nodeClosure(nodeObjects(inputs), params);
        },
        get: function(node:Node, prop:String, nodeObj:Node) {
            if (Reflect.hasField(node, prop)) {
                return Reflect.field(node, prop);
            }
            if (NodeElements.exists(prop)) {
                var nodeElement:Node->Void = NodeElements.get(prop);
                return if (node.isStackNode) (params:Array<Dynamic>) -> nodeObject(nodeObj.add(nodeElement(params))); else (params:Array<Dynamic>) -> nodeElement(nodeObj, params);
            }
            // ...
        },
        set: function(node:Node, prop:String, value:Dynamic, nodeObj:Node) {
            if (Reflect.hasField(node, prop)) {
                return Reflect.setField(node, prop, value);
            }
            // ...
        }
    };

    static var NodeElements:Map<String, Node->Void> = new Map();
    static var nodeObjectsCacheMap:WeakMap<Node, Node> = new WeakMap();
    static var nodeBuilderFunctionsCacheMap:WeakMap<Dynamic, WeakMap<Node, Node>> = new WeakMap();

    static function ShaderNodeObject(obj:Dynamic, altType:Null<String> = null):Node {
        var type:String = NodeUtils.getValueType(obj);
        // ...
    }

    static function ShaderNodeObjects(objects:Dynamic, altType:Null<String> = null):Dynamic {
        // ...
    }

    static function ShaderNodeArray(array:Array<Dynamic>, altType:Null<String> = null):Array<Node> {
        // ...
    }

    static function ShaderNodeProxy(NodeClass:Class<Node>, scope:Null<Node> = null, factor:Null<Node> = null, settings:Null<Dynamic> = null):Node->Void {
        // ...
    }

    static function ShaderNodeImmutable(NodeClass:Class<Node>, params:Array<Dynamic>):Node {
        // ...
    }
}

class ShaderCallNodeInternal extends Node {
    var shaderNode:ShaderNodeInternal;
    var inputNodes:Array<Node>;

    public function new(shaderNode:ShaderNodeInternal, inputNodes:Array<Node>) {
        super();
        this.shaderNode = shaderNode;
        this.inputNodes = inputNodes;
    }

    // ...
}

class ShaderNodeInternal extends Node {
    var jsFunc:Dynamic;
    var layout:Dynamic;

    public function new(jsFunc:Dynamic) {
        super();
        this.jsFunc = jsFunc;
        this.layout = null;
    }

    // ...
}

// ...