import NodeMaterial from "./NodeMaterial";
import UniformNode from "../core/UniformNode";
import CameraNode from "../accessors/CameraNode";
import MaterialNode from "../accessors/MaterialNode";
import ModelNode from "../accessors/ModelNode";
import PositionNode from "../accessors/PositionNode";
import ShaderNode from "../shadernode/ShaderNode";
import SpriteMaterial from "three";

class SpriteNodeMaterial extends NodeMaterial {
    public var isSpriteNodeMaterial:Bool;
    public var lights:Bool;
    public var normals:Bool;
    public var positionNode:Dynamic;
    public var rotationNode:Dynamic;
    public var scaleNode:Dynamic;

    public function new(parameters:Dynamic = null) {
        super();
        this.isSpriteNodeMaterial = true;
        this.lights = false;
        this.normals = false;
        this.positionNode = null;
        this.rotationNode = null;
        this.scaleNode = null;
        this.setDefaultValues(new SpriteMaterial());
        this.setValues(parameters);
    }

    public function setupPosition(object:Dynamic, context:Dynamic):Dynamic {
        // < VERTEX STAGE >
        var positionNode = this.positionNode;
        var rotationNode = this.rotationNode;
        var scaleNode = this.scaleNode;

        var vertex = PositionNode.positionLocal;
        var mvPosition = ModelNode.modelViewMatrix.mul(ShaderNode.vec3(positionNode == null ? 0 : positionNode));
        var scale = ShaderNode.vec2(ModelNode.modelWorldMatrix[0].xyz.length(), ModelNode.modelWorldMatrix[1].xyz.length());

        if (scaleNode != null) {
            scale = scale.mul(scaleNode);
        }
        var alignedPosition = vertex.xy;
        if (object.center != null && object.center.isVector2) {
            alignedPosition = alignedPosition.sub(UniformNode.uniform(object.center).sub(0.5));
        }
        alignedPosition = alignedPosition.mul(scale);
        var rotation = ShaderNode.float(rotationNode == null ? MaterialNode.materialRotation : rotationNode);
        var rotatedPosition = alignedPosition.rotate(rotation);
        mvPosition = ShaderNode.vec4(mvPosition.xy.add(rotatedPosition), mvPosition.zw);
        var modelViewProjection = CameraNode.cameraProjectionMatrix.mul(mvPosition);
        context.vertex = vertex;
        return modelViewProjection;
    }

    public function copy(source:SpriteNodeMaterial):SpriteNodeMaterial {
        this.positionNode = source.positionNode;
        this.rotationNode = source.rotationNode;
        this.scaleNode = source.scaleNode;
        return super.copy(source);
    }
}

export default SpriteNodeMaterial;

NodeMaterial.addNodeMaterial("SpriteNodeMaterial", SpriteNodeMaterial);