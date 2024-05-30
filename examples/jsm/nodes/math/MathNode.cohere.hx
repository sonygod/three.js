import TempNode from '../core/TempNode.hx';
import { sub, mul, div } from './OperatorNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeObject, nodeProxy, float, vec3, vec4 } from '../shadernode/ShaderNode.hx';

class MathNode extends TempNode {
    public method: String;
    public aNode: TempNode;
    public bNode: TempNode;
    public cNode: TempNode;

    public function new(method: String, aNode: TempNode, bNode: TempNode = null, cNode: TempNode = null) {
        super();
        this.method = method;
        this.aNode = aNode;
        this.bNode = bNode;
        this.cNode = cNode;
    }

    public function getInputType(builder: Builder): String {
        var aType = this.aNode.getNodeType(builder);
        var bType = this.bNode != null ? this.bNode.getNodeType(builder) : null;
        var cType = this.cNode != null ? this.cNode.getNodeType(builder) : null;

        var aLen = builder.isMatrix(aType) ? 0 : builder.getTypeLength(aType);
        var bLen = builder.isMatrix(bType) ? 0 : builder.getTypeLength(bType);
        var cLen = builder.isMatrix(cType) ? 0 : builder.getTypeLength(cType);

        if (aLen > bLen && aLen > cLen) {
            return aType;
        } else if (bLen > cLen) {
            return bType;
        } else if (cLen > aLen) {
            return cType;
        }

        return aType;
    }

    public function getNodeType(builder: Builder): String {
        switch(this.method) {
            case MathNode.LENGTH:
            case MathNode.DISTANCE:
            case MathNode.DOT:
                return 'float';
            case MathNode.CROSS:
                return 'vec3';
            case MathNode.ALL:
                return 'bool';
            case MathNode.EQUALS:
                return builder.changeComponentType(this.aNode.getNodeType(builder), 'bool');
            case MathNode.MOD:
                return this.aNode.getNodeType(builder);
            default:
                return this.getInputType(builder);
        }
    }

    public function generate(builder: Builder, output: Bool): String {
        var method = this.method;
        var type = this.getNodeType(builder);
        var inputType = this.getInputType(builder);

        var a = this.aNode;
        var b = this.bNode;
        var c = this.cNode;

        var isWebGL = builder.renderer.isWebGLRenderer;

        if (method == MathNode.TRANSFORM_DIRECTION) {
            // dir can be either a direction vector or a normal vector
            // upper-left 3x3 of matrix is assumed to be orthogonal

            var tA = a;
            var tB = b;

            if (builder.isMatrix(tA.getNodeType(builder))) {
                tB = vec4(vec3(tB), 0.0);
            } else {
                tA = vec4(vec3(tA), 0.0);
            }

            var mulNode = mul(tA, tB).xyz;

            return normalize(mulNode).build(builder, output);
        } else if (method == MathNode.NEGATE) {
            return builder.format('(- ${a.build(builder, inputType)})', type, output);
        } else if (method == MathNode.ONE_MINUS) {
            return sub(1.0, a).build(builder, output);
        } else if (method == MathNode.RECIPROCAL) {
            return div(1.0, a).build(builder, output);
        } else if (method == MathNode.DIFFERENCE) {
            return abs(sub(a, b)).build(builder, output);
        } else {
            var params = [];

            if (method == MathNode.CROSS || method == MathNode.MOD) {
                params.push(a.build(builder, type));
                params.push(b.build(builder, type));
            } else if (method == MathNode.STEP) {
                params.push(a.build(builder, if (builder.getTypeLength(a.getNodeType(builder)) == 1) 'float' else inputType));
                params.push(b.build(builder, inputType));
            } else if ((isWebGL && (method == MathNode.MIN || method == MathNode.MAX)) || method == MathNode.MOD) {
                params.push(a.build(builder, inputType));
                params.push(b.build(builder, if (builder.getTypeLength(b.getNodeType(builder)) == 1) 'float' else inputType));
            } else if (method == MathNode.REFRACT) {
                params.push(a.build(builder, inputType));
                params.push(b.build(builder, inputType));
                params.push(c.build(builder, 'float'));
            } else if (method == MathNode.MIX) {
                params.push(a.build(builder, inputType));
                params.push(b.build(builder, inputType));
                params.push(c.build(builder, if (builder.getTypeLength(c.getNodeType(builder)) == 1) 'float' else inputType));
            } else {
                params.push(a.build(builder, inputType));
                if (b != null) params.push(b.build(builder, inputType));
                if (c != null) params.push(c.build(builder, inputType));
            }

            return builder.format('${builder.getMethod(method, type)}(${params.join(', ')})', type, output);
        }
    }

