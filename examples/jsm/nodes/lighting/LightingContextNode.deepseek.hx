import ContextNode from '../core/ContextNode.js';
import { addNodeClass } from '../core/Node.js';
import { addNodeElement, nodeProxy, float, vec3 } from '../shadernode/ShaderNode.js';

class LightingContextNode extends ContextNode {

	public function new(node:Dynamic, lightingModel:Dynamic = null, backdropNode:Dynamic = null, backdropAlphaNode:Dynamic = null) {
		super(node);

		this.lightingModel = lightingModel;
		this.backdropNode = backdropNode;
		this.backdropAlphaNode = backdropAlphaNode;

		this._context = null;
	}

	public function getContext():Dynamic {
		var directDiffuse = vec3().temp('directDiffuse');
		var directSpecular = vec3().temp('directSpecular');
		var indirectDiffuse = vec3().temp('indirectDiffuse');
		var indirectSpecular = vec3().temp('indirectSpecular');

		var reflectedLight = {
			directDiffuse: directDiffuse,
			directSpecular: directSpecular,
			indirectDiffuse: indirectDiffuse,
			indirectSpecular: indirectSpecular
		};

		var context = {
			radiance: vec3().temp('radiance'),
			irradiance: vec3().temp('irradiance'),
			iblIrradiance: vec3().temp('iblIrradiance'),
			ambientOcclusion: float(1).temp('ambientOcclusion'),
			reflectedLight: reflectedLight,
			backdrop: this.backdropNode,
			backdropAlpha: this.backdropAlphaNode
		};

		return context;
	}

	public function setup(builder:Dynamic):Dynamic {
		this.context = this._context || (this._context = this.getContext());
		this.context.lightingModel = this.lightingModel || builder.context.lightingModel;

		return super.setup(builder);
	}
}

var lightingContext = nodeProxy(LightingContextNode);

addNodeElement('lightingContext', lightingContext);

addNodeClass('LightingContextNode', LightingContextNode);