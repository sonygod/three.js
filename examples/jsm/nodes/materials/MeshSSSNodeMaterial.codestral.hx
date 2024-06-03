import js.Browser.document;
import three.nodes.NodeMaterial;
import three.nodes.accessors.NormalNode;
import three.nodes.accessors.PositionNode;
import three.nodes.functions.PhysicalLightingModel;
import three.nodes.materials.MeshPhysicalNodeMaterial;
import three.nodes.shadernode.ShaderNode;

class SSSLightingModel extends PhysicalLightingModel {

    public var useSSS:Bool;

    public function new(useClearcoat:Bool, useSheen:Bool, useIridescence:Bool, useSSS:Bool) {
        super(useClearcoat, useSheen, useIridescence);
        this.useSSS = useSSS;
    }

    public function direct(light:Dynamic, stack:Dynamic, builder:Dynamic):Void {
        if (this.useSSS) {
            var material = builder.material;

            var thicknessColorNode = material.thicknessColorNode;
            var thicknessDistortionNode = material.thicknessDistortionNode;
            var thicknessAmbientNode = material.thicknessAmbientNode;
            var thicknessAttenuationNode = material.thicknessAttenuationNode;
            var thicknessPowerNode = material.thicknessPowerNode;
            var thicknessScaleNode = material.thicknessScaleNode;

            var lightDirection = light.lightDirection;
            var lightColor = light.lightColor;
            var reflectedLight = light.reflectedLight;

            var scatteringHalf = lightDirection.add(NormalNode.transformedNormalView.mul(thicknessDistortionNode)).normalize();
            var scatteringDot = ShaderNode.float(PositionNode.positionViewDirection.dot(scatteringHalf.negate()).saturate().pow(thicknessPowerNode).mul(thicknessScaleNode));
            var scatteringIllu = ShaderNode.vec3(scatteringDot.add(thicknessAmbientNode).mul(thicknessColorNode));

            reflectedLight.directDiffuse.addAssign(scatteringIllu.mul(thicknessAttenuationNode.mul(lightColor)));
        }

        super.direct(light, stack, builder);
    }
}

class MeshSSSNodeMaterial extends MeshPhysicalNodeMaterial {

    public var thicknessColorNode:Dynamic;
    public var thicknessDistortionNode:Float;
    public var thicknessAmbientNode:Float;
    public var thicknessAttenuationNode:Float;
    public var thicknessPowerNode:Float;
    public var thicknessScaleNode:Float;

    public function new(parameters:Dynamic) {
        super(parameters);

        this.thicknessColorNode = null;
        this.thicknessDistortionNode = 0.1;
        this.thicknessAmbientNode = 0.0;
        this.thicknessAttenuationNode = 0.1;
        this.thicknessPowerNode = 2.0;
        this.thicknessScaleNode = 10.0;
    }

    public function get_useSSS():Bool {
        return this.thicknessColorNode !== null;
    }

    public function setupLightingModel(builder:Dynamic):PhysicalLightingModel {
        return new SSSLightingModel(this.useClearcoat, this.useSheen, this.useIridescence, this.useSSS);
    }

    public function copy(source:MeshSSSNodeMaterial):MeshPhysicalNodeMaterial {
        this.thicknessColorNode = source.thicknessColorNode;
        this.thicknessDistortionNode = source.thicknessDistortionNode;
        this.thicknessAmbientNode = source.thicknessAmbientNode;
        this.thicknessAttenuationNode = source.thicknessAttenuationNode;
        this.thicknessPowerNode = source.thicknessPowerNode;
        this.thicknessScaleNode = source.thicknessScaleNode;

        return super.copy(source);
    }
}

NodeMaterial.addNodeMaterial('MeshSSSNodeMaterial', MeshSSSNodeMaterial);