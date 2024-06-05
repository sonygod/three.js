import TempNode from "../core/TempNode";
import { nodeObject, addNodeElement, tslFn, float, vec2, vec4 } from "../shadernode/ShaderNode";
import { NodeUpdateType } from "../core/constants";
import { mul } from "../math/OperatorNode";
import { uv } from "../accessors/UVNode";
import { texturePass } from "./PassNode";
import { uniform } from "../core/UniformNode";
import { Vector2, RenderTarget } from "three";
import QuadMesh from "../../objects/QuadMesh";

// WebGPU: The use of a single QuadMesh for both gaussian blur passes results in a single RenderObject with a SampledTexture binding that
// alternates between source textures and triggers creation of new BindGroups and BindGroupLayouts every frame.

class GaussianBlurNode extends TempNode {

	public textureNode: TempNode;
	public sigma: Float;
	public directionNode: TempNode;
	public _invSize: TempNode;
	public _passDirection: TempNode;
	public _horizontalRT: RenderTarget;
	public _verticalRT: RenderTarget;
	public _textureNode: TempNode;
	public resolution: Vector2;

	public function new(textureNode: TempNode, sigma: Float = 2) {
		super("vec4");
		this.textureNode = textureNode;
		this.sigma = sigma;
		this.directionNode = vec2(1);
		this._invSize = uniform(new Vector2());
		this._passDirection = uniform(new Vector2());
		this._horizontalRT = new RenderTarget();
		this._horizontalRT.texture.name = "GaussianBlurNode.horizontal";
		this._verticalRT = new RenderTarget();
		this._verticalRT.texture.name = "GaussianBlurNode.vertical";
		this._textureNode = texturePass(this, this._verticalRT.texture);
		this.updateBeforeType = NodeUpdateType.RENDER;
		this.resolution = new Vector2(1, 1);
	}

	public function setSize(width: Float, height: Float) {
		width = Math.max(Math.round(width * this.resolution.x), 1);
		height = Math.max(Math.round(height * this.resolution.y), 1);
		this._invSize.value.set(1 / width, 1 / height);
		this._horizontalRT.setSize(width, height);
		this._verticalRT.setSize(width, height);
	}

	public function updateBefore(frame: Dynamic) {
		var renderer = frame.renderer;

		var textureNode = this.textureNode;
		var map = textureNode.value;

		var currentRenderTarget = renderer.getRenderTarget();
		var currentTexture = textureNode.value;

		var quadMesh1 = new QuadMesh();
		var quadMesh2 = new QuadMesh();
		quadMesh1.material = this._material;
		quadMesh2.material = this._material;

		this.setSize(map.image.width, map.image.height);

		var textureType = map.type;

		this._horizontalRT.texture.type = textureType;
		this._verticalRT.texture.type = textureType;

		// horizontal

		renderer.setRenderTarget(this._horizontalRT);

		this._passDirection.value.set(1, 0);

		quadMesh1.render(renderer);

		// vertical

		textureNode.value = this._horizontalRT.texture;
		renderer.setRenderTarget(this._verticalRT);

		this._passDirection.value.set(0, 1);

		quadMesh2.render(renderer);

		// restore

		renderer.setRenderTarget(currentRenderTarget);
		textureNode.value = currentTexture;
	}

	public function getTextureNode(): TempNode {
		return this._textureNode;
	}

	public function setup(builder: Dynamic): TempNode {
		var textureNode = this.textureNode;

		if (!textureNode.isTextureNode) {
			console.error("GaussianBlurNode requires a TextureNode.");
			return vec4();
		}

		//

		var uvNode = textureNode.uvNode || uv();

		var sampleTexture = function(uv: TempNode): TempNode {
			return textureNode.cache().context({getUV: function(): TempNode {
				return uv;
			}, forceUVContext: true});
		};

		var blur = tslFn(function() {
			var kernelSize = 3 + (2 * this.sigma);
			var gaussianCoefficients = this._getCoefficients(kernelSize);

			var invSize = this._invSize;
			var direction = vec2(this.directionNode).mul(this._passDirection);

			var weightSum = float(gaussianCoefficients[0]).toVar();
			var diffuseSum = vec4(sampleTexture(uvNode).mul(weightSum)).toVar();

			for (var i = 1; i < kernelSize; i++) {
				var x = float(i);
				var w = float(gaussianCoefficients[i]);

				var uvOffset = vec2(direction.mul(invSize.mul(x))).toVar();

				var sample1 = vec4(sampleTexture(uvNode.add(uvOffset)));
				var sample2 = vec4(sampleTexture(uvNode.sub(uvOffset)));

				diffuseSum.addAssign(sample1.add(sample2).mul(w));
				weightSum.addAssign(mul(2.0, w));
			}

			return diffuseSum.div(weightSum);
		});

		//

		var material = this._material || (this._material = builder.createNodeMaterial());
		material.fragmentNode = blur();

		//

		var properties = builder.getNodeProperties(this);
		properties.textureNode = textureNode;

		//

		return this._textureNode;
	}

	public function _getCoefficients(kernelRadius: Int): Array<Float> {
		var coefficients = new Array<Float>();

		for (var i = 0; i < kernelRadius; i++) {
			coefficients.push(0.39894 * Math.exp(-0.5 * i * i / (kernelRadius * kernelRadius)) / kernelRadius);
		}

		return coefficients;
	}

	private var _material: Dynamic;
}

export var gaussianBlur = function(node: TempNode, sigma: Float): TempNode {
	return nodeObject(new GaussianBlurNode(nodeObject(node), sigma));
};

addNodeElement("gaussianBlur", gaussianBlur);

export default GaussianBlurNode;