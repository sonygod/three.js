import ContextNode from '../core/ContextNode.js';
import { addNodeClass } from '../core/Node.js';
import { addNodeElement, nodeProxy, float, vec3 } from '../shadernode/ShaderNode.js';

class LightingContextNode extends ContextNode {

	public var lightingModel:Dynamic;
	public var backdropNode:Dynamic;
	public var backdropAlphaNode:Dynamic;

	private var _context:Dynamic;

	public function new(node:Dynamic, lightingModel:Dynamic = null, backdropNode:Dynamic = null, backdropAlphaNode:Dynamic = null) {

		super(node);

		this.lightingModel = lightingModel;
		this.backdropNode = backdropNode;
		this.backdropAlphaNode = backdropAlphaNode;

		this._context = null;

	}

	public function getContext():Dynamic {

		var backdropNode = this.backdropNode;
		var backdropAlphaNode = this.backdropAlphaNode;

		var directDiffuse = vec3().temp( 'directDiffuse' ),
			directSpecular = vec3().temp( 'directSpecular' ),
			indirectDiffuse = vec3().temp( 'indirectDiffuse' ),
			indirectSpecular = vec3().temp( 'indirectSpecular' );

		var reflectedLight = {
			directDiffuse,
			directSpecular,
			indirectDiffuse,
			indirectSpecular
		};

		var context = {
			radiance: vec3().temp( 'radiance' ),
			irradiance: vec3().temp( 'irradiance' ),
			iblIrradiance: vec3().temp( 'iblIrradiance' ),
			ambientOcclusion: float( 1 ).temp( 'ambientOcclusion' ),
			reflectedLight,
			backdrop: backdropNode,
			backdropAlpha: backdropAlphaNode
		};

		return context;

	}

	public function setup(builder:Dynamic):Dynamic {

		this._context = this._context || ( this._context = this.getContext() );
		this._context.lightingModel = this.lightingModel || builder.context.lightingModel;

		return super.setup(builder);

	}

}

export default LightingContextNode;

export var lightingContext = nodeProxy( LightingContextNode );

addNodeElement( 'lightingContext', lightingContext );

addNodeClass( 'LightingContextNode', LightingContextNode );