import NodeMaterial from "./NodeMaterial";
import UniformNode from "../core/UniformNode";
import CameraNode from "../accessors/CameraNode";
import MaterialNode from "../accessors/MaterialNode";
import ModelNode from "../accessors/ModelNode";
import PositionNode from "../accessors/PositionNode";
import ShaderNode from "../shadernode/ShaderNode";
import SpriteMaterial from "three";

class SpriteNodeMaterial extends NodeMaterial {

  public isSpriteNodeMaterial:Bool = true;
  public lights:Bool = false;
  public normals:Bool = false;
  public positionNode:ShaderNode = null;
  public rotationNode:ShaderNode = null;
  public scaleNode:ShaderNode = null;

  public function new(parameters:Dynamic = null) {
    super();

    this.setDefaultValues(cast SpriteMaterial.default);
    this.setValues(parameters);
  }

  public function setupPosition(context:Dynamic):Dynamic {
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

    if (context.object.center != null && context.object.center.isVector2) {
      alignedPosition = alignedPosition.sub(UniformNode.uniform(context.object.center).sub(0.5));
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

    return cast super.copy(source);
  }

}

export default SpriteNodeMaterial;

NodeMaterial.addNodeMaterial("SpriteNodeMaterial", SpriteNodeMaterial);