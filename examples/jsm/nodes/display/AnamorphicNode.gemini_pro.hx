import TempNode from "../core/TempNode";
import { nodeObject, addNodeElement, tslFn, float, vec2, vec3, vec4 } from "../shadernode/ShaderNode";
import { loop } from "../utils/LoopNode";
import { uniform } from "../core/UniformNode";
import { NodeUpdateType } from "../core/constants";
import { threshold } from "./ColorAdjustmentNode";
import { uv } from "../accessors/UVNode";
import { texturePass } from "./PassNode";
import { Vector2, RenderTarget } from "three";
import QuadMesh from "../../objects/QuadMesh";

class AnamorphicNode extends TempNode {

	public textureNode:TempNode;
	public tresholdNode:TempNode;
	public scaleNode:TempNode;
	public colorNode:TempNode;
	public samples:Int;
	public resolution:Vector2;
	private _renderTarget:RenderTarget;
	private _invSize:UniformNode;
	private _textureNode:TempNode;
	private _material:any;

	public function new(textureNode:TempNode, tresholdNode:TempNode, scaleNode:TempNode, samples:Int) {
		super("vec4");
		this.textureNode = textureNode;
		this.tresholdNode = tresholdNode;
		this.scaleNode = scaleNode;
		this.colorNode = vec3(0.1, 0.0, 1.0);
		this.samples = samples;
		this.resolution = new Vector2(1, 1);

		this._renderTarget = new RenderTarget();
		this._renderTarget.texture.name = "anamorphic";

		this._invSize = uniform(new Vector2());

		this._textureNode = texturePass(this, this._renderTarget.texture);

		this.updateBeforeType = NodeUpdateType.RENDER;
	}

	public function getTextureNode():TempNode {
		return this._textureNode;
	}

	public function setSize(width:Float, height:Float):Void {
		this._invSize.value.set(1 / width, 1 / height);

		width = Math.max(Math.round(width * this.resolution.x), 1);
		height = Math.max(Math.round(height * this.resolution.y), 1);

		this._renderTarget.setSize(width, height);
	}

	public function updateBefore(frame:Dynamic):Void {
		var renderer = frame.renderer;

		var textureNode = this.textureNode;
		var map = textureNode.value;

		this._renderTarget.texture.type = map.type;

		var currentRenderTarget = renderer.getRenderTarget();
		var currentTexture = textureNode.value;

		quadMesh.material = this._material;

		this.setSize(map.image.width, map.image.height);

		// render

		renderer.setRenderTarget(this._renderTarget);

		quadMesh.render(renderer);

		// restore

		renderer.setRenderTarget(currentRenderTarget);
		textureNode.value = currentTexture;
	}

	public function setup(builder:Dynamic):TempNode {
		var textureNode = this.textureNode;

		if (textureNode.isTextureNode != true) {
			console.error("AnamorphNode requires a TextureNode.");
			return vec4();
		}

		//

		var uvNode = textureNode.uvNode || uv();

		var sampleTexture = function(uv:TempNode) {
			return textureNode.cache().context({getUV: function() {
				return uv;
			}, forceUVContext: true});
		};

		var anamorph = tslFn(function() {
			var samples = this.samples;
			var halfSamples = Math.floor(samples / 2);

			var total = vec3(0).toVar();

			loop({start: -halfSamples, end: halfSamples}, function({i}) {
				var softness = float(i).abs().div(halfSamples).oneMinus();

				var uv = vec2(uvNode.x.add(this._invSize.x.mul(i).mul(this.scaleNode)), uvNode.y);
				var color = sampleTexture(uv);
				var pass = threshold(color, this.tresholdNode).mul(softness);

				total.addAssign(pass);
			});

			return total.mul(this.colorNode);
		});

		//

		var material = this._material || (this._material = builder.createNodeMaterial());
		material.fragmentNode = anamorph();

		//

		var properties = builder.getNodeProperties(this);
		properties.textureNode = textureNode;

		//

		return this._textureNode;
	}
}

var quadMesh = new QuadMesh();

var anamorphic = function(node:TempNode, threshold:Float = 0.9, scale:Float = 3, samples:Int = 32):TempNode {
	return nodeObject(new AnamorphicNode(nodeObject(node), nodeObject(threshold), nodeObject(scale), samples));
};

addNodeElement("anamorphic", anamorphic);

export default AnamorphicNode;