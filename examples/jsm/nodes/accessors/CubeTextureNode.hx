package three.js.examples.jm.nodes.accessors;

import three.js.examples.jm.nodes.TextureNode;
import three.js.examples.jm.nodes.ReflectVectorNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.WebGPUCoordinateSystem;

class CubeTextureNode extends TextureNode {
    public var isCubeTextureNode:Bool;

    public function new(value, uvNode:Null<TextureNode> = null, levelNode:Null<TextureNode> = null) {
        super(value, uvNode, levelNode);
        this.isCubeTextureNode = true;
    }

    override public function getInputType(builder:Dynamic):String {
        return 'cubeTexture';
    }

    public function getDefaultUV():ReflectVectorNode {
        return ReflectVectorNode.getInstance();
    }

    public function setUpdateMatrix(updateMatrix:Dynamic):Void { } // Ignore .updateMatrix for CubeTextureNode

    public function setupUV(builder:Dynamic, uvNode:TextureNode):Vec3 {
        var texture = this.value;
        if (builder.renderer.coordinateSystem == WebGPUCoordinateSystem || !texture.isRenderTargetTexture) {
            return new Vec3(-uvNode.x, uvNode.y, uvNode.z);
        } else {
            return uvNode;
        }
    }

    public function generateUV(builder:Dynamic, cubeUV:Dynamic):Vec3 {
        return cubeUV.build(builder, 'vec3');
    }
}

class CubeTextureNodeProxy {
    public static function getInstance():CubeTextureNode {
        return new CubeTextureNode(null, null, null);
    }
}

ShaderNode.addNodeElement('cubeTexture', CubeTextureNodeProxy.getInstance());
Node.addClass('CubeTextureNode', CubeTextureNode);