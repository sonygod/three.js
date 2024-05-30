import three.examples.jsm.nodes.core.TempNode;
import three.examples.jsm.nodes.core.Node;
import three.examples.jsm.nodes.shadernode.ShaderNode;
import three.examples.jsm.nodes.accessors.RendererReferenceNode;
import three.examples.jsm.nodes.math.MathNode;
import three.examples.jsm.nodes.math.OperatorNode;

import three.NoToneMapping;
import three.LinearToneMapping;
import three.ReinhardToneMapping;
import three.CineonToneMapping;
import three.ACESFilmicToneMapping;
import three.AgXToneMapping;

class ToneMappingNode extends TempNode {

	public function new(toneMapping:Dynamic = NoToneMapping, exposureNode:Dynamic = toneMappingExposure, colorNode:Dynamic = null) {
		super('vec3');

		this.toneMapping = toneMapping;
		this.exposureNode = exposureNode;
		this.colorNode = colorNode;
	}

	public function getCacheKey():String {
		var cacheKey = super.getCacheKey();
		cacheKey = '{toneMapping:' + this.toneMapping + ',nodes:' + cacheKey + '}';
		return cacheKey;
	}

	public function setup(builder:Dynamic):Dynamic {
		var colorNode = this.colorNode || builder.context.color;
		var toneMapping = this.toneMapping;

		if (toneMapping === NoToneMapping) return colorNode;

		var toneMappingParams = { exposure: this.exposureNode, color: colorNode };
		var toneMappingNode = toneMappingLib[toneMapping];

		var outputNode = null;

		if (toneMappingNode) {
			outputNode = toneMappingNode(toneMappingParams);
		} else {
			trace('ToneMappingNode: Unsupported Tone Mapping configuration.', toneMapping);
			outputNode = colorNode;
		}

		return outputNode;
	}
}

static function toneMapping(mapping:Dynamic, exposure:Dynamic, color:Dynamic):Dynamic {
	return new Node.nodeObject(new ToneMappingNode(mapping, Node.nodeObject(exposure), Node.nodeObject(color)));
}

static var toneMappingExposure = RendererReferenceNode.rendererReference('toneMappingExposure', 'float');

Node.addNodeElement('toneMapping', (color:Dynamic, mapping:Dynamic, exposure:Dynamic) -> toneMapping(mapping, exposure, color));

Node.addNodeClass('ToneMappingNode', ToneMappingNode);