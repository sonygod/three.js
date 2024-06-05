import TempNode from "../core/TempNode";
import {nodeObject, addNodeElement, tslFn, float, vec4} from "../shadernode/ShaderNode";
import {NodeUpdateType} from "../core/constants";
import {uv} from "../accessors/UVNode";
import {texture} from "../accessors/TextureNode";
import {texturePass} from "./PassNode";
import {uniform} from "../core/UniformNode";
import {RenderTarget} from "three";
import {sign, max} from "../math/MathNode";
import QuadMesh from "../../objects/QuadMesh";

class AfterImageNode extends TempNode {
	public textureNode:TempNode;
	public textureNodeOld:TempNode;
	public damp:TempNode;
	private _compRT:RenderTarget;
	private _oldRT:RenderTarget;
	private _textureNode:TempNode;

	public function new(textureNode:TempNode, damp:Float = 0.96) {
		super(textureNode);
		this.textureNode = textureNode;
		this.textureNodeOld = texture();
		this.damp = uniform(damp);
		this._compRT = new RenderTarget();
		this._compRT.texture.name = "AfterImageNode.comp";
		this._oldRT = new RenderTarget();
		this._oldRT.texture.name = "AfterImageNode.old";
		this._textureNode = texturePass(this, this._compRT.texture);
		this.updateBeforeType = NodeUpdateType.RENDER;
	}

	public function getTextureNode():TempNode {
		return this._textureNode;
	}

	public function setSize(width:Int, height:Int):Void {
		this._compRT.setSize(width, height);
		this._oldRT.setSize(width, height);
	}

	public function updateBefore(frame:Dynamic):Void {
		final renderer = frame.renderer;
		final textureNode = this.textureNode;
		final map = textureNode.value;
		final textureType = map.type;
		this._compRT.texture.type = textureType;
		this._oldRT.texture.type = textureType;
		final currentRenderTarget = renderer.getRenderTarget();
		final currentTexture = textureNode.value;
		this.textureNodeOld.value = this._oldRT.texture;
		// comp
		renderer.setRenderTarget(this._compRT);
		QuadMesh.render(renderer);
		// Swap the textures
		final temp = this._oldRT;
		this._oldRT = this._compRT;
		this._compRT = temp;
		// set size before swapping fails
		this.setSize(map.image.width, map.image.height);
		renderer.setRenderTarget(currentRenderTarget);
		textureNode.value = currentTexture;
	}

	override public function setup(builder:Dynamic):TempNode {
		final textureNode = this.textureNode;
		final textureNodeOld = this.textureNodeOld;
		if (!textureNode.isTextureNode) {
			console.error("AfterImageNode requires a TextureNode.");
			return vec4();
		}
		//
		final uvNode = textureNode.uvNode != null ? textureNode.uvNode : uv();
		textureNodeOld.uvNode = uvNode;
		final sampleTexture = (uv:TempNode) -> vec4 {
			return textureNode.cache().context({getUV: () -> uv, forceUVContext: true});
		};
		final when_gt = tslFn((args:Array<Dynamic>) -> TempNode {
			final y = float(args[1]).toVar();
			final x = vec4(args[0]).toVar();
			return max(sign(x.sub(y)), 0.0);
		});
		final afterImg = tslFn(() -> {
			final texelOld = vec4(textureNodeOld);
			final texelNew = vec4(sampleTexture(uvNode));
			texelOld.mulAssign(this.damp.mul(when_gt([texelOld, 0.1])));
			return max(texelNew, texelOld);
		});
		//
		final materialComposed = this._materialComposed != null ? this._materialComposed : builder.createNodeMaterial();
		materialComposed.fragmentNode = afterImg();
		QuadMesh.material = materialComposed;
		//
		final properties = builder.getNodeProperties(this);
		properties.textureNode = textureNode;
		//
		return this._textureNode;
	}
}

final afterImage = (node:TempNode, damp:Float) -> TempNode {
	return nodeObject(new AfterImageNode(nodeObject(node), damp));
};

addNodeElement("afterImage", afterImage);

export default AfterImageNode;