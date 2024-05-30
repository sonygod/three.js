import three.js.src.constants.NotEqualDepth;
import three.js.src.constants.GreaterDepth;
import three.js.src.constants.GreaterEqualDepth;
import three.js.src.constants.EqualDepth;
import three.js.src.constants.LessEqualDepth;
import three.js.src.constants.LessDepth;
import three.js.src.constants.AlwaysDepth;
import three.js.src.constants.NeverDepth;
import three.js.src.constants.CullFaceFront;
import three.js.src.constants.CullFaceBack;
import three.js.src.constants.CullFaceNone;
import three.js.src.constants.DoubleSide;
import three.js.src.constants.BackSide;
import three.js.src.constants.CustomBlending;
import three.js.src.constants.MultiplyBlending;
import three.js.src.constants.SubtractiveBlending;
import three.js.src.constants.AdditiveBlending;
import three.js.src.constants.NoBlending;
import three.js.src.constants.NormalBlending;
import three.js.src.constants.AddEquation;
import three.js.src.constants.SubtractEquation;
import three.js.src.constants.ReverseSubtractEquation;
import three.js.src.constants.MinEquation;
import three.js.src.constants.MaxEquation;
import three.js.src.constants.ZeroFactor;
import three.js.src.constants.OneFactor;
import three.js.src.constants.SrcColorFactor;
import three.js.src.constants.SrcAlphaFactor;
import three.js.src.constants.SrcAlphaSaturateFactor;
import three.js.src.constants.DstColorFactor;
import three.js.src.constants.DstAlphaFactor;
import three.js.src.constants.OneMinusSrcColorFactor;
import three.js.src.constants.OneMinusSrcAlphaFactor;
import three.js.src.constants.OneMinusDstColorFactor;
import three.js.src.constants.OneMinusDstAlphaFactor;
import three.js.src.constants.ConstantColorFactor;
import three.js.src.constants.OneMinusConstantColorFactor;
import three.js.src.constants.ConstantAlphaFactor;
import three.js.src.constants.OneMinusConstantAlphaFactor;
import three.js.src.math.Color;
import three.js.src.math.Vector4;

class WebGLState {

