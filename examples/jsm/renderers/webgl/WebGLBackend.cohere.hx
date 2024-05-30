import haxe.Serializer;
import haxe.Unserializer;

import js.Browser;
import js.html.Element;
import js.html.Window;

import js.webgl.WebGLRenderingContext;
import js.webgl.WebGL2RenderingContext;
import js.webgl.WebGLQuery;
import js.webgl.WebGLProgram;
import js.webgl.WebGLShader;
import js.webgl.WebGLBuffer;
import js.webgl.WebGLFramebuffer;
import js.webgl.WebGLTexture;
import js.webgl.WebGLRenderbuffer;
import js.webgl.WebGLActiveInfo;
import js.webgl.WebGLUniformLocation;
import js.webgl.WebGLVertexArrayObject;
import js.webgl.EXT_color_buffer_float;
import js.webgl.EXT_disjoint_timer_query_webgl2;
import js.webgl.KHR_parallel_shader_compile;

import js.Three.WebGLCoordinateSystem;
import js.Three.GLSLNodeBuilder;
import js.Three.Backend;
import js.Three.WebGLAttributeUtils;
import js.Three.WebGLState;
import js.Three.WebGLUtils;
import js.Three.WebGLTextureUtils;
import js.Three.WebGLExtensions;
import js.Three.WebGLCapabilities;
import js.Three.GLFeatureName;
import js.Three.WebGLBufferRenderer;

class WebGLBackend extends Backend {
	public var isWebGLBackend:Bool;
	public var gl:WebGLRenderingContext;
	public var extensions:WebGLExtensions;
	public var capabilities:WebGLCapabilities;
	public var attributeUtils:WebGLAttributeUtils;
	public var textureUtils:WebGLTextureUtils;
	public var bufferRenderer:WebGLBufferRenderer;
	public var state:WebGLState;
	public var utils:WebGLUtils;
	public var vaoCache:Map<String,WebGLVertexArrayObject>;
	public var transformFeedbackCache:Map<String,WebGLTransformFeedback>;
	public var discard:Bool;
	public var trackTimestamp:Bool;
	public var _currentContext:Dynamic;
	public var disjoint:Dynamic;
	public var parallel:Dynamic;

	public function new(parameters:Dynamic) {
		super(parameters);
		isWebGLBackend = true;
	}

	public function init(renderer:Dynamic) {
		super.init(renderer);
		var parameters = this.parameters;
		var glContext = parameters.context != null ? parameters.context : (renderer as Element).getContext('webgl2');
		gl = glContext;
		extensions = new WebGLExtensions(this);
		capabilities = new WebGLCapabilities(this);
		attributeUtils = new WebGLAttributeUtils(this);
		textureUtils = new WebGLTextureUtils(this);
		bufferRenderer = new WebGLBufferRenderer(this);
		state = new WebGLState(this);
		utils = new WebGLUtils(this);
		vaoCache = new Map();
		transformFeedbackCache = new Map();
		discard = false;
		trackTimestamp = parameters.trackTimestamp;
		extensions.get(EXT_color_buffer_float);
		disjoint = extensions.get(EXT_disjoint_timer_query_webgl2);
		parallel = extensions.get(KHR_parallel_shader_compile);
		_currentContext = null;
	}

	public function get coordinateSystem():WebGLCoordinateSystem {
		return WebGLCoordinateSystem;
	}

	public async function getArrayBufferAsync(attribute:Dynamic):Dynamic {
		return await attributeUtils.getArrayBufferAsync(attribute);
	}

	public function initTimestampQuery(renderContext:Dynamic) {
		if (!disjoint || !trackTimestamp) return;
		var renderContextData = this.get(renderContext);
		if (queryRunning) {
			if (!renderContextData.queryQueue) renderContextData.queryQueue = [];
			renderContextData.queryQueue.push(renderContext);
			return;
		}
		if (renderContextData.activeQuery) {
			gl.endQuery(disjoint.TIME_ELAPSED_EXT);
			renderContextData.activeQuery = null;
		}
		renderContextData.activeQuery = gl.createQuery();
		if (renderContextData.activeQuery != null) {
			gl.beginQuery(disjoint.TIME_ELAPSED_EXT, renderContextData.activeQuery);
			queryRunning = true;
		}
	}

