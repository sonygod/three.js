import three.WebGLCoordinateSystem;
import three.nodes.GLSLNodeBuilder;
import three.common.Backend;
import three.utils.WebGLAttributeUtils;
import three.utils.WebGLState;
import three.utils.WebGLUtils;
import three.utils.WebGLTextureUtils;
import three.utils.WebGLExtensions;
import three.utils.WebGLCapabilities;
import three.utils.WebGLConstants.GLFeatureName;
import three.WebGLBufferRenderer;

class WebGLBackend extends Backend {
	public var isWebGLBackend:Bool = true;
	public var gl:Dynamic;
	public var extensions:WebGLExtensions;
	public var capabilities:WebGLCapabilities;
	public var attributeUtils:WebGLAttributeUtils;
	public var textureUtils:WebGLTextureUtils;
	public var bufferRenderer:WebGLBufferRenderer;
	public var state:WebGLState;
	public var utils:WebGLUtils;
	public var vaoCache:Map<String,Dynamic> = new Map();
	public var transformFeedbackCache:Map<String,Dynamic> = new Map();
	public var discard:Bool = false;
	public var trackTimestamp:Bool;
	public var disjoint:Dynamic;
	public var parallel:Dynamic;
	public var _currentContext:Dynamic = null;
	public var queryRunning:Bool = false;

	public function new(parameters:Dynamic = {}) {
		super(parameters);
	}

	public function init(renderer:Dynamic) {
		super.init(renderer);

		var parameters = this.parameters;
		var glContext = parameters.context != null ? parameters.context : renderer.domElement.getContext('webgl2');

		this.gl = glContext;
		this.extensions = new WebGLExtensions(this);
		this.capabilities = new WebGLCapabilities(this);
		this.attributeUtils = new WebGLAttributeUtils(this);
		this.textureUtils = new WebGLTextureUtils(this);
		this.bufferRenderer = new WebGLBufferRenderer(this);
		this.state = new WebGLState(this);
		this.utils = new WebGLUtils(this);

		this.trackTimestamp = parameters.trackTimestamp == true;
		this.extensions.get('EXT_color_buffer_float');
		this.disjoint = this.extensions.get('EXT_disjoint_timer_query_webgl2');
		this.parallel = this.extensions.get('KHR_parallel_shader_compile');
	}

	public function get coordinateSystem():Dynamic {
		return WebGLCoordinateSystem;
	}

	public function getArrayBufferAsync(attribute:Dynamic):Dynamic {
		return this.attributeUtils.getArrayBufferAsync(attribute);
	}

	public function initTimestampQuery(renderContext:Dynamic) {
		if (!this.disjoint || !this.trackTimestamp) return;

		var renderContextData = this.get(renderContext);

		if (this.queryRunning) {
			if (renderContextData.queryQueue == null) renderContextData.queryQueue = [];
			renderContextData.queryQueue.push(renderContext);
			return;
		}

		if (renderContextData.activeQuery != null) {
			this.gl.endQuery(this.disjoint.TIME_ELAPSED_EXT);
			renderContextData.activeQuery = null;
		}

		renderContextData.activeQuery = this.gl.createQuery();

		if (renderContextData.activeQuery != null) {
			this.gl.beginQuery(this.disjoint.TIME_ELAPSED_EXT, renderContextData.activeQuery);
			this.queryRunning = true;
		}
	}

	public function prepareTimestampBuffer(renderContext:Dynamic) {
		if (!this.disjoint || !this.trackTimestamp) return;

		var renderContextData = this.get(renderContext);

		if (renderContextData.activeQuery != null) {
			this.gl.endQuery(this.disjoint.TIME_ELAPSED_EXT);

			if (renderContextData.gpuQueries == null) renderContextData.gpuQueries = [];
			renderContextData.gpuQueries.push({query: renderContextData.activeQuery});
			renderContextData.activeQuery = null;
			this.queryRunning = false;

			if (renderContextData.queryQueue != null && renderContextData.queryQueue.length > 0) {
				var nextRenderContext = renderContextData.queryQueue.shift();
				this.initTimestampQuery(nextRenderContext);
			}
		}
	}