    public function serialize(data: Dynamic) {
        super.serialize(data);
        data.method = this.method;
    }

    public function deserialize(data: Dynamic) {
        super.deserialize(data);
        this.method = data.method;
    }
}

// 1 input

static MathNode.ALL = 'all';
static MathNode.ANY = 'any';
static MathNode.EQUALS = 'equals';

static MathNode.RADIANS = 'radians';
static MathNode.DEGREES = 'degrees';
static MathNode.EXP = 'exp';
static MathNode.EXP2 = 'exp2';
static MathNode.LOG = 'log';
static MathNode.LOG2 = 'log2';
static MathNode.SQRT = 'sqrt';
static MathNode.INVERSE_SQRT = 'inversesqrt';
static MathNode.FLOOR = 'floor';
static MathNode.CEIL = 'ceil';
static MathNode.NORMALIZE = 'normalize';
static MathNode.FRACT = 'fract';
static MathNode.SIN = 'sin';
static MathNode.COS = 'cos';
static MathNode.TAN = 'tan';
static MathNode.ASIN = 'asin';
static MathNode.ACOS = 'acos';
static MathNode.ATAN = 'atan';
static MathNode.ABS = 'abs';
static MathNode.SIGN = 'sign';
static MathNode.LENGTH = 'length';
static MathNode.NEGATE = 'negate';
static MathNode.ONE_MINUS = 'oneMinus';
static MathNode.DFDX = 'dFdx';
static MathNode.DFDY = 'dFdy';
static MathNode.ROUND = 'round';
static MathNode.RECIPROCAL = 'reciprocal';
static MathNode.TRUNC = 'trunc';
static MathNode.FWIDTH = 'fwidth';
static MathNode.BITCAST = 'bitcast';

// 2 inputs

static MathNode.ATAN2 = 'atan2';
static MathNode.MIN = 'min';
static MathNode.MAX = 'max';
static MathNode.MOD = 'mod';
static MathNode.STEP = 'step';
static MathNode.REFLECT = 'reflect';
static MathNode.DISTANCE = 'distance';
static MathNode.DIFFERENCE = 'difference';
static MathNode.DOT = 'dot';
static MathNode.CROSS = 'cross';
static MathNode.POW = 'pow';
static MathNode.TRANSFORM_DIRECTION = 'transformDirection';

// 3 inputs

static MathNode.MIX = 'mix';
static MathNode.CLAMP = 'clamp';
static MathNode.REFRACT = 'refract';
static MathNode.SMOOTHSTEP = 'smoothstep';
static MathNode.FACEFORWARD = 'faceforward';

static public function cbrt(a: Float) {
    return mul(sign(a), pow(abs(a), 1.0 / 3.0));
}

static public function lengthSq(a: Float) {
    return dot(a, a);
}

static public function clamp(value: Float, low: Float = 0, high: Float = 1) {
    return nodeObject(new MathNode(MathNode.CLAMP, nodeObject(value), nodeObject(low), nodeObject(high)));
}

static public function saturate(value: Float) {
    return clamp(value);
}

static public function mixElement(t: Float, e1: Float, e2: Float) {
    return mix(e1, e2, t);
}

static public function smoothstepElement(x: Float, low: Float, high: Float) {
    return smoothstep(low, high, x);
}

addNodeClass('MathNode', MathNode);

addNodeElement('all', nodeProxy(MathNode, MathNode.ALL));
addNodeElement('any', nodeProxy(MathNode, MathNode.ANY));
addNodeElement('equals', nodeProxy(MathNode, MathNode.EQUALS));

