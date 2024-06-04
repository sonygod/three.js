// @TODO: We can simplify "export { default as SomeNode, other, exports } from '...'" to just "export * from '...'" if we will use only named exports

import NodeMaterial from "./NodeMaterial";
import InstancedPointsNodeMaterial from "./InstancedPointsNodeMaterial";
import LineBasicNodeMaterial from "./LineBasicNodeMaterial";
import LineDashedNodeMaterial from "./LineDashedNodeMaterial";
import Line2NodeMaterial from "./Line2NodeMaterial";
import MeshNormalNodeMaterial from "./MeshNormalNodeMaterial";
import MeshBasicNodeMaterial from "./MeshBasicNodeMaterial";
import MeshLambertNodeMaterial from "./MeshLambertNodeMaterial";
import MeshPhongNodeMaterial from "./MeshPhongNodeMaterial";
import MeshStandardNodeMaterial from "./MeshStandardNodeMaterial";
import MeshPhysicalNodeMaterial from "./MeshPhysicalNodeMaterial";
import MeshSSSNodeMaterial from "./MeshSSSNodeMaterial";
import MeshToonNodeMaterial from "./MeshToonNodeMaterial";
import MeshMatcapNodeMaterial from "./MeshMatcapNodeMaterial";
import PointsNodeMaterial from "./PointsNodeMaterial";
import SpriteNodeMaterial from "./SpriteNodeMaterial";
import ShadowNodeMaterial from "./ShadowNodeMaterial";

class NodeMaterials {
  public static addNodeMaterial = NodeMaterial.addNodeMaterial;
  public static createNodeMaterialFromType = NodeMaterial.createNodeMaterialFromType;
}

export {
  NodeMaterials,
  NodeMaterial,
  InstancedPointsNodeMaterial,
  LineBasicNodeMaterial,
  LineDashedNodeMaterial,
  Line2NodeMaterial,
  MeshNormalNodeMaterial,
  MeshBasicNodeMaterial,
  MeshLambertNodeMaterial,
  MeshPhongNodeMaterial,
  MeshStandardNodeMaterial,
  MeshPhysicalNodeMaterial,
  MeshSSSNodeMaterial,
  MeshToonNodeMaterial,
  MeshMatcapNodeMaterial,
  PointsNodeMaterial,
  SpriteNodeMaterial,
  ShadowNodeMaterial
};