import js.NodeMaterial;
import js.NormalNode.transformedNormalView;
import js.PositionNode.positionViewDirection;
import js.functions.PhysicalLightingModel;
import js.MeshPhysicalNodeMaterial;
import js.ShaderNode.{ float, vec3 };

class SSSLightingModel extends PhysicalLightingModel {
    public function new(useClearcoat:Bool, useSheen:Bool, useIridescence:Bool, useSSS:Bool) {
        super(useClearcoat, useSheen, useIridescence);
        this.useSSS = useSSS;
    }

    public function direct(lightDirection:Float, lightColor:Float, reflectedLight:ReflectedLight, stack:Stack, builder:Builder) {
        if (this.useSSS) {
            var material = builder.material;
            var thicknessColorNode = material.thicknessColorNode;
            var thicknessDistortionNode = material.thicknessDistortionNode;
            var thicknessAmbientNode = material.thicknessAmbientNode;
            var thicknessAttenuationNode = material.thicknessAttenuationNode;
            var thicknessPowerNode = material.thicknessPowerNode;
            var thicknessScaleNode = material.thicknessScaleNode;

            var scatteringHalf = lightDirection + transformedNormalView * thicknessDistortionNode;
            var scatteringDot = float(positionViewDirection.dot(scatteringHalf.negate()).saturate().pow(thicknessPowerNode) * thicknessScaleNode);
            var scatteringIllu = vec3(scatteringDot + thicknessAmbientNode) * thicknessColorNode;

            reflectedLight.directDiffuse += scatteringIllu * (thicknessAttenuationNode * lightColor);
        }

        super.direct(lightDirection, lightColor, reflectedLight, stack, builder);
    }
}

class MeshSSSNodeMaterial extends MeshPhysicalNodeMaterial {
    public var thicknessColorNode:Float;
    public var thicknessDistortionNode:Float = 0.1;
    public var thicknessAmbientNode:Float = 0.0;
    public var thicknessAttenuationNode:Float = 0.1;
    public var thicknessPowerNode:Float = 2.0;
    public var thicknessScaleNode:Float = 10.0;

    public function new(parameters:Dynamic) {
        super(parameters);
    }

    public function get_useSSS():Bool {
        return thicknessColorNode != null;
    }

    public function setupLightingModel():PhysicalLightingModel {
        return new SSSLightingModel(this.useClearcoat, this.useSheen, this.useIridescence, this.useSSS);
    }

    public function copy(source:MeshSSSNodeMaterial):Void {
        this.thicknessColorNode = source.thicknessColorNode;
        this.thicknessDistortionNode = source.thicknessDistortionNode;
        this.thicknessAmbientNode = source.thicknessAmbientNode;
        this.thicknessAttenuationNode = source.thicknessAttenuationNode;
        this.thicknessPowerNode = source.thicknessPowerNode;
        this.thicknessScaleNode = source.thicknessScaleNode;

        super.copy(source);
    }
}

@:jsRequire(MeshSSSNodeMaterial.addNodeMaterial, 'MeshSSSNodeMaterial', 'MeshSSSNodeMaterial')
class MeshSSSNodeMaterial {
    public static function addNodeMaterial(name:String, material:MeshSSSNodeMaterial):Void {
        // Add the material to the NodeMaterial class
    }
}