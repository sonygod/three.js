import ContextNode from "../core/ContextNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class LightingContextNode extends ContextNode {

	public var lightingModel:ShaderNode.Node;
	public var backdropNode:ShaderNode.Node;
	public var backdropAlphaNode:ShaderNode.Node;

	public var _context:Dynamic;

	public function new(node:ShaderNode.Node, lightingModel:ShaderNode.Node = null, backdropNode:ShaderNode.Node = null, backdropAlphaNode:ShaderNode.Node = null) {
		super(node);
		this.lightingModel = lightingModel;
		this.backdropNode = backdropNode;
		this.backdropAlphaNode = backdropAlphaNode;
	}

	public function getContext():Dynamic {
		var directDiffuse = ShaderNode.vec3().temp("directDiffuse");
		var directSpecular = ShaderNode.vec3().temp("directSpecular");
		var indirectDiffuse = ShaderNode.vec3().temp("indirectDiffuse");
		var indirectSpecular = ShaderNode.vec3().temp("indirectSpecular");

		var reflectedLight = {
			directDiffuse: directDiffuse,
			directSpecular: directSpecular,
			indirectDiffuse: indirectDiffuse,
			indirectSpecular: indirectSpecular
		};

		var context = {
			radiance: ShaderNode.vec3().temp("radiance"),
			irradiance: ShaderNode.vec3().temp("irradiance"),
			iblIrradiance: ShaderNode.vec3().temp("iblIrradiance"),
			ambientOcclusion: ShaderNode.float(1).temp("ambientOcclusion"),
			reflectedLight: reflectedLight,
			backdrop: this.backdropNode,
			backdropAlpha: this.backdropAlphaNode
		};

		return context;
	}

	public function setup(builder:ShaderNode.Builder):ShaderNode.Builder {
		this.context = this._context != null ? this._context : this.getContext();
		this.context.lightingModel = this.lightingModel != null ? this.lightingModel : builder.context.lightingModel;

		return super.setup(builder);
	}
}

class LightingContextNodeProxy extends ShaderNode.NodeProxy {
	public function new() {
		super(LightingContextNode);
	}
}

var lightingContext = new LightingContextNodeProxy();
ShaderNode.addNodeElement("lightingContext", lightingContext);
Node.addNodeClass("LightingContextNode", LightingContextNode);