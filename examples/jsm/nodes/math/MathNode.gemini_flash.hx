import TempNode from "../core/TempNode";
import OperatorNode from "./OperatorNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class MathNode extends TempNode {
  public method:String;
  public aNode:TempNode;
  public bNode:TempNode;
  public cNode:TempNode;

  public function new(method:String, aNode:TempNode, bNode:TempNode = null, cNode:TempNode = null) {
    super();
    this.method = method;
    this.aNode = aNode;
    this.bNode = bNode;
    this.cNode = cNode;
  }

  override public function getInputType(builder:ShaderNode.Builder):String {
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

  override public function getNodeType(builder:ShaderNode.Builder):String {
    var method = this.method;
    if (method == MathNode.LENGTH || method == MathNode.DISTANCE || method == MathNode.DOT) {
      return "float";
    } else if (method == MathNode.CROSS) {
      return "vec3";
    } else if (method == MathNode.ALL) {
      return "bool";
    } else if (method == MathNode.EQUALS) {
      return builder.changeComponentType(this.aNode.getNodeType(builder), "bool");
    } else if (method == MathNode.MOD) {
      return this.aNode.getNodeType(builder);
    } else {
      return this.getInputType(builder);
    }
  }

  override public function generate(builder:ShaderNode.Builder, output:String):String {
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
        tB = ShaderNode.vec4(ShaderNode.vec3(tB), 0.0);
      } else {
        tA = ShaderNode.vec4(ShaderNode.vec3(tA), 0.0);
      }
      var mulNode = OperatorNode.mul(tA, tB).xyz;
      return ShaderNode.normalize(mulNode).build(builder, output);
    } else if (method == MathNode.NEGATE) {
      return builder.format("(-" + a.build(builder, inputType) + ")", type, output);
    } else if (method == MathNode.ONE_MINUS) {
      return OperatorNode.sub(1.0, a).build(builder, output);
    } else if (method == MathNode.RECIPROCAL) {
      return OperatorNode.div(1.0, a).build(builder, output);
    } else if (method == MathNode.DIFFERENCE) {
      return ShaderNode.abs(OperatorNode.sub(a, b)).build(builder, output);
    } else {
      var params:Array<String> = [];
      if (method == MathNode.CROSS || method == MathNode.MOD) {
        params.push(a.build(builder, type), b.build(builder, type));
      } else if (method == MathNode.STEP) {
        params.push(
          a.build(builder, builder.getTypeLength(a.getNodeType(builder)) == 1 ? "float" : inputType),
          b.build(builder, inputType)
        );
      } else if (
        (isWebGL && (method == MathNode.MIN || method == MathNode.MAX)) ||
        method == MathNode.MOD
      ) {
        params.push(
          a.build(builder, inputType),
          b.build(builder, builder.getTypeLength(b.getNodeType(builder)) == 1 ? "float" : inputType)
        );
      } else if (method == MathNode.REFRACT) {
        params.push(
          a.build(builder, inputType),
          b.build(builder, inputType),
          c.build(builder, "float")
        );
      } else if (method == MathNode.MIX) {
        params.push(
          a.build(builder, inputType),
          b.build(builder, inputType),
          c.build(builder, builder.getTypeLength(c.getNodeType(builder)) == 1 ? "float" : inputType)
        );
      } else {
        params.push(a.build(builder, inputType));
        if (b != null) params.push(b.build(builder, inputType));
        if (c != null) params.push(c.build(builder, inputType));
      }
      return builder.format("${builder.getMethod(method, type)}(${params.join(', ')})", type, output);
    }
  }

  override public function serialize(data:Dynamic) {
    super.serialize(data);
    data.method = this.method;
  }

  override public function deserialize(data:Dynamic) {
    super.deserialize(data);
    this.method = data.method;
  }
}

// 1 input
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

export default MathNode;

export var EPSILON:ShaderNode.Float = ShaderNode.float(1e-6);
export var INFINITY:ShaderNode.Float = ShaderNode.float(1e6);
export var PI:ShaderNode.Float = ShaderNode.float(Math.PI);
export var PI2:ShaderNode.Float = ShaderNode.float(Math.PI * 2);

export var all:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.ALL);
export var any:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.ANY);
export var equals:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.EQUALS);

export var radians:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.RADIANS);
export var degrees:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.DEGREES);
export var exp:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.EXP);
export var exp2:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.EXP2);
export var log:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.LOG);
export var log2:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.LOG2);
export var sqrt:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.SQRT);
export var inverseSqrt:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.INVERSE_SQRT);
export var floor:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.FLOOR);
export var ceil:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.CEIL);
export var normalize:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.NORMALIZE);
export var fract:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.FRACT);
export var sin:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.SIN);
export var cos:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.COS);
export var tan:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.TAN);
export var asin:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.ASIN);
export var acos:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.ACOS);
export var atan:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.ATAN);
export var abs:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.ABS);
export var sign:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.SIGN);
export var length:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.LENGTH);
export var negate:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.NEGATE);
export var oneMinus:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.ONE_MINUS);
export var dFdx:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.DFDX);
export var dFdy:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.DFDY);
export var round:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.ROUND);
export var reciprocal:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.RECIPROCAL);
export var trunc:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.TRUNC);
export var fwidth:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.FWIDTH);
export var bitcast:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.BITCAST);