	public function prepareTimestampBuffer(renderContext:Dynamic) {
		if (!disjoint || !trackTimestamp) return;
		var renderContextData = this.get(renderContext);
		if (renderContextData.activeQuery) {
			gl.endQuery(disjoint.TIME_ELAPSED_EXT);
			if (!renderContextData.gpuQueries) renderContextData.gpuQueries = [];
			renderContextData.gpuQueries.push({query: renderContextData.activeQuery});
			renderContextData.activeQuery = null;
			queryRunning = false;
			if (renderContextData.queryQueue && renderContextData.queryQueue.length > 0) {
				var nextRenderContext = renderContextData.queryQueue.shift();
				initTimestampQuery(nextRenderContext);
			}
		}
	}

	public async function resolveTimestampAsync(renderContext:Dynamic, type:String = 'render'):Void {
		if (!disjoint || !trackTimestamp) return;
		var renderContextData = this.get(renderContext);
		if (!renderContextData.gpuQueries) renderContextData.gpuQueries = [];
		for (i in 0...renderContextData.gpuQueries.length) {
			var queryInfo = renderContextData.gpuQueries[i];
			var available = gl.getQueryParameter(queryInfo.query, gl.QUERY_RESULT_AVAILABLE);
			var disjoint = gl.getParameter(disjoint.GPU_DISJOINT_EXT);
			if (available && !disjoint) {
				var elapsed = gl.getQueryParameter(queryInfo.query, gl.QUERY_RESULT);
				var duration = Std.parseFloat(elapsed) / 1000000; // Convert nanoseconds to milliseconds
				gl.deleteQuery(queryInfo.query);
				renderContextData.gpuQueries.splice(i, 1); // Remove the processed query
				i--;
				renderer.info.updateTimestamp(type, duration);
			}
		}
	}

	public function getContext():WebGLRenderingContext {
		return gl;
	}

	public function beginRender(renderContext:Dynamic) {
		var gl = this.gl;
		var renderContextData = this.get(renderContext);
		initTimestampQuery(renderContext);
		renderContextData.previousContext = _currentContext;
		_currentContext = renderContext;
		_setFramebuffer(renderContext);
		clear(renderContext.clearColor, renderContext.clearDepth, renderContext.clearStencil, renderContext, false);
		if (renderContext.viewport) {
			updateViewport(renderContext);
		} else {
			gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
		}
		if (renderContext.scissor) {
			var x = renderContext.scissorValue.x;
			var y = renderContext.scissorValue.y;
			var width = renderContext.scissorValue.width;
			var height = renderContext.scissorValue.height;
			gl.scissor(x, y, width, height);
		}
		var occlusionQueryCount = renderContext.occlusionQueryCount;
		if (occlusionQueryCount > 0) {
			// Get a reference to the array of objects with queries. The renderContextData property
			// can be changed by another render pass before the async reading of all previous queries complete
			renderContextData.currentOcclusionQueries = renderContextData.occlusionQueries;
			renderContextData.currentOcclusionQueryObjects = renderContextData.occlusionQueryObjects;
			renderContextData.lastOcclusionObject = null;
			renderContextData.occlusionQueries = [];
			renderContextData.occlusionQueryObjects = [];
			renderContextData.occlusionQueryIndex = 0;
		}
	}

