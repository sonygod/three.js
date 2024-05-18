import openfl.utils.Enum;
import openfl.display.GLTexture;
import openfl.display3D.Context3DProgram;
import openfl.display3D.Context3DVertexBuffer;
import openfl.display3D.Context3DRenderbuffer;
import openfl.display3D.Context3DFRAMEBUFFER_ATTACHMENT;

@:forward
class WebGLState {

	public var backend:Dynamic;
	public var gl:Dynamic;

	public var enabled:Object = {};
	public var currentFlipSided:Bool = false;
	public var currentCullFace:Int = 0;
	public var currentProgram:Context3DProgram;
	public var currentBlendingEnabled:Bool = false;
	public var currentBlending:Int = 0;
	public var currentBlendSrc:Int = 0;
	public var currentBlendDst:Int = 0;
	public var currentBlendSrcAlpha:Int = 0;
	public var currentBlendDstAlpha:Int = 0;
	public var currentPremultipledAlpha:Bool = false;
	public var currentPolygonOffsetFactor:Float = 0.0;
	public var currentPolygonOffsetUnits:Float = 0.0;
	public var currentColorMask:Array<Bool> = [true, true, true, true];
	public var currentDepthFunc:Int = 0;
	public var currentDepthMask:Bool = true;
	public var currentStencilFunc:Int = 0;
	public var currentStencilRef:Int = 0;
	public var currentStencilFuncMask:Int = 0xFFFFFFFF;
	public var currentStencilFail:Int = 0;
	public var currentStencilZFail:Int = 0;
	public var currentStencilZPass:Int = 0;
	public var currentStencilMask:Int = 0xFFFFFFFF;
	public var currentLineWidth:Float = 1.0;

	public var currentBoundFramebuffers:Object = {};
	public var currentDrawbuffers:Map<Dynamic, Array<Int>> = new Map();

	public var maxTextures:Int = 0;
	public var currentTextureSlot:Int = 0;
	public var currentBoundTextures:Object = {};

	public function new( backend:Dynamic ) {
		this.backend = backend;
		this.gl = backend.gl;

		if ( initialized === false ) {
			_init( this.gl );
			initialized = true;
		}
	}

	public function _init( gl:Dynamic ) {
		// Store only WebGL constants here.
	}

	public function enable( id:Int ) {
		if ( enabled[id] !== true ) {
			gl.enable( id );
			enabled[id] = true;
		}
	}

	public function disable( id:Int ) {
		if ( enabled[id] !== false ) {
			gl.disable( id );
			enabled[id] = false;
		}
	}

	public function setFlipSided( flipSided:Bool ) {
		if ( this.currentFlipSided !== flipSided ) {
			if ( flipSided ) {
				gl.frontFace( gl.CW );
			} else {
				gl.frontFace( gl.CCW );
			}
			this.currentFlipSided = flipSided;
		}
	}

	public function setCullFace( cullFace:Int ) {
		if ( cullFace !== CullFaceNone ) {
			this.enable( gl.CULL_FACE );
			if ( cullFace !== this.currentCullFace ) {
				if ( cullFace === CullFaceBack ) {
					gl.cullFace( gl.BACK );
				} else if ( cullFace === CullFaceFront ) {
					gl.cullFace( gl.FRONT );
				} else {
					gl.cullFace( gl.FRONT_AND_BACK );
				}
			}
		} else {
			this.disable( gl.CULL_FACE );
		}
		this.currentCullFace = cullFace;
	}

	public function setLineWidth( width:Float ) {
		const { currentLineWidth, gl } = this;
		if ( width !== currentLineWidth ) {
			gl.lineWidth( width );
			this.currentLineWidth = width;
		}
	}

	// ... Rest of the code (omitted for brevity)

}

enum CullFace {
	CullFaceNone;
	CullFaceBack;
	CullFaceFront;
}

// ... Rest of the enum definitions (omitted for brevity)