export var atan2:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.ATAN2);
export var min:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.MIN);
export var max:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.MAX);
export var mod:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.MOD);
export var step:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.STEP);
export var reflect:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.REFLECT);
export var distance:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.DISTANCE);
export var difference:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.DIFFERENCE);
export var dot:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.DOT);
export var cross:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.CROSS);
export var pow:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.POW);
export var pow2:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.POW, 2);
export var pow3:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.POW, 3);
export var pow4:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.POW, 4);
export var transformDirection:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.TRANSFORM_DIRECTION);

export function cbrt(a:ShaderNode.Node):ShaderNode.Node {
  return OperatorNode.mul(ShaderNode.sign(a), OperatorNode.pow(ShaderNode.abs(a), 1.0 / 3.0));
}
export function lengthSq(a:ShaderNode.Node):ShaderNode.Node {
  return OperatorNode.dot(a, a);
}
export var mix:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.MIX);
export function clamp(value:ShaderNode.Node, low:ShaderNode.Node = 0, high:ShaderNode.Node = 1):ShaderNode.Node {
  return ShaderNode.nodeObject(new MathNode(MathNode.CLAMP, ShaderNode.nodeObject(value), ShaderNode.nodeObject(low), ShaderNode.nodeObject(high)));
}
export function saturate(value:ShaderNode.Node):ShaderNode.Node {
  return clamp(value);
}
export var refract:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.REFRACT);
export var smoothstep:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.SMOOTHSTEP);
export var faceForward:ShaderNode.NodeProxy<MathNode> = ShaderNode.nodeProxy(MathNode, MathNode.FACEFORWARD);

export function mixElement(t:ShaderNode.Node, e1:ShaderNode.Node, e2:ShaderNode.Node):ShaderNode.Node {
  return mix(e1, e2, t);
}
export function smoothstepElement(x:ShaderNode.Node, low:ShaderNode.Node, high:ShaderNode.Node):ShaderNode.Node {
  return smoothstep(low, high, x);
}

ShaderNode.addNodeElement("all", all);
ShaderNode.addNodeElement("any", any);
ShaderNode.addNodeElement("equals", equals);

ShaderNode.addNodeElement("radians", radians);
ShaderNode.addNodeElement("degrees", degrees);
ShaderNode.addNodeElement("exp", exp);
ShaderNode.addNodeElement("exp2", exp2);
ShaderNode.addNodeElement("log", log);
ShaderNode.addNodeElement("log2", log2);
ShaderNode.addNodeElement("sqrt", sqrt);
ShaderNode.addNodeElement("inverseSqrt", inverseSqrt);
ShaderNode.addNodeElement("floor", floor);
ShaderNode.addNodeElement("ceil", ceil);
ShaderNode.addNodeElement("normalize", normalize);
ShaderNode.addNodeElement("fract", fract);
ShaderNode.addNodeElement("sin", sin);
ShaderNode.addNodeElement("cos", cos);
ShaderNode.addNodeElement("tan", tan);
ShaderNode.addNodeElement("asin", asin);
ShaderNode.addNodeElement("acos", acos);
ShaderNode.addNodeElement("atan", atan);
ShaderNode.addNodeElement("abs", abs);
ShaderNode.addNodeElement("sign", sign);
ShaderNode.addNodeElement("length", length);
ShaderNode.addNodeElement("lengthSq", lengthSq);
ShaderNode.addNodeElement("negate", negate);
ShaderNode.addNodeElement("oneMinus", oneMinus);
ShaderNode.addNodeElement("dFdx", dFdx);
ShaderNode.addNodeElement("dFdy", dFdy);
ShaderNode.addNodeElement("round", round);
ShaderNode.addNodeElement("reciprocal", reciprocal);
ShaderNode.addNodeElement("trunc", trunc);
ShaderNode.addNodeElement("fwidth", fwidth);
ShaderNode.addNodeElement("atan2", atan2);
ShaderNode.addNodeElement("min", min);
ShaderNode.addNodeElement("max", max);
ShaderNode.addNodeElement("mod", mod);
ShaderNode.addNodeElement("step", step);
ShaderNode.addNodeElement("reflect", reflect);
ShaderNode.addNodeElement("distance", distance);
ShaderNode.addNodeElement("dot", dot);
ShaderNode.addNodeElement("cross", cross);
ShaderNode.addNodeElement("pow", pow);
ShaderNode.addNodeElement("pow2", pow2);
ShaderNode.addNodeElement("pow3", pow3);
ShaderNode.addNodeElement("pow4", pow4);
ShaderNode.addNodeElement("transformDirection", transformDirection);
ShaderNode.addNodeElement("mix", mixElement);
ShaderNode.addNodeElement("clamp", clamp);
ShaderNode.addNodeElement("refract", refract);
ShaderNode.addNodeElement("smoothstep", smoothstepElement);
ShaderNode.addNodeElement("faceForward", faceForward);
ShaderNode.addNodeElement("difference", difference);
ShaderNode.addNodeElement("saturate", saturate);
ShaderNode.addNodeElement("cbrt", cbrt);

ShaderNode.addNodeClass("MathNode", MathNode);