import DataMap from './DataMap.hx';
import Constants.AttributeType;

class Bindings extends DataMap {

	public function new(backend:Dynamic, nodes:Dynamic, textures:Dynamic, attributes:Dynamic, pipelines:Dynamic, info:Dynamic) {

		super();

		this.backend = backend;
		this.textures = textures;
		this.pipelines = pipelines;
		this.attributes = attributes;
		this.nodes = nodes;
		this.info = info;

		this.pipelines.bindings = this; // assign bindings to pipelines

	}

	public function getForRender(renderObject:Dynamic):Dynamic {

		var bindings = renderObject.getBindings();

		var data = this.get(renderObject);

		if (data.bindings !== bindings) {

			// each object defines an array of bindings (ubos, textures, samplers etc.)

			data.bindings = bindings;

			this._init(bindings);

			this.backend.createBindings(bindings);

		}

		return data.bindings;

	}

	public function getForCompute(computeNode:Dynamic):Dynamic {

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

	public function updateForCompute(computeNode:Dynamic):Void {

		this._update(computeNode, this.getForCompute(computeNode));

	}

	public function updateForRender(renderObject:Dynamic):Void {

		this._update(renderObject, this.getForRender(renderObject));

	}

	private function _init(bindings:Dynamic):Void {

		for (binding in bindings) {

			if (binding.isSampledTexture) {

				this.textures.updateTexture(binding.texture);

			} else if (binding.isStorageBuffer) {

				var attribute = binding.attribute;

				this.attributes.update(attribute, AttributeType.STORAGE);

			}

		}

	}

	private function _update(object:Dynamic, bindings:Dynamic):Void {

		var backend = this.backend;

		var needsBindingsUpdate = false;

		// iterate over all bindings and check if buffer updates or a new binding group is required

		for (binding in bindings) {

			if (binding.isNodeUniformsGroup) {

				var updated = this.nodes.updateGroup(binding);

				if (!updated) continue;

			}

			if (binding.isUniformBuffer) {

				var updated = binding.update();

				if (updated) {

					backend.updateBinding(binding);

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

				var textureData = backend.get(binding.texture);

				if (backend.isWebGPUBackend === true && textureData.texture === undefined && textureData.externalTexture === undefined) {

					// TODO: Remove this once we found why updated === false isn't bound to a texture in the WebGPU backend
					trace('Bindings._update: binding should be available:', binding, updated, binding.texture, binding.textureNode.value);

					this.textures.updateTexture(binding.texture);
					needsBindingsUpdate = true;

				}


				if (texture.isStorageTexture === true) {

					var textureData = this.get(texture);

					if (binding.store === true) {

						textureData.needsMipmap = true;

					} else if (texture.generateMipmaps === true && this.textures.needsMipmaps(texture) && textureData.needsMipmap === true) {

						this.backend.generateMipmaps(texture);

						textureData.needsMipmap = false;

					}

				}

			}

		}

		if (needsBindingsUpdate === true) {

			var pipeline = this.pipelines.getForRender(object);

			this.backend.updateBindings(bindings, pipeline);

		}

	}

}