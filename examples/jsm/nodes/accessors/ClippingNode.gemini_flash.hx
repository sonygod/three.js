import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";
import PositionNode from "./PositionNode";
import PropertyNode from "../core/PropertyNode";
import { tslFn, nodeObject } from "../shadernode/ShaderNode";
import LoopNode from "../utils/LoopNode";
import MathNode from "../math/MathNode";
import { smoothstep } from "../math/MathNode";
import UniformsNode from "./UniformsNode";

class ClippingNode extends Node {
  public scope: String;

  public static ALPHA_TO_COVERAGE: String = "alphaToCoverage";
  public static DEFAULT: String = "default";

  public constructor(scope: String = ClippingNode.DEFAULT) {
    super();
    this.scope = scope;
  }

  public setup(builder: any): Void {
    super.setup(builder);

    var clippingContext = builder.clippingContext;
    var { localClipIntersection, localClippingCount, globalClippingCount } = clippingContext;

    var numClippingPlanes = globalClippingCount + localClippingCount;
    var numUnionClippingPlanes = localClipIntersection ? numClippingPlanes - localClippingCount : numClippingPlanes;

    if (this.scope == ClippingNode.ALPHA_TO_COVERAGE) {
      return this.setupAlphaToCoverage(clippingContext.planes, numClippingPlanes, numUnionClippingPlanes);
    } else {
      return this.setupDefault(clippingContext.planes, numClippingPlanes, numUnionClippingPlanes);
    }
  }

  public setupAlphaToCoverage(planes: Array<any>, numClippingPlanes: Int, numUnionClippingPlanes: Int): Void {
    return tslFn(() => {
      var clippingPlanes = uniforms(planes);

      var distanceToPlane = property("float", "distanceToPlane");
      var distanceGradient = property("float", "distanceToGradient");

      var clipOpacity = property("float", "clipOpacity");

      clipOpacity.assign(1);

      var plane: any;

      loop(numUnionClippingPlanes, ({ i }) => {
        plane = clippingPlanes.element(i);

        distanceToPlane.assign(positionView.dot(plane.xyz).negate().add(plane.w));
        distanceGradient.assign(distanceToPlane.fwidth().div(2.0));

        clipOpacity.mulAssign(smoothstep(distanceGradient.negate(), distanceGradient, distanceToPlane));

        clipOpacity.equal(0.0).discard();
      });

      if (numUnionClippingPlanes < numClippingPlanes) {
        var unionClipOpacity = property("float", "unionclipOpacity");

        unionClipOpacity.assign(1);

        loop({ start: numUnionClippingPlanes, end: numClippingPlanes }, ({ i }) => {
          plane = clippingPlanes.element(i);

          distanceToPlane.assign(positionView.dot(plane.xyz).negate().add(plane.w));
          distanceGradient.assign(distanceToPlane.fwidth().div(2.0));

          unionClipOpacity.mulAssign(smoothstep(distanceGradient.negate(), distanceGradient, distanceToPlane).oneMinus());
        });

        clipOpacity.mulAssign(unionClipOpacity.oneMinus());
      }

      diffuseColor.a.mulAssign(clipOpacity);

      diffuseColor.a.equal(0.0).discard();
    })();
  }

  public setupDefault(planes: Array<any>, numClippingPlanes: Int, numUnionClippingPlanes: Int): Void {
    return tslFn(() => {
      var clippingPlanes = uniforms(planes);

      var plane: any;

      loop(numUnionClippingPlanes, ({ i }) => {
        plane = clippingPlanes.element(i);
        positionView.dot(plane.xyz).greaterThan(plane.w).discard();
      });

      if (numUnionClippingPlanes < numClippingPlanes) {
        var clipped = property("bool", "clipped");

        clipped.assign(true);

        loop({ start: numUnionClippingPlanes, end: numClippingPlanes }, ({ i }) => {
          plane = clippingPlanes.element(i);
          clipped.assign(positionView.dot(plane.xyz).greaterThan(plane.w).and(clipped));
        });

        clipped.discard();
      }
    })();
  }
}

export var clipping = (): ShaderNode => nodeObject(new ClippingNode());

export var clippingAlpha = (): ShaderNode => nodeObject(new ClippingNode(ClippingNode.ALPHA_TO_COVERAGE));

export default ClippingNode;