	public function finishRender(renderContext:Dynamic) {
		var gl = this.gl;
		var state = this.state;
		var renderContextData = this.get(renderContext);
		var previousContext = renderContextData.previousContext;
		var textures = renderContext.textures;
		if (textures != null) {
			for (i in 0...textures.length) {
				var texture = textures[i];
				if (texture.generateMipmaps) {
					generateMipmaps(texture);
				}
			}
		}
		_currentContext = previousContext;
		if (renderContext.textures != null && renderContext.renderTarget) {
			var renderTargetContextData = this.get(renderContext.renderTarget);
			var samples = renderContext.renderTarget.samples;
			var fb = renderTargetContextData.framebuffer;
			var mask = gl.COLOR_BUFFER_BIT;
			if (samples > 0) {
				var msaaFrameBuffer = renderTargetContextData.msaaFrameBuffer;
				var textures = renderContext.textures;
				state.bindFramebuffer(gl.READ_FRAMEBUFFER, msaaFrameBuffer);
				state.bindFramebuffer(gl.DRAW_FRAMEBUFFER, fb);
				for (i in 0...textures.length) {
					// TODO Add support for MRT
					gl.blitFramebuffer(0, 0, renderContext.width, renderContext.height, 0, 0, renderContext.width, renderContext.height, mask, gl.NEAREST);
					gl.invalidateFramebuffer(gl.READ_FRAMEBUFFER, renderTargetContextData.invalidationArray);
				}
			}
		}
		if (previousContext != null) {
			_setFramebuffer(previousContext);
			if (previousContext.viewport) {
				updateViewport(previousContext);
			} else {
				var gl = this.gl;
				gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
			}
		}
		var occlusionQueryCount = renderContext.occlusionQueryCount;
		if (occlusionQueryCount > 0) {
			var renderContextData = this.get(renderContext);
			if (occlusionQueryCount > renderContextData.occlusionQueryIndex) {
				var gl = this.gl;
				gl.endQuery(gl.ANY_SAMPLES_PASSED);
			}
			resolveOccludedAsync(renderContext);
		}
		prepareTimestampBuffer(renderContext);
	}

	public function resolveOccludedAsync(renderContext:Dynamic) {
		var renderContextData = this.get(renderContext);
		// handle occlusion query results
		var currentOcclusionQueries = renderContextData.currentOcclusionQueries;
		var currentOcclusionQueryObjects = renderContextData.currentOcclusionQueryObjects;
		if (currentOcclusionQueries && currentOcclusionQueryObjects) {
			var occluded = new WeakSet();
			var gl = this.gl;
			renderContextData.currentOcclusionQueryObjects = null;
			renderContextData.currentOcclusionQueries = null;
			var check = function() {
				var completed = 0;
				// check all queries and requeue as appropriate
				for (i in 0...currentOcclusionQueries.length) {
					var query = currentOcclusionQueries[i];
					if (query == null) continue;
					if (gl.getQueryParameter(query, gl.QUERY_RESULT_AVAILABLE)) {
						if (gl.getQueryParameter(query, gl.QUERY_RESULT) > 0) occluded.add(currentOcclusionQueryObjects[i]);
						currentOcclusionQueries[i] = null;
						gl.deleteQuery(query);
						completed++;
					}
				}
				if (completed < currentOcclusionQueries.length) {
					Browser.requestAnimationFrame(check);
				} else {
					renderContextData.occluded = occluded;
				}
			};
			check();
		}
	}

	public function isOccluded(renderContext:Dynamic, object:Dynamic):Bool {
		var renderContextData = this.get(renderContext);
		return renderContextData.occluded && renderContextData.occluded.has(object);
	}

	public function updateViewport(renderContext:Dynamic) {
		var gl = this.gl;
		var x = renderContext.viewportValue.x;
		var y = renderContext.viewportValue.y;
		var width = renderContext.viewportValue.width;
		var height = renderContext.viewportValue.height;
		gl.viewport(x, y, width, height);
	}

	public function setScissorTest(boolean:Bool) {
		var gl = this.gl;
		if (boolean) {
			gl.enable(gl.SCISSOR_TEST);
		} else {
			gl.disable(gl.SCISSOR_TEST);
		}
	}

