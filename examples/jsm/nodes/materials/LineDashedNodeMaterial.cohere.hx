import NodeMaterial from './NodeMaterial.hx';
import { attribute, varying } from '../core/AttributeNode.hx';
import { materialLineDashSize, materialLineGapSize, materialLineScale } from '../accessors/MaterialNode.hx';
import { dashSize, gapSize } from '../core/PropertyNode.hx';
import { float } from '../shadernode/ShaderNode.hx';

class LineDashedNodeMaterial extends NodeMaterial {
    public isLineDashedNodeMaterial: Bool;
    public lights: Bool;
    public normals: Bool;
    public offsetNode: Float;
    public dashScaleNode: Float;
    public dashSizeNode: Float;
    public gapSizeNode: Float;

    public function new(parameters: Dynamic) {
        super();
        this.isLineDashedNodeMaterial = true;
        this.lights = false;
        this.normals = false;
        this.setDefaultValues(defaultValues);
        this.offsetNode = null;
        this.dashScaleNode = null;
        this.dashSizeNode = null;
        this.gapSizeNode = null;
        this.setValues(parameters);
    }

    public function setupVariants() {
        var offsetNode = this.offsetNode;
        var dashScaleNode = this.dashScaleNode != null ? float(this.dashScaleNode) : materialLineScale;
        var dashSizeNode = this.dashSizeNode != null ? float(this.dashSizeNode) : materialLineDashSize;
        var gapSizeNode = this.dashSizeNode != null ? float(this.dashGapNode) : materialLineGapSize;

        dashSize.assign(dashSizeNode);
        gapSize.assign(gapSizeNode);

        var vLineDistance = varying(attribute('lineDistance').mul(dashScaleNode));
        var vLineDistanceOffset = offsetNode != null ? vLineDistance.add(offsetNode) : vLineDistance;

        vLineDistanceOffset.mod(dashSize.add(gapSize)).greaterThan(dashSize).discard();
    }
}

var defaultValues = new LineDashedMaterial();

static function addNodeMaterial(name: String, material: NodeMaterial) {
    // ... add node material logic here
}

addNodeMaterial('LineDashedNodeMaterial', LineDashedNodeMaterial);

class LineDashedMaterial {
    // ... LineDashedMaterial implementation here
}