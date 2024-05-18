package three.js.examples.jsm.nodes.display;

import three.js.core.Node;
import three.js.core.TempNode;
import three.js.accessors.TextureNode;
import three.js.core.constants.NodeUpdateType;
import three.js.shadernode.ShaderNode;
import three.js.core.UniformNode;
import three.js.nodes.display.ViewportDepthNode;
import three.js.RenderTarget;
import three.js.Vector2;
import three.js.HalfFloatType;
import three.js.DepthTexture;
import three.js.NoToneMapping;

class PassTextureNode extends TextureNode {

    public var passNode:PassNode;
    public var texture:Texture;

    public function new(passNode:PassNode, texture:Texture) {
        super(texture);
        this.passNode = passNode;
        this.setUpdateMatrix(false);
    }

    override public function setup(builder:Dynamic):Void {
        passNode.build(builder);
        super.setup(builder);
    }

    override public function clone():PassTextureNode {
        return new PassTextureNode(passNode, texture);
    }
}

class PassNode extends TempNode {

    public var scope:String;
    public var scene:Dynamic;
    public var camera:Dynamic;
    public var pixelRatio:Float;
    public var width:Int;
    public var height:Int;
    public var renderTarget:RenderTarget;
    public var textureNode:ShaderNode;
    public var depthTextureNode:ShaderNode;
    public var depthNode:ShaderNode;
    public var viewZNode:ShaderNode;
    public var cameraNear:UniformNode;
    public var cameraFar:UniformNode;

    public function new(scope:String, scene:Dynamic, camera:Dynamic) {
        super('vec4');
        this.scope = scope;
        this.scene = scene;
        this.camera = camera;
        pixelRatio = 1;
        width = 1;
        height = 1;

        var depthTexture = new DepthTexture();
        depthTexture.isRenderTargetTexture = true;
        //depthTexture.type = FloatType;
        depthTexture.name = 'PostProcessingDepth';

        renderTarget = new RenderTarget(width * pixelRatio, height * pixelRatio, { type: HalfFloatType } );
        renderTarget.texture.name = 'PostProcessing';
        renderTarget.depthTexture = depthTexture;

        updateBeforeType = NodeUpdateType.FRAME;

        textureNode = nodeObject(new PassTextureNode(this, renderTarget.texture));
        depthTextureNode = nodeObject(new PassTextureNode(this, depthTexture));

        depthNode = null;
        viewZNode = null;
        cameraNear = uniform(0);
        cameraFar = uniform(0);

        isPassNode = true;
    }

    public function isGlobal():Bool {
        return true;
    }

    public function getTextureNode():ShaderNode {
        return textureNode;
    }

    public function getTextureDepthNode():ShaderNode {
        return depthTextureNode;
    }

    public function getViewZNode():ShaderNode {
        if (viewZNode == null) {
            var cameraNear = cameraNear;
            var cameraFar = cameraFar;
            viewZNode = perspectiveDepthToViewZ(depthTextureNode, cameraNear, cameraFar);
        }
        return viewZNode;
    }

    public function getDepthNode():ShaderNode {
        if (depthNode == null) {
            var cameraNear = cameraNear;
            var cameraFar = cameraFar;
            depthNode = viewZToOrthographicDepth(getViewZNode(), cameraNear, cameraFar);
        }
        return depthNode;
    }

    public function setup():ShaderNode {
        return scope == PassNode.COLOR ? getTextureNode() : getDepthNode();
    }

    public function updateBefore(frame:Dynamic):Void {
        var renderer = frame.renderer;
        var size = renderer.getSize(new Vector2());
        pixelRatio = renderer.getPixelRatio();

        setSize(size.width, size.height);

        var currentToneMapping = renderer.toneMapping;
        var currentToneMappingNode = renderer.toneMappingNode;
        var currentRenderTarget = renderer.getRenderTarget();

        cameraNear.value = camera.near;
        cameraFar.value = camera.far;

        renderer.toneMapping = NoToneMapping;
        renderer.toneMappingNode = null;
        renderer.setRenderTarget(renderTarget);

        renderer.render(scene, camera);

        renderer.toneMapping = currentToneMapping;
        renderer.toneMappingNode = currentToneMappingNode;
        renderer.setRenderTarget(currentRenderTarget);
    }

    public function setSize(width:Int, height:Int):Void {
        this.width = width;
        this.height = height;

        var effectiveWidth = width * pixelRatio;
        var effectiveHeight = height * pixelRatio;

        renderTarget.setSize(effectiveWidth, effectiveHeight);
    }

    public function setPixelRatio(pixelRatio:Float):Void {
        this.pixelRatio = pixelRatio;
        setSize(width, height);
    }

    public function dispose():Void {
        renderTarget.dispose();
    }
}

class PassNode {
    public static inline var COLOR:String = 'color';
    public static inline var DEPTH:String = 'depth';
}

function pass(scene:Dynamic, camera:Dynamic):ShaderNode {
    return nodeObject(new PassNode(PassNode.COLOR, scene, camera));
}

function texturePass(pass:PassNode, texture:Texture):ShaderNode {
    return nodeObject(new PassTextureNode(pass, texture));
}

function depthPass(scene:Dynamic, camera:Dynamic):ShaderNode {
    return nodeObject(new PassNode(PassNode.DEPTH, scene, camera));
}

addNodeClass('PassNode', PassNode);