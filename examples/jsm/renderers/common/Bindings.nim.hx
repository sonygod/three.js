import DataMap from './DataMap.hx';
import AttributeType from './Constants.hx';

class Bindings extends DataMap {

	public var backend: Backend;
	public var textures: Textures;
	public var pipelines: Pipelines;
	public var attributes: Attributes;
	public var nodes: Nodes;
	public var info: Info;

	public function new(backend: Backend, nodes: Nodes, textures: Textures, attributes: Attributes, pipelines: Pipelines, info: Info) {

		super();

		this.backend = backend;
		this.textures = textures;
		this.pipelines = pipelines;
		this.attributes = attributes;
		this.nodes = nodes;
		this.info = info;

		this.pipelines.bindings = this; // assign bindings to pipelines

	}

	public function getForRender(renderObject: RenderObject): Bindings {

		var bindings = renderObject.getBindings();

		var data = this.get(renderObject);

		if (data.bindings !== bindings) {

			data.bindings = bindings;

			this._init(bindings);

			this.backend.createBindings(bindings);

		}

		return data.bindings;

	}

	public function getForCompute(computeNode: ComputeNode): Bindings {

		var data = this.get(computeNode);

		if (data.bindings === undefined) {

			var nodeBuilderState = this.nodes.getForCompute(computeNode);

			var bindings = nodeBuilderState.bindings;

			data.bindings = bindings;

			this._init(bindings);

			this.backend.createBindings(bindings);

		}

		return data.bindings;

	}

	public function updateForCompute(computeNode: ComputeNode) {

		this._update(computeNode, this.getForCompute(computeNode));

	}

	public function updateForRender(renderObject: RenderObject) {

		this._update(renderObject, this.getForRender(renderObject));

	}

	private function _init(bindings: Array<Dynamic>) {

		for (binding in bindings) {

			if (binding.isSampledTexture) {

				this.textures.updateTexture(binding.texture);

			} else if (binding.isStorageBuffer) {

				var attribute = binding.attribute;

				this.attributes.update(attribute, AttributeType.STORAGE);

			}

		}

	}

	private function _update(object: Dynamic, bindings: Array<Dynamic>) {

		var needsBindingsUpdate: Bool = false;

		for (binding in bindings) {

			if (binding.isNodeUniformsGroup) {

				var updated = this.nodes.updateGroup(binding);

				if (!updated) continue;

			}

			if (binding.isUniformBuffer) {

				var updated = binding.update();

				if (updated) {

					this.backend.updateBinding(binding);

				}

			} else if (binding.isSampler) {

				binding.update();

			} else if (binding.isSampledTexture) {

				var texture = binding.texture;

				if (binding.needsBindingsUpdate) needsBindingsUpdate = true;

				var updated = binding.update();

				if (updated) {

					this.textures.updateTexture(binding.texture);

				}

				var textureData = this.backend.get(binding.texture);

				if (this.backend.isWebGPUBackend && textureData.texture === null && textureData.externalTexture === null) {

					// TODO: Remove this once we found why updated === false isn't bound to a texture in the WebGPU backend
					trace('Bindings._update: binding should be available:', binding, updated, binding.texture, binding.textureNode.value);

					this.textures.updateTexture(binding.texture);
					needsBindingsUpdate = true;

				}

				if (texture.isStorageTexture) {

					var textureData = this.get(texture);

					if (binding.store) {

						textureData.needsMipmap = true;

					} else if (texture.generateMipmaps && this.textures.needsMipmaps(texture) && textureData.needsMipmap) {

						this.backend.generateMipmaps(texture);

						textureData.needsMipmap = false;

					}

				}

			}

		}

		if (needsBindingsUpdate) {

			var pipeline = this.pipelines.getForRender(object);

			this.backend.updateBindings(bindings, pipeline);

		}

	}

}

export default Bindings;