import TempNode from "../core/TempNode";
import MathNode from "../math/MathNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class BurnNode extends TempNode {
	public function new(base:ShaderNode.Vec3, blend:ShaderNode.Vec3) {
		super();
		this.output = vec3(
			blend.x.lessThan(MathNode.EPSILON).cond(blend.x, base.x.oneMinus().div(blend.x).oneMinus().max(0.0)),
			blend.y.lessThan(MathNode.EPSILON).cond(blend.y, base.y.oneMinus().div(blend.y).oneMinus().max(0.0)),
			blend.z.lessThan(MathNode.EPSILON).cond(blend.z, base.z.oneMinus().div(blend.z).oneMinus().max(0.0))
		);
	}
	private inline function vec3(x:ShaderNode.Float, y:ShaderNode.Float, z:ShaderNode.Float):ShaderNode.Vec3 {
		return cast ShaderNode.vec3(x, y, z);
	}
}

class DodgeNode extends TempNode {
	public function new(base:ShaderNode.Vec3, blend:ShaderNode.Vec3) {
		super();
		this.output = vec3(
			blend.x.equal(1.0).cond(blend.x, base.x.div(blend.x.oneMinus()).max(0.0)),
			blend.y.equal(1.0).cond(blend.y, base.y.div(blend.y.oneMinus()).max(0.0)),
			blend.z.equal(1.0).cond(blend.z, base.z.div(blend.z.oneMinus()).max(0.0))
		);
	}
	private inline function vec3(x:ShaderNode.Float, y:ShaderNode.Float, z:ShaderNode.Float):ShaderNode.Vec3 {
		return cast ShaderNode.vec3(x, y, z);
	}
}

class ScreenNode extends TempNode {
	public function new(base:ShaderNode.Vec3, blend:ShaderNode.Vec3) {
		super();
		this.output = vec3(
			base.x.oneMinus().mul(blend.x.oneMinus()).oneMinus(),
			base.y.oneMinus().mul(blend.y.oneMinus()).oneMinus(),
			base.z.oneMinus().mul(blend.z.oneMinus()).oneMinus()
		);
	}
	private inline function vec3(x:ShaderNode.Float, y:ShaderNode.Float, z:ShaderNode.Float):ShaderNode.Vec3 {
		return cast ShaderNode.vec3(x, y, z);
	}
}

class OverlayNode extends TempNode {
	public function new(base:ShaderNode.Vec3, blend:ShaderNode.Vec3) {
		super();
		this.output = vec3(
			base.x.lessThan(0.5).cond(base.x.mul(blend.x, 2.0), base.x.oneMinus().mul(blend.x.oneMinus()).oneMinus()),
			base.y.lessThan(0.5).cond(base.y.mul(blend.y, 2.0), base.y.oneMinus().mul(blend.y.oneMinus()).oneMinus()),
			base.z.lessThan(0.5).cond(base.z.mul(blend.z, 2.0), base.z.oneMinus().mul(blend.z.oneMinus()).oneMinus())
		);
	}
	private inline function vec3(x:ShaderNode.Float, y:ShaderNode.Float, z:ShaderNode.Float):ShaderNode.Vec3 {
		return cast ShaderNode.vec3(x, y, z);
	}
}

enum BlendMode {
	BURN;
	DODGE;
	SCREEN;
	OVERLAY;
}

class BlendModeNode extends TempNode {
	public var blendMode:BlendMode;
	public var baseNode:ShaderNode;
	public var blendNode:ShaderNode;
	public function new(blendMode:BlendMode, baseNode:ShaderNode, blendNode:ShaderNode) {
		super();
		this.blendMode = blendMode;
		this.baseNode = baseNode;
		this.blendNode = blendNode;
	}
	override public function setup():ShaderNode {
		var outputNode:ShaderNode = null;
		switch (blendMode) {
		case BURN:
			outputNode = new BurnNode(cast ShaderNode.vec3(baseNode), cast ShaderNode.vec3(blendNode));
		case DODGE:
			outputNode = new DodgeNode(cast ShaderNode.vec3(baseNode), cast ShaderNode.vec3(blendNode));
		case SCREEN:
			outputNode = new ScreenNode(cast ShaderNode.vec3(baseNode), cast ShaderNode.vec3(blendNode));
		case OVERLAY:
			outputNode = new OverlayNode(cast ShaderNode.vec3(baseNode), cast ShaderNode.vec3(blendNode));
		default:
		}
		return outputNode;
	}
}

public function burn(baseNode:ShaderNode, blendNode:ShaderNode):BlendModeNode {
	return new BlendModeNode(BlendMode.BURN, baseNode, blendNode);
}

public function dodge(baseNode:ShaderNode, blendNode:ShaderNode):BlendModeNode {
	return new BlendModeNode(BlendMode.DODGE, baseNode, blendNode);
}

public function overlay(baseNode:ShaderNode, blendNode:ShaderNode):BlendModeNode {
	return new BlendModeNode(BlendMode.OVERLAY, baseNode, blendNode);
}

public function screen(baseNode:ShaderNode, blendNode:ShaderNode):BlendModeNode {
	return new BlendModeNode(BlendMode.SCREEN, baseNode, blendNode);
}

ShaderNode.addNodeElement("burn", burn);
ShaderNode.addNodeElement("dodge", dodge);
ShaderNode.addNodeElement("overlay", overlay);
ShaderNode.addNodeElement("screen", screen);
ShaderNode.addNodeClass("BlendModeNode", BlendModeNode);