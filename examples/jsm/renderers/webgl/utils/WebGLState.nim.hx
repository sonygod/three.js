import three.js.examples.jsm.renderers.webgl.utils.WebGLState.*;

class WebGLState {

	var backend:Backend;
	var gl:WebGLRenderingContext;
	var enabled:Map<Bool>;
	var currentFlipSided:Bool;
	var currentCullFace:Int;
	var currentProgram:WebGLProgram;
	var currentBlendingEnabled:Bool;
	var currentBlending:Int;
	var currentBlendSrc:Int;
	var currentBlendDst:Int;
	var currentBlendSrcAlpha:Int;
	var currentBlendDstAlpha:Int;
	var currentPremultipledAlpha:Bool;
	var currentPolygonOffsetFactor:Float;
	var currentPolygonOffsetUnits:Float;
	var currentColorMask:Bool;
	var currentDepthFunc:Int;
	var currentDepthMask:Bool;
	var currentStencilFunc:Int;
	var currentStencilRef:Int;
	var currentStencilFuncMask:Int;
	var currentStencilFail:Int;
	var currentStencilZFail:Int;
	var currentStencilZPass:Int;
	var currentStencilMask:Int;
	var currentLineWidth:Float;
	var currentBoundFramebuffers:Map<WebGLFramebuffer>;
	var currentDrawbuffers:Map<Array<Int>>;
	var maxTextures:Int;
	var currentTextureSlot:Int;
	var currentBoundTextures:Map<WebGLTexture>;

	var equationToGL:Map<Int>;
	var factorToGL:Map<Int>;

	public function new(backend:Backend) {
		this.backend = backend;
		this.gl = this.backend.gl;
		this.enabled = new Map<Bool>();
		this.currentFlipSided = null;
		this.currentCullFace = null;
		this.currentProgram = null;
		this.currentBlendingEnabled = false;
		this.currentBlending = null;
		this.currentBlendSrc = null;
		this.currentBlendDst = null;
		this.currentBlendSrcAlpha = null;
		this.currentBlendDstAlpha = null;
		this.currentPremultipledAlpha = null;
		this.currentPolygonOffsetFactor = null;
		this.currentPolygonOffsetUnits = null;
		this.currentColorMask = null;
		this.currentDepthFunc = null;
		this.currentDepthMask = null;
		this.currentStencilFunc = null;
		this.currentStencilRef = null;
		this.currentStencilFuncMask = null;
		this.currentStencilFail = null;
		this.currentStencilZFail = null;
		this.currentStencilZPass = null;
		this.currentStencilMask = null;
		this.currentLineWidth = null;
		this.currentBoundFramebuffers = new Map<WebGLFramebuffer>();
		this.currentDrawbuffers = new Map<Array<Int>>();
		this.maxTextures = this.gl.getParameter(this.gl.MAX_TEXTURE_IMAGE_UNITS);
		this.currentTextureSlot = null;
		this.currentBoundTextures = new Map<WebGLTexture>();
		if (!initialized) {
			this._init(this.gl);
			initialized = true;
		}
	}

	private function _init(gl:WebGLRenderingContext) {
		equationToGL = [
			AddEquation => gl.FUNC_ADD,
			SubtractEquation => gl.FUNC_SUBTRACT,
			ReverseSubtractEquation => gl.FUNC_REVERSE_SUBTRACT
		];
		factorToGL = [
			ZeroFactor => gl.ZERO,
			OneFactor => gl.ONE,
			SrcColorFactor => gl.SRC_COLOR,
			SrcAlphaFactor => gl.SRC_ALPHA,
			SrcAlphaSaturateFactor => gl.SRC_ALPHA_SATURATE,
			DstColorFactor => gl.DST_COLOR,
			DstAlphaFactor => gl.DST_ALPHA,
			OneMinusSrcColorFactor => gl.ONE_MINUS_SRC_COLOR,
			OneMinusSrcAlphaFactor => gl.ONE_MINUS_SRC_ALPHA,
			OneMinusDstColorFactor => gl.ONE_MINUS_DST_COLOR,
			OneMinusDstAlphaFactor => gl.ONE_MINUS_DST_ALPHA
		];
	}

	public function enable(id:Int) {
		if (!this.enabled.exists(id) || this.enabled.get(id) !== true) {
			this.gl.enable(id);
			this.enabled.set(id, true);
		}
	}

	public function disable(id:Int) {
		if (!this.enabled.exists(id) || this.enabled.get(id) !== false) {
			this.gl.disable(id);
			this.enabled.set(id, false);
		}
	}

