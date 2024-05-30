package three.js.examples.jm.renderers.common;

import three.js.renderers.WebGLCubeRenderTarget;
import three.js.scenes.Scene;
import three.js.cameras.CubeCamera;
import three.js.geometries.BoxGeometry;
import three.js.meshes.Mesh;
import three.js.materialsMaterial;
import three.js.constants.Side;
import three.js.constants.Blending;
import three.js.constants.Filter;
import nodes.utils.EquirectUVNode;
import nodes.accessors.TextureNode;
import nodes.accessors.PositionNode;
import nodes.materials.NodeMaterial;

class CubeRenderTarget extends WebGLCubeRenderTarget {
  public var isCubeRenderTarget:Bool = true;

  public function new(size:Int = 1, options:Dynamic = {}) {
    super(size, options);
    isCubeRenderTarget = true;
  }

  public function fromEquirectangularTexture(renderer:Dynamic, texture:Dynamic):CubeRenderTarget {
    var currentMinFilter:Dynamic = texture.minFilter;
    var currentGenerateMipmaps:Dynamic = texture.generateMipmaps;

    texture.generateMipmaps = true;

    this.texture.type = texture.type;
    this.texture.colorSpace = texture.colorSpace;

    this.texture.generateMipmaps = texture.generateMipmaps;
    this.texture.minFilter = texture.minFilter;
    this.texture.magFilter = texture.magFilter;

    var geometry:BoxGeometry = new BoxGeometry(5, 5, 5);

    var uvNode:EquirectUVNode = equirectUV(positionWorldDirection);
    var material:NodeMaterial = createNodeMaterialFromType('MeshBasicNodeMaterial');
    material.colorNode = new TSL_Texture(texture, uvNode, 0);
    material.side = Side.BACK;
    material.blending = Blending.NO_BLENDING;

    var mesh:Mesh = new Mesh(geometry, material);

    var scene:Scene = new Scene();
    scene.add(mesh);

    // Avoid blurred poles
    if (texture.minFilter == Filter.LINEAR_MIPMAP_LINEAR) texture.minFilter = Filter.LINEAR;

    var camera:CubeCamera = new CubeCamera(1, 10, this);
    camera.update(renderer, scene);

    texture.minFilter = currentMinFilter;
    texture.generateMipmaps = currentGenerateMipmaps;

    mesh.geometry.dispose();
    mesh.material.dispose();

    return this;
  }
}