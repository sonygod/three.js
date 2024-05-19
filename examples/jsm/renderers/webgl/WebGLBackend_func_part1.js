import { WebGLCoordinateSystem } from 'three';

import GLSLNodeBuilder from './nodes/GLSLNodeBuilder.js';
import Backend from '../common/Backend.js';

import WebGLAttributeUtils from './utils/WebGLAttributeUtils.js';
import WebGLState from './utils/WebGLState.js';
import WebGLUtils from './utils/WebGLUtils.js';
import WebGLTextureUtils from './utils/WebGLTextureUtils.js';
import WebGLExtensions from './utils/WebGLExtensions.js';
import WebGLCapabilities from './utils/WebGLCapabilities.js';
import { GLFeatureName } from './utils/WebGLConstants.js';
import { WebGLBufferRenderer } from './WebGLBufferRenderer.js';

//


class WebGLBackend extends Backend {

	constructor( parameters = {} ) {

		super( parameters );

		this.isWebGLBackend = true;

	}
init( renderer ) {

		super.init( renderer );

		//

		const parameters = this.parameters;

		const glContext = ( parameters.context !== undefined ) ? parameters.context : renderer.domElement.getContext( 'webgl2' );

		this.gl = glContext;

		this.extensions = new WebGLExtensions( this );
		this.capabilities = new WebGLCapabilities( this );
		this.attributeUtils = new WebGLAttributeUtils( this );
		this.textureUtils = new WebGLTextureUtils( this );
		this.bufferRenderer = new WebGLBufferRenderer( this );

		this.state = new WebGLState( this );
		this.utils = new WebGLUtils( this );

		this.vaoCache = {};
		this.transformFeedbackCache = {};
		this.discard = false;
		this.trackTimestamp = ( parameters.trackTimestamp === true );

		this.extensions.get( 'EXT_color_buffer_float' );
		this.disjoint = this.extensions.get( 'EXT_disjoint_timer_query_webgl2' );
		this.parallel = this.extensions.get( 'KHR_parallel_shader_compile' );
		this._currentContext = null;

	}
get coordinateSystem() {

		return WebGLCoordinateSystem;

	}
async getArrayBufferAsync( attribute ) {

		return await this.attributeUtils.getArrayBufferAsync( attribute );

	}
initTimestampQuery( renderContext ) {

		if ( ! this.disjoint || ! this.trackTimestamp ) return;

		const renderContextData = this.get( renderContext );

		if ( this.queryRunning ) {

		  if ( ! renderContextData.queryQueue ) renderContextData.queryQueue = [];
		  renderContextData.queryQueue.push( renderContext );
		  return;

		}

		if ( renderContextData.activeQuery ) {

		  this.gl.endQuery( this.disjoint.TIME_ELAPSED_EXT );
		  renderContextData.activeQuery = null;

		}

		renderContextData.activeQuery = this.gl.createQuery();

		if ( renderContextData.activeQuery !== null ) {

		  this.gl.beginQuery( this.disjoint.TIME_ELAPSED_EXT, renderContextData.activeQuery );
		  this.queryRunning = true;

		}

	}
prepareTimestampBuffer( renderContext ) {

		if ( ! this.disjoint || ! this.trackTimestamp ) return;

		const renderContextData = this.get( renderContext );

		if ( renderContextData.activeQuery ) {

		  this.gl.endQuery( this.disjoint.TIME_ELAPSED_EXT );

		  if ( ! renderContextData.gpuQueries ) renderContextData.gpuQueries = [];
		  renderContextData.gpuQueries.push( { query: renderContextData.activeQuery } );
		  renderContextData.activeQuery = null;
		  this.queryRunning = false;

		  if ( renderContextData.queryQueue && renderContextData.queryQueue.length > 0 ) {

				const nextRenderContext = renderContextData.queryQueue.shift();
				this.initTimestampQuery( nextRenderContext );

			}

		}

	}
async resolveTimestampAsync( renderContext, type = 'render' ) {

		if ( ! this.disjoint || ! this.trackTimestamp ) return;

		const renderContextData = this.get( renderContext );

		if ( ! renderContextData.gpuQueries ) renderContextData.gpuQueries = [];

		for ( let i = 0; i < renderContextData.gpuQueries.length; i ++ ) {

		  const queryInfo = renderContextData.gpuQueries[ i ];
		  const available = this.gl.getQueryParameter( queryInfo.query, this.gl.QUERY_RESULT_AVAILABLE );
		  const disjoint = this.gl.getParameter( this.disjoint.GPU_DISJOINT_EXT );

		  if ( available && ! disjoint ) {

				const elapsed = this.gl.getQueryParameter( queryInfo.query, this.gl.QUERY_RESULT );
				const duration = Number( elapsed ) / 1000000; // Convert nanoseconds to milliseconds
				this.gl.deleteQuery( queryInfo.query );
				renderContextData.gpuQueries.splice( i, 1 ); // Remove the processed query
				i --;
				this.renderer.info.updateTimestamp( type, duration );

			}

		}

	}
getContext() {

		return this.gl;

	}
beginRender( renderContext ) {

		const { gl } = this;
		const renderContextData = this.get( renderContext );

		//

		//

		this.initTimestampQuery( renderContext );

		renderContextData.previousContext = this._currentContext;
		this._currentContext = renderContext;

		this._setFramebuffer( renderContext );

		this.clear( renderContext.clearColor, renderContext.clearDepth, renderContext.clearStencil, renderContext, false );

		//
		if ( renderContext.viewport ) {

			this.updateViewport( renderContext );

		} else {

			gl.viewport( 0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight );

		}

		if ( renderContext.scissor ) {

			const { x, y, width, height } = renderContext.scissorValue;

			gl.scissor( x, y, width, height );

		}

		const occlusionQueryCount = renderContext.occlusionQueryCount;

		if ( occlusionQueryCount > 0 ) {

			// Get a reference to the array of objects with queries. The renderContextData property
			// can be changed by another render pass before the async reading of all previous queries complete
			renderContextData.currentOcclusionQueries = renderContextData.occlusionQueries;
			renderContextData.currentOcclusionQueryObjects = renderContextData.occlusionQueryObjects;

			renderContextData.lastOcclusionObject = null;
			renderContextData.occlusionQueries = new Array( occlusionQueryCount );
			renderContextData.occlusionQueryObjects = new Array( occlusionQueryCount );
			renderContextData.occlusionQueryIndex = 0;

		}

	}
finishRender( renderContext ) {

		const { gl, state } = this;
		const renderContextData = this.get( renderContext );
		const previousContext = renderContextData.previousContext;

		const textures = renderContext.textures;

		if ( textures !== null ) {

			for ( let i = 0; i < textures.length; i ++ ) {

				const texture = textures[ i ];

				if ( texture.generateMipmaps ) {

					this.generateMipmaps( texture );

				}

			}

		}

		this._currentContext = previousContext;


		if ( renderContext.textures !== null && renderContext.renderTarget ) {

			const renderTargetContextData = this.get( renderContext.renderTarget );

			const { samples } = renderContext.renderTarget;
			const fb = renderTargetContextData.framebuffer;

			const mask = gl.COLOR_BUFFER_BIT;

			if ( samples > 0 ) {

				const msaaFrameBuffer = renderTargetContextData.msaaFrameBuffer;

				const textures = renderContext.textures;

				state.bindFramebuffer( gl.READ_FRAMEBUFFER, msaaFrameBuffer );
				state.bindFramebuffer( gl.DRAW_FRAMEBUFFER, fb );

				for ( let i = 0; i < textures.length; i ++ ) {

					// TODO Add support for MRT

					gl.blitFramebuffer( 0, 0, renderContext.width, renderContext.height, 0, 0, renderContext.width, renderContext.height, mask, gl.NEAREST );

					gl.invalidateFramebuffer( gl.READ_FRAMEBUFFER, renderTargetContextData.invalidationArray );

				}

			}


		}

		if ( previousContext !== null ) {

			this._setFramebuffer( previousContext );

			if ( previousContext.viewport ) {

				this.updateViewport( previousContext );

			} else {

				const gl = this.gl;

				gl.viewport( 0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight );

			}

		}

		const occlusionQueryCount = renderContext.occlusionQueryCount;

		if ( occlusionQueryCount > 0 ) {

			const renderContextData = this.get( renderContext );

			if ( occlusionQueryCount > renderContextData.occlusionQueryIndex ) {

				const { gl } = this;

				gl.endQuery( gl.ANY_SAMPLES_PASSED );

			}

			this.resolveOccludedAsync( renderContext );

		}

		this.prepareTimestampBuffer( renderContext );

	}
resolveOccludedAsync( renderContext ) {

		const renderContextData = this.get( renderContext );

		// handle occlusion query results

		const { currentOcclusionQueries, currentOcclusionQueryObjects } = renderContextData;

		if ( currentOcclusionQueries && currentOcclusionQueryObjects ) {

			const occluded = new WeakSet();
			const { gl } = this;

			renderContextData.currentOcclusionQueryObjects = null;
			renderContextData.currentOcclusionQueries = null;

			const check = () => {

				let completed = 0;

				// check all queries and requeue as appropriate
				for ( let i = 0; i < currentOcclusionQueries.length; i ++ ) {

					const query = currentOcclusionQueries[ i ];

					if ( query === null ) continue;

					if ( gl.getQueryParameter( query, gl.QUERY_RESULT_AVAILABLE ) ) {

						if ( gl.getQueryParameter( query, gl.QUERY_RESULT ) > 0 ) occluded.add( currentOcclusionQueryObjects[ i ] );

						currentOcclusionQueries[ i ] = null;
						gl.deleteQuery( query );

						completed ++;

					}

				}

				if ( completed < currentOcclusionQueries.length ) {

					requestAnimationFrame( check );

				} else {

					renderContextData.occluded = occluded;

				}

			};

			check();

		}

	}
isOccluded( renderContext, object ) {

		const renderContextData = this.get( renderContext );

		return renderContextData.occluded && renderContextData.occluded.has( object );

	}
updateViewport( renderContext ) {

		const gl = this.gl;
		const { x, y, width, height } = renderContext.viewportValue;

		gl.viewport( x, y, width, height );

	}
setScissorTest( boolean ) {

		const gl = this.gl;

		if ( boolean ) {

			gl.enable( gl.SCISSOR_TEST );

		} else {

			gl.disable( gl.SCISSOR_TEST );

		}

	}
clear( color, depth, stencil, descriptor = null, setFrameBuffer = true ) {

		const { gl } = this;

		if ( descriptor === null ) {

			descriptor = {
				textures: null,
				clearColorValue: this.getClearColor()
			};

		}

		//

		let clear = 0;

		if ( color ) clear |= gl.COLOR_BUFFER_BIT;
		if ( depth ) clear |= gl.DEPTH_BUFFER_BIT;
		if ( stencil ) clear |= gl.STENCIL_BUFFER_BIT;

		if ( clear !== 0 ) {

			const clearColor = descriptor.clearColorValue || this.getClearColor();

			if ( depth ) this.state.setDepthMask( true );

			if ( descriptor.textures === null ) {

				gl.clearColor( clearColor.r, clearColor.g, clearColor.b, clearColor.a );
				gl.clear( clear );

			} else {

				if ( setFrameBuffer ) this._setFramebuffer( descriptor );

				if ( color ) {

					for ( let i = 0; i < descriptor.textures.length; i ++ ) {

						gl.clearBufferfv( gl.COLOR, i, [ clearColor.r, clearColor.g, clearColor.b, clearColor.a ] );

					}

				}

				if ( depth && stencil ) {

					gl.clearBufferfi( gl.DEPTH_STENCIL, 0, 1, 0 );

				} else if ( depth ) {

					gl.clearBufferfv( gl.DEPTH, 0, [ 1.0 ] );

				} else if ( stencil ) {

					gl.clearBufferiv( gl.STENCIL, 0, [ 0 ] );

				}

			}

		}

	}
beginCompute( computeGroup ) {

		const gl = this.gl;

		gl.bindFramebuffer( gl.FRAMEBUFFER, null );
		this.initTimestampQuery( computeGroup );

	}