	public function resolveTimestampAsync(renderContext:Dynamic, type:String = 'render'):Dynamic {
		if (!this.disjoint || !this.trackTimestamp) return;

		var renderContextData = this.get(renderContext);

		if (renderContextData.gpuQueries == null) renderContextData.gpuQueries = [];

		for (var i = 0; i < renderContextData.gpuQueries.length; i++) {
			var queryInfo = renderContextData.gpuQueries[i];
			var available = this.gl.getQueryParameter(queryInfo.query, this.gl.QUERY_RESULT_AVAILABLE);
			var disjoint = this.gl.getParameter(this.disjoint.GPU_DISJOINT_EXT);

			if (available && !disjoint) {
				var elapsed = this.gl.getQueryParameter(queryInfo.query, this.gl.QUERY_RESULT);
				var duration = Std.parseFloat(elapsed) / 1000000; // Convert nanoseconds to milliseconds
				this.gl.deleteQuery(queryInfo.query);
				renderContextData.gpuQueries.splice(i, 1); // Remove the processed query
				i--;
				this.renderer.info.updateTimestamp(type, duration);
			}
		}
	}

	public function getContext():Dynamic {
		return this.gl;
	}

	public function beginRender(renderContext:Dynamic) {
		var gl = this.gl;
		var renderContextData = this.get(renderContext);

		this.initTimestampQuery(renderContext);

		renderContextData.previousContext = this._currentContext;
		this._currentContext = renderContext;

		this._setFramebuffer(renderContext);

		this.clear(renderContext.clearColor, renderContext.clearDepth, renderContext.clearStencil, renderContext, false);

		if (renderContext.viewport != null) {
			this.updateViewport(renderContext);
		} else {
			gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
		}

		if (renderContext.scissor != null) {
			var x = renderContext.scissorValue.x;
			var y = renderContext.scissorValue.y;
			var width = renderContext.scissorValue.width;
			var height = renderContext.scissorValue.height;
			gl.scissor(x, y, width, height);
		}

		var occlusionQueryCount = renderContext.occlusionQueryCount;

		if (occlusionQueryCount > 0) {
			renderContextData.currentOcclusionQueries = renderContextData.occlusionQueries;
			renderContextData.currentOcclusionQueryObjects = renderContextData.occlusionQueryObjects;

			renderContextData.lastOcclusionObject = null;
			renderContextData.occlusionQueries = new Array(occlusionQueryCount);
			renderContextData.occlusionQueryObjects = new Array(occlusionQueryCount);
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
			for (var i = 0; i < textures.length; i++) {
				var texture = textures[i];
				if (texture.generateMipmaps) {
					this.generateMipmaps(texture);
				}
			}
		}

		this._currentContext = previousContext;

		if (renderContext.textures != null && renderContext.renderTarget != null) {
			var renderTargetContextData = this.get(renderContext.renderTarget);
			var samples = renderContext.renderTarget.samples;
			var fb = renderTargetContextData.framebuffer;
			var mask = gl.COLOR_BUFFER_BIT;

			if (samples > 0) {
				var msaaFrameBuffer = renderTargetContextData.msaaFrameBuffer;
				var textures = renderContext.textures;

				state.bindFramebuffer(gl.READ_FRAMEBUFFER, msaaFrameBuffer);
				state.bindFramebuffer(gl.DRAW_FRAMEBUFFER, fb);

				for (var i = 0; i < textures.length; i++) {
					gl.blitFramebuffer(0, 0, renderContext.width, renderContext.height, 0, 0, renderContext.width, renderContext.height, mask, gl.NEAREST);
					gl.invalidateFramebuffer(gl.READ_FRAMEBUFFER, renderTargetContextData.invalidationArray);
				}
			}
		}

		if (previousContext != null) {
			this._setFramebuffer(previousContext);

			if (previousContext.viewport != null) {
				this.updateViewport(previousContext);
			} else {
				gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
			}
		}

		var occlusionQueryCount = renderContext.occlusionQueryCount;

		if (occlusionQueryCount > 0) {
			var renderContextData = this.get(renderContext);

			if (occlusionQueryCount > renderContextData.occlusionQueryIndex) {
				gl.endQuery(gl.ANY_SAMPLES_PASSED);
			}

			this.resolveOccludedAsync(renderContext);
		}

		this.prepareTimestampBuffer(renderContext);
	}

	public function resolveOccludedAsync(renderContext:Dynamic) {
		var renderContextData = this.get(renderContext);

		var currentOcclusionQueries = renderContextData.currentOcclusionQueries;
		var currentOcclusionQueryObjects = renderContextData.currentOcclusionQueryObjects;

		if (currentOcclusionQueries != null && currentOcclusionQueryObjects != null) {
			var occluded = new WeakSet();
			var gl = this.gl;

			renderContextData.currentOcclusionQueryObjects = null;
			renderContextData.currentOcclusionQueries = null;

			var check = function() {
				var completed = 0;

				for (var i = 0; i < currentOcclusionQueries.length; i++) {
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
					requestAnimationFrame(check);
				} else {
					renderContextData.occluded = occluded;
				}
			};

			check();
		}
	}

