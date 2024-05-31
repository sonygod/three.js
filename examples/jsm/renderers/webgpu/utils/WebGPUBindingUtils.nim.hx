import GPUTextureAspect.All;
import GPUTextureViewDimension.*;
import GPUBufferBindingType.*;
import GPUTextureSampleType.*;
import three.FloatType;
import three.IntType;
import three.UnsignedIntType;

class WebGPUBindingUtils {

	var backend:WebGPUBackend;

	public function new(backend:WebGPUBackend) {
		this.backend = backend;
	}

	public function createBindingsLayout(bindings:Array<Dynamic>):GPUBindGroupLayout {
		var backend = this.backend;
		var device = backend.device;

		var entries:Array<Dynamic> = [];

		var index = 0;

		for (binding in bindings) {

			var bindingGPU:Dynamic = {
				binding: index++,
				visibility: binding.visibility
			};

			if (binding.isUniformBuffer || binding.isStorageBuffer) {

				var buffer:Dynamic = {};

				if (binding.isStorageBuffer) {
					buffer.type = Storage;
				}

				bindingGPU.buffer = buffer;

			} else if (binding.isSampler) {

				var sampler:Dynamic = {};

				if (binding.texture.isDepthTexture) {
					if (binding.texture.compareFunction !== null) {
						sampler.type = 'comparison';
					}
				}

				bindingGPU.sampler = sampler;

			} else if (binding.isSampledTexture && binding.texture.isVideoTexture) {

				bindingGPU.externalTexture = {};

			} else if (binding.isSampledTexture && binding.store) {

				var format = this.backend.get(binding.texture).texture.format;

				bindingGPU.storageTexture = { format };

			} else if (binding.isSampledTexture) {

				var texture:Dynamic = {};

				if (binding.texture.isDepthTexture) {
					texture.sampleType = Depth;
				} else if (binding.texture.isDataTexture) {
					var type = binding.texture.type;

					if (type == IntType) {
						texture.sampleType = SInt;
					} else if (type == UnsignedIntType) {
						texture.sampleType = UInt;
					} else if (type == FloatType) {
						texture.sampleType = UnfilterableFloat;
					}
				}

				if (binding.isSampledCubeTexture) {
					texture.viewDimension = Cube;
				} else if (binding.texture.isDataArrayTexture) {
					texture.viewDimension = TwoDArray;
				}

				bindingGPU.texture = texture;

			} else {
				trace('WebGPUBindingUtils: Unsupported binding "${ binding }".');
			}

			entries.push(bindingGPU);

		}

		return device.createBindGroupLayout({ entries });
	}

	public function createBindings(bindings:Array<Dynamic>) {
		var backend = this.backend;
		var bindingsData = backend.get(bindings);

		var bindLayoutGPU = this.createBindingsLayout(bindings);
		var bindGroupGPU = this.createBindGroup(bindings, bindLayoutGPU);

		bindingsData.layout = bindLayoutGPU;
		bindingsData.group = bindGroupGPU;
		bindingsData.bindings = bindings;
	}

	public function updateBinding(binding:Dynamic) {
		var backend = this.backend;
		var device = backend.device;

		var buffer = binding.buffer;
		var bufferGPU = backend.get(binding).buffer;

		device.queue.writeBuffer(bufferGPU, 0, buffer, 0);
	}

	public function createBindGroup(bindings:Array<Dynamic>, layoutGPU:GPUBindGroupLayout):GPUBindGroup {
		var backend = this.backend;
		var device = backend.device;

		var bindingPoint = 0;
		var entriesGPU:Array<Dynamic> = [];

		for (binding in bindings) {

			if (binding.isUniformBuffer) {

				var bindingData = backend.get(binding);

				if (bindingData.buffer === undefined) {
					var byteLength = binding.byteLength;

					var usage = GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST;

					var bufferGPU = device.createBuffer({
						label: 'bindingBuffer_' + binding.name,
						size: byteLength,
						usage: usage
					});

					bindingData.buffer = bufferGPU;
				}

				entriesGPU.push({ binding: bindingPoint, resource: { buffer: bindingData.buffer } });

			} else if (binding.isStorageBuffer) {

				var bindingData = backend.get(binding);

				if (bindingData.buffer === undefined) {
					var attribute = binding.attribute;
					//var usage = GPUBufferUsage.STORAGE | GPUBufferUsage.VERTEX | /*GPUBufferUsage.COPY_SRC |*/ GPUBufferUsage.COPY_DST;

					//backend.attributeUtils.createAttribute(attribute, usage); // @TODO: Move it to universal renderer

					bindingData.buffer = backend.get(attribute).buffer;
				}

				entriesGPU.push({ binding: bindingPoint, resource: { buffer: bindingData.buffer } });

			} else if (binding.isSampler) {

				var textureGPU = backend.get(binding.texture);

				entriesGPU.push({ binding: bindingPoint, resource: textureGPU.sampler });

			} else if (binding.isSampledTexture) {

				var textureData = backend.get(binding.texture);

				var dimensionViewGPU:Dynamic;

				if (binding.isSampledCubeTexture) {
					dimensionViewGPU = Cube;
				} else if (binding.texture.isDataArrayTexture) {
					dimensionViewGPU = TwoDArray;
				} else {
					dimensionViewGPU = TwoD;
				}

				var resourceGPU:Dynamic;

				if (textureData.externalTexture !== undefined) {
					resourceGPU = device.importExternalTexture({ source: textureData.externalTexture });
				} else {
					var aspectGPU = All;

					resourceGPU = textureData.texture.createView({ aspect: aspectGPU, dimension: dimensionViewGPU, mipLevelCount: binding.store ? 1 : textureData.mipLevelCount });
				}

				entriesGPU.push({ binding: bindingPoint, resource: resourceGPU });

			}

			bindingPoint++;

		}

		return device.createBindGroup({
			layout: layoutGPU,
			entries: entriesGPU
		});
	}

}