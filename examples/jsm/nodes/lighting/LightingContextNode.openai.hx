package three.js.examples.jsm.nodes.lighting;

import three.js.core.ContextNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class LightingContextNode extends ContextNode {

    public var lightingModel:Null<Float>; // assume Float, adjust type as needed
    public var backdropNode:Null<Node>;
    public var backdropAlphaNode:Null<Node>;

    private var _context:Null<Dynamic>;

    public function new(node:Node, ?lightingModel:Null<Float>, ?backdropNode:Null<Node>, ?backdropAlphaNode:Null<Node>) {
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
        this._context = this._context || (this._context = this.getContext());
        this._context.lightingModel = this.lightingModel || builder.context.lightingModel;

        super.setup(builder);
    }

    public static var lightingContext:Dynamic = nodeProxy(LightingContextNode);

    static function main() {
        Node.addElement('lightingContext', lightingContext);
        Node.addNodeClass('LightingContextNode', LightingContextNode);
    }
}