	public function setFlipSided(flipSided:Bool) {
		if (this.currentFlipSided !== flipSided) {
			if (flipSided) {
				this.gl.frontFace(this.gl.CW);
			} else {
				this.gl.frontFace(this.gl.CCW);
			}
			this.currentFlipSided = flipSided;
		}
	}

	public function setCullFace(cullFace:Int) {
		if (cullFace !== CullFaceNone) {
			this.enable(this.gl.CULL_FACE);
			if (cullFace !== this.currentCullFace) {
				if (cullFace === CullFaceBack) {
					this.gl.cullFace(this.gl.BACK);
				} else if (cullFace === CullFaceFront) {
					this.gl.cullFace(this.gl.FRONT);
				} else {
					this.gl.cullFace(this.gl.FRONT_AND_BACK);
				}
			}
		} else {
			this.disable(this.gl.CULL_FACE);
		}
		this.currentCullFace = cullFace;
	}

	public function setLineWidth(width:Float) {
		if (this.currentLineWidth !== width) {
			this.gl.lineWidth(width);
			this.currentLineWidth = width;
		}
	}

	public function setBlending(blending:Int, blendEquation:Int, blendSrc:Int, blendDst:Int, blendEquationAlpha:Int, blendSrcAlpha:Int, blendDstAlpha:Int, premultipliedAlpha:Bool) {
		if (blending === NoBlending) {
			if (this.currentBlendingEnabled === true) {
				this.disable(this.gl.BLEND);
				this.currentBlendingEnabled = false;
			}
			return;
		}
		if (this.currentBlendingEnabled === false) {
			this.enable(this.gl.BLEND);
			this.currentBlendingEnabled = true;
		}
		if (blending !== CustomBlending) {
			if (blending !== this.currentBlending || premultipliedAlpha !== this.currentPremultipledAlpha) {
				if (this.currentBlendEquation !== AddEquation || this.currentBlendEquationAlpha !== AddEquation) {
					this.gl.blendEquation(this.gl.FUNC_ADD);
					this.currentBlendEquation = AddEquation;
					this.currentBlendEquationAlpha = AddEquation;
				}
				if (premultipliedAlpha) {
					switch (blending) {
						case NormalBlending:
							this.gl.blendFuncSeparate(this.gl.ONE, this.gl.ONE_MINUS_SRC_ALPHA, this.gl.ONE, this.gl.ONE_MINUS_SRC_ALPHA);
							break;
						case AdditiveBlending:
							this.gl.blendFunc(this.gl.ONE, this.gl.ONE);
							break;
						case SubtractiveBlending:
							this.gl.blendFuncSeparate(this.gl.ZERO, this.gl.ONE_MINUS_SRC_COLOR, this.gl.ZERO, this.gl.ONE);
							break;
						case MultiplyBlending:
							this.gl.blendFuncSeparate(this.gl.ZERO, this.gl.SRC_COLOR, this.gl.ZERO, this.gl.SRC_ALPHA);
							break;
						default:
							trace('THREE.WebGLState: Invalid blending: ', blending);
							break;
					}
				} else {
					switch (blending) {
						case NormalBlending:
							this.gl.blendFuncSeparate(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA, this.gl.ONE, this.gl.ONE_MINUS_SRC_ALPHA);
							break;
						case AdditiveBlending:
							this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE);
							break;
						case SubtractiveBlending:
							this.gl.blendFuncSeparate(this.gl.ZERO, this.gl.ONE_MINUS_SRC_COLOR, this.gl.ZERO, this.gl.ONE);
							break;
						case MultiplyBlending:
							this.gl.blendFunc(this.gl.ZERO, this.gl.SRC_COLOR);
							break;
						default:
							trace('THREE.WebGLState: Invalid blending: ', blending);
							break;
					}
				}
				this.currentBlendSrc = null;
				this.currentBlendDst = null;
				this.currentBlendSrcAlpha = null;
				this.currentBlendDstAlpha = null;
				this.currentBlending = blending;
				this.currentPremultipledAlpha = premultipliedAlpha;
			}
			return;
		}
		// custom blending
		blendEquationAlpha = blendEquationAlpha || blendEquation;
		blendSrcAlpha = blendSrcAlpha || blendSrc;
		blendDstAlpha = blendDstAlpha || blendDst;
		if (blendEquation !== this.currentBlendEquation || blendEquationAlpha !== this.currentBlendEquationAlpha) {
			this.gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
			this.currentBlendEquation = blendEquation;
			this.currentBlendEquationAlpha = blendEquationAlpha;
		}
		if (blendSrc !== this.currentBlendSrc || blendDst !== this.currentBlendDst || blendSrcAlpha !== this.currentBlendSrcAlpha || blendDstAlpha !== this.currentBlendDstAlpha) {
			this.gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
			this.currentBlendSrc = blendSrc;
			this.currentBlendDst = blendDst;
			this.currentBlendSrcAlpha = blendSrcAlpha;
			this.currentBlendDstAlpha = blendDstAlpha;
		}
		this.currentBlending = blending;
		this.currentPremultipledAlpha = false;
	}

	public function setColorMask(colorMask:Bool) {
		if (this.currentColorMask !== colorMask) {
			this.gl.colorMask(colorMask, colorMask, colorMask, colorMask);
			this.currentColorMask = colorMask;
		}
	}

	public function setDepthTest(depthTest:Bool) {
		if (depthTest) {
			this.enable(this.gl.DEPTH_TEST);
		} else {
			this.disable(this.gl.DEPTH_TEST);
		}
	}

	public function setDepthMask(depthMask:Bool) {
		if (this.currentDepthMask !== depthMask) {
			this.gl.depthMask(depthMask);
			this.currentDepthMask = depthMask;
		}
	}

	public function setDepthFunc(depthFunc:Int) {
		if (this.currentDepthFunc !== depthFunc) {
			switch (depthFunc) {
				case NeverDepth:
					this.gl.depthFunc(this.gl.NEVER);
					break;
				case AlwaysDepth:
					this.gl.depthFunc(this.gl.ALWAYS);
					break;
				case LessDepth:
					this.gl.depthFunc(this.gl.LESS);
					break;
				case LessEqualDepth:
					this.gl.depthFunc(this.gl.LEQUAL);
					break;
				case EqualDepth:
					this.gl.depthFunc(this.gl.EQUAL);
					break;
				case GreaterEqualDepth:
					this.gl.depthFunc(this.gl.GEQUAL);
					break;
				case GreaterDepth:
					this.gl.depthFunc(this.gl.GREATER);
					break;
				case NotEqualDepth:
					this.gl.depthFunc(this.gl.NOTEQUAL);
					break;
				default:
					this.gl.depthFunc(this.gl.LEQUAL);
			}
			this.currentDepthFunc = depthFunc;
		}
	}

	public function setStencilTest(stencilTest:Bool) {
		if (stencilTest) {
			this.enable(this.gl.STENCIL_TEST);
		} else {
			this.disable(this.gl.STENCIL_TEST);
		}
	}

	public function setStencilMask(stencilMask:Int) {
		if (this.currentStencilMask !== stencilMask) {
			this.gl.stencilMask(stencilMask);
			this.currentStencilMask = stencilMask;
		}
	}

	public function setStencilFunc(stencilFunc:Int, stencilRef:Int, stencilMask:Int) {
		if (this.currentStencilFunc !== stencilFunc || this.currentStencilRef !== stencilRef || this.currentStencilFuncMask !== stencilMask) {
			this.gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
			this.currentStencilFunc = stencilFunc;
			this.currentStencilRef = stencilRef;
			this.currentStencilFuncMask = stencilMask;
		}
	}

	public function setStencilOp(stencilFail:Int, stencilZFail:Int, stencilZPass:Int) {
		if (this.currentStencilFail !== stencilFail || this.currentStencilZFail !== stencilZFail || this.currentStencilZPass !== stencilZPass) {
			this.gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
			this.currentStencilFail = stencilFail;
			this.currentStencilZFail = stencilZFail;
			this.currentStencilZPass = stencilZPass;
		}
	}

	public function setMaterial(material:Material, frontFaceCW:Bool) {
		if (material.side === DoubleSide) {
			this.disable(this.gl.CULL_FACE);
		} else {
			this.enable(this.gl.CULL_FACE);
		}
		let flipSided = (material.side === BackSide);
		if (frontFaceCW) flipSided = !flipSided;
		this.setFlipSided(flipSided);
		if (material.blending === NormalBlending && material.transparent === false) {
			this.setBlending(NoBlending);
		} else {
			this.setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.premultipliedAlpha);
		}
		this.setDepthFunc(material.depthFunc);
		this.setDepthTest(material.depthTest);
		this.setDepthMask(material.depthWrite);
		this.setColorMask(material.colorWrite);
		const stencilWrite = material.stencilWrite;
		this.setStencilTest(stencilWrite);
		if (stencilWrite) {
			this.setStencilMask(material.stencilWriteMask);
			this.setStencilFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
			this.setStencilOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
		}
		this.setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
		if (material.alphaToCoverage === true) {
			this.enable(this.gl.SAMPLE_ALPHA_TO_COVERAGE);
		} else {
			this.disable(this.gl.SAMPLE_ALPHA_TO_COVERAGE);
		}
	}

	public function setPolygonOffset(polygonOffset:Bool, factor:Float, units:Float) {
		if (polygonOffset) {
			this.enable(this.gl.POLYGON_OFFSET_FILL);
			if (this.currentPolygonOffsetFactor !== factor || this.currentPolygonOffsetUnits !== units) {
				this.gl.polygonOffset(factor, units);
				this.currentPolygonOffsetFactor = factor;
				this.currentPolygonOffsetUnits = units;
			}
		} else {
			this.disable(this.gl.POLYGON_OFFSET_FILL);
		}
	}

	public function useProgram(program:WebGLProgram):Bool {
		if (this.currentProgram !== program) {
			this.gl.useProgram(program);
			this.currentProgram = program;
			return true;
		}
		return false;
	}

	public function bindFramebuffer(target:Int, framebuffer:WebGLFramebuffer):Bool {
		if (this.currentBoundFramebuffers.get(target) !== framebuffer) {
			this.gl.bindFramebuffer(target, framebuffer);
			this.currentBoundFramebuffers.set(target, framebuffer);
			if (target === this.gl.DRAW_FRAMEBUFFER) {
				this.currentBoundFramebuffers.set(this.gl.FRAMEBUFFER, framebuffer);
			}
			if (target === this.gl.FRAMEBUFFER) {
				this.currentBoundFramebuffers.set(this.gl.DRAW_FRAMEBUFFER, framebuffer);
			}
			return true;
		}
		return false;
	}

	public function drawBuffers(renderContext:RenderContext, framebuffer:WebGLFramebuffer) {
		let drawBuffers:Array<Int>;
		let needsUpdate:Bool = false;
		if (renderContext.textures !== null) {
			drawBuffers = this.currentDrawbuffers.get(framebuffer);
			if (drawBuffers === null) {
				drawBuffers = [];
				this.currentDrawbuffers.set(framebuffer, drawBuffers);
			}
			const textures:Array<WebGLTexture> = renderContext.textures;
			if (drawBuffers.length !== textures.length || drawBuffers[0] !== this.gl.COLOR_ATTACHMENT0) {
				for (i in 0...textures.length) {
					drawBuffers[i] = this.gl.COLOR_ATTACHMENT0 + i;
				}
				drawBuffers.length = textures.length;
				needsUpdate = true;
			}
		} else {
			if (drawBuffers[0] !== this.gl.BACK) {
				drawBuffers[0] = this.gl.BACK;
				needsUpdate = true;
			}
		}
		if (needsUpdate) {
			this.gl.drawBuffers(drawBuffers);
		}
	}

	public function activeTexture(webglSlot:Int) {
		if (webglSlot === null) webglSlot = this.gl.TEXTURE0 + this.maxTextures - 1;
		if (this.currentTextureSlot !== webglSlot) {
			this.gl.activeTexture(webglSlot);
			this.currentTextureSlot = webglSlot;
		}
	}

	public function bindTexture(webglType:Int, webglTexture:WebGLTexture, webglSlot:Int) {
		if (webglSlot === null) {
			if (this.currentTextureSlot === null) {
				webglSlot = this.gl.TEXTURE0 + this.maxTextures - 1;
			} else {
				webglSlot = this.currentTextureSlot;
			}
		}
		let boundTexture:WebGLTexture = this.currentBoundTextures.get(webglSlot);
		if (boundTexture === null) {
			boundTexture = { type: null, texture: null };
			this.currentBoundTextures.set(webglSlot, boundTexture);
		}
		if (boundTexture.type !== webglType || boundTexture.texture !== webglTexture) {
			if (this.currentTextureSlot !== webglSlot) {
				this.gl.activeTexture(webglSlot);
				this.currentTextureSlot = webglSlot;
			}
			this.gl.bindTexture(webglType, webglTexture);
			boundTexture.type = webglType;
			boundTexture.texture = webglTexture;
		}
	}

	public function unbindTexture() {
		let boundTexture:WebGLTexture = this.currentBoundTextures.get(this.currentTextureSlot);
		if (boundTexture !== null && boundTexture.type !== null) {
			this.gl.bindTexture(boundTexture.type, null);
			boundTexture.type = null;
			boundTexture.texture = null;
		}
	}

}