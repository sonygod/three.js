import three.extras.CubeCamera;
import three.geometries.BoxGeometry;
import three.materials.MeshBasicMaterial;
import three.math.Color;
import three.objects.Mesh;
import three.renderers.WebGLRenderer;
import three.scenes.Scene;
import three.textures.Texture;
import three.textures.WebGLCubeRenderTarget;

import three.constants.Blending;
import three.constants.Side;
import three.constants.TextureFilter;

class CubeRenderTarget extends WebGLCubeRenderTarget {

    public function new(size:Float = 1, options:Dynamic = null) {
        super(size, options);
        this.isCubeRenderTarget = true;
    }

    public function fromEquirectangularTexture(renderer:WebGLRenderer, texture:Texture):CubeRenderTarget {

        var currentMinFilter = texture.minFilter;
        var currentGenerateMipmaps = texture.generateMipmaps;

        texture.generateMipmaps = true;

        this.texture.type = texture.type;
        this.texture.colorSpace = texture.colorSpace;

        this.texture.generateMipmaps = texture.generateMipmaps;
        this.texture.minFilter = texture.minFilter;
        this.texture.magFilter = texture.magFilter;

        var geometry = new BoxGeometry(5, 5, 5);

        var material = new MeshBasicMaterial();
        material.color = Color.fromHex(0xffffff);
        material.side = Side.BackSide;
        material.blending = Blending.NoBlending;

        var mesh = new Mesh(geometry, material);

        var scene = new Scene();
        scene.add(mesh);

        // Avoid blurred poles
        if (texture.minFilter == TextureFilter.LinearMipmapLinearFilter) texture.minFilter = TextureFilter.LinearFilter;

        var camera = new CubeCamera(1, 10, this);
        camera.update(renderer, scene);

        texture.minFilter = currentMinFilter;
        texture.generateMipmaps = currentGenerateMipmaps;

        mesh.geometry.dispose();
        mesh.material.dispose();

        return this;

    }

}