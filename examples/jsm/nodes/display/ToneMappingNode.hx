package three.js.examples.jspm.display;

import three.js.core.TempNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.js.accessors.RendererReferenceNode;
import three.js.math.MathNode;
import three.js.math.OperatorNode;

class ToneMappingNode extends TempNode {
    public var toneMapping:Dynamic;
    public var exposureNode:Node;
    public var colorNode:Node;

    public function new(toneMapping:Dynamic = NoToneMapping, exposureNode:Node = null, colorNode:Node = null) {
        super('vec3');
        this.toneMapping = toneMapping;
        this.exposureNode = exposureNode;
        this.colorNode = colorNode;
    }

    override public function getCacheKey():String {
        var cacheKey = super.getCacheKey();
        cacheKey += '{toneMapping:' + Std.string(toneMapping) + ',nodes:' + cacheKey + '}';
        return cacheKey;
    }

    override public function setup(builder:ShaderNode):Node {
        var colorNode:Node = this.colorNode != null ? this.colorNode : builder.context.color;
        var toneMapping:Dynamic = this.toneMapping;

        if (toneMapping == NoToneMapping) return colorNode;

        var toneMappingParams = { exposure: this.exposureNode, color: colorNode };
        var toneMappingNode:Node = toneMappingLib.get(toneMapping);

        var outputNode:Node = null;

        if (toneMappingNode != null) {
            outputNode = toneMappingNode(toneMappingParams);
        } else {
            trace('ToneMappingNode: Unsupported Tone Mapping configuration.', toneMapping);
            outputNode = colorNode;
        }

        return outputNode;
    }
}

class Main {
    static function main() {
        var toneMappingLib:Map<Dynamic, Node->Node> = new Map();

        toneMappingLib.set(LinearToneMapping, linearToneMappingNode);
        toneMappingLib.set(ReinhardToneMapping, reinhardToneMappingNode);
        toneMappingLib.set(CineonToneMapping, optimizedCineonToneMappingNode);
        toneMappingLib.set(ACESFilmicToneMapping, acesFilmicToneMappingNode);
        toneMappingLib.set(AgXToneMapping, agXToneMappingNode);

        ShaderNode.addNodeElement('toneMapping', toneMapping);

        ShaderNode.addNodeClass('ToneMappingNode', ToneMappingNode);
    }
}

// tone mapping nodes
function linearToneMappingNode(params:NodeObject):Node {
    return params.color.mul(params.exposure).clamp();
}

function reinhardToneMappingNode(params:NodeObject):Node {
    params.color = params.color.mul(params.exposure);
    return params.color.div(params.color.add(1.0)).clamp();
}

function optimizedCineonToneMappingNode(params:NodeObject):Node {
    params.color = params.color.mul(params.exposure);
    params.color = params.color.sub(0.004).max(0.0);
    var a = params.color.mul(params.color.mul(6.2).add(0.5));
    var b = params.color.mul(params.color.mul(6.2).add(1.7)).add(0.06);
    return a.div(b).pow(2.2);
}

function acesFilmicToneMappingNode(params:NodeObject):Node {
    var ACESInputMat:Mat3 = new Mat3(
        0.59719, 0.35458, 0.04823,
        0.07600, 0.90834, 0.01566,
        0.02840, 0.13383, 0.83777
    );

    var ACESOutputMat:Mat3 = new Mat3(
        1.60475, -0.53108, -0.07367,
        -0.10208, 1.10813, -0.00605,
        -0.00327, -0.07276, 1.07602
    );

    params.color = params.color.mul(params.exposure).div(0.6);
    params.color = ACESInputMat.mul(params.color);
    params.color = rrtoDTFit(params.color);
    params.color = ACESOutputMat.mul(params.color);
    return params.color.clamp();
}

function rrtoDTFit(color:Node):Node {
    var a = color.mul(color.add(0.0245786)).sub(0.000090537);
    var b = color.mul(color.add(0.4329510)).mul(0.983729).add(0.238081);
    return a.div(b);
}

function agXToneMappingNode(params:NodeObject):Node {
    var colortone:Vec3 = params.color.toVar();
    var AgXInsetMatrix:Mat3 = new Mat3(
        0.856627153315983, 0.137318972929847, 0.11189821299995,
        0.0951212405381588, 0.761241990602591, 0.0767994186031903,
        0.0482516061458583, 0.101439036467562, 0.811302368396859
    );

    var AgXOutsetMatrix:Mat3 = new Mat3(
        1.1271005818144368, -0.1413297634984383, -0.14132976349843826,
        -0.11060664309660323, 1.157823702216272, -0.11060664309660294,
        -0.016493938717834573, -0.016493938717834257, 1.2519364065950405
    );

    var AgxMinEv:Float = -12.47393;
    var AgxMaxEv:Float = 4.026069;

    colortone.mulAssign(params.exposure);
    colortone.assign(AgXInsetMatrix.mul(colortone));
    colortone.assign(max(colortone, 1e-10));
    colortone.assign(log2(colortone));
    colortone.assign(colortone.sub(AgxMinEv).div(AgxMaxEv - AgxMinEv));
    colortone.assign(clamp(colortone, 0.0, 1.0));
    colortone.assign(agxDefaultContrastApprox(colortone));
    colortone.assign(AgXOutsetMatrix.mul(colortone));
    colortone.assign(pow(max(Vec3(0.0), colortone), Vec3(2.2)));
    colortone.assign(LINEAR_REC2020_TO_LINEAR_SRGB.mul(colortone));
    return colortone.clamp(0.0, 1.0);
}

function agxDefaultContrastApprox(x:Vec3):Vec3 {
    var x2:Vec3 = x.mul(x);
    var x4:Vec3 = x2.mul(x2);
    return float(15.5).mul(x4.mul(x2)).sub(mul(40.14, x4.mul(x))).add(mul(31.96, x4).sub(mul(6.868, x2.mul(x))).add(mul(0.4298, x2).add(mul(0.1191, x).sub(0.00232))));
}