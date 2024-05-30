package three.nodes.materials;

import three.nodes.NodeMaterial;
import three.accessors.MaterialNode;
import three.core.AttributeNode;
import three.core.VaryingNode;
import three.core.PropertyNode;
import three.shadernode.ShaderNode;
import three LineDashedMaterial;

class LineDashedNodeMaterial extends NodeMaterial {

    public var isLineDashedNodeMaterial:Bool = true;

    public var lights:Bool = false;
    public var normals:Bool = false;

    private var offsetNode:Null<ShaderNode> = null;
    private var dashScaleNode:Null<ShaderNode> = null;
    private var dashSizeNode:Null<ShaderNode> = null;
    private var gapSizeNode:Null<ShaderNode> = null;

    public function new(parameters:Dynamic = null) {
        super();
        setDefaultValues(new LineDashedMaterial());
        setValues(parameters);
    }

    override function setupVariants() {
        var offsetNode:ShaderNode = this.offsetNode != null ? this.offsetNode : null;
        var dashScaleNode:ShaderNode = this.dashScaleNode != null ? ShaderNode.float(this.dashScaleNode) : MaterialNode.materialLineScale;
        var dashSizeNode:ShaderNode = this.dashSizeNode != null ? ShaderNode.float(this.dashSizeNode) : MaterialNode.materialLineDashSize;
        var gapSizeNode:ShaderNode = this.gapSizeNode != null ? ShaderNode.float(this.gapSizeNode) : MaterialNode.materialLineGapSize;

        PropertyNode.dashSize.assign(dashSizeNode);
        PropertyNode.gapSize.assign(gapSizeNode);

        var vLineDistance:VaryingNode = VaryingNode.varying(AttributeNode.attribute("lineDistance").mul(dashScaleNode));
        var vLineDistanceOffset:VaryingNode = offsetNode != null ? vLineDistance.add(offsetNode) : vLineDistance;

        vLineDistanceOffset.mod(dashSizeNode.add(gapSizeNode)).greaterThan(dashSizeNode).discard();
    }

}

NodeMaterial.addNodeMaterial("LineDashedNodeMaterial", LineDashedNodeMaterial);