	function new(gl) {

		function ColorBuffer() {

			var locked = false;

			var color = new Vector4();
			var currentColorMask = null;
			var currentColorClear = new Vector4(0, 0, 0, 0);

			return {

				setMask: function(colorMask) {

					if (currentColorMask !== colorMask && !locked) {

						gl.colorMask(colorMask, colorMask, colorMask, colorMask);
						currentColorMask = colorMask;

					}

				},

				setLocked: function(lock) {

					locked = lock;

				},

				setClear: function(r, g, b, a, premultipliedAlpha) {

					if (premultipliedAlpha === true) {

						r *= a; g *= a; b *= a;

					}

					color.set(r, g, b, a);

					if (currentColorClear.equals(color) === false) {

						gl.clearColor(r, g, b, a);
						currentColorClear.copy(color);

					}

				},

				reset: function() {

					locked = false;

					currentColorMask = null;
					currentColorClear.set(-1, 0, 0, 0); // set to invalid state

				}

			};

		}

		function DepthBuffer() {

			var locked = false;

			var currentDepthMask = null;
			var currentDepthFunc = null;
			var currentDepthClear = null;

			return {

				setTest: function(depthTest) {

					if (depthTest) {

						enable(gl.DEPTH_TEST);

					} else {

						disable(gl.DEPTH_TEST);

					}

				},

				setMask: function(depthMask) {

					if (currentDepthMask !== depthMask && !locked) {

						gl.depthMask(depthMask);
						currentDepthMask = depthMask;

					}

				},

				setFunc: function(depthFunc) {

					if (currentDepthFunc !== depthFunc) {

						switch (depthFunc) {

							case NeverDepth:

								gl.depthFunc(gl.NEVER);
								break;

							case AlwaysDepth:

								gl.depthFunc(gl.ALWAYS);
								break;

							case LessDepth:

								gl.depthFunc(gl.LESS);
								break;

							case LessEqualDepth:

								gl.depthFunc(gl.LEQUAL);
								break;

							case EqualDepth:

								gl.depthFunc(gl.EQUAL);
								break;

							case GreaterEqualDepth:

								gl.depthFunc(gl.GEQUAL);
								break;

							case GreaterDepth:

								gl.depthFunc(gl.GREATER);
								break;

							case NotEqualDepth:

								gl.depthFunc(gl.NOTEQUAL);
								break;

							default:

								gl.depthFunc(gl.LEQUAL);

						}

						currentDepthFunc = depthFunc;

					}

				},

				setLocked: function(lock) {

					locked = lock;

				},

				setClear: function(depth) {

					if (currentDepthClear !== depth) {

						gl.clearDepth(depth);
						currentDepthClear = depth;

					}

				},

				reset: function() {

					locked = false;

					currentDepthMask = null;
					currentDepthFunc = null;
					currentDepthClear = null;

				}

			};

		}

		function StencilBuffer() {

			var locked = false;

			var currentStencilMask = null;
			var currentStencilFunc = null;
			var currentStencilRef = null;
			var currentStencilFuncMask = null;
			var currentStencilFail = null;
			var currentStencilZFail = null;
			var currentStencilZPass = null;
			var currentStencilClear = null;

			return {

				setTest: function(stencilTest) {

					if (!locked) {

						if (stencilTest) {

							enable(gl.STENCIL_TEST);

						} else {

							disable(gl.STENCIL_TEST);

						}

					}

				},

				setMask: function(stencilMask) {

					if (currentStencilMask !== stencilMask && !locked) {

						gl.stencilMask(stencilMask);
						currentStencilMask = stencilMask;

					}

				},

				setFunc: function(stencilFunc, stencilRef, stencilMask) {

					if (currentStencilFunc !== stencilFunc ||
						currentStencilRef !== stencilRef ||
						currentStencilFuncMask !== stencilMask) {

						gl.stencilFunc(stencilFunc, stencilRef, stencilMask);

						currentStencilFunc = stencilFunc;
						currentStencilRef = stencilRef;
						currentStencilFuncMask = stencilMask;

					}

				},

				setOp: function(stencilFail, stencilZFail, stencilZPass) {

					if (currentStencilFail !== stencilFail ||
						currentStencilZFail !== stencilZFail ||
						currentStencilZPass !== stencilZPass) {

						gl.stencilOp(stencilFail, stencilZFail, stencilZPass);

						currentStencilFail = stencilFail;
						currentStencilZFail = stencilZFail;
						currentStencilZPass = stencilZPass;

					}

				},

				setLocked: function(lock) {

					locked = lock;

				},

				setClear: function(stencil) {

					if (currentStencilClear !== stencil) {

						gl.clearStencil(stencil);
						currentStencilClear = stencil;

					}

				},

				reset: function() {

					locked = false;

					currentStencilMask = null;
					currentStencilFunc = null;
					currentStencilRef = null;
					currentStencilFuncMask = null;
					currentStencilFail = null;
					currentStencilZFail = null;
					currentStencilZPass = null;
					currentStencilClear = null;

				}

			};

		}

		//

		var colorBuffer = new ColorBuffer();
		var depthBuffer = new DepthBuffer();
		var stencilBuffer = new StencilBuffer();

		var uboBindings = new haxe.ds.WeakMap();
		var uboProgramMap = new haxe.ds.WeakMap();

		var enabledCapabilities = {};

		var currentBoundFramebuffers = {};
		var currentDrawbuffers = new haxe.ds.WeakMap();
		var defaultDrawbuffers = [];

		var currentProgram = null;

		var currentBlendingEnabled = false;
		var currentBlending = null;
		var currentBlendEquation = null;
		var currentBlendSrc = null;
		var currentBlendDst = null;
		var currentBlendEquationAlpha = null;
		var currentBlendSrcAlpha = null;
		var currentBlendDstAlpha = null;
		var currentBlendColor = new Color(0, 0, 0);
		var currentBlendAlpha = 0;
		var currentPremultipledAlpha = false;

		var currentFlipSided = null;
		var currentCullFace = null;

		var currentLineWidth = null;

		var currentPolygonOffsetFactor = null;
		var currentPolygonOffsetUnits = null;

		var maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

		var lineWidthAvailable = false;
		var version = 0;
		var glVersion = gl.getParameter(gl.VERSION);

		if (glVersion.indexOf('WebGL') !== -1) {

			version = parseFloat(/^WebGL (\d)/.exec(glVersion)[1]);
			lineWidthAvailable = (version >= 1.0);

		} else if (glVersion.indexOf('OpenGL ES') !== -1) {

			version = parseFloat(/^OpenGL ES (\d)/.exec(glVersion)[1]);
			lineWidthAvailable = (version >= 2.0);

		}

		var currentTextureSlot = null;
		var currentBoundTextures = {};

		var scissorParam = gl.getParameter(gl.SCISSOR_BOX);
		var viewportParam = gl.getParameter(gl.VIEWPORT);

		var currentScissor = new Vector4().fromArray(scissorParam);
		var currentViewport = new Vector4().fromArray(viewportParam);

		function createTexture(type, target, count, dimensions) {

			var data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
			var texture = gl.createTexture();

			gl.bindTexture(type, texture);
			gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
			gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

			for (i in 0...count) {

				if (type === gl.TEXTURE_3D || type === gl.TEXTURE_2D_ARRAY) {

					gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);

				} else {

					gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);

				}

			}

