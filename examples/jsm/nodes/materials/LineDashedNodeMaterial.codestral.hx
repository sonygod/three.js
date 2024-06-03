import NodeMaterial;
import NodeMaterial.addNodeMaterial;
import AttributeNode.attribute;
import VaryingNode.varing;
import MaterialNode.{materialLineDashSize, materialLineGapSize, materialLineScale};
import PropertyNode.{dashSize, gapSize};
import ShaderNode.float;
import three.LineDashedMaterial;

class LineDashedNodeMaterial extends NodeMaterial {

    public var isLineDashedNodeMaterial:Bool = true;
    public var offsetNode:Dynamic = null;
    public var dashScaleNode:Dynamic = null;
    public var dashSizeNode:Dynamic = null;
    public var gapSizeNode:Dynamic = null;

    public function new(parameters:Dynamic) {
        super();

        this.lights = false;
        this.normals = false;

        this.setDefaultValues(new LineDashedMaterial());
        this.setValues(parameters);
    }

    public function setupVariants() {
        var dashScaleNode:Dynamic = this.dashScaleNode != null ? float(this.dashScaleNode) : materialLineScale;
        var dashSizeNode:Dynamic = this.dashSizeNode != null ? float(this.dashSizeNode) : materialLineDashSize;
        var gapSizeNode:Dynamic = this.dashSizeNode != null ? float(this.dashGapNode) : materialLineGapSize;

        dashSize.assign(dashSizeNode);
        gapSize.assign(gapSizeNode);

        var vLineDistance:Dynamic = varying(attribute('lineDistance').mul(dashScaleNode));
        var vLineDistanceOffset:Dynamic = this.offsetNode != null ? vLineDistance.add(this.offsetNode) : vLineDistance;

        vLineDistanceOffset.mod(dashSize.add(gapSize)).greaterThan(dashSize).discard();
    }
}

addNodeMaterial('LineDashedNodeMaterial', LineDashedNodeMaterial);