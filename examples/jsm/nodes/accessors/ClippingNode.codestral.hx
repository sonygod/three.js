import Node from '../core/Node';
import { nodeObject } from '../shadernode/ShaderNode';
import { positionView } from './PositionNode';
import { diffuseColor, property } from '../core/PropertyNode';
import { tslFn } from '../shadernode/ShaderNode';
import { loop } from '../utils/LoopNode';
import { smoothstep } from '../math/MathNode';
import { uniforms } from './UniformsNode';

class ClippingNode extends Node {

    public var scope:String;

    public function new(scope:String = ClippingNode.DEFAULT) {
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

        if (this.scope == ClippingNode.ALPHA_TO_COVERAGE) {
            return this.setupAlphaToCoverage(clippingContext.planes, numClippingPlanes, numUnionClippingPlanes);
        } else {
            return this.setupDefault(clippingContext.planes, numClippingPlanes, numUnionClippingPlanes);
        }
    }

    public function setupAlphaToCoverage(planes:Dynamic, numClippingPlanes:Int, numUnionClippingPlanes:Int):Dynamic {
        var clippingPlanes = uniforms(planes);
        var distanceToPlane = property('float', 'distanceToPlane');
        var distanceGradient = property('float', 'distanceToGradient');
        var clipOpacity = property('float', 'clipOpacity');

        clipOpacity.assign(1);

        var plane:Dynamic;

        loop(numUnionClippingPlanes, ({i}) -> {
            plane = clippingPlanes.element(i);
            distanceToPlane.assign(positionView.dot(plane.xyz).negate().add(plane.w));
            distanceGradient.assign(distanceToPlane.fwidth().div(2.0));
            clipOpacity.mulAssign(smoothstep(distanceGradient.negate(), distanceGradient, distanceToPlane));
            clipOpacity.equal(0.0).discard();
        });

        if (numUnionClippingPlanes < numClippingPlanes) {
            var unionClipOpacity = property('float', 'unionclipOpacity');
            unionClipOpacity.assign(1);
            loop({start: numUnionClippingPlanes, end: numClippingPlanes}, ({i}) -> {
                plane = clippingPlanes.element(i);
                distanceToPlane.assign(positionView.dot(plane.xyz).negate().add(plane.w));
                distanceGradient.assign(distanceToPlane.fwidth().div(2.0));
                unionClipOpacity.mulAssign(smoothstep(distanceGradient.negate(), distanceGradient, distanceToPlane).oneMinus());
            });
            clipOpacity.mulAssign(unionClipOpacity.oneMinus());
        }

        diffuseColor.a.mulAssign(clipOpacity);
        diffuseColor.a.equal(0.0).discard();

        return null; // since tslFn is returning an anonymous function in JavaScript, we're returning null in Haxe as there's no direct equivalent
    }

    public function setupDefault(planes:Dynamic, numClippingPlanes:Int, numUnionClippingPlanes:Int):Dynamic {
        var clippingPlanes = uniforms(planes);
        var plane:Dynamic;

        loop(numUnionClippingPlanes, ({i}) -> {
            plane = clippingPlanes.element(i);
            positionView.dot(plane.xyz).greaterThan(plane.w).discard();
        });

        if (numUnionClippingPlanes < numClippingPlanes) {
            var clipped = property('bool', 'clipped');
            clipped.assign(true);
            loop({start: numUnionClippingPlanes, end: numClippingPlanes}, ({i}) -> {
                plane = clippingPlanes.element(i);
                clipped.assign(positionView.dot(plane.xyz).greaterThan(plane.w).and(clipped));
            });
            clipped.discard();
        }

        return null; // since tslFn is returning an anonymous function in JavaScript, we're returning null in Haxe as there's no direct equivalent
    }
}

static var ALPHA_TO_COVERAGE:String = 'alphaToCoverage';
static var DEFAULT:String = 'default';

static function clipping():Dynamic {
    return nodeObject(new ClippingNode());
}

static function clippingAlpha():Dynamic {
    return nodeObject(new ClippingNode(ClippingNode.ALPHA_TO_COVERAGE));
}