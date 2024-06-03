import three.examples.jsm.nodes.accessors.TextureNode;
import three.examples.jsm.nodes.accessors.ReflectVectorNode;
import three.examples.jsm.core.Node;
import three.examples.jsm.shadernode.ShaderNode;
import three.WebGPUCoordinateSystem;

class CubeTextureNode extends TextureNode {

    public function new(value:Dynamic, uvNode:Dynamic = null, levelNode:Dynamic = null) {
        super(value, uvNode, levelNode);
        this.isCubeTextureNode = true;
    }

    public function getInputType():String {
        return 'cubeTexture';
    }

    public function getDefaultUV():Dynamic {
        return ReflectVectorNode.reflectVector;
    }

    public function setUpdateMatrix(updateMatrix:Dynamic) { } // Ignore .updateMatrix for CubeTextureNode

    public function setupUV(builder:Dynamic, uvNode:Dynamic):Dynamic {
        var texture = this.value;
        if (builder.renderer.coordinateSystem === WebGPUCoordinateSystem || !texture.isRenderTargetTexture) {
            return ShaderNode.vec3(uvNode.x.negate(), uvNode.yz);
        } else {
            return uvNode;
        }
    }

    public function generateUV(builder:Dynamic, cubeUV:Dynamic):Dynamic {
        return cubeUV.build(builder, 'vec3');
    }
}

var cubeTexture = ShaderNode.nodeProxy(CubeTextureNode);
ShaderNode.addNodeElement('cubeTexture', cubeTexture);
Node.addNodeClass('CubeTextureNode', CubeTextureNode);