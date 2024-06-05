import LightingNode from "./LightingNode";
import CacheNode from "../core/CacheNode";
import ContextNode from "../core/ContextNode";
import PropertyNode from "../core/PropertyNode";
import CameraNode from "../accessors/CameraNode";
import NormalNode from "../accessors/NormalNode";
import PositionNode from "../accessors/PositionNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";
import ReferenceNode from "../accessors/ReferenceNode";
import AccessorsUtils from "../accessors/AccessorsUtils";
import PMREMNode from "../pmrem/PMREMNode";

class EnvironmentNode extends LightingNode {
  public envNode: Node;

  public constructor(envNode: Node = null) {
    super();
    this.envNode = envNode;
  }

  public setup(builder: Node) {
    let envNode = this.envNode;

    if (cast envNode : TextureNode) {
      let cacheEnvNode = envNodeCache.get(envNode.value);

      if (cacheEnvNode == null) {
        cacheEnvNode = PMREMNode.pmremTexture(envNode.value);

        envNodeCache.set(envNode.value, cacheEnvNode);
      }

      envNode = cacheEnvNode;
    }

    //

    let material = cast builder : MaterialNode;

    let envMap = material.envMap;
    let intensity = envMap != null ? ReferenceNode.reference('envMapIntensity', 'float', material) : ReferenceNode.reference('environmentIntensity', 'float', builder.scene); // @TODO: Add materialEnvIntensity in MaterialNode

    let useAnisotropy = material.useAnisotropy == true || material.anisotropy > 0;
    let radianceNormalView = useAnisotropy ? AccessorsUtils.transformedBentNormalView : NormalNode.transformedNormalView;

    let radiance = ContextNode.context(envNode, createRadianceContext(PropertyNode.roughness, radianceNormalView)).mul(intensity);
    let irradiance = ContextNode.context(envNode, createIrradianceContext(NormalNode.transformedNormalWorld)).mul(Math.PI).mul(intensity);

    let isolateRadiance = CacheNode.cache(radiance);

    //

    builder.context.radiance.addAssign(isolateRadiance);

    builder.context.iblIrradiance.addAssign(irradiance);

    //

    let clearcoatRadiance = builder.context.lightingModel.clearcoatRadiance;

    if (clearcoatRadiance != null) {
      let clearcoatRadianceContext = ContextNode.context(envNode, createRadianceContext(PropertyNode.clearcoatRoughness, NormalNode.transformedClearcoatNormalView)).mul(intensity);
      let isolateClearcoatRadiance = CacheNode.cache(clearcoatRadianceContext);

      clearcoatRadiance.addAssign(isolateClearcoatRadiance);
    }
  }
}

let envNodeCache: WeakMap<Node, Node> = new WeakMap();

const createRadianceContext = (roughnessNode: Node, normalViewNode: Node): ContextNode.Context => {
  let reflectVec: Node = null;

  return {
    getUV: function() {
      if (reflectVec == null) {
        reflectVec = PositionNode.positionViewDirection.negate().reflect(normalViewNode);

        // Mixing the reflection with the normal is more accurate and keeps rough objects from gathering light from behind their tangent plane.
        reflectVec = roughnessNode.mul(roughnessNode).mix(reflectVec, normalViewNode).normalize();

        reflectVec = reflectVec.transformDirection(CameraNode.cameraViewMatrix);
      }

      return reflectVec;
    },
    getTextureLevel: function() {
      return roughnessNode;
    }
  };
};

const createIrradianceContext = (normalWorldNode: Node): ContextNode.Context => {
  return {
    getUV: function() {
      return normalWorldNode;
    },
    getTextureLevel: function() {
      return ShaderNode.float(1.0);
    }
  };
};

export default EnvironmentNode;

Node.addNodeClass('EnvironmentNode', EnvironmentNode);