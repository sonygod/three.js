import ContextNode from '../core/ContextNode.hx';
import Node from '../core/Node.hx';
import ShaderNode from '../shadernode/ShaderNode.hx';

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

    public function setup(builder:Dynamic):Dynamic {
        if(this._context == null) this._context = this.getContext();
        this._context.lightingModel = this.lightingModel != null ? this.lightingModel : builder.context.lightingModel;

        return super.setup(builder);
    }
}

var lightingContext = ShaderNode.nodeProxy(Type.getClass<LightingContextNode>());
ShaderNode.addNodeElement("lightingContext", lightingContext);
Node.addNodeClass("LightingContextNode", Type.getClass<LightingContextNode>());