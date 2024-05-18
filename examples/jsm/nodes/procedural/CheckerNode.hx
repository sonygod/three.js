package three.js.examples.jsm.nodes.procedural;

import three.js.core.TempNode;
import three.js.accessors.UVNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class CheckerNode extends TempNode {
    var uvNode:UVNode;

    public function new(uvNode:UVNode = null) {
        super('float');
        this.uvNode = uvNode != null ? uvNode : UVNode.uv();
    }

    override public function setup():ShaderNode {
        return tslFn(function(inputs:Dynamic) {
            var uv:ShaderNode = inputs.uv.mul(2.0);
            var cx:ShaderNode = uv.x.floor();
            var cy:ShaderNode = uv.y.floor();
            var result:ShaderNode = cx.add(cy).mod(2.0);
            return result.sign();
        }, { uv: this.uvNode });
    }
}

var checker = nodeProxy(CheckerNode);

addNodeElement('checker', checker);
addNodeClass('CheckerNode', CheckerNode);