import js.Browser.document;
import js.html.Console;
import three.nodes.core.TempNode;
import three.nodes.core.Node;
import three.nodes.shadernode.ShaderNode;
import three.nodes.accessors.RendererReferenceNode;
import three.nodes.math.MathNode;
import three.nodes.math.OperatorNode;

import three.NoToneMapping;
import three.LinearToneMapping;
import three.ReinhardToneMapping;
import three.CineonToneMapping;
import three.ACESFilmicToneMapping;
import three.AgXToneMapping;

class ToneMappingNode extends TempNode {
    public var toneMapping:Int;
    public var exposureNode:ShaderNode;
    public var colorNode:ShaderNode;

    public function new(toneMapping:Int = NoToneMapping, exposureNode:ShaderNode = toneMappingExposure, colorNode:ShaderNode = null) {
        super("vec3");

        this.toneMapping = toneMapping;
        this.exposureNode = exposureNode;
        this.colorNode = colorNode;
    }

    @:override
    public function getCacheKey():String {
        var cacheKey = super.getCacheKey();
        cacheKey = '{toneMapping:' + this.toneMapping + ',nodes:' + cacheKey + '}';
        return cacheKey;
    }

    @:override
    public function setup(builder:ShaderNodeBuilder):ShaderNode {
        var colorNode = this.colorNode != null ? this.colorNode : builder.context.color;
        var toneMapping = this.toneMapping;

        if (toneMapping == NoToneMapping) return colorNode;

        var toneMappingParams = { exposure: this.exposureNode, color: colorNode };
        var toneMappingNode = getToneMappingNode(toneMapping);

        var outputNode:ShaderNode = null;

        if (toneMappingNode != null) {
            outputNode = toneMappingNode(toneMappingParams);
        } else {
            Console.error("ToneMappingNode: Unsupported Tone Mapping configuration.", toneMapping);
            outputNode = colorNode;
        }

        return outputNode;
    }
}

function getToneMappingNode(toneMapping:Int):Dynamic {
    switch (toneMapping) {
        case LinearToneMapping:
            return LinearToneMappingNode;
        case ReinhardToneMapping:
            return ReinhardToneMappingNode;
        case CineonToneMapping:
            return OptimizedCineonToneMappingNode;
        case ACESFilmicToneMapping:
            return ACESFilmicToneMappingNode;
        case AgXToneMapping:
            return AGXToneMappingNode;
        default:
            return null;
    }
}

function toneMapping(mapping:Int, exposure:ShaderNode, color:ShaderNode):ShaderNode {
    return ShaderNode.nodeObject(new ToneMappingNode(mapping, ShaderNode.nodeObject(exposure), ShaderNode.nodeObject(color)));
}

function toneMappingExposure(renderer:Renderer, type:String):RendererReferenceNode {
    return RendererReferenceNode.rendererReference(renderer, "toneMappingExposure", type);
}

ShaderNode.addNodeElement("toneMapping", function(color:ShaderNode, mapping:Int, exposure:ShaderNode):ShaderNode {
    return toneMapping(mapping, exposure, color);
});

Node.addNodeClass("ToneMappingNode", ToneMappingNode);