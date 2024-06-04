import ContextNode from "../core/ContextNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class LightingContextNode extends ContextNode {

	public lightingModel: ShaderNode.ShaderNode | null;
	public backdropNode: ShaderNode.ShaderNode | null;
	public backdropAlphaNode: ShaderNode.ShaderNode | null;
	private _context: any;

	public function new(node: ShaderNode.ShaderNode, lightingModel: ShaderNode.ShaderNode = null, backdropNode: ShaderNode.ShaderNode = null, backdropAlphaNode: ShaderNode.ShaderNode = null) {
		super(node);
		this.lightingModel = lightingModel;
		this.backdropNode = backdropNode;
		this.backdropAlphaNode = backdropAlphaNode;
		this._context = null;
	}

	public function getContext(): Dynamic {
		var {backdropNode, backdropAlphaNode} = this;

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
			backdrop: backdropNode,
			backdropAlpha: backdropAlphaNode
		};

		return context;
	}

	public function setup(builder: any): ShaderNode.ShaderNode {
		this.context = this._context || (this._context = this.getContext());
		this.context.lightingModel = this.lightingModel || builder.context.lightingModel;

		return super.setup(builder);
	}

}

export default LightingContextNode;

export var lightingContext = ShaderNode.nodeProxy(LightingContextNode);

ShaderNode.addNodeElement("lightingContext", lightingContext);

Node.addNodeClass("LightingContextNode", LightingContextNode);