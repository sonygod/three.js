import three.examples.jsm.nodes.core.TempNode;
import three.examples.jsm.nodes.math.OperatorNode.*;
import three.examples.jsm.nodes.core.Node.addNodeClass;
import three.examples.jsm.nodes.shadernode.ShaderNode.*;

class MathNode extends TempNode {

    public var method:String;
    public var aNode:Dynamic;
    public var bNode:Dynamic;
    public var cNode:Dynamic;

    public function new(method:String, aNode:Dynamic, bNode:Dynamic = null, cNode:Dynamic = null) {
        super();
        this.method = method;
        this.aNode = aNode;
        this.bNode = bNode;
        this.cNode = cNode;
    }

    public function getInputType(builder:Dynamic):String {
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

    public function getNodeType(builder:Dynamic):String {
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

    public function generate(builder:Dynamic, output:Dynamic):String {
        var method = this.method;

        var type = this.getNodeType(builder);
        var inputType = this.getInputType(builder);

        var a = this.aNode;
        var b = this.bNode;
        var c = this.cNode;

        var isWebGL = builder.renderer.isWebGLRenderer == true;

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
            var params = [];

            if (method == MathNode.CROSS || method == MathNode.MOD) {
                params.push(a.build(builder, type), b.build(builder, type));
            } else if (method == MathNode.STEP) {
                params.push(a.build(builder, builder.getTypeLength(a.getNodeType(builder)) == 1 ? 'float' : inputType), b.build(builder, inputType));
            } else if ((isWebGL && (method == MathNode.MIN || method == MathNode.MAX)) || method == MathNode.MOD) {
                params.push(a.build(builder, inputType), b.build(builder, builder.getTypeLength(b.getNodeType(builder)) == 1 ? 'float' : inputType));
            } else if (method == MathNode.REFRACT) {
                params.push(a.build(builder, inputType), b.build(builder, inputType), c.build(builder, 'float'));
            } else if (method == MathNode.MIX) {
                params.push(a.build(builder, inputType), b.build(builder, inputType), c.build(builder, builder.getTypeLength(c.getNodeType(builder)) == 1 ? 'float' : inputType));
            } else {
                params.push(a.build(builder, inputType));
                if (b != null) params.push(b.build(builder, inputType));
                if (c != null) params.push(c.build(builder, inputType));
            }

            return builder.format('${builder.getMethod(method, type)}(${params.join(', ')})', type, output);
        }
    }

    public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.method = this.method;
    }

    public function deserialize(data:Dynamic):Void {
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

// Constants
public static var EPSILON(default, null):Float = 1e-6;
public static var INFINITY(default, null):Float = 1e6;
public static var PI(default, null):Float = Math.PI;
public static var PI2(default, null):Float = Math.PI * 2;

// Exports
addNodeClass('MathNode', MathNode);