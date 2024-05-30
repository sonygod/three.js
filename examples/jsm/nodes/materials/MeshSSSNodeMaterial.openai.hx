package three.js.examples.jsm.nodes.materials;

import three.js.examples.jsm.nodes.accessors.NormalNode;
import three.js.examples.jsm.nodes.accessors.PositionNode;
import three.js.examples.jsm.nodes.accessors.ShaderNode;

class MeshSSSNodeMaterial extends MeshPhysicalNodeMaterial {

    public var thicknessColorNode:Null<FloatNode> = null;
    public var thicknessDistortionNode:FloatNode = new FloatNode(0.1);
    public var thicknessAmbientNode:FloatNode = new FloatNode(0.0);
    public var thicknessAttenuationNode:FloatNode = new FloatNode(0.1);
    public var thicknessPowerNode:FloatNode = new FloatNode(2.0);
    public var thicknessScaleNode:FloatNode = new FloatNode(10.0);

    public function new(parameters:Dynamic) {
        super(parameters);
    }

    public var useSSS(get, never):Bool {
        return thicknessColorNode != null;
    }

    public function setupLightingModel(builder:Dynamic):LightingModel {
        return new SSSLightingModel(useClearcoat, useSheen, useIridescence, useSSS);
    }

    public function copy(source:MeshSSSNodeMaterial):MeshSSSNodeMaterial {
        thicknessColorNode = source.thicknessColorNode;
        thicknessDistortionNode.value = source.thicknessDistortionNode.value;
        thicknessAmbientNode.value = source.thicknessAmbientNode.value;
        thicknessAttenuationNode.value = source.thicknessAttenuationNode.value;
        thicknessPowerNode.value = source.thicknessPowerNode.value;
        thicknessScaleNode.value = source.thicknessScaleNode.value;
        return super.copy(source);
    }
}

class SSSLightingModel extends PhysicalLightingModel {

    public var useSSS:Bool;

    public function new(useClearcoat:Bool, useSheen:Bool, useIridescence:Bool, useSSS:Bool) {
        super(useClearcoat, useSheen, useIridescence);
        this.useSSS = useSSS;
    }

    override public function direct(context:Dynamic, stack:Dynamic, builder:Dynamic) {
        if (useSSS) {
            var material:MeshSSSNodeMaterial = builder.material;
            var scatteringHalf = context.lightDirection.add(NormalNode.transformedNormalView.mul(material.thicknessDistortionNode)).normalize();
            var scatteringDot = FloatNode.saturate(positionViewDirection.dot(scatteringHalf.negate())).pow(material.thicknessPowerNode).mul(material.thicknessScaleNode);
            var scatteringIllu = Vec3Node.scatteringDot.add(material.thicknessAmbientNode).mul(material.thicknessColorNode);
            context.reflectedLight.directDiffuse.addAssign(scatteringIllu.mul(material.thicknessAttenuationNode.mul(context.lightColor)));
        }
        super.direct(context, stack, builder);
    }
}

registerNodeMaterial("MeshSSSNodeMaterial", MeshSSSNodeMaterial);