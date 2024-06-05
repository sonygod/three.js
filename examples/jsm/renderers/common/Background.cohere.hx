import DataMap from './DataMap.hx';
import Color4 from './Color4.hx';
import { Mesh, SphereGeometry, BackSide, LinearSRGBColorSpace } from 'three';
import { $vec4, context, normalWorld, backgroundBlurriness, backgroundIntensity, NodeMaterial, modelViewProjection } from '../../nodes/Nodes.hx';

var _clearColor = new Color4();

class Background extends DataMap {

	public function new( renderer, nodes ) {

		super();

		this.renderer = renderer;
		this.nodes = nodes;

	}

	public function update( scene, renderList, renderContext ) {

		var renderer = this.renderer;
		var background = this.nodes.getBackgroundNode( scene ) ?? scene.background;

		var forceClear = false;

		if ( background == null ) {

			// no background settings, use clear color configuration from the renderer

			renderer._clearColor.getRGB( _clearColor, LinearSRGBColorSpace );
			_clearColor.a = renderer._clearColor.a;

		} else if ( background.isColor ) {

			// background is an opaque color

			background.getRGB( _clearColor, LinearSRGBColorSpace );
			_clearColor.a = 1;

			forceClear = true;

		} else if ( background.isNode ) {

			var sceneData = this.get( scene );
			var backgroundNode = background;

			_clearColor.copy( renderer._clearColor );

			var backgroundMesh = sceneData.backgroundMesh;

			if ( backgroundMesh == null ) {

				var backgroundMeshNode = context( $vec4( backgroundNode ).mul( backgroundIntensity ), {
					// @TODO: Add Texture2D support using node context
					getUV: function() { return normalWorld; },
					getTextureLevel: function() { return backgroundBlurriness; }
				} );

				var viewProj = modelViewProjection();
				viewProj.z = viewProj.w;

				var nodeMaterial = new NodeMaterial();
				nodeMaterial.side = BackSide;
				nodeMaterial.depthTest = false;
				nodeMaterial.depthWrite = false;
				nodeMaterial.fog = false;
				nodeMaterial.vertexNode = viewProj;
				nodeMaterial.fragmentNode = backgroundMeshNode;

				sceneData.backgroundMeshNode = backgroundMeshNode;
				sceneData.backgroundMesh = backgroundMesh = new Mesh( new SphereGeometry( 1, 32, 32 ), nodeMaterial );
				backgroundMesh.frustumCulled = false;

				backgroundMesh.onBeforeRender = function ( renderer, scene, camera ) {

					this.matrixWorld.copyPosition( camera.matrixWorld );

				};

			}

			var backgroundCacheKey = backgroundNode.getCacheKey();

			if ( sceneData.backgroundCacheKey != backgroundCacheKey ) {

				sceneData.backgroundMeshNode.node = $vec4( backgroundNode ).mul( backgroundIntensity );

				backgroundMesh.material.needsUpdate = true;

				sceneData.backgroundCacheKey = backgroundCacheKey;

			}

			renderList.unshift( backgroundMesh, backgroundMesh.geometry, backgroundMesh.material, 0, 0, null );

		} else {

			trace( 'THREE.Renderer: Unsupported background configuration: $background' );

		}

		//

		if ( renderer.autoClear || forceClear ) {

			_clearColor.multiplyScalar( _clearColor.a );

			var clearColorValue = renderContext.clearColorValue;

			clearColorValue.r = _clearColor.r;
			clearColorValue.g = _clearColor.g;
			clearColorValue.b = _clearColor.b;
			clearColorValue.a = _clearColor.a;

			renderContext.depthClearValue = renderer._clearDepth;
			renderContext.stencilClearValue = renderer._clearStencil;

			renderContext.clearColor = renderer.autoClearColor;
			renderContext.clearDepth = renderer.autoClearDepth;
			renderContext.clearStencil = renderer.autoClearStencil;

		} else {

			renderContext.clearColor = false;
			renderContext.clearDepth = false;
			renderContext.clearStencil = false;

		}

	}

}

class export Background;