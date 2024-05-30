import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.PositionNode;
import three.js.examples.jsm.nodes.core.PropertyNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.utils.LoopNode;
import three.js.examples.jsm.math.MathNode;
import three.js.examples.jsm.nodes.UniformsNode;

class ClippingNode extends Node {

	public static var ALPHA_TO_COVERAGE:String = 'alphaToCoverage';
	public static var DEFAULT:String = 'default';

	var scope:String;

	public function new(scope:String = ClippingNode.DEFAULT) {
		super();
		this.scope = scope;
	}

	public function setup(builder:ShaderNode.Builder):Void {
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

	public function setupAlphaToCoverage(planes:Array<PropertyNode>, numClippingPlanes:Int, numUnionClippingPlanes:Int):Void {
		var clippingPlanes = ShaderNode.uniforms(planes);
		var distanceToPlane = PropertyNode.property('float', 'distanceToPlane');
		var distanceGradient = PropertyNode.property('float', 'distanceToGradient');
		var clipOpacity = PropertyNode.property('float', 'clipOpacity');
		clipOpacity.assign(1);
		var plane:PropertyNode;

		LoopNode.loop(numUnionClippingPlanes, (i:Int) -> {
			plane = clippingPlanes.element(i);
			distanceToPlane.assign(PositionNode.positionView.dot(plane.xyz).negate().add(plane.w));
			distanceGradient.assign(distanceToPlane.fwidth().div(2.0));
			clipOpacity.mulAssign(MathNode.smoothstep(distanceGradient.negate(), distanceGradient, distanceToPlane));
			clipOpacity.equal(0.0).discard();
		});

		if (numUnionClippingPlanes < numClippingPlanes) {
			var unionClipOpacity = PropertyNode.property('float', 'unionclipOpacity');
			unionClipOpacity.assign(1);

			LoopNode.loop({start: numUnionClippingPlanes, end: numClippingPlanes}, (i:Int) -> {
				plane = clippingPlanes.element(i);
				distanceToPlane.assign(PositionNode.positionView.dot(plane.xyz).negate().add(plane.w));
				distanceGradient.assign(distanceToPlane.fwidth().div(2.0));
				unionClipOpacity.mulAssign(MathNode.smoothstep(distanceGradient.negate(), distanceGradient, distanceToPlane).oneMinus());
			});

			clipOpacity.mulAssign(unionClipOpacity.oneMinus());
			PropertyNode.diffuseColor.a.mulAssign(clipOpacity);
			PropertyNode.diffuseColor.a.equal(0.0).discard();
		}
	}

	public function setupDefault(planes:Array<PropertyNode>, numClippingPlanes:Int, numUnionClippingPlanes:Int):Void {
		var clippingPlanes = ShaderNode.uniforms(planes);
		var plane:PropertyNode;

		LoopNode.loop(numUnionClippingPlanes, (i:Int) -> {
			plane = clippingPlanes.element(i);
			PositionNode.positionView.dot(plane.xyz).greaterThan(plane.w).discard();
		});

		if (numUnionClippingPlanes < numClippingPlanes) {
			var clipped = PropertyNode.property('bool', 'clipped');
			clipped.assign(true);

			LoopNode.loop({start: numUnionClippingPlanes, end: numClippingPlanes}, (i:Int) -> {
				plane = clippingPlanes.element(i);
				clipped.assign(PositionNode.positionView.dot(plane.xyz).greaterThan(plane.w).and(clipped));
			});

			clipped.discard();
		}
	}
}

class Clipping {
	public static function clipping():Node {
		return ShaderNode.nodeObject(new ClippingNode());
	}

	public static function clippingAlpha():Node {
		return ShaderNode.nodeObject(new ClippingNode(ClippingNode.ALPHA_TO_COVERAGE));
	}
}