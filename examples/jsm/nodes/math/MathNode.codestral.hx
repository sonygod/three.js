import TempNode from '../core/TempNode';
import { sub, mul, div } from './OperatorNode';
import { addNodeClass } from '../core/Node';
import { addNodeElement, nodeObject, nodeProxy, float, vec3, vec4 } from '../shadernode/ShaderNode';

class MathNode extends TempNode {

    public var method: String;
    public var aNode: Node;
    public var bNode: Node;
    public var cNode: Node;

    public function new(method: String, aNode: Node, bNode: Node = null, cNode: Node = null) {
        super();
        this.method = method;
        this.aNode = aNode;
        this.bNode = bNode;
        this.cNode = cNode;
    }

    public function getInputType(builder: ShaderNodeBuilder): String {
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

    public function getNodeType(builder: ShaderNodeBuilder): String {
        var method = this.method;

        if (method == MathNode.LENGTH || method == MathNode.DISTANCE || method == MathNode.DOT) {
            return 'float';
        } else if (method == MathNode.CROSS) {
            return 'vec3';
        } else if (method == MathNode.ALL) {
            return 'bool';
        } else if (method == MathNode.EQUALS) {
            return builder.changeComponentType(this.aNode.getNodeType(builder), 'bool');
        } else if (method == MathNode.MOD) {
            return this.aNode.getNodeType(builder);
        } else {
            return this.getInputType(builder);
        }
    }

    public function generate(builder: ShaderNodeBuilder, output: String): String {
        var method = this.method;

        var type = this.getNodeType(builder);
        var inputType = this.getInputType(builder);

        var a = this.aNode;
        var b = this.bNode;
        var c = this.cNode;

        var isWebGL = builder.renderer.isWebGLRenderer === true;

        if (method == MathNode.TRANSFORM_DIRECTION) {
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
            return builder.format('( - ' + a.build(builder, inputType) + ' )', type, output);
        } else if (method == MathNode.ONE_MINUS) {
            return sub(1.0, a).build(builder, output);
        } else if (method == MathNode.RECIPROCAL) {
            return div(1.0, a).build(builder, output);
        } else if (method == MathNode.DIFFERENCE) {
            return abs(sub(a, b)).build(builder, output);
        } else {
            var params = new Array<String>();

            if (method == MathNode.CROSS || method == MathNode.MOD) {
                params.push(a.build(builder, type), b.build(builder, type));
            } else if (method == MathNode.STEP) {
                params.push(a.build(builder, builder.getTypeLength(a.getNodeType(builder)) == 1 ? 'float' : inputType),
                             b.build(builder, inputType));
            } else if ((isWebGL && (method == MathNode.MIN || method == MathNode.MAX)) || method == MathNode.MOD) {
                params.push(a.build(builder, inputType),
                             b.build(builder, builder.getTypeLength(b.getNodeType(builder)) == 1 ? 'float' : inputType));
            } else if (method == MathNode.REFRACT) {
                params.push(a.build(builder, inputType), b.build(builder, inputType), c.build(builder, 'float'));
            } else if (method == MathNode.MIX) {
                params.push(a.build(builder, inputType), b.build(builder, inputType),
                             c.build(builder, builder.getTypeLength(c.getNodeType(builder)) == 1 ? 'float' : inputType));
            } else {
                params.push(a.build(builder, inputType));
                if (b != null) params.push(b.build(builder, inputType));
                if (c != null) params.push(c.build(builder, inputType));
            }

            return builder.format('${builder.getMethod(method, type)}(${params.join(', ')})', type, output);
        }
    }

    public function serialize(data: Object) {
        super.serialize(data);
        data.method = this.method;
    }

    public function deserialize(data: Object) {
        super.deserialize(data);
        this.method = data.method;
    }
}

// 1 input
MathNode.ALL = 'all';
MathNode.ANY = 'any';
MathNode.EQUALS = 'equals';
MathNode.RADIANS = 'radians';
MathNode.DEGREES = 'degrees';
MathNode.EXP = 'exp';
MathNode.EXP2 = 'exp2';
MathNode.LOG = 'log';
MathNode.LOG2 = 'log2';
MathNode.SQRT = 'sqrt';
MathNode.INVERSE_SQRT = 'inversesqrt';
MathNode.FLOOR = 'floor';
MathNode.CEIL = 'ceil';
MathNode.NORMALIZE = 'normalize';
MathNode.FRACT = 'fract';
MathNode.SIN = 'sin';
MathNode.COS = 'cos';
MathNode.TAN = 'tan';
MathNode.ASIN = 'asin';
MathNode.ACOS = 'acos';
MathNode.ATAN = 'atan';
MathNode.ABS = 'abs';
MathNode.SIGN = 'sign';
MathNode.LENGTH = 'length';
MathNode.NEGATE = 'negate';
MathNode.ONE_MINUS = 'oneMinus';
MathNode.DFDX = 'dFdx';
MathNode.DFDY = 'dFdy';
MathNode.ROUND = 'round';
MathNode.RECIPROCAL = 'reciprocal';
MathNode.TRUNC = 'trunc';
MathNode.FWIDTH = 'fwidth';
MathNode.BITCAST = 'bitcast';

// 2 inputs
MathNode.ATAN2 = 'atan2';
MathNode.MIN = 'min';
MathNode.MAX = 'max';
MathNode.MOD = 'mod';
MathNode.STEP = 'step';
MathNode.REFLECT = 'reflect';
MathNode.DISTANCE = 'distance';
MathNode.DIFFERENCE = 'difference';
MathNode.DOT = 'dot';
MathNode.CROSS = 'cross';
MathNode.POW = 'pow';
MathNode.TRANSFORM_DIRECTION = 'transformDirection';

// 3 inputs
MathNode.MIX = 'mix';
MathNode.CLAMP = 'clamp';
MathNode.REFRACT = 'refract';
MathNode.SMOOTHSTEP = 'smoothstep';
MathNode.FACEFORWARD = 'faceforward';

export default MathNode;

export var EPSILON = float(1e-6);
export var INFINITY = float(1e6);
export var PI = float(Math.PI);
export var PI2 = float(Math.PI * 2);

export function all(a: Node): Node { return nodeProxy(MathNode, MathNode.ALL, a); }
export function any(a: Node): Node { return nodeProxy(MathNode, MathNode.ANY, a); }
export function equals(a: Node, b: Node): Node { return nodeProxy(MathNode, MathNode.EQUALS, a, b); }
export function radians(a: Node): Node { return nodeProxy(MathNode, MathNode.RADIANS, a); }
export function degrees(a: Node): Node { return nodeProxy(MathNode, MathNode.DEGREES, a); }
export function exp(a: Node): Node { return nodeProxy(MathNode, MathNode.EXP, a); }
export function exp2(a: Node): Node { return nodeProxy(MathNode, MathNode.EXP2, a); }
export function log(a: Node): Node { return nodeProxy(MathNode, MathNode.LOG, a); }
export function log2(a: Node): Node { return nodeProxy(MathNode, MathNode.LOG2, a); }
export function sqrt(a: Node): Node { return nodeProxy(MathNode, MathNode.SQRT, a); }
export function inverseSqrt(a: Node): Node { return nodeProxy(MathNode, MathNode.INVERSE_SQRT, a); }
export function floor(a: Node): Node { return nodeProxy(MathNode, MathNode.FLOOR, a); }
export function ceil(a: Node): Node { return nodeProxy(MathNode, MathNode.CEIL, a); }
export function normalize(a: Node): Node { return nodeProxy(MathNode, MathNode.NORMALIZE, a); }
export function fract(a: Node): Node { return nodeProxy(MathNode, MathNode.FRACT, a); }
export function sin(a: Node): Node { return nodeProxy(MathNode, MathNode.SIN, a); }
export function cos(a: Node): Node { return nodeProxy(MathNode, MathNode.COS, a); }
export function tan(a: Node): Node { return nodeProxy(MathNode, MathNode.TAN, a); }
export function asin(a: Node): Node { return nodeProxy(MathNode, MathNode.ASIN, a); }
export function acos(a: Node): Node { return nodeProxy(MathNode, MathNode.ACOS, a); }
export function atan(a: Node): Node { return nodeProxy(MathNode, MathNode.ATAN, a); }
export function abs(a: Node): Node { return nodeProxy(MathNode, MathNode.ABS, a); }
export function sign(a: Node): Node { return nodeProxy(MathNode, MathNode.SIGN, a); }
export function length(a: Node): Node { return nodeProxy(MathNode, MathNode.LENGTH, a); }
export function negate(a: Node): Node { return nodeProxy(MathNode, MathNode.NEGATE, a); }
export function oneMinus(a: Node): Node { return nodeProxy(MathNode, MathNode.ONE_MINUS, a); }
export function dFdx(a: Node): Node { return nodeProxy(MathNode, MathNode.DFDX, a); }
export function dFdy(a: Node): Node { return nodeProxy(MathNode, MathNode.DFDY, a); }
export function round(a: Node): Node { return nodeProxy(MathNode, MathNode.ROUND, a); }
export function reciprocal(a: Node): Node { return nodeProxy(MathNode, MathNode.RECIPROCAL, a); }
export function trunc(a: Node): Node { return nodeProxy(MathNode, MathNode.TRUNC, a); }
export function fwidth(a: Node): Node { return nodeProxy(MathNode, MathNode.FWIDTH, a); }
export function bitcast(a: Node, b: Node): Node { return nodeProxy(MathNode, MathNode.BITCAST, a, b); }
export function atan2(a: Node, b: Node): Node { return nodeProxy(MathNode, MathNode.ATAN2, a, b); }
export function min(a: Node, b: Node): Node { return nodeProxy(MathNode, MathNode.MIN, a, b); }
export function max(a: Node, b: Node): Node { return nodeProxy(MathNode, MathNode.MAX, a, b); }
export function mod(a: Node, b: Node): Node { return nodeProxy(MathNode, MathNode.MOD, a, b); }
export function step(a: Node, b: Node): Node { return nodeProxy(MathNode, MathNode.STEP, a, b); }
export function reflect(a: Node, b: Node): Node { return nodeProxy(MathNode, MathNode.REFLECT, a, b); }
export function distance(a: Node, b: Node): Node { return nodeProxy(MathNode, MathNode.DISTANCE, a, b); }
export function difference(a: Node, b: Node): Node { return nodeProxy(MathNode, MathNode.DIFFERENCE, a, b); }
export function dot(a: Node, b: Node): Node { return nodeProxy(MathNode, MathNode.DOT, a, b); }
export function cross(a: Node, b: Node): Node { return nodeProxy(MathNode, MathNode.CROSS, a, b); }
export function pow(a: Node, b: Node): Node { return nodeProxy(MathNode, MathNode.POW, a, b); }
export function pow2(a: Node): Node { return nodeProxy(MathNode, MathNode.POW, a, 2); }
export function pow3(a: Node): Node { return nodeProxy(MathNode, MathNode.POW, a, 3); }
export function pow4(a: Node): Node { return nodeProxy(MathNode, MathNode.POW, a, 4); }
export function transformDirection(a: Node, b: Node): Node { return nodeProxy(MathNode, MathNode.TRANSFORM_DIRECTION, a, b); }
export function mix(a: Node, b: Node, c: Node): Node { return nodeProxy(MathNode, MathNode.MIX, a, b, c); }
export function clamp(value: Node, low: Node = 0, high: Node = 1): Node { return nodeObject(new MathNode(MathNode.CLAMP, nodeObject(value), nodeObject(low), nodeObject(high))); }
export function saturate(value: Node): Node { return clamp(value); }
export function refract(a: Node, b: Node, c: Node): Node { return nodeProxy(MathNode, MathNode.REFRACT, a, b, c); }
export function smoothstep(a: Node, b: Node, c: Node): Node { return nodeProxy(MathNode, MathNode.SMOOTHSTEP, a, b, c); }
export function faceForward(a: Node, b: Node, c: Node): Node { return nodeProxy(MathNode, MathNode.FACEFORWARD, a, b, c); }
export function mixElement(t: Node, e1: Node, e2: Node): Node { return mix(e1, e2, t); }
export function smoothstepElement(x: Node, low: Node, high: Node): Node { return smoothstep(low, high, x); }
export function cbrt(a: Node): Node { return mul(sign(a), pow(abs(a), 1.0 / 3.0)); }
export function lengthSq(a: Node): Node { return dot(a, a); }
export function saturate(value: Node): Node { return clamp(value); }

addNodeElement('all', all);
addNodeElement('any', any);
addNodeElement('equals', equals);
addNodeElement('radians', radians);
addNodeElement('degrees', degrees);
addNodeElement('exp', exp);
addNodeElement('exp2', exp2);
addNodeElement('log', log);
addNodeElement('log2', log2);
addNodeElement('sqrt', sqrt);
addNodeElement('inverseSqrt', inverseSqrt);
addNodeElement('floor', floor);
addNodeElement('ceil', ceil);
addNodeElement('normalize', normalize);
addNodeElement('fract', fract);
addNodeElement('sin', sin);
addNodeElement('cos', cos);
addNodeElement('tan', tan);
addNodeElement('asin', asin);
addNodeElement('acos', acos);
addNodeElement('atan', atan);
addNodeElement('abs', abs);
addNodeElement('sign', sign);
addNodeElement('length', length);
addNodeElement('lengthSq', lengthSq);
addNodeElement('negate', negate);
addNodeElement('oneMinus', oneMinus);
addNodeElement('dFdx', dFdx);
addNodeElement('dFdy', dFdy);
addNodeElement('round', round);
addNodeElement('reciprocal', reciprocal);
addNodeElement('trunc', trunc);
addNodeElement('fwidth', fwidth);
addNodeElement('atan2', atan2);
addNodeElement('min', min);
addNodeElement('max', max);
addNodeElement('mod', mod);
addNodeElement('step', step);
addNodeElement('reflect', reflect);
addNodeElement('distance', distance);
addNodeElement('dot', dot);
addNodeElement('cross', cross);
addNodeElement('pow', pow);
addNodeElement('pow2', pow2);
addNodeElement('pow3', pow3);
addNodeElement('pow4', pow4);
addNodeElement('transformDirection', transformDirection);
addNodeElement('mix', mixElement);
addNodeElement('clamp', clamp);
addNodeElement('refract', refract);
addNodeElement('smoothstep', smoothstepElement);
addNodeElement('faceForward', faceForward);
addNodeElement('difference', difference);
addNodeElement('saturate', saturate);
addNodeElement('cbrt', cbrt);

addNodeClass('MathNode', MathNode);