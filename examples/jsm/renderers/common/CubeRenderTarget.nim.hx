import three.js.renderers.common.WebGLCubeRenderTarget;
import three.js.scenes.Scene;
import three.js.cameras.CubeCamera;
import three.js.geometries.BoxGeometry;
import three.js.objects.Mesh;
import three.js.constants.BackSide;
import three.js.constants.NoBlending;
import three.js.constants.LinearFilter;
import three.js.constants.LinearMipmapLinearFilter;
import three.js.nodes.utils.EquirectUVNode;
import three.js.nodes.accessors.TextureNode;
import three.js.nodes.accessors.PositionNode;
import three.js.nodes.materials.NodeMaterial;

// @TODO: Consider rename WebGLCubeRenderTarget to just CubeRenderTarget

class CubeRenderTarget extends WebGLCubeRenderTarget {

	public function new( size:Int = 1, options:Dynamic = {}) {

		super( size, options );

		this.isCubeRenderTarget = true;

	}

	public function fromEquirectangularTexture( renderer:Dynamic, texture:Dynamic ) {

		var currentMinFilter = texture.minFilter;
		var currentGenerateMipmaps = texture.generateMipmaps;

		texture.generateMipmaps = true;

		this.texture.type = texture.type;
		this.texture.colorSpace = texture.colorSpace;

		this.texture.generateMipmaps = texture.generateMipmaps;
		this.texture.minFilter = texture.minFilter;
		this.texture.magFilter = texture.magFilter;

		var geometry = new BoxGeometry( 5, 5, 5 );

		var uvNode = equirectUV( positionWorldDirection );

		var material = createNodeMaterialFromType( 'MeshBasicNodeMaterial' );
		material.colorNode = TSL_Texture( texture, uvNode, 0 );
		material.side = BackSide;
		material.blending = NoBlending;

		var mesh = new Mesh( geometry, material );

		var scene = new Scene();
		scene.add( mesh );

		// Avoid blurred poles
		if ( texture.minFilter == LinearMipmapLinearFilter ) texture.minFilter = LinearFilter;

		var camera = new CubeCamera( 1, 10, this );
		camera.update( renderer, scene );

		texture.minFilter = currentMinFilter;
		texture.currentGenerateMipmaps = currentGenerateMipmaps;

		mesh.geometry.dispose();
		mesh.material.dispose();

		return this;

	}

}