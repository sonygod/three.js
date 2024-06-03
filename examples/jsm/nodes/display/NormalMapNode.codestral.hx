import js.NodeJS.require;
import js.Boot;
import js.html.Window;

using js.Boot;

import three.js.nodes.core.TempNode;
import three.js.nodes.math.OperatorNode;
import three.js.nodes.accessors.ModelNode;
import three.js.nodes.accessors.NormalNode;
import three.js.nodes.accessors.PositionNode;
import three.js.nodes.accessors.AccessorsUtils;
import three.js.nodes.accessors.UVNode;
import three.js.nodes.display.FrontFacingNode;
import three.js.nodes.core.Node;
import three.js.nodes.shadernode.ShaderNode;
import three.core.Three;

class NormalMapNode extends TempNode {

    public var node:Dynamic;
    public var scaleNode:Dynamic;
    public var normalMapType:Int;

    public function new(node:Dynamic, scaleNode:Dynamic = null) {
        super("vec3");
        this.node = node;
        this.scaleNode = scaleNode;
        this.normalMapType = Three.TangentSpaceNormalMap;
    }

    public function setup(builder:Dynamic):Dynamic {
        var normalMap = OperatorNode.sub(OperatorNode.mul(this.node, 2.0), 1.0);

        if (this.scaleNode !== null) {
            normalMap = ShaderNode.vec3(OperatorNode.mul(normalMap.xy, this.scaleNode), normalMap.z);
        }

        var outputNode = null;

        if (this.normalMapType == Three.ObjectSpaceNormalMap) {
            outputNode = OperatorNode.normalize(OperatorNode.mul(ModelNode.modelNormalMatrix, normalMap));
        } else if (this.normalMapType == Three.TangentSpaceNormalMap) {
            if (builder.hasGeometryAttribute("tangent") == true) {
                outputNode = OperatorNode.normalize(OperatorNode.mul(AccessorsUtils.TBNViewMatrix, normalMap));
            } else {
                outputNode = ShaderNode.perturbNormal2Arb({
                    eye_pos: PositionNode.positionView,
                    surf_norm: NormalNode.normalView,
                    mapN: normalMap,
                    uv: UVNode.uv()
                });
            }
        }

        return outputNode;
    }

}

@:jsRequire("./three.js/nodes/core/TempNode.js")
abstract TempNode(String) from "three.js.nodes.core.TempNode";

@:jsRequire("./three.js/nodes/math/OperatorNode.js")
abstract OperatorNode(Dynamic, Dynamic) from "three.js.nodes.math.OperatorNode";

@:jsRequire("./three.js/nodes/accessors/ModelNode.js")
abstract ModelNode from "three.js.nodes.accessors.ModelNode";

@:jsRequire("./three.js/nodes/accessors/NormalNode.js")
abstract NormalNode from "three.js.nodes.accessors.NormalNode";

@:jsRequire("./three.js/nodes/accessors/PositionNode.js")
abstract PositionNode from "three.js.nodes.accessors.PositionNode";

@:jsRequire("./three.js/nodes/accessors/AccessorsUtils.js")
abstract AccessorsUtils from "three.js.nodes.accessors.AccessorsUtils";

@:jsRequire("./three.js/nodes/accessors/UVNode.js")
abstract UVNode from "three.js.nodes.accessors.UVNode";

@:jsRequire("./three.js/nodes/display/FrontFacingNode.js")
abstract FrontFacingNode from "three.js.nodes.display.FrontFacingNode";

@:jsRequire("./three.js/nodes/core/Node.js")
abstract Node from "three.js.nodes.core.Node";

@:jsRequire("./three.js/nodes/shadernode/ShaderNode.js")
abstract ShaderNode(Dynamic) from "three.js.nodes.shadernode.ShaderNode";

@:jsRequire("three")
abstract Three from "three.core.Three";

class NormalMap {
    public static function new():Dynamic {
        return ShaderNode.nodeProxy(NormalMapNode);
    }
}

Node.addNodeElement("normalMap", NormalMap.new());
Node.addNodeClass("NormalMapNode", NormalMapNode);