			return texture;

		}

		var emptyTextures = {};
		emptyTextures[gl.TEXTURE_2D] = createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1);
		emptyTextures[gl.TEXTURE_CUBE_MAP] = createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, 6);
		emptyTextures[gl.TEXTURE_2D_ARRAY] = createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1);
		emptyTextures[gl.TEXTURE_3D] = createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1);

		// init

		colorBuffer.setClear(0, 0, 0, 1);
		depthBuffer.setClear(1);
		stencilBuffer.setClear(0);

		enable(gl.DEPTH_TEST);
		depthBuffer.setFunc(LessEqualDepth);

		setFlipSided(false);
		setCullFace(CullFaceBack);
		enable(gl.CULL_FACE);

		setBlending(NoBlending);

		//

		function enable(id) {

			if (enabledCapabilities[id] !== true) {

				gl.enable(id);
				enabledCapabilities[id] = true;

			}

		}

		function disable(id) {

			if (enabledCapabilities[id] !== false) {

				gl.disable(id);
				enabledCapabilities[id] = false;

			}

		}

		function bindFramebuffer(target, framebuffer) {

			if (currentBoundFramebuffers[target] !== framebuffer) {

				gl.bindFramebuffer(target, framebuffer);

				currentBoundFramebuffers[target] = framebuffer;

				// gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER

				if (target === gl.DRAW_FRAMEBUFFER) {

					currentBoundFramebuffers[gl.FRAMEBUFFER] = framebuffer;

				}

				if (target === gl.FRAMEBUFFER) {

					currentBoundFramebuffers[gl.DRAW_FRAMEBUFFER] = framebuffer;

				}

				return true;

			}

			return false;

		}

		function drawBuffers(renderTarget, framebuffer) {

			var drawBuffers = defaultDrawbuffers;

			var needsUpdate = false;

			if (renderTarget) {

				drawBuffers = currentDrawbuffers.get(framebuffer);

				if (drawBuffers === undefined) {

					drawBuffers = [];
					currentDrawbuffers.set(framebuffer, drawBuffers);

				}

				var textures = renderTarget.textures;

				if (drawBuffers.length !== textures.length || drawBuffers[0] !== gl.COLOR_ATTACHMENT0) {

					for (i in 0...textures.length) {

						drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;

					}

					drawBuffers.length = textures.length;

					needsUpdate = true;

				}

			} else {

				if (drawBuffers[0] !== gl.BACK) {

					drawBuffers[0] = gl.BACK;

					needsUpdate = true;

				}

			}

			if (needsUpdate) {

				gl.drawBuffers(drawBuffers);

			}

		}

		function useProgram(program) {

			if (currentProgram !== program) {

				gl.useProgram(program);

				currentProgram = program;

				return true;

			}

			return false;

		}

		var equationToGL = {
			[AddEquation]: gl.FUNC_ADD,
			[SubtractEquation]: gl.FUNC_SUBTRACT,
			[ReverseSubtractEquation]: gl.FUNC_REVERSE_SUBTRACT
		};

		equationToGL[MinEquation] = gl.MIN;
		equationToGL[MaxEquation] = gl.MAX;

		var factorToGL = {
			[ZeroFactor]: gl.ZERO,
			[OneFactor]: gl.ONE,
			[SrcColorFactor]: gl.SRC_COLOR,
			[SrcAlphaFactor]: gl.SRC_ALPHA,
			[SrcAlphaSaturateFactor]: gl.SRC_ALPHA_SATURATE,
			[DstColorFactor]: gl.DST_COLOR,
			[DstAlphaFactor]: gl.DST_ALPHA,
			[OneMinusSrcColorFactor]: gl.ONE_MINUS_SRC_COLOR,
			[OneMinusSrcAlphaFactor]: gl.ONE_MINUS_SRC_ALPHA,
			[OneMinusDstColorFactor]: gl.ONE_MINUS_DST_COLOR,
			[OneMinusDstAlphaFactor]: gl.ONE_MINUS_DST_ALPHA,
			[ConstantColorFactor]: gl.CONSTANT_COLOR,
			[OneMinusConstantColorFactor]: gl.ONE_MINUS_CONSTANT_COLOR,
			[ConstantAlphaFactor]: gl.CONSTANT_ALPHA,
			[OneMinusConstantAlphaFactor]: gl.ONE_MINUS_CONSTANT_ALPHA
		};

		function setBlending(blending, blendEquation, blendSrc, blendDst, blendEquationAlpha, blendSrcAlpha, blendDstAlpha, blendColor, blendAlpha, premultipliedAlpha) {

			if (blending === NoBlending) {

				if (currentBlendingEnabled === true) {

					disable(gl.BLEND);
					currentBlendingEnabled = false;

				}

				return;

			}

			if (currentBlendingEnabled === false) {

				enable(gl.BLEND);
				currentBlendingEnabled = true;

			}

			if (blending !== CustomBlending) {

				if (blending !== currentBlending || premultipliedAlpha !== currentPremultipledAlpha) {

					if (currentBlendEquation !== AddEquation || currentBlendEquationAlpha !== AddEquation) {

						gl.blendEquation(gl.FUNC_ADD);

						currentBlendEquation = AddEquation;
						currentBlendEquationAlpha = AddEquation;

					}

					if (premultipliedAlpha) {

						switch (blending) {

							case NormalBlending:
								gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
								break;

							case AdditiveBlending:
								gl.blendFunc(gl.ONE, gl.ONE);
								break;

							case SubtractiveBlending:
								gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
								break;

							case MultiplyBlending:
								gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
								break;

							default:
								console.error('THREE.WebGLState: Invalid blending: ', blending);
								break;

						}

					} else {

						switch (blending) {

							case NormalBlending:
								gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
								break;

							case AdditiveBlending:
								gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
								break;

							case SubtractiveBlending:
								gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
								break;

							case MultiplyBlending:
								gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
								break;

							default:
								console.error('THREE.WebGLState: Invalid blending: ', blending);
								break;

						}

					}

					currentBlendSrc = null;
					currentBlendDst = null;
					currentBlendSrcAlpha = null;
					currentBlendDstAlpha = null;
					currentBlendColor.set(0, 0, 0);
					currentBlendAlpha = 0;

					currentBlending = blending;
					currentPremultipledAlpha = premultipliedAlpha;

				}

				return;

			}

			// custom blending

			blendEquationAlpha = blendEquationAlpha || blendEquation;
			blendSrcAlpha = blendSrcAlpha || blendSrc;
			blendDstAlpha = blendDstAlpha || blendDst;

			if (blendEquation !== currentBlendEquation || blendEquationAlpha !== currentBlendEquationAlpha) {

				gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);

				currentBlendEquation = blendEquation;
				currentBlendEquationAlpha = blendEquationAlpha;

			}

			if (blendSrc !== currentBlendSrc || blendDst !== currentBlendDst || blendSrcAlpha !== currentBlendSrcAlpha || blendDstAlpha !== currentBlendDstAlpha) {

				gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);

				currentBlendSrc = blendSrc;
				currentBlendDst = blendDst;
				currentBlendSrcAlpha = blendSrcAlpha;
				currentBlendDstAlpha = blendDstAlpha;

			}

			if (blendColor.equals(currentBlendColor) === false || blendAlpha !== currentBlendAlpha) {

				gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);

				currentBlendColor.copy(blendColor);
				currentBlendAlpha = blendAlpha;

			}

			currentBlending = blending;
			currentPremultipledAlpha = false;

		}

		function setMaterial(material, frontFaceCW) {

			material.side === DoubleSide
				? disable(gl.CULL_FACE)
				: enable(gl.CULL_FACE);

			var flipSided = (material.side === BackSide);
			if (frontFaceCW) flipSided = !flipSided;

			setFlipSided(flipSided);

			(material.blending === NormalBlending && material.transparent === false)
				? setBlending(NoBlending)
				: setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.blendColor, material.blendAlpha, material.premultipliedAlpha);

			depthBuffer.setFunc(material.depthFunc);
			depthBuffer.setTest(material.depthTest);
			depthBuffer.setMask(material.depthWrite);
			colorBuffer.setMask(material.colorWrite);

			var stencilWrite = material.stencilWrite;
			stencilBuffer.setTest(stencilWrite);
			if (stencilWrite) {

				stencilBuffer.setMask(material.stencilWriteMask);
				stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
				stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);

			}

			setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);

			material.alphaToCoverage === true
				? enable(gl.SAMPLE_ALPHA_TO_COVERAGE)
				: disable(gl.SAMPLE_ALPHA_TO_COVERAGE);

		}

		//

		function setFlipSided(flipSided) {

			if (currentFlipSided !== flipSided) {

				if (flipSided) {

					gl.frontFace(gl.CW);

				} else {

					gl.frontFace(gl.CCW);

				}

				currentFlipSided = flipSided;

			}

		}

		function setCullFace(cullFace) {

			if (cullFace !== CullFaceNone) {

				enable(gl.CULL_FACE);

				if (cullFace !== currentCullFace) {

					if (cullFace === CullFaceBack) {

						gl.cullFace(gl.BACK);

					} else if (cullFace === CullFaceFront) {

						gl.cullFace(gl.FRONT);

					} else {

						gl.cullFace(gl.FRONT_AND_BACK);

					}

				}

			} else {

				disable(gl.CULL_FACE);

			}

			currentCullFace = cullFace;

		}

		function setLineWidth(width) {

			if (width !== currentLineWidth) {

				if (lineWidthAvailable) gl.lineWidth(width);

				currentLineWidth = width;

			}

		}

		function setPolygonOffset(polygonOffset, factor, units) {

			if (polygonOffset) {

				enable(gl.POLYGON_OFFSET_FILL);

				if (currentPolygonOffsetFactor !== factor || currentPolygonOffsetUnits !== units) {

					gl.polygonOffset(factor, units);

					currentPolygonOffsetFactor = factor;
					currentPolygonOffsetUnits = units;

				}

			} else {

				disable(gl.POLYGON_OFFSET_FILL);

			}

		}

		function setScissorTest(scissorTest) {

			if (scissorTest) {

				enable(gl.SCISSOR_TEST);

			} else {

				disable(gl.SCISSOR_TEST);

			}

		}

		// texture

		function activeTexture(webglSlot) {

			if (webglSlot === undefined) webglSlot = gl.TEXTURE0 + maxTextures - 1;

			if (currentTextureSlot !== webglSlot) {

				gl.activeTexture(webglSlot);
				currentTextureSlot = webglSlot;

			}

		}

		function bindTexture(webglType, webglTexture, webglSlot) {

			if (webglSlot === undefined) {

				if (currentTextureSlot === null) {

					webglSlot = gl.TEXTURE0 + maxTextures - 1;

				} else {

					webglSlot = currentTextureSlot;

				}

			}

			var boundTexture = currentBoundTextures[webglSlot];

			if (boundTexture === undefined) {

				boundTexture = {type: undefined, texture: undefined};
				currentBoundTextures[webglSlot] = boundTexture;

			}

			if (boundTexture.type !== webglType || boundTexture.texture !== webglTexture) {

				if (currentTextureSlot !== webglSlot) {

					gl.activeTexture(webglSlot);
					currentTextureSlot = webglSlot;

				}

				gl.bindTexture(webglType, webglTexture || emptyTextures[webglType]);

				boundTexture.type = webglType;
				boundTexture.texture = webglTexture;

			}

		}

		function unbindTexture() {

			var boundTexture = currentBoundTextures[currentTextureSlot];

			if (boundTexture !== undefined && boundTexture.type !== undefined) {

				gl.bindTexture(boundTexture.type, null);

				boundTexture.type = undefined;
				boundTexture.texture = undefined;

			}

		}

		function compressedTexImage2D() {

			try {

				gl.compressedTexImage2D.apply(gl, arguments);

			} catch (error) {

				console.error('THREE.WebGLState:', error);

			}

		}

		function compressedTexImage3D() {

			try {

				gl.compressedTexImage3D.apply(gl, arguments);

			} catch (error) {

				console.error('THREE.WebGLState:', error);

			}

		}

		function texSubImage2D() {

			try {

				gl.texSubImage2D.apply(gl, arguments);

			} catch (error) {

				console.error('THREE.WebGLState:', error);

			}

		}

		function texSubImage3D() {

			try {

				gl.texSubImage3D.apply(gl, arguments);

			} catch (error) {

				console.error('THREE.WebGLState:', error);

			}

		}

		function compressedTexSubImage2D() {

			try {

				gl.compressedTexSubImage2D.apply(gl, arguments);

			} catch (error) {

				console.error('THREE.WebGLState:', error);

			}

		}

		function compressedTexSubImage3D() {

			try {

				gl.compressedTexSubImage3D.apply(gl, arguments);

			} catch (error) {

				console.error('THREE.WebGLState:', error);

			}

		}

		function texStorage2D() {

			try {

				gl.texStorage2D.apply(gl, arguments);

			} catch (error) {

				console.error('THREE.WebGLState:', error);

			}

		}

		function texStorage3D() {

			try {

				gl.texStorage3D.apply(gl, arguments);

			} catch (error) {

				console.error('THREE.WebGLState:', error);

			}

		}

		function texImage2D() {

			try {

				gl.texImage2D.apply(gl, arguments);

			} catch (error) {

				console.error('THREE.WebGLState:', error);

			}

		}

		function texImage3D() {

			try {

				gl.texImage3D.apply(gl, arguments);

			} catch (error) {

				console.error('THREE.WebGLState:', error);

			}

		}

		//

		function scissor(scissor) {

			if (currentScissor.equals(scissor) === false) {

				gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
				currentScissor.copy(scissor);

			}

		}

		function viewport(viewport) {

			if (currentViewport.equals(viewport) === false) {

				gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
				currentViewport.copy(viewport);

			}

		}

		function updateUBOMapping(uniformsGroup, program) {

			var mapping = uboProgramMap.get(program);

			if (mapping === undefined) {

				mapping = new haxe.ds.WeakMap();

				uboProgramMap.set(program, mapping);

			}

			var blockIndex = mapping.get(uniformsGroup);

			if (blockIndex === undefined) {

				blockIndex = gl.getUniformBlockIndex(program, uniformsGroup.name);

				mapping.set(uniformsGroup, blockIndex);

			}

		}

		function uniformBlockBinding(uniformsGroup, program) {

			var mapping = uboProgramMap.get(program);
			var blockIndex = mapping.get(uniformsGroup);

			if (uboBindings.get(program) !== blockIndex) {

				// bind shader specific block index to global block point
				gl.uniformBlockBinding(program, blockIndex, uniformsGroup.__bindingPointIndex);

				uboBindings.set(program, blockIndex);

			}

		}

		//

		function reset() {

			// reset state

			gl.disable(gl.BLEND);
			gl.disable(gl.CULL_FACE);
			gl.disable(gl.DEPTH_TEST);
			gl.disable(gl.POLYGON_OFFSET_FILL);
			gl.disable(gl.SCISSOR_TEST);
			gl.disable(gl.STENCIL_TEST);
			gl.disable(gl.SAMPLE_ALPHA_TO_COVERAGE);

			gl.blendEquation(gl.FUNC_ADD);
			gl.blendFunc(gl.ONE, gl.ZERO);
			gl.blendFuncSeparate(gl.ONE, gl.ZERO, gl.ONE, gl.ZERO);
			gl.blendColor(0, 0, 0, 0);

			gl.colorMask(true, true, true, true);
			gl.clearColor(0, 0, 0, 0);

			gl.depthMask(true);
			gl.depthFunc(gl.LESS);
			gl.clearDepth(1);

			gl.stencilMask(0xffffffff);
			gl.stencilFunc(gl.ALWAYS, 0, 0xffffffff);
			gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
			gl.clearStencil(0);

			gl.cullFace(gl.BACK);
			gl.frontFace(gl.CCW);

			gl.polygonOffset(0, 0);

			gl.activeTexture(gl.TEXTURE0);

			gl.bindFramebuffer(gl.FRAMEBUFFER, null);
			gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
			gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);

			gl.useProgram(null);

			gl.lineWidth(1);

			gl.scissor(0, 0, gl.canvas.width, gl.canvas.height);
			gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

			// reset internals

			enabledCapabilities = {};

			currentTextureSlot = null;
			currentBoundTextures = {};

			currentBoundFramebuffers = {};
			currentDrawbuffers = new haxe.ds.WeakMap();
			defaultDrawbuffers = [];

			currentProgram = null;

			currentBlendingEnabled = false;
			currentBlending = null;
			currentBlendEquation = null;
			currentBlendSrc = null;
			currentBlendDst = null;
			currentBlendEquationAlpha = null;
			currentBlendSrcAlpha = null;
			currentBlendDstAlpha = null;
			currentBlendColor.set(0, 0, 0);
			currentBlendAlpha = 0;
			currentPremultipledAlpha = false;

			currentFlipSided = null;
			currentCullFace = null;

			currentLineWidth = null;

			currentPolygonOffsetFactor = null;
			currentPolygonOffsetUnits = null;

			currentScissor.set(0, 0, gl.canvas.width, gl.canvas.height);
			currentViewport.set(0, 0, gl.canvas.width, gl.canvas.height);

			colorBuffer.reset();
			depthBuffer.reset();
			stencilBuffer.reset();

		}

		return {

			buffers: {
				color: colorBuffer,
				depth: depthBuffer,
				stencil: stencilBuffer
			},

			enable: enable,
			disable: disable,

			bindFramebuffer: bindFramebuffer,
			drawBuffers: drawBuffers,

			useProgram: useProgram,

			setBlending: setBlending,
			setMaterial: setMaterial,

			setFlipSided: setFlipSided,
			setCullFace: setCullFace,

			setLineWidth: setLineWidth,
			setPolygonOffset: setPolygonOffset,

			setScissorTest: setScissorTest,

			activeTexture: activeTexture,
			bindTexture: bindTexture,
			unbindTexture: unbindTexture,
			compressedTexImage2D: compressedTexImage2D,
			compressedTexImage3D: compressedTexImage3D,
			texImage2D: texImage2D,
			texImage3D: texImage3D,

			updateUBOMapping: updateUBOMapping,
			uniform 以下是将 JavaScript 代码转换为 Haxe 的结果：