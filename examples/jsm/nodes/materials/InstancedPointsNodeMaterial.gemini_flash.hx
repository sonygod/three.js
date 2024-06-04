import NodeMaterial from "./NodeMaterial";
import VaryingNode from "../core/VaryingNode";
import PropertyNode from "../core/PropertyNode";
import AttributeNode from "../core/AttributeNode";
import CameraNode from "../accessors/CameraNode";
import MaterialNode from "../accessors/MaterialNode";
import ModelNode from "../accessors/ModelNode";
import PositionNode from "../accessors/PositionNode";
import MathNode from "../math/MathNode";
import ShaderNode from "../shadernode/ShaderNode";
import UVNode from "../accessors/UVNode";
import ViewportNode from "../display/ViewportNode";

import PointsMaterial from "three";

class InstancedPointsNodeMaterial extends NodeMaterial {
  public normals:Bool = false;
  public lights:Bool = false;
  public useAlphaToCoverage:Bool = true;
  public useColor:Bool = false;
  public pointWidth:Float = 1;
  public pointColorNode:ShaderNode.ShaderNode? = null;

  public constructor(params:Dynamic = {}) {
    super();
    this.setDefaultValues(new PointsMaterial());
    this.useColor = params.vertexColors != null;
    this.setupShaders();
    this.setValues(params);
  }

  public setupShaders() {
    const useAlphaToCoverage:Bool = this.useAlphaToCoverage;
    const useColor:Bool = this.useColor;

    this.vertexNode = ShaderNode.tslFn(() => {
      VaryingNode.varying(ShaderNode.vec2(), "vUv").assign(UVNode.uv());
      const instancePosition = AttributeNode.attribute("instancePosition");
      const mvPos = PropertyNode.property("vec4", "mvPos");
      mvPos.assign(ModelNode.modelViewMatrix.mul(ShaderNode.vec4(instancePosition, 1)));
      const aspect = ViewportNode.viewport.z.div(ViewportNode.viewport.w);
      const clipPos = CameraNode.cameraProjectionMatrix.mul(mvPos);
      const offset = PropertyNode.property("vec2", "offset");
      offset.assign(PositionNode.positionGeometry.xy);
      offset.assign(offset.mul(MaterialNode.materialPointWidth));
      offset.assign(offset.div(ViewportNode.viewport.z));
      offset.y.assign(offset.y.mul(aspect));
      offset.assign(offset.mul(clipPos.w));
      clipPos.assign(clipPos.add(ShaderNode.vec4(offset, 0, 0)));
      return clipPos;
    })();

    this.fragmentNode = ShaderNode.tslFn(() => {
      const vUv = VaryingNode.varying(ShaderNode.vec2(), "vUv");
      const alpha = PropertyNode.property("float", "alpha");
      alpha.assign(1);
      const a = vUv.x;
      const b = vUv.y;
      const len2 = a.mul(a).add(b.mul(b));
      if (useAlphaToCoverage) {
        const dlen = PropertyNode.property("float", "dlen");
        dlen.assign(len2.fwidth());
        alpha.assign(MathNode.smoothstep(dlen.oneMinus(), dlen.add(1), len2).oneMinus());
      } else {
        len2.greaterThan(1).discard();
      }
      let pointColorNode:ShaderNode.ShaderNode;
      if (this.pointColorNode != null) {
        pointColorNode = this.pointColorNode;
      } else {
        if (useColor) {
          const instanceColor = AttributeNode.attribute("instanceColor");
          pointColorNode = instanceColor.mul(MaterialNode.materialColor);
        } else {
          pointColorNode = MaterialNode.materialColor;
        }
      }
      return ShaderNode.vec4(pointColorNode, alpha);
    })();

    this.needsUpdate = true;
  }

  public get alphaToCoverage():Bool {
    return this.useAlphaToCoverage;
  }

  public set alphaToCoverage(value:Bool) {
    if (this.useAlphaToCoverage != value) {
      this.useAlphaToCoverage = value;
      this.setupShaders();
    }
  }
}

export default InstancedPointsNodeMaterial;

NodeMaterial.addNodeMaterial("InstancedPointsNodeMaterial", InstancedPointsNodeMaterial);