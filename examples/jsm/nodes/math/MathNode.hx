package three.js.examples.jsm.nodes.math;

import three.js.core.TempNode;
import three.js.shadernode.ShaderNode;
import three.js.shadernode.OperatorNode;

class MathNode extends TempNode {

    public var method:String;
    public var aNode:ShaderNode;
    public var bNode:ShaderNode;
    public var cNode:ShaderNode;

    public function new(method:String, aNode:ShaderNode, ?bNode:ShaderNode, ?cNode:ShaderNode) {
        super();
        this.method = method;
        this.aNode = aNode;
        this.bNode = bNode;
        this.cNode = cNode;
    }

    public function getInputType(builder:Dynamic):String {
        var aType:String = aNode.getNodeType(builder);
        var bType:String = bNode != null ? bNode.getNodeType(builder) : null;
        var cType:String = cNode != null ? cNode.getNodeType(builder) : null;

        var aLen:Int = builder.isMatrix(aType) ? 0 : builder.getTypeLength(aType);
        var bLen:Int = builder.isMatrix(bType) ? 0 : builder.getTypeLength(bType);
        var cLen:Int = builder.isMatrix(cType) ? 0 : builder.getTypeLength(cType);

        if (aLen > bLen && aLen > cLen) {
            return aType;
        } else if (bLen > cLen) {
            return bType;
        } else if (cLen > aLen) {
            return cType;
        }
        return aType;
    }

    public function getNodeType(builder:Dynamic):String {
        switch (method) {
            case LENGTH, DISTANCE, DOT:
                return 'float';
            case CROSS:
                return 'vec3';
            case ALL:
                return 'bool';
            case EQUALS:
                return builder.changeComponentType(aNode.getNodeType(builder), 'bool');
            case MOD:
                return aNode.getNodeType(builder);
            default:
                return getInputType(builder);
        }
    }

    public function generate(builder:Dynamic, output:Dynamic):Void {
        var type:String = getNodeType(builder);
        var inputType:String = getInputType(builder);

        var a:ShaderNode = aNode;
        var b:ShaderNode = bNode;
        var c:ShaderNode = cNode;

        var isWebGL:Bool = builder.renderer.isWebGLRenderer;

        switch (method) {
            case TRANSFORM_DIRECTION:
                // dir can be either a direction vector or a normal vector
                // upper-left 3x3 of matrix is assumed to be orthogonal

                var tA:ShaderNode = a;
                var tB:ShaderNode = b;

                if (builder.isMatrix(tA.getNodeType(builder))) {
                    tB = vec4(vec3(tB), 0.0);
                } else {
                    tA = vec4(vec3(tA), 0.0);
                }

                var mulNode:OperatorNode = mul(tA, tB).xyz;

                return normalize(mulNode).build(builder, output);

            case NEGATE:
                return builder.format('(- ' + a.build(builder, inputType) + ')', type, output);

            case ONE_MINUS:
                return sub(1.0, a).build(builder, output);

            case RECIPROCAL:
                return div(1.0, a).build(builder, output);

            case DIFFERENCE:
                return abs(sub(a, b)).build(builder, output);

            default:
                var params:Array<ShaderNode> = [];

                switch (method) {
                    case CROSS, MOD:
                        params.push(a.build(builder, type));
                        params.push(b.build(builder, type));
                    case STEP:
                        params.push(a.build(builder, builder.getTypeLength(a.getNodeType(builder)) == 1 ? 'float' : inputType));
                        params.push(b.build(builder, inputType));
                    case REFRACT:
                        params.push(a.build(builder, inputType));
                        params.push(b.build(builder, inputType));
                        params.push(c.build(builder, 'float'));
                    case MIX:
                        params.push(a.build(builder, inputType));
                        params.push(b.build(builder, inputType));
                        params.push(c.build(builder, builder.getTypeLength(c.getNodeType(builder)) == 1 ? 'float' : inputType));
                    default:
                        params.push(a.build(builder, inputType));
                        if (b != null) params.push(b.build(builder, inputType));
                        if (c != null) params.push(c.build(builder, inputType));
                }

                return builder.format('${builder.getMethod(method, type)}(${params.join(', ')})', type, output);
        }
    }

    public function serialize(data:Dynamic) {
        super.serialize(data);
        data.method = method;
    }

