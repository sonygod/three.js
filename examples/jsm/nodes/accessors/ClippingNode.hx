package three.js.examples.jsm.nodes.accessors;

import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.js.nodes.PositionNode;
import three.js.core.PropertyNode;
import three.js.shadernode.ShaderNode;
import three.js.utils.LoopNode;
import three.js.math.MathNode;
import three.js.nodes.UniformsNode;

class ClippingNode extends Node {

    public static inline var ALPHA_TO_COVERAGE:String = 'alphaToCoverage';
    public static inline var DEFAULT:String = 'default';

    private var scope:String;

    public function new(?scope:String = DEFAULT) {
        super();
        this.scope = scope;
    }

    override public function setup(builder:Dynamic) {
        super.setup(builder);

        var clippingContext = builder.clippingContext;
        var localClipIntersection = clippingContext.localClipIntersection;
        var localClippingCount = clippingContext.localClippingCount;
        var globalClippingCount = clippingContext.globalClippingCount;

        var numClippingPlanes = globalClippingCount + localClippingCount;
        var numUnionClippingPlanes = localClipIntersection ? numClippingPlanes - localClippingCount : numClippingPlanes;

        if (scope == ALPHA_TO_COVERAGE) {
            return setupAlphaToCoverage(clippingContext.planes, numClippingPlanes, numUnionClippingPlanes);
        } else {
            return setupDefault(clippingContext.planes, numClippingPlanes, numUnionClippingPlanes);
        }
    }

    private function setupAlphaToCoverage(planes:Array<Dynamic>, numClippingPlanes:Int, numUnionClippingPlanes:Int) {
        tslFn(() => {
            var clippingPlanes = uniforms(planes);

            var distanceToPlane = property('float', 'distanceToPlane');
            var distanceGradient = property('float', 'distanceGradient');

            var clipOpacity = property('float', 'clipOpacity');
            clipOpacity.assign(1);

            var plane:Dynamic;

            loop(numUnionClippingPlanes, (i) => {
                plane = clippingPlanes.element(i);
                distanceToPlane.assign(positionView.dot(plane.xyz).negate().add(plane.w));
                distanceGradient.assign(distanceToPlane.fwidth().div(2.0));
                clipOpacity.mulAssign(smoothstep(distanceGradient.negate(), distanceGradient, distanceToPlane));
                clipOpacity.equal(0.0).discard();
            });

            if (numUnionClippingPlanes < numClippingPlanes) {
                var unionClipOpacity = property('float', 'unionclipOpacity');
                unionClipOpacity.assign(1);

                loop({ start: numUnionClippingPlanes, end: numClippingPlanes }, (i) => {
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

    private function setupDefault(planes:Array<Dynamic>, numClippingPlanes:Int, numUnionClippingPlanes:Int) {
        tslFn(() => {
            var clippingPlanes = uniforms(planes);

            var plane:Dynamic;

            loop(numUnionClippingPlanes, (i) => {
                plane = clippingPlanes.element(i);
                positionView.dot(plane.xyz).greaterThan(plane.w).discard();
            });

            if (numUnionClippingPlanes < numClippingPlanes) {
                var clipped = property('bool', 'clipped');
                clipped.assign(true);

                loop({ start: numUnionClippingPlanes, end: numClippingPlanes }, (i) => {
                    plane = clippingPlanes.element(i);
                    clipped.assign(positionView.dot(plane.xyz).greaterThan(plane.w).and(clipped));
                });

                clipped.discard();
            }
        })();
    }
}

class Clipping {
    public static function clipping():Dynamic {
        return nodeObject(new ClippingNode());
    }

    public static function clippingAlpha():Dynamic {
        return nodeObject(new ClippingNode(ClippingNode.ALPHA_TO_COVERAGE));
    }
}