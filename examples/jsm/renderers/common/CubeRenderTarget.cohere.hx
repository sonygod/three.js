import js.three.WebGLCubeRenderTarget;
import js.three.Scene;
import js.three.CubeCamera;
import js.three.BoxGeometry;
import js.three.Mesh;
import js.three.BackSide;
import js.three.NoBlending;
import js.three.LinearFilter;
import js.three.LinearMipmapLinearFilter;

import js.threelabs.nodes.utils.EquirectUVNode.equirectUV;
import js.threelabs.nodes.accessors.TextureNode.TSL_Texture;
import js.threelabs.nodes.accessors.PositionNode.positionWorldDirection;
import jsMultiplier.nodes.materials.NodeMaterial.createNodeMaterialFromType;

class CubeRenderTarget extends WebGLCubeRenderTarget {
    public var isCubeRenderTarget:Bool = true;

    public function new(size:Int = 1, ?options:Dynamic) {
        super(size, options);
    }

    public function fromEquirectangularTexture(renderer, texture) : CubeRenderTarget {
        var currentMinFilter = texture.minFilter;
        var currentGenerateMipmaps = texture.generateMipmaps;

        texture.generateMipmaps = true;

        this.texture.type = texture.type;
        this.texture.colorSpace = texture.colorSpace;

        this.texture.generateMipmaps = texture.generateMipmaps;
        this.texture.minFilter = texture.minFilter;
        this.texture.magFilter = texture.magFilter;

        var geometry = new BoxGeometry(5, 5, 5);
        var uvNode = equirectUV(positionWorldDirection());
        var material = createNodeMaterialFromType('MeshBasicNodeMaterial');
        material.colorNode = TSL_Texture(texture, uvNode, 0);
        material.side = BackSide.BackSide;
        material.blending = NoBlending.NoBlending;

        var mesh = new Mesh(geometry, material);
        var scene = new Scene();
        scene.add(mesh);

        if (texture.minFilter == LinearMipmapLinearFilter.LinearMipmapLinearFilter) {
            texture.minFilter = LinearFilter.LinearFilter;
        }

        var camera = new CubeCamera(1, 10, this);
        camera.update(renderer, scene);

        texture.minFilter = currentMinFilter;
        texture.currentGenerateMipmaps = currentGenerateMipmaps;

        mesh.geometry.dispose();
        mesh.material.dispose();

        return this;
    }
}