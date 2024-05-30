package three.js.nodes;

import three.core.TempNode;
import three.nodes.OperatorNode;
import three.shadernode.ShaderNode;

class MathNode extends TempNode {
    public var method:String;
    public var aNode:Node;
    public var bNode:Node;
    public var cNode:Node;

    public function new(method:String, aNode:Node, ?bNode:Node, ?cNode:Node) {
        super();
        this.method = method;
        this.aNode = aNode;
        this.bNode = bNode;
        this.cNode = cNode;
    }

    public function getInputType(builder:IShaderBuilder):String {
        var aType = aNode.getNodeType(builder);
        var bType = bNode != null ? bNode.getNodeType(builder) : null;
        var cType = cNode != null ? cNode.getNodeType(builder) : null;

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

    public function getNodeType(builder:IShaderBuilder):String {
        switch (method) {
            case MathNode.LENGTH, MathNode.DISTANCE, MathNode.DOT:
                return "float";
            case MathNode.CROSS:
                return "vec3";
            case MathNode.ALL:
                return "bool";
            case MathNode.EQUALS:
                return builder.changeComponentType(aNode.getNodeType(builder), "bool");
            case MathNode.MOD:
                return aNode.getNodeType(builder);
            default:
                return getInputType(builder);
        }
    }

    public function generate(builder:IShaderBuilder, output:String):String {
        switch (method) {
            case MathNode.TRANSFORM_DIRECTION:
                var tA = aNode;
                var tB = bNode;

                if (builder.isMatrix(tA.getNodeType(builder))) {
                    tB = vec4(vec3(tB), 0.0);
                } else {
                    tA = vec4(vec3(tA), 0.0);
                }

                var mulNode = mul(tA, tB).xyz;
                return normalize(mulNode).build(builder, output);

            case MathNode.NEGATE:
                return builder.format("( - " + aNode.build(builder, getInputType(builder)) + " )", "float", output);

            case MathNode.ONE_MINUS:
                return sub(1.0, aNode).build(builder, output);

            case MathNode.RECIPROCAL:
                return div(1.0, aNode).build(builder, output);

            case MathNode.DIFFERENCE:
                return abs(sub(aNode, bNode)).build(builder, output);

            default:
                var params:Array<String> = [];

                switch (method) {
                    case MathNode.CROSS, MathNode.MOD:
                        params.push(aNode.build(builder, getInputType(builder)));
                        params.push(bNode.build(builder, getInputType(builder)));

                    case MathNode.STEP:
                        params.push(aNode.build(builder, builder.getTypeLength(aNode.getNodeType(builder)) == 1 ? "float" : getInputType(builder)));
                        params.push(bNode.build(builder, getInputType(builder)));

                    case MathNode.REFRACT:
                        params.push(aNode.build(builder, getInputType(builder)));
                        params.push(bNode.build(builder, getInputType(builder)));
                        params.push(cNode.build(builder, "float"));

                    default:
                        params.push(aNode.build(builder, getInputType(builder)));
                        if (bNode != null) params.push(bNode.build(builder, getInputType(builder)));
                        if (cNode != null) params.push(cNode.build(builder, getInputType(builder)));
                }

                return builder.format("${builder.getMethod(method, getInputType(builder))}(${params.join(", ")})", getInputType(builder), output);
        }
    }

    public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.method = method;
    }

    public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        method = data.method;
    }
}

// Constants
MathNode.ALL = "all";
MathNode.ANY = "any";
MathNode.EQUALS = "equals";

MathNode.RADIANS = "radians";
MathNode.DEGREES = "degrees";
MathNode.EXP = "exp";
MathNode.EXP2 = "exp2";
MathNode.LOG = "log";
MathNode.LOG2 = "log2";
MathNode.SQRT = "sqrt";
MathNode.INVERSE_SQRT = "inversesqrt";
MathNode.FLOOR = "floor";
MathNode.CEIL = "ceil";
MathNode.NORMALIZE = "normalize";
MathNode.FRACT = "fract";
MathNode.SIN = "sin";
MathNode.COS = "cos";
MathNode.TAN = "tan";
MathNode.ASIN = "asin";
MathNode.ACOS = "acos";
MathNode.ATAN = "atan";
MathNode.ABS = "abs";
MathNode.SIGN = "sign";
MathNode.LENGTH = "length";
MathNode.NEGATE = "negate";
MathNode.ONE_MINUS = "oneMinus";
MathNode.DFDX = "dFdx";
MathNode.DFDY = "dFdy";
MathNode.ROUND = "round";
MathNode.RECIPROCAL = "reciprocal";
MathNode.TRUNC = "trunc";
MathNode.FWIDTH = "fwidth";
MathNode.BITCAST = "bitcast";

// 2 inputs
MathNode.ATAN2 = "atan2";
MathNode.MIN = "min";
MathNode.MAX = "max";
MathNode.MOD = "mod";
MathNode.STEP = "step";
MathNode.REFLECT = "reflect";
MathNode.DISTANCE = "distance";
MathNode.DIFFERENCE = "difference";
MathNode.DOT = "dot";
MathNode.CROSS = "cross";
MathNode.POW = "pow";
MathNode.TRANSFORM_DIRECTION = "transformDirection";

// 3 inputs
MathNode.MIX = "mix";
MathNode.CLAMP = "clamp";
MathNode.REFRACT = "refract";
MathNode.SMOOTHSTEP = "smoothstep";
MathNode.FACEFORWARD = "faceforward";

// Node proxies
var all = nodeProxy(MathNode, MathNode.ALL);
var any = nodeProxy(MathNode, MathNode.ANY);
var equals = nodeProxy(MathNode, MathNode.EQUALS);

// ...

// Add node elements
addNodeElement("all", all);
addNodeElement("any", any);
addNodeElement("equals", equals);

// ...

addNodeClass("MathNode", MathNode);