    public function deserialize(data:Dynamic) {
        super.deserialize(data);
        method = data.method;
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

// Proxies
var all:ShaderNode = nodeProxy(MathNode, MathNode.ALL);
var any:ShaderNode = nodeProxy(MathNode, MathNode.ANY);
var equals:ShaderNode = nodeProxy(MathNode, MathNode.EQUALS);

var radians:ShaderNode = nodeProxy(MathNode, MathNode.RADIANS);
var degrees:ShaderNode = nodeProxy(MathNode, MathNode.DEGREES);
var exp:ShaderNode = nodeProxy(MathNode, MathNode.EXP);
var exp2:ShaderNode = nodeProxy(MathNode, MathNode.EXP2);
var log:ShaderNode = nodeProxy(MathNode, MathNode.LOG);
var log2:ShaderNode = nodeProxy(MathNode, MathNode.LOG2);
var sqrt:ShaderNode = nodeProxy(MathNode, MathNode.SQRT);
var inverseSqrt:ShaderNode = nodeProxy(MathNode, MathNode.INVERSE_SQRT);
var floor:ShaderNode = nodeProxy(MathNode, MathNode.FLOOR);
var ceil:ShaderNode = nodeProxy(MathNode, MathNode.CEIL);
var normalize:ShaderNode = nodeProxy(MathNode, MathNode.NORMALIZE);
var fract:ShaderNode = nodeProxy(MathNode, MathNode.FRACT);
var sin:ShaderNode = nodeProxy(MathNode, MathNode.SIN);
var cos:ShaderNode = nodeProxy(MathNode, MathNode.COS);
var tan:ShaderNode = nodeProxy(MathNode, MathNode.TAN);
var asin:ShaderNode = nodeProxy(MathNode, MathNode.ASIN);
var acos:ShaderNode = nodeProxy(MathNode, MathNode.ACOS);
var atan:ShaderNode = nodeProxy(MathNode, MathNode.ATAN);
var abs:ShaderNode = nodeProxy(MathNode, MathNode.ABS);
var sign:ShaderNode = nodeProxy(MathNode, MathNode.SIGN);
var length:ShaderNode = nodeProxy(MathNode, MathNode.LENGTH);
var negate:ShaderNode = nodeProxy(MathNode, MathNode.NEGATE);
var oneMinus:ShaderNode = nodeProxy(MathNode, MathNode.ONE_MINUS);
var dFdx:ShaderNode = nodeProxy(MathNode, MathNode.DFDX);
var dFdy:ShaderNode = nodeProxy(MathNode, MathNode.DFDY);
var round:ShaderNode = nodeProxy(MathNode, MathNode.ROUND);
var reciprocal:ShaderNode = nodeProxy(MathNode, MathNode.RECIPROCAL);
var trunc:ShaderNode = nodeProxy(MathNode, MathNode.TRUNC);
var fwidth:ShaderNode = nodeProxy(MathNode, MathNode.FWIDTH);
var bitcast:ShaderNode = nodeProxy(MathNode, MathNode.BITCAST);

// 2 inputs
var atan2:ShaderNode = nodeProxy(MathNode, MathNode.ATAN2);
var min:ShaderNode = nodeProxy(MathNode, MathNode.MIN);
var max:ShaderNode = nodeProxy(MathNode, MathNode.MAX);
var mod:ShaderNode = nodeProxy(MathNode, MathNode.MOD);
var step:ShaderNode = nodeProxy(MathNode, MathNode.STEP);
var reflect:ShaderNode = nodeProxy(MathNode, MathNode.REFLECT);
var distance:ShaderNode = nodeProxy(MathNode, MathNode.DISTANCE);
var difference:ShaderNode = nodeProxy(MathNode, MathNode.DIFFERENCE);
var dot:ShaderNode = nodeProxy(MathNode, MathNode.DOT);
var cross:ShaderNode = nodeProxy(MathNode, MathNode.CROSS);
var pow:ShaderNode = nodeProxy(MathNode, MathNode.POW);
var pow2:ShaderNode = nodeProxy(MathNode, MathNode.POW, 2);
var pow3:ShaderNode = nodeProxy(MathNode, MathNode.POW, 3);
var pow4:ShaderNode = nodeProxy(MathNode, MathNode.POW, 4);
var transformDirection:ShaderNode = nodeProxy(MathNode, MathNode.TRANSFORM_DIRECTION);

// 3 inputs
var mix:ShaderNode = nodeProxy(MathNode, MathNode.MIX);
var clamp:ShaderNode = clamp;
var refract:ShaderNode = nodeProxy(MathNode, MathNode.REFRACT);
var smoothstep:ShaderNode = nodeProxy(MathNode, MathNode.SMOOTHSTEP);
var faceForward:ShaderNode = nodeProxy(MathNode, MathNode.FACEFORWARD);

// Utilities
var EPSILON:Float = 1e-6;
var INFINITY:Float = 1e6;
var PI:Float = Math.PI;
var PI2:Float = Math.PI * 2;

// Node elements
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
addNodeElement('difference', difference);
addNodeElement('dot', dot);
addNodeElement('cross', cross);
addNodeElement('pow', pow);
addNodeElement('pow2', pow2);
addNodeElement('pow3', pow3);
addNodeElement('pow4', pow4);
addNodeElement('transformDirection', transformDirection);
addNodeElement('mix', mix);
addNodeElement('clamp', clamp);
addNodeElement('refract', refract);
addNodeElement('smoothstep', smoothstep);
addNodeElement('faceForward', faceForward);

addNodeClass('MathNode', MathNode);