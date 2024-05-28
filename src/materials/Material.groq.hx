package three.materials;

import three.math.Color;
import three.core.EventDispatcher;
import three.constants.FrontSide;
import three.constants.NormalBlending;
import three.constants.LessEqualDepth;
import three.constants.AddEquation;
import three.constants.OneMinusSrcAlphaFactor;
import three.constants.SrcAlphaFactor;
import three.constants.AlwaysStencilFunc;
import three.constants.KeepStencilOp;
import three.math.MathUtils;

class Material extends EventDispatcher {
    public var isMaterial:Bool = true;

    private var _materialId:Int = 0;
    public var id:Int;
    public var uuid:String;
    public var name:String = '';
    public var type:String = 'Material';

    public var blending:Int = NormalBlending;
    public var side:Int = FrontSide;
    public var vertexColors:Bool = false;

    public var opacity:Float = 1;
    public var transparent:Bool = false;
    public var alphaHash:Bool = false;

    public var blendSrc:Int;
    public var blendDst:Int;
    public var blendEquation:Int;
    public var blendSrcAlpha:Null<Int>;
    public var blendDstAlpha:Null<Int>;
    public var blendEquationAlpha:Null<Int>;
    public var blendColor:Color;
    public var blendAlpha:Float = 0;

    public var depthFunc:Int = LessEqualDepth;
    public var depthTest:Bool = true;
    public var depthWrite:Bool = true;

    public var stencilWriteMask:Int = 0xff;
    public var stencilFunc:Int = AlwaysStencilFunc;
    public var stencilRef:Int = 0;
    public var stencilFuncMask:Int = 0xff;
    public var stencilFail:Int = KeepStencilOp;
    public var stencilZFail:Int = KeepStencilOp;
    public var stencilZPass:Int = KeepStencilOp;
    public var stencilWrite:Bool = false;

    public var clippingPlanes:Array<Plane>;
    public var clipIntersection:Bool = false;
    public var clipShadows:Bool = false;

    public var shadowSide:Null<Int>;

    public var colorWrite:Bool = true;

    public var precision:Null<String>;

    public var polygonOffset:Bool = false;
    public var polygonOffsetFactor:Float = 0;
    public var polygonOffsetUnits:Float = 0;

    public var dithering:Bool = false;

    public var alphaToCoverage:Bool = false;
    public var premultipliedAlpha:Bool = false;
    public var forceSinglePass:Bool = false;

    public var visible:Bool = true;

    public var toneMapped:Bool = true;

    public var userData:Dynamic = {};

    public var version:Int = 0;

    private var _alphaTest:Int = 0;

    public function new() {
        super();
        _materialId++;
        id = _materialId;
        uuid = MathUtils.generateUUID();
    }

    public function get_alphaTest():Int {
        return _alphaTest;
    }

    public function set_alphaTest(value:Int):Void {
        if (_alphaTest > 0 != value > 0) {
            version++;
        }
        _alphaTest = value;
    }

    public function onBuild(?shaderObject:Dynamic, ?renderer:Dynamic):Void {}

    public function onBeforeRender(?renderer:Dynamic, ?scene:Dynamic, ?camera:Dynamic, ?geometry:Dynamic, ?object:Dynamic, ?group:Dynamic):Void {}

    public function onBeforeCompile(?shaderObject:Dynamic, ?renderer:Dynamic):Void {}

    public function customProgramCacheKey():String {
        return onBeforeCompile.toString();
    }

    public function setValues(values:Dynamic):Void {
        if (values == null) return;
        for (key in values) {
            var newValue:Dynamic = values[key];
            if (newValue == null) {
                Console.warn('THREE.Material: parameter \'$key\' has value of undefined.');
                continue;
            }
            var currentValue:Dynamic = this[key];
            if (currentValue == null) {
                Console.warn('THREE.Material: \'$key\' is not a property of THREE.$type.');
                continue;
            }
            if (currentValue.isColor) {
                currentValue.set(newValue);
            } else if (currentValue.isVector3 &&newValue.isVector3) {
                currentValue.copy(newValue);
            } else {
                this[key] = newValue;
            }
        }
    }

    public function toJSON(?meta:Dynamic):Dynamic {
        // ...
    }

    public function clone():Material {
        return new Material().copy(this);
    }

    public function copy(source:Material):Material {
        // ...
        return this;
    }

    public function dispose():Void {
        dispatchEvent({ type: 'dispose' });
    }

    public function set_needsUpdate(value:Bool):Void {
        if (value) version++;
    }
}