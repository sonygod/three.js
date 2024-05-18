package three.js.examples.jsm.renderers.common;

import three.js.WebGLCubeRenderTarget;
import three.js.Scene;
import three.js.CubeCamera;
import three.js.BoxGeometry;
import three.js.Mesh;
import three.js.BackSide;
import three.js.NoBlending;
import three.js.LinearFilter;
import three.js.LinearMipmapLinearFilter;
import nodes.utils.EquirectUVNode;
import nodes.accessors.TextureNode;
import nodes.accessors.PositionNode;
import nodes.materials.NodeMaterial;

class CubeRenderTarget extends WebGLCubeRenderTarget {

    public function new(size:Int = 1, options:Dynamic = null) {
        super(size, options);
        this.isCubeRenderTarget = true;
    }

    public function fromEquirectangularTexture(renderer:Dynamic, texture:Dynamic):CubeRenderTarget {
        var currentMinFilter:Int = texture.minFilter;
        var currentGenerateMipmaps:Bool = texture.generateMipmaps;

        texture.generateMipmaps = true;

        this.texture.type = texture.type;
        this.texture.colorSpace = texture.colorSpace;

        this.texture.generateMipmaps = texture.generateMipmaps;
        this.texture.minFilter = texture.minFilter;
        this.texture.magFilter = texture.magFilter;

        var geometry:BoxGeometry = new BoxGeometry(5, 5, 5);

        var uvNode:EquirectUVNode = EquirectUVNode.equirectUV(PositionNode.positionWorldDirection);

        var material:NodeMaterial = NodeMaterial.createNodeMaterialFromType('MeshBasicNodeMaterial');
        material.colorNode = TextureNode.TSL_Texture(texture, uvNode, 0);
        material.side = BackSide;
        material.blending = NoBlending;

        var mesh:Mesh = new Mesh(geometry, material);

        var scene:Scene = new Scene();
        scene.add(mesh);

        // Avoid blurred poles
        if (texture.minFilter == LinearMipmapLinearFilter) texture.minFilter = LinearFilter;

        var camera:CubeCamera = new CubeCamera(1, 10, this);
        camera.update(renderer, scene);

        texture.minFilter = currentMinFilter;
        texture.generateMipmaps = currentGenerateMipmaps;

        mesh.geometry.dispose();
        mesh.material.dispose();

        return this;
    }
}