	public function clear(color:Dynamic, depth:Dynamic, stencil:Dynamic, descriptor:Dynamic = null, setFrameBuffer:Dynamic = true):Void {
		var gl = this.gl;
		if (descriptor == null) {
			descriptor = {
				textures: null,
				clearColorValue: getClearColor()
			};
		}
		var clear = 0;
		if (color) clear |= gl.COLOR_BUFFER_BIT;
		if (depth) clear |= gl.DEPTH_BUFFER_BIT;
		if (stencil) clear |= gl.STENCIL_BUFFER_BIT;
		if (clear != 0) {
			var clearColor = descriptor.clearColorValue != null ? descriptor.clearColorValue : getClearColor();
			if (depth) state.setDepthMask(true);
			if (descriptor.textures == null) {
				gl.clearColor(clearColor.r, clearColor.g, clearColor.b, clearColor.a);
				gl.clear(clear);
			} else {
				if (setFrameBuffer) _setFramebuffer(descriptor);
				if (color) {
					for (i in 0...descriptor.textures.length) {
						gl.clearBufferfv(gl.COLOR, i, [clearColor.r, clearColor.g, clearColor.b, clearColor.a]);
					}
				}
				if (depth && stencil) {
					gl.clearBufferfi(gl.DEPTH_STENCIL, 0, 1, 0);
				} else if (depth) {
					gl.clearBufferfv(gl.DEPTH, 0, [1.0]);
				} else if (stencil) {
					gl.clearBufferiv(gl.STENCIL, 0, [0]);
				}
			}
		}
	}

	public function beginCompute(computeGroup:Dynamic) {
		var gl = this.gl;
		gl.bindFramebuffer(gl.FRAMEBUFFER, null);
		initTimestampQuery(computeGroup);
	}

	public function compute(computeGroup:Dynamic, computeNode:Dynamic, bindings:Dynamic, pipeline:Dynamic) {
		var gl = this.gl;
		if (!discard) {
			// required here to handle async behaviour of render.compute()
			gl.enable(gl.RASTERIZER_DISCARD);
			discard = true;
		}
		var programGPU = this.get(pipeline).programGPU;
		var transformBuffers = this.get(pipeline).transformBuffers;
		var attributes = this.get(pipeline).attributes;
		var vaoKey = _getVaoKey(null, attributes);
		var vaoGPU = vaoCache.get(vaoKey);
		if (vaoGPU == null) {
			_createVao(null, attributes);
		} else {
			gl.bindVertexArray(vaoGPU);
		}
		gl.useProgram(programGPU);
		_bindUniforms(bindings);
		var transformFeedbackGPU = _getTransformFeedback(transformBuffers);
		gl.bindTransformFeedback(gl.TRANSFORM_FEEDBACK, transformFeedbackGPU);
		gl.beginTransformFeedback(gl.POINTS);
		if (attributes[0].isStorageInstancedBufferAttribute) {
			gl.drawArraysInstanced(gl.POINTS, 0, 1, computeNode.count);
		} else {
			gl.drawArrays(gl.POINTS, 0, computeNode.count);
		}
		gl.endTransformFeedback();
		gl.bindTransformFeedback(gl.TRANSFORM_FEEDBACK, null);
		// switch active buffers
		for (i in 0...transformBuffers.length) {
			var dualAttributeData = transformBuffers[i];
			if (dualAttributeData.pbo) {
				textureUtils.copyBufferToTexture(dualAttributeData.transformBuffer, dualAttributeData.pbo);
			}
			dualAttributeData.switchBuffers();
		}
	}

	public function finishCompute(computeGroup:Dynamic) {
		var gl = this.gl;
		discard = false;
		gl.disable(gl.RASTERIZER_DISCARD);
		prepareTimestampBuffer(computeGroup);
	}

	public function draw(renderObject:Dynamic, info:Dynamic) {
		var object = renderObject.object;
		var