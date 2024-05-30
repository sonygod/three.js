import three.WebGLCubeRenderTarget;
import three.Scene;
import three.CubeCamera;
import three.BoxGeometry;
import three.Mesh;
import three.BackSide;
import three.NoBlending;
import three.LinearFilter;
import three.LinearMipmapLinearFilter;
import three.nodes.utils.EquirectUVNode;
import three.nodes.accessors.TextureNode;
import three.nodes.accessors.PositionNode;
import three.nodes.materials.NodeMaterial;

class CubeRenderTarget extends WebGLCubeRenderTarget {

	public function new(size:Int = 1, options:Dynamic = {}) {
		super(size, options);
		this.isCubeRenderTarget = true;
	}

	public function fromEquirectangularTexture(renderer:Dynamic, texture:Dynamic):CubeRenderTarget {
		var currentMinFilter = texture.minFilter;
		var currentGenerateMipmaps = texture.generateMipmaps;

		texture.generateMipmaps = true;

		this.texture.type = texture.type;
		this.texture.colorSpace = texture.colorSpace;

		this.texture.generateMipmaps = texture.generateMipmaps;
		this.texture.minFilter = texture.minFilter;
		this.texture.magFilter = texture.magFilter;

		var geometry = new BoxGeometry(5, 5, 5);

		var uvNode = EquirectUVNode.equirectUV(PositionNode.positionWorldDirection);

		var material = NodeMaterial.createNodeMaterialFromType('MeshBasicNodeMaterial');
		material.colorNode = TextureNode.texture(texture, uvNode, 0);
		material.side = BackSide;
		material.blending = NoBlending;

		var mesh = new Mesh(geometry, material);

		var scene = new Scene();
		scene.add(mesh);

		if (texture.minFilter == LinearMipmapLinearFilter) texture.minFilter = LinearFilter;

		var camera = new CubeCamera(1, 10, this);
		camera.update(renderer, scene);

		texture.minFilter = currentMinFilter;
		texture.currentGenerateMipmaps = currentGenerateMipmaps;

		mesh.geometry.dispose();
		mesh.material.dispose();

		return this;
	}
}