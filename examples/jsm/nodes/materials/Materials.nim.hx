// @TODO: We can simplify "export { default as SomeNode, other, exports } from '...'" to just "export * from '...'" if we will use only named exports

import NodeMaterial from './NodeMaterial.js';
import InstancedPointsNodeMaterial from './InstancedPointsNodeMaterial.js';
import LineBasicNodeMaterial from './LineBasicNodeMaterial.js';
import LineDashedNodeMaterial from './LineDashedNodeMaterial.js';
import Line2NodeMaterial from './Line2NodeMaterial.js';
import MeshNormalNodeMaterial from './MeshNormalNodeMaterial.js';
import MeshBasicNodeMaterial from './MeshBasicNodeMaterial.js';
import MeshLambertNodeMaterial from './MeshLambertNodeMaterial.js';
import MeshPhongNodeMaterial from './MeshPhongNodeMaterial.js';
import MeshStandardNodeMaterial from './MeshStandardNodeMaterial.js';
import MeshPhysicalNodeMaterial from './MeshPhysicalNodeMaterial.js';
import MeshSSSNodeMaterial from './MeshSSSNodeMaterial.js';
import MeshToonNodeMaterial from './MeshToonNodeMaterial.js';
import MeshMatcapNodeMaterial from './MeshMatcapNodeMaterial.js';
import PointsNodeMaterial from './PointsNodeMaterial.js';
import SpriteNodeMaterial from './SpriteNodeMaterial.js';
import ShadowNodeMaterial from './ShadowNodeMaterial.js';

export {
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