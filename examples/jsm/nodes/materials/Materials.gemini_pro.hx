// @TODO: We can simplify "export { default as SomeNode, other, exports } from '...'" to just "export * from '...'" if we will use only named exports

export { default as NodeMaterial, addNodeMaterial, createNodeMaterialFromType } from './NodeMaterial.hx';
export { default as InstancedPointsNodeMaterial } from './InstancedPointsNodeMaterial.hx';
export { default as LineBasicNodeMaterial } from './LineBasicNodeMaterial.hx';
export { default as LineDashedNodeMaterial } from './LineDashedNodeMaterial.hx';
export { default as Line2NodeMaterial } from './Line2NodeMaterial.hx';
export { default as MeshNormalNodeMaterial } from './MeshNormalNodeMaterial.hx';
export { default as MeshBasicNodeMaterial } from './MeshBasicNodeMaterial.hx';
export { default as MeshLambertNodeMaterial } from './MeshLambertNodeMaterial.hx';
export { default as MeshPhongNodeMaterial } from './MeshPhongNodeMaterial.hx';
export { default as MeshStandardNodeMaterial } from './MeshStandardNodeMaterial.hx';
export { default as MeshPhysicalNodeMaterial } from './MeshPhysicalNodeMaterial.hx';
export { default as MeshSSSNodeMaterial } from './MeshSSSNodeMaterial.hx';
export { default as MeshToonNodeMaterial } from './MeshToonNodeMaterial.hx';
export { default as MeshMatcapNodeMaterial } from './MeshMatcapNodeMaterial.hx';
export { default as PointsNodeMaterial } from './PointsNodeMaterial.hx';
export { default as SpriteNodeMaterial } from './SpriteNodeMaterial.hx';
export { default as ShadowNodeMaterial } from './ShadowNodeMaterial.hx';