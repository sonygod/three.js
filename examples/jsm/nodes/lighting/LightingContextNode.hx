package three.js.examples.jsm.nodes.lighting;

import three.js.core.ContextNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

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
            backdrop: backdropNode,
            backdropAlpha: backdropAlphaNode
        };

        return context;
    }

    public function setup(builder:Dynamic):Void {
        this._context = this._context != null ? this._context : (this._context = this.getContext());
        this._context.lightingModel = this.lightingModel != null ? this.lightingModel : builder.context.lightingModel;

        super.setup(builder);
    }
}

// Register the node
nodeProxy('LightingContextNode', LightingContextNode);
addNodeElement('lightingContext', nodeProxy('LightingContextNode'));
addNodeClass('LightingContextNode', LightingContextNode);