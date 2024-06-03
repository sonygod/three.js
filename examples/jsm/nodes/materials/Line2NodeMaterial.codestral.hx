import NodeMaterial;
import addNodeMaterial from './NodeMaterial';
import temp from '../core/VarNode';
import varying from '../core/VaryingNode';
import property from '../core/PropertyNode';
import attribute from '../core/AttributeNode';
import cameraProjectionMatrix from '../accessors/CameraNode';
import materialColor from '../accessors/MaterialNode';
import materialLineScale from '../accessors/MaterialNode';
import materialLineDashSize from '../accessors/MaterialNode';
import materialLineGapSize from '../accessors/MaterialNode';
import materialLineDashOffset from '../accessors/MaterialNode';
import materialLineWidth from '../accessors/MaterialNode';
import modelViewMatrix from '../accessors/ModelNode';
import positionGeometry from '../accessors/PositionNode';
import mix from '../math/MathNode';
import smoothstep from '../math/MathNode';
import tslFn from '../shadernode/ShaderNode';
import float from '../shadernode/ShaderNode';
import vec2 from '../shadernode/ShaderNode';
import vec3 from '../shadernode/ShaderNode';
import vec4 from '../shadernode/ShaderNode';
import If from '../shadernode/ShaderNode';
import uv from '../accessors/UVNode';
import viewport from '../display/ViewportNode';
import dashSize from '../core/PropertyNode';
import gapSize from '../core/PropertyNode';
import LineDashedMaterial from 'three';

class Line2NodeMaterial extends NodeMaterial {

    public var normals:Bool;
    public var lights:Bool;

    public var useAlphaToCoverage:Bool;
    public var useColor:Bool;
    public var useDash:Bool;
    public var useWorldUnits:Bool;

    public var dashOffset:Float;
    public var lineWidth:Float;

    public var lineColorNode:Dynamic;

    public var offsetNode:Dynamic;
    public var dashScaleNode:Dynamic;
    public var dashSizeNode:Dynamic;
    public var gapSizeNode:Dynamic;

    public function new(params:Object = {}) {
        super();

        this.normals = false;
        this.lights = false;

        var defaultValues = new LineDashedMaterial();
        this.setDefaultValues(defaultValues);

        this.useAlphaToCoverage = true;
        this.useColor = params.vertexColors;
        this.useDash = params.dashed;
        this.useWorldUnits = false;

        this.dashOffset = 0;
        this.lineWidth = 1;

        this.lineColorNode = null;

        this.offsetNode = null;
        this.dashScaleNode = null;
        this.dashSizeNode = null;
        this.gapSizeNode = null;

        this.setValues(params);
    }

    @override
    public function setup(builder:Dynamic) {
        this.setupShaders();
        super.setup(builder);
    }

    public function setupShaders() {
        var useAlphaToCoverage = this.alphaToCoverage;
        var useColor = this.useColor;
        var useDash = this.dashed;
        var useWorldUnits = this.worldUnits;

        var trimSegment = tslFn(function ({ start, end }) {
            var a = cameraProjectionMatrix.element(2).element(2);
            var b = cameraProjectionMatrix.element(3).element(2);
            var nearEstimate = b.mul(-0.5).div(a);

            var alpha = nearEstimate.sub(start.z).div(end.z.sub(start.z));

            return vec4(mix(start.xyz, end.xyz, alpha), end.w);
        });

        this.vertexNode = tslFn(function () {
            //... rest of the code
        })();

        var closestLineToLine = tslFn(function ({ p1, p2, p3, p4 }) {
            //... rest of the code
        });

        this.fragmentNode = tslFn(function () {
            //... rest of the code
        })();
    }

    //... rest of the code
}

export default Line2NodeMaterial;

addNodeMaterial('Line2NodeMaterial', Line2NodeMaterial);