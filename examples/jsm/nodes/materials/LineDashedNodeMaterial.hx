package three.js.examples.jsm.nodes.materials;

import NodeMaterial;
import AttributeNode;
import VaryingNode;
import MaterialNode;
import PropertyNode;
import ShaderNode;
import three.LineDashedMaterial;

class LineDashedNodeMaterial extends NodeMaterial {
    public var isLineDashedNodeMaterial:Bool = true;
    public var lights:Bool = false;
    public var normals:Bool = false;
    public var offsetNode:Null<FloatNode> = null;
    public var dashScaleNode:Null<FloatNode> = null;
    public var dashSizeNode:Null<FloatNode> = null;
    public var gapSizeNode:Null<FloatNode> = null;

    public function new(parameters:Dynamic) {
        super();
        setDefaultValues(new LineDashedMaterial());
        setValues(parameters);
    }

    public function setupVariants():Void {
        var offsetNode = this.offsetNode;
        var dashScaleNode = (this.dashScaleNode != null) ? new FloatNode(this.dashScaleNode) : MaterialNode.materialLineScale;
        var dashSizeNode = (this.dashSizeNode != null) ? new FloatNode(this.dashSizeNode) : MaterialNode.materialLineDashSize;
        var gapSizeNode = (this.gapSizeNode != null) ? new FloatNode(this.gapSizeNode) : MaterialNode.materialLineGapSize;

        PropertyNode.dashSize.assign(dashSizeNode);
        PropertyNode.gapSize.assign(gapSizeNode);

        var vLineDistance = new VaryingNode(AttributeNode.attribute("lineDistance").mul(dashScaleNode));
        var vLineDistanceOffset = (offsetNode != null) ? vLineDistance.add(offsetNode) : vLineDistance;

        vLineDistanceOffset.mod(dashSizeNode.add(gapSizeNode)).greaterThan(dashSizeNode).discard();
    }

    static public function main() {
        NodeMaterial.addNodeMaterial("LineDashedNodeMaterial", LineDashedNodeMaterial);
    }
}