	public function isOccluded(renderContext:Dynamic, object:Dynamic):Bool {
		var renderContextData = this.get(renderContext);

		return renderContextData.occluded != null && renderContextData.occluded.has(object);
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

	public function clear(color:Bool, depth:Bool, stencil:Bool, descriptor:Dynamic = null, setFrameBuffer:Bool = true) {
		var gl = this.gl;

		if (descriptor == null) {
			descriptor = {
				textures: null,
				clearColorValue: this.getClearColor()
			};
		}

		var clear = 0;

		if (color) clear |= gl.COLOR_BUFFER_BIT;
		if (depth) clear |= gl.DEPTH_BUFFER_BIT;
		if (stencil) clear |= gl.STENCIL_BUFFER_BIT;

		if (clear != 0) {
			var clearColor = descriptor.clearColorValue != null ? descriptor.clearColorValue : this.getClearColor();

			if (depth) this.state.setDepthMask(true);

			if (descriptor.textures == null) {
				gl.clearColor(clearColor.r, clearColor.g, clearColor.b, clearColor.a);
				gl.clear(clear);
			} else {
				if (setFrameBuffer) this._setFramebuffer(descriptor);

				if (color) {
					for (var i = 0; i < descriptor.textures.length; i++) {
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
		this.initTimestampQuery(computeGroup);
	}

	public function compute(computeGroup:Dynamic, computeNode:Dynamic, bindings:Dynamic, pipeline:Dynamic) {
		var gl = this.gl;

		if (!this.discard) {
			gl.enable(gl.RASTERIZER_DISCARD);
			this.discard = true;
		}

		var programGPU = this.get(pipeline).programGPU;
		var transformBuffers = this.get(pipeline).transformBuffers;
		var attributes = this.get(pipeline).attributes;

		var vaoKey = this._getVaoKey(null, attributes);
		var vaoGPU = this.vaoCache.get(vaoKey);

		if (vaoGPU == null) {
			this._createVao(null, attributes);
		} else {
			gl.bindVertexArray(vaoGPU);
		}

		gl.useProgram(programGPU);

		this._bindUniforms(bindings);

		var transformFeedbackGPU = this._getTransformFeedback(transformBuffers);

		gl.bindTransformFeedback(gl.TRANSFORM_FEEDBACK, transformFeedbackGPU);
		gl.beginTransformFeedback(gl.POINTS);

		if (attributes[0].isStorageInstancedBufferAttribute) {
			gl.drawArraysInstanced(gl.POINTS, 0, 1, computeNode.count);
		} else {
			gl.drawArrays(gl.POINTS, 0, computeNode.count);
		}

		gl.endTransformFeedback();
		gl.bindTransformFeedback(gl.TRANSFORM_FEEDBACK, null);

		for (var i = 0; i < transformBuffers.length; i++) {
			var dualAttributeData = transformBuffers[i];

			if (dualAttributeData.pbo != null) {
				this.textureUtils.copyBufferToTexture(dualAttributeData.transformBuffer, dualAttributeData.pbo);
			}

			dualAttributeData.switchBuffers();
		}
	}

	public function finishCompute(computeGroup:Dynamic) {
		var gl = this.gl;

		this.discard = false;
		gl.disable(gl.RASTERIZER_DISCARD);
		this.prepareTimestampBuffer(computeGroup);
	}

	public function draw(renderObject:Dynamic, info:Dynamic) {
		var gl = this.gl;
		var state = this.state;

		var object = renderObject.object;
		var pipeline = renderObject.pipeline;
		var material = renderObject.material;
		var context = renderObject.context;

		var programGPU = this.get(pipeline).programGPU;
		var contextData = this.get(context);

		this._bindUniforms(renderObject.getBindings());

		var frontFaceCW = object.isMesh && object.matrixWorld.determinant() < 0;
		state.setMaterial(material, frontFaceCW);

		gl.useProgram(programGPU);

		var vaoGPU = renderObject.staticVao;

		if (vaoGPU == null) {
			var vaoKey = this._getVaoKey(renderObject.getIndex(), renderObject.getAttributes());
			vaoGPU = this.vaoCache.get(vaoKey);

			if (vaoGPU == null) {
				var staticVao:Dynamic;
				var _this = this._createVao(renderObject.getIndex(), renderObject.getAttributes());
				vaoGPU = _this.vaoGPU;
				staticVao = _this.staticVao;
				if (staticVao) renderObject.staticVao = vaoGPU;
			}
		}

		gl.bindVertexArray(vaoGPU);

		var index = renderObject.getIndex();
		var geometry = renderObject.geometry;
		var drawRange = renderObject.drawRange;
		var firstVertex = drawRange.start;

		var lastObject = contextData.lastOcclusionObject;

		if (lastObject != object && lastObject != null) {
			if (lastObject != null && lastObject.occlusionTest == true) {
				gl.endQuery(gl.ANY_SAMPLES_PASSED);
				contextData.occlusionQueryIndex++;
			}

			if (object.occlusionTest == true) {
				var query = gl.createQuery();
				gl.beginQuery(gl.ANY_SAMPLES_PASSED, query);
				contextData.occlusionQueries[contextData.occlusionQueryIndex] = query;
				contextData.occlusionQueryObjects[contextData.occlusionQueryIndex] = object;
			}

			contextData.lastOcclusionObject = object;
		}

		var renderer = this.bufferRenderer;

		if (object.isPoints) renderer.mode = gl.POINTS;
		else if (object.isLineSegments) renderer.mode = gl.LINES;
		else if (object.isLine) renderer.mode = gl.LINE_STRIP;
		else if (object.isLineLoop) renderer.mode = gl.LINE_LOOP;
		else {
			if (material.wireframe == true) {
				state.setLineWidth(material.wireframeLinewidth * this.renderer.getPixelRatio());
				renderer.mode = gl.LINES;
			} else {
				renderer.mode = gl.TRIANGLES;
			}
		}

		var count:Int;

		renderer.object = object;

		if (index != null) {
			var indexData = this.get(index);
			var indexCount = drawRange.count != Infinity ? drawRange.count : index.count;
			renderer.index = index.count;
			renderer.type = indexData.type;
			count = indexCount;
		} else {
			renderer.index = 0;
			var vertexCount = drawRange.count != Infinity ? drawRange.count : geometry.attributes.position.count;
			count = vertexCount;
		}

		var instanceCount = this.getInstanceCount(renderObject);

		if (object.isBatchedMesh) {
			if (object._multiDrawInstances != null) {
				renderer.renderMultiDrawInstances(object._multiDrawStarts, object._multiDrawCounts, object._multiDrawCount, object._multiDrawInstances);
			} else {
				renderer.renderMultiDraw(object._multiDrawStarts, object._multiDrawCounts, object._multiDrawCount);
			}
		} else if (instanceCount > 1) {
			renderer.renderInstances(firstVertex, count, instanceCount);
		} else {
			renderer.render(firstVertex, count);
		}

		gl.bindVertexArray(null);
	}

	public function needsRenderUpdate(renderObject:Dynamic):Bool {
		return false;
	}

	public function getRenderCacheKey(renderObject:Dynamic):String {
		return Std.string(renderObject.id);
	}

	public function createDefaultTexture(texture:Dynamic) {
		this.textureUtils.createDefaultTexture(texture);
	}

	public function createTexture(texture:Dynamic, options:Dynamic) {
		this.textureUtils.createTexture(texture, options);
	}

	public function updateTexture(texture:Dynamic, options:Dynamic) {
		this.textureUtils.updateTexture(texture, options);
	}

	public function generateMipmaps(texture:Dynamic) {
		this.textureUtils.generateMipmaps(texture);
	}

	public function destroyTexture(texture:Dynamic) {
		this.textureUtils.destroyTexture(texture);
	}

	public function copyTextureToBuffer(texture:Dynamic, x:Int, y:Int, width:Int, height:Int):Dynamic {
		return this.textureUtils.copyTextureToBuffer(texture, x, y, width, height);
	}

	public function createSampler(texture:Dynamic):Dynamic {
		//console.warn( 'Abstract class.' );
		return null;
	}

	public function destroySampler() {
	}

	public function createNodeBuilder(object:Dynamic, renderer:Dynamic, scene:Dynamic = null):Dynamic {
		return new GLSLNodeBuilder(object, renderer, scene);
	}

	public function createProgram(program:Dynamic) {
		var gl = this.gl;
		var stage = program.stage;
		var code = program.code;

		var shader = stage == 'fragment' ? gl.createShader(gl.FRAGMENT_SHADER) : gl.createShader(gl.VERTEX_SHADER);

		gl.shaderSource(shader, code);
		gl.compileShader(shader);

		this.set(program, {
			shaderGPU: shader
		});
	}

	public function destroyProgram(program:Dynamic) {
		console.warn('Abstract class.');
	}

	public function createRenderPipeline(renderObject:Dynamic, promises:Array<Dynamic>):Void {
		var gl = this.gl;
		var pipeline = renderObject.pipeline;

		var fragmentProgram = pipeline.fragmentProgram;
		var vertexProgram = pipeline.vertexProgram;

		var programGPU = gl.createProgram();
		var fragmentShader = this.get(fragmentProgram).shaderGPU;
		var vertexShader = this.get(vertexProgram).shaderGPU;

		gl.attachShader(programGPU, fragmentShader);
		gl.attachShader(programGPU, vertexShader);
		gl.linkProgram(programGPU);

		this.set(pipeline, {
			programGPU: programGPU,
			fragmentShader: fragmentShader,
			vertexShader: vertexShader
		});

		if (promises != null && this.parallel != null) {
			var p = new Promise(function(resolve) {
				var parallel = this.parallel;
				var checkStatus = function() {
					if (gl.getProgramParameter(programGPU, parallel.COMPLETION_STATUS_KHR)) {
						this._completeCompile(renderObject, pipeline);
						resolve();
					} else {
						requestAnimationFrame(checkStatus);
					}
				};

				checkStatus();
			});

			promises.push(p);
			return;
		}

		this._completeCompile(renderObject, pipeline);
	}

	public function _completeCompile(renderObject:Dynamic, pipeline:Dynamic):Void {
		var gl = this.gl;
		var pipelineData = this.get(pipeline);
		var programGPU = pipelineData.programGPU;
		var fragmentShader = pipelineData.fragmentShader;
		var vertexShader = pipelineData.vertexShader;

		if (gl.getProgramParameter(programGPU, gl.LINK_STATUS) == false) {
			console.error('THREE.WebGLBackend:', gl.getProgramInfoLog(programGPU));
			console.error('THREE.WebGLBackend:', gl.getShaderInfoLog(fragmentShader));
			console.error('THREE.WebGLBackend:', gl.getShaderInfoLog(vertexShader));
		}

		gl.useProgram(programGPU);

		this._setupBindings(renderObject.getBindings(), programGPU);

		this.set(pipeline, {
			programGPU: programGPU
		});
	}

	public function createComputePipeline(computePipeline:Dynamic, bindings:Dynamic):Void {
		var gl = this.gl;

		var fragmentProgram = {
			stage: 'fragment',
			code: '#version 300 es\nprecision highp float;\nvoid main() {}'
		};

		this.createProgram(fragmentProgram);

		var computeProgram = computePipeline.computeProgram;

		var programGPU = gl.createProgram();
		var fragmentShader = this.get(fragmentProgram).shaderGPU;
		var vertexShader = this.get(computeProgram).shaderGPU;

		var transforms = computeProgram.transforms;

		var transformVaryingNames:Array<String> = [];
		var transformAttributeNodes:Array<Dynamic> = [];

		for (var i = 0; i < transforms.length; i++) {
			var transform = transforms[i];
			transformVaryingNames.push(transform.varyingName);
			transformAttributeNodes.push(transform.attributeNode);
		}

		gl.attachShader(programGPU, fragmentShader);
		gl.attachShader(programGPU, vertexShader);

		gl.transformFeedbackVaryings(programGPU, transformVaryingNames, gl.SEPARATE_ATTRIBS);
		gl.linkProgram(programGPU);

		if (gl.getProgramParameter(programGPU, gl.LINK_STATUS) == false) {
			console.error('THREE.WebGLBackend:', gl.getProgramInfoLog(programGPU));
			console.error('THREE.WebGLBackend:', gl.getShaderInfoLog(fragmentShader));
			console.error('THREE.WebGLBackend:', gl.getShaderInfoLog(vertexShader));
		}

		gl.useProgram(programGPU);

		this.createBindings(bindings);

		this._setupBindings(bindings, programGPU);

		var attributeNodes = computeProgram.attributes;
		var attributes:Array<Dynamic> = [];
		var transformBuffers:Array<Dynamic> = [];

		for (var i = 0; i < attributeNodes.length; i++) {
			var attribute = attributeNodes[i].node.attribute;
			attributes.push(attribute);
			if (!this.has(attribute)) this.attributeUtils.createAttribute(attribute, gl.ARRAY_BUFFER);
		}

		for (var i = 0; i < transformAttributeNodes.length; i++) {
			var attribute = transformAttributeNodes[i].attribute;
			if (!this.has(attribute)) this.attributeUtils.createAttribute(attribute, gl.ARRAY_BUFFER);
			var attributeData = this.get(attribute);
			transformBuffers.push(attributeData);
		}

		this.set(computePipeline, {
			programGPU: programGPU,
			transformBuffers: transformBuffers,
			attributes: attributes
		});
	}

	public function createBindings(bindings:Dynamic) {
		this.updateBindings(bindings);
	}

	public function updateBindings(bindings:Dynamic) {
		var gl = this.gl;

		var groupIndex = 0;
		var textureIndex = 0;

		for (var binding in bindings) {
			if (binding.isUniformsGroup || binding.isUniformBuffer) {
				var bufferGPU = gl.createBuffer();
				var data = binding.buffer;

				gl.bindBuffer(gl.UNIFORM_BUFFER, bufferGPU);
				gl.bufferData(gl.UNIFORM_BUFFER, data, gl.DYNAMIC_DRAW);
				gl.bindBufferBase(gl.UNIFORM_BUFFER, groupIndex, bufferGPU);

				this.set(binding, {
					index: groupIndex++,
					bufferGPU: bufferGPU
				});
			} else if (binding.isSampledTexture) {
				var textureGPU = this.get(binding.texture).textureGPU;
				var glTextureType = this.get(binding.texture).glTextureType;
				this.set(binding, {
					index: textureIndex++,
					textureGPU: textureGPU,
					glTextureType: glTextureType
				});
			}
		}
	}

	public function updateBinding(binding:Dynamic) {
		var gl = this.gl;

		if (binding.isUniformsGroup || binding.isUniformBuffer) {
			var bindingData = this.get(binding);
			var bufferGPU = bindingData.bufferGPU;
			var data = binding.buffer;

			gl.bindBuffer(gl.UNIFORM_BUFFER, bufferGPU);
			gl.bufferData(gl.UNIFORM_BUFFER, data, gl.DYNAMIC_DRAW);
		}
	}

	public function createIndexAttribute(attribute:Dynamic) {
		var gl = this.gl;
		this.attributeUtils.createAttribute(attribute, gl.ELEMENT_ARRAY_BUFFER);
	}

	public function createAttribute(attribute:Dynamic) {
		if (this.has(attribute)) return;

		var gl = this.gl;
		this.attributeUtils.createAttribute(attribute, gl.ARRAY_BUFFER);
	}

	public function createStorageAttribute(attribute:Dynamic) {
		//console.warn( 'Abstract class.' );
	}

	public function updateAttribute(attribute:Dynamic) {
		this.attributeUtils.updateAttribute(attribute);
	}

	public function destroyAttribute(attribute:Dynamic) {
		this.attributeUtils.destroyAttribute(attribute);
	}

	public function updateSize() {
		//console.warn( 'Abstract class.' );
	}

	public function hasFeature(name:String):Bool {
		var keysMatching = Reflect.fields(GLFeatureName).filter(function(key) {
			return GLFeatureName[key] == name;
		});

		var extensions = this.extensions;

		for (var i = 0; i < keysMatching.length; i++) {
			if (extensions.has(keysMatching[i])) return true;
		}

		return false;
	}

	public function getMaxAnisotropy():Int {
		return this.capabilities.getMaxAnisotropy();
	}

	public function copyTextureToTexture(position:Dynamic, srcTexture:Dynamic, dstTexture:Dynamic, level:Int) {
		this.textureUtils.copyTextureToTexture(position, srcTexture, dstTexture, level);
	}

	public function copyFramebufferToTexture(texture:Dynamic, renderContext:Dynamic) {
		this.textureUtils.copyFramebufferToTexture(texture, renderContext);
	}

	public function _setFramebuffer(renderContext:Dynamic) {
		var gl = this.gl;
		var state = this.state;

		var currentFrameBuffer:Dynamic = null;

		if (renderContext.textures != null) {
			var renderTarget = renderContext.renderTarget;
			var renderTargetContextData = this.get(renderTarget);
			var samples = renderTarget.samples;
			var depthBuffer = renderTarget.depthBuffer;
			var stencilBuffer = renderTarget.stencilBuffer;
			var cubeFace = this.renderer._activeCubeFace;
			var isCube = renderTarget.isWebGLCubeRenderTarget == true;

			var msaaFb = renderTargetContextData.msaaFrameBuffer;
			var depthRenderbuffer = renderTargetContextData.depthRenderbuffer;

			var fb:Dynamic;

			if (isCube) {
				if (renderTargetContextData.cubeFramebuffers == null) {
					renderTargetContextData.cubeFramebuffers = [];
				}

				fb = renderTargetContextData.cubeFramebuffers[cubeFace];
			} else {
				fb = renderTargetContextData.framebuffer;
			}

			if (fb == null) {
				fb = gl.createFramebuffer();
				state.bindFramebuffer(gl.FRAMEBUFFER, fb);

				var textures = renderContext.textures;

				if (isCube) {
					renderTargetContextData.cubeFramebuffers[cubeFace] = fb;
					var textureGPU = this.get(textures[0]).textureGPU;
					gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_CUBE_MAP_POSITIVE_X + cubeFace, textureGPU, 0);
				} else {
					for (var i = 0; i < textures.length; i++) {
						var texture = textures[i];
						var textureData = this.get(texture);
						textureData.renderTarget = renderContext.renderTarget;

						var attachment = gl.COLOR_ATTACHMENT0 + i;
						gl.framebufferTexture2D(gl.FRAMEBUFFER, attachment, gl.TEXTURE_2D, textureData.textureGPU, 0);
					}

					renderTargetContextData.framebuffer = fb;
					state.drawBuffers(renderContext, fb);
				}

				if (renderContext.depthTexture != null) {
					var textureData = this.get(renderContext.depthTexture);
					var depthStyle = stencilBuffer ? gl.DEPTH_STENCIL_ATTACHMENT : gl.DEPTH_ATTACHMENT;
					gl.framebufferTexture2D(gl.FRAMEBUFFER, depthStyle, gl.TEXTURE_2D, textureData.textureGPU, 0);
				}
			}

			if (samples > 0) {
				if (msaaFb == null) {
					var invalidationArray:Array<Int> = [];
					msaaFb = gl.createFramebuffer();
					state.bindFramebuffer(gl.FRAMEBUFFER, msaaFb);

					var msaaRenderbuffers:Array<Dynamic> = [];
					var textures = renderContext.textures;

					for (var i = 0; i < textures.length; i++) {
						msaaRenderbuffers[i] = gl.createRenderbuffer();
						gl.bindRenderbuffer(gl.RENDERBUFFER, msaaRenderbuffers[i]);

						invalidationArray.push(gl.COLOR_ATTACHMENT0 + i);

						if (depthBuffer) {
							var depthStyle = stencilBuffer ? gl.DEPTH_STENCIL_ATTACHMENT : gl.DEPTH_ATTACHMENT;
							invalidationArray.push(depthStyle);
						}

						var texture = renderContext.textures[i];
						var textureData = this.get(texture);
						gl.renderbufferStorageMultisample(gl.RENDERBUFFER, samples, textureData.glInternalFormat, renderContext.width, renderContext.height);
						gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0
						gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0 + i, gl.RENDERBUFFER, msaaRenderbuffers[i]);


					}

					renderTargetContextData.msaaFrameBuffer = msaaFb;
					renderTargetContextData.msaaRenderbuffers = msaaRenderbuffers;

					if (depthRenderbuffer == null) {

						depthRenderbuffer = gl.createRenderbuffer();
						this.textureUtils.setupRenderBufferStorage(depthRenderbuffer, renderContext);

						renderTargetContextData.depthRenderbuffer = depthRenderbuffer;

						var depthStyle = stencilBuffer ? gl.DEPTH_STENCIL_ATTACHMENT : gl.DEPTH_ATTACHMENT;
						invalidationArray.push(depthStyle);

					}

					renderTargetContextData.invalidationArray = invalidationArray;

				}

				currentFrameBuffer = renderTargetContextData.msaaFrameBuffer;

			} else {

				currentFrameBuffer = fb;

			}

		}

		state.bindFramebuffer(gl.FRAMEBUFFER, currentFrameBuffer);

	}


	public function _getVaoKey(index:Dynamic, attributes:Array<Dynamic>):String {

		var key = [];

		if (index != null) {

			var indexData = this.get(index);

			key += ':' + indexData.id;

		}

		for (var i = 0; i < attributes.length; i++) {

			var attributeData = this.get(attributes[i]);

			key += ':' + attributeData.id;

		}

		return key;

	}

	public function _createVao(index:Dynamic, attributes:Array<Dynamic>):{vaoGPU:Dynamic, staticVao:Bool} {

		var gl = this.gl;

		var vaoGPU = gl.createVertexArray();
		var key = '';

		var staticVao = true;

		gl.bindVertexArray(vaoGPU);

		if (index != null) {

			var indexData = this.get(index);

			gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexData.bufferGPU);

			key += ':' + indexData.id;

		}

		for (var i = 0; i < attributes.length; i++) {

			var attribute = attributes[i];
			var attributeData = this.get(attribute);

			key += ':' + attributeData.id;

			gl.bindBuffer(gl.ARRAY_BUFFER, attributeData.bufferGPU);
			gl.enableVertexAttribArray(i);

			if (attribute.isStorageBufferAttribute || attribute.isStorageInstancedBufferAttribute) staticVao = false;

			var stride:Int, offset:Int;

			if (attribute.isInterleavedBufferAttribute == true) {

				stride = attribute.data.stride * attributeData.bytesPerElement;
				offset = attribute.offset * attributeData.bytesPerElement;

			} else {

				stride = 0;
				offset = 0;

			}

			if (attributeData.isInteger) {

				gl.vertexAttribIPointer(i, attribute.itemSize, attributeData.type, stride, offset);

			} else {

				gl.vertexAttribPointer(i, attribute.itemSize, attributeData.type, attribute.normalized, stride, offset);

			}

			if (attribute.isInstancedBufferAttribute && !attribute.isInterleavedBufferAttribute) {

				gl.vertexAttribDivisor(i, attribute.meshPerAttribute);

			} else if (attribute.isInterleavedBufferAttribute && attribute.data.isInstancedInterleavedBuffer) {

				gl.vertexAttribDivisor(i, attribute.data.meshPerAttribute);

			}

		}

		gl.bindBuffer(gl.ARRAY_BUFFER, null);

		this.vaoCache.set(key, vaoGPU);

		return {vaoGPU: vaoGPU, staticVao: staticVao};

	}

	public function _getTransformFeedback(transformBuffers:Array<Dynamic>):Dynamic {

		var key = '';

		for (var i = 0; i < transformBuffers.length; i++) {

			key += ':' + transformBuffers[i].id;

		}

		var transformFeedbackGPU = this.transformFeedbackCache.get(key);

		if (transformFeedbackGPU != null) {

			return transformFeedbackGPU;

		}

		var gl = this.gl;

		transformFeedbackGPU = gl.createTransformFeedback();

		gl.bindTransformFeedback(gl.TRANSFORM_FEEDBACK, transformFeedbackGPU);

		for (var i = 0; i < transformBuffers.length; i++) {

			var attributeData = transformBuffers[i];

			gl.bindBufferBase(gl.TRANSFORM_FEEDBACK_BUFFER, i, attributeData.transformBuffer);

		}

		gl.bindTransformFeedback(gl.TRANSFORM_FEEDBACK, null);

		this.transformFeedbackCache.set(key, transformFeedbackGPU);

		return transformFeedbackGPU;

	}


	public function _setupBindings(bindings:Dynamic, programGPU:Dynamic) {

		var gl = this.gl;

		for (var binding in bindings) {

			var bindingData = this.get(binding);
			var index = bindingData.index;

			if (binding.isUniformsGroup || binding.isUniformBuffer) {

				var location = gl.getUniformBlockIndex(programGPU, binding.name);
				gl.uniformBlockBinding(programGPU, location, index);

			} else if (binding.isSampledTexture) {

				var location = gl.getUniformLocation(programGPU, binding.name);
				gl.uniform1i(location, index);

			}

		}

	}

	public function _bindUniforms(bindings:Dynamic) {

		var gl = this.gl;
		var state = this.state;

		for (var binding in bindings) {

			var bindingData = this.get(binding);
			var index = bindingData.index;

			if (binding.isUniformsGroup || binding.isUniformBuffer) {

				gl.bindBufferBase(gl.UNIFORM_BUFFER, index, bindingData.bufferGPU);

			} else if (binding.isSampledTexture) {

				state.bindTexture(bindingData.glTextureType, bindingData.textureGPU, gl.TEXTURE0 + index);

			}

		}

	}

}

export default WebGLBackend;