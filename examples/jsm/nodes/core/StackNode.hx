package three.js.examples.jsm.nodes.core;

import Node;
import math.CondNode;
import shadernode.ShaderNode;

class StackNode extends Node {
    public var nodes:Array<Node>;
    public var outputNode:Node;
    public var parent:Node;
    public var _currentCond:CondNode;

    public function new(?parent:Node) {
        super();
        nodes = new Array<Node>();
        outputNode = null;
        this.parent = parent;
        _currentCond = null;
        isStackNode = true;
    }

    public function getNodeType(builder:Dynamic):String {
        return if (outputNode != null) outputNode.getNodeType(builder) else 'void';
    }

    public function add(node:Node):StackNode {
        nodes.push(node);
        return this;
    }

    public function if(boolNode:Dynamic, method:Dynamic):StackNode {
        var methodNode = new ShaderNode(method);
        _currentCond = CondNode.cond(boolNode, methodNode);
        return add(_currentCond);
    }

    public function elseif(boolNode:Dynamic, method:Dynamic):StackNode {
        var methodNode = new ShaderNode(method);
        var ifNode = CondNode.cond(boolNode, methodNode);
        _currentCond.elseNode = ifNode;
        _currentCond = ifNode;
        return this;
    }

    public function else(method:Dynamic):StackNode {
        _currentCond.elseNode = new ShaderNode(method);
        return this;
    }

    public function build(builder:Dynamic, params:Array<Dynamic>):Node {
        var previousStack = getCurrentStack();
        setCurrentStack(this);
        for (node in nodes) {
            node.build(builder, 'void');
        }
        setCurrentStack(previousStack);
        return if (outputNode != null) outputNode.build(builder, params) else super.build(builder, params);
    }
}

#elseif macro
class StackNodeMacro {
    macro public static function build():Void {
        haxe.macro.Context.defineModule('three.js.examples.jsm.nodes.core.StackNode');
    }
}

#end

extern class StackNode extends Node {
    public static var stack:Node;
}

Node.addClass('StackNode', StackNode);
StackNode.stack = nodeProxy(StackNode);