addNodeElement('radians', nodeProxy(MathNode, MathNode.RADIANS));
addNodeElement('degrees', nodeProxy(MathNode, MathNode.DEGREES));
addNodeElement('exp', nodeProxy(MathNode, MathNode.EXP));
addNodeElement('exp2', nodeProxy(MathNode, MathNode.EXP2));
addNodeElement('log', nodeProxy(MathNode, MathNode.LOG));
addNodeElement('log2', nodeProxy(MathNode, MathNode.LOG2));
addNodeElement('sqrt', nodeProxy(MathNode, MathNode.SQRT));
addNodeElement('inverseSqrt', nodeProxy(MathNode, MathNode.INVERSE_SQRT));
addNodeElement('floor', nodeProxy(MathNode, MathNode.FLOOR));
addNodeElement('ceil', nodeProxy(MathNode, MathNode.CEIL));
addNodeElement('normalize', nodeProxy(MathNode, MathNode.NORMALIZE));
addNodeElement('fract', nodeProxy(MathNode, MathNode.FRACT));
addNodeElement('sin', nodeProxy(MathNode, MathNode.SIN));
addNodeElement('cos', nodeProxy(MathNode, MathNode.COS));
addNodeElement('tan', nodeProxy(MathNode, MathNode.TAN));
addNodeElement('asin', nodeProxy(MathNode, MathNode.ASIN));
addNodeElement('acos', nodeProxy(MathNode, MathNode.ACOS));
addNodeElement('atan', nodeProxy(MathNode, MathNode.ATAN));
addNodeElement('abs', nodeProxy(MathNode, MathNode.ABS));
addNodeElement('sign', nodeProxy(MathNode, MathNode.SIGN));
addNodeElement('length', nodeProxy(MathNode, MathNode.LENGTH));
addNodeElement('lengthSq', lengthSq);
addNodeElement('negate', nodeProxy(MathNode, MathNode.NEGATE));
addNodeElement('oneMinus', nodeProxy(MathNode, MathNode.ONE_MINUS));
addNodeElement('dFdx', nodeProxy(MathNode, MathNode.DFDX));
addNodeElement('dFdy', nodeProxy(MathNode, MathNode.DFDY));
addNodeElement('round', nodeProxy(MathNode, MathNode.ROUND));
addNodeElement('reciprocal', nodeProxy(MathNode, MathNode.RECIPROCAL));
addNodeElement('trunc', nodeProxy(MathNode, MathNode.TRUNC));
addNodeElement('fwidth', nodeProxy(MathNode, MathNode.FWIDTH));
addNodeElement('atan2', nodeProxy(MathNode, MathNode.ATAN2));
addNodeElement('min', nodeProxy(MathNode, MathNode.MIN));
addNodeElement('max', nodeProxy(MathNode, MathNode.MAX));
addNodeElement('mod', nodeProxy(MathNode, MathNode.MOD));
addNodeElement('step', nodeProxy(MathNode, MathNode.STEP));
addNodeElement('reflect', nodeProxy(MathNode, MathNode.REFLECT));
addNodeElement('distance', nodeProxy(MathNode, MathNode.DISTANCE));
addNodeElement('dot', nodeProxy(MathNode, MathNode.DOT));
addNodeElement('cross', nodeProxy(MathNode, MathNode.CROSS));
addNodeElement('pow', nodeProxy(MathNode, MathNode.POW));
addNodeElement('pow2', nodeProxy(MathNode, MathNode.POW, 2));
addNodeElement('pow3', nodeProxy(MathNode, MathNode.POW, 3));
addNodeElement('pow4', nodeProxy(MathNode, MathNode.POW, 4));
addNodeElement('transformDirection', nodeProxy(MathNode, MathNode.TRANSFORM_DIRECTION));
addNodeElement('mix', mixElement);
addNodeElement('clamp', clamp);
addNodeElement('refract', nodeProxy(MathNode, MathNode.REFRACT));
addNodeElement('smoothstep', smoothstepElement);
addNodeElement('faceForward', nodeProxy(MathNode, MathNode.FACEFORWARD));
addNodeElement('difference', nodeProxy(MathNode, MathNode.DIFFERENCE));
addNodeElement('saturate', saturate);
addNodeElement('cbrt', cbrt);

export {
    MathNode,
    EPSILON = float(1e-6),
    INFINITY = float(1e6),
    PI = float(Math.PI),
    PI2 = float(Math.PI * 2)
}