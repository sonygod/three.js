import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";
import PositionNode from "./PositionNode";
import PropertyNode from "../core/PropertyNode";
import { loop, LoopNode } from "../utils/LoopNode";
import { smoothstep } from "../math/MathNode";
import { uniforms } from "./UniformsNode";

class ClippingNode extends Node {
  public static ALPHA_TO_COVERAGE: String = "alphaToCoverage";
  public static DEFAULT: String = "default";

  public scope: String;

  public constructor(scope: String = ClippingNode.DEFAULT) {
    super();
    this.scope = scope;
  }

  public setup(builder: any): any {
    super.setup(builder);

    var clippingContext = builder.clippingContext;
    var {
      localClipIntersection,
      localClippingCount,
      globalClippingCount
    } = clippingContext;

    var numClippingPlanes = globalClippingCount + localClippingCount;
    var numUnionClippingPlanes = localClipIntersection
      ? numClippingPlanes - localClippingCount
      : numClippingPlanes;

    if (this.scope == ClippingNode.ALPHA_TO_COVERAGE) {
      return this.setupAlphaToCoverage(
        clippingContext.planes,
        numClippingPlanes,
        numUnionClippingPlanes
      );
    } else {
      return this.setupDefault(
        clippingContext.planes,
        numClippingPlanes,
        numUnionClippingPlanes
      );
    }
  }

  public setupAlphaToCoverage(
    planes: any,
    numClippingPlanes: number,
    numUnionClippingPlanes: number
  ): any {
    return ShaderNode.tslFn(() => {
      var clippingPlanes = uniforms(planes);
      var distanceToPlane = PropertyNode.property("float", "distanceToPlane");
      var distanceGradient = PropertyNode.property("float", "distanceToGradient");
      var clipOpacity = PropertyNode.property("float", "clipOpacity");

      clipOpacity.assign(1);

      var plane: any;

      loop(numUnionClippingPlanes, ({ i }) => {
        plane = clippingPlanes.element(i);
        distanceToPlane.assign(
          PositionNode.positionView.dot(plane.xyz).negate().add(plane.w)
        );
        distanceGradient.assign(
          distanceToPlane.fwidth().div(2.0)
        );

        clipOpacity.mulAssign(
          smoothstep(
            distanceGradient.negate(),
            distanceGradient,
            distanceToPlane
          )
        );

        clipOpacity.equal(0.0).discard();
      });

      if (numUnionClippingPlanes < numClippingPlanes) {
        var unionClipOpacity = PropertyNode.property("float", "unionclipOpacity");

        unionClipOpacity.assign(1);

        loop({ start: numUnionClippingPlanes, end: numClippingPlanes }, ({ i }) => {
          plane = clippingPlanes.element(i);
          distanceToPlane.assign(
            PositionNode.positionView.dot(plane.xyz).negate().add(plane.w)
          );
          distanceGradient.assign(
            distanceToPlane.fwidth().div(2.0)
          );

          unionClipOpacity.mulAssign(
            smoothstep(
              distanceGradient.negate(),
              distanceGradient,
              distanceToPlane
            ).oneMinus()
          );
        });

        clipOpacity.mulAssign(unionClipOpacity.oneMinus());
      }

      PropertyNode.diffuseColor.a.mulAssign(clipOpacity);
      PropertyNode.diffuseColor.a.equal(0.0).discard();
    })();
  }

  public setupDefault(
    planes: any,
    numClippingPlanes: number,
    numUnionClippingPlanes: number
  ): any {
    return ShaderNode.tslFn(() => {
      var clippingPlanes = uniforms(planes);
      var plane: any;

      loop(numUnionClippingPlanes, ({ i }) => {
        plane = clippingPlanes.element(i);
        PositionNode.positionView
          .dot(plane.xyz)
          .greaterThan(plane.w)
          .discard();
      });

      if (numUnionClippingPlanes < numClippingPlanes) {
        var clipped = PropertyNode.property("bool", "clipped");

        clipped.assign(true);

        loop({ start: numUnionClippingPlanes, end: numClippingPlanes }, ({ i }) => {
          plane = clippingPlanes.element(i);
          clipped.assign(
            PositionNode.positionView
              .dot(plane.xyz)
              .greaterThan(plane.w)
              .and(clipped)
          );
        });

        clipped.discard();
      }
    })();
  }
}

export function clipping() {
  return ShaderNode.nodeObject(new ClippingNode());
}

export function clippingAlpha() {
  return ShaderNode.nodeObject(new ClippingNode(ClippingNode.ALPHA_TO_COVERAGE));
}

export default ClippingNode;