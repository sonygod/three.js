package three.js.examples.jsm.nodes.materials;

import three.js.examples.jsm.nodes.NodeMaterial;
import three.js.examples.jsm.accessors.NormalNode;
import three.js.examples.jsm.accessors.PositionNode;
import three.js.examples.jsm.functions.PhysicalLightingModel;
import three.js.examples.jsm.nodes.materials.MeshPhysicalNodeMaterial;
import three.js.examples.jsm.shadernode.ShaderNode;

class SSSLightingModel extends PhysicalLightingModel {
    public var useSSS:Bool;

    public function new(useClearcoat:Bool, useSheen:Bool, useIridescence:Bool, useSSS:Bool) {
        super(useClearcoat, useSheen, useIridescence);
        this.useSSS = useSSS;
    }

    override public function direct(args:{ lightDirection:Vec3, lightColor:Vec3, reflectedLight:Vec3 }, stack:Array<Any>, builder:Any) {
        if (useSSS) {
            var material:MeshSSSNodeMaterial = builder.material;
            var thicknessColorNode:ShaderNode = material.thicknessColorNode;
            var thicknessDistortionNode:Float = material.thicknessDistortionNode;
            var thicknessAmbientNode:Float = material.thicknessAmbientNode;
            var thicknessAttenuationNode:Float = material.thicknessAttenuationNode;
            var thicknessPowerNode:Float = material.thicknessPowerNode;
            var thicknessScaleNode:Float = material.thicknessScaleNode;

            var scatteringHalf:Vec3 = args.lightDirection.add(NormalNode.transformedNormalView.mul(thicknessDistortionNode)).normalize();
            var scatteringDot:Float = Math.max(0, PositionNode.positionViewDirection.dot(scatteringHalf.negate())).pow(thicknessPowerNode) * thicknessScaleNode;
            var scatteringIllu:Vec3 = new Vec3(scatteringDot + thicknessAmbientNode).mul(thicknessColorNode);

            args.reflectedLight.directDiffuse.addAssign(scatteringIllu.mul(thicknessAttenuationNode * args.lightColor));
        }
        super.direct(args, stack, builder);
    }
}

class MeshSSSNodeMaterial extends MeshPhysicalNodeMaterial {
    public var thicknessColorNode:ShaderNode;
    public var thicknessDistortionNode:Float;
    public var thicknessAmbientNode:Float;
    public var thicknessAttenuationNode:Float;
    public var thicknessPowerNode:Float;
    public var thicknessScaleNode:Float;

    public function new(parameters:Any) {
        super(parameters);
        thicknessDistortionNode = 0.1;
        thicknessAmbientNode = 0.0;
        thicknessAttenuationNode = 0.1;
        thicknessPowerNode = 2.0;
        thicknessScaleNode = 10.0;
    }

    public function get_useSSS():Bool {
        return thicknessColorNode != null;
    }

    override public function setupLightingModel(builder:Any):PhysicalLightingModel {
        return new SSSLightingModel(useClearcoat, useSheen, useIridescence, get_useSSS());
    }

    override public function copy(source:MeshSSSNodeMaterial):MeshSSSNodeMaterial {
        thicknessColorNode = source.thicknessColorNode;
        thicknessDistortionNode = source.thicknessDistortionNode;
        thicknessAmbientNode = source.thicknessAmbientNode;
        thicknessAttenuationNode = source.thicknessAttenuationNode;
        thicknessPowerNode = source.thicknessPowerNode;
        thicknessScaleNode = source.thicknessScaleNode;
        return super.copy(source);
    }
}

NodeMaterial.addNodeMaterial('MeshSSSNodeMaterial', MeshSSSNodeMaterial);