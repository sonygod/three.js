import three.FloatType;
import three.IntType;
import three.UnsignedIntType;
import WebGPUConstants;

class WebGPUBindingUtils {

    private var backend: dynamic;

    public function new(backend: dynamic) {
        this.backend = backend;
    }

    public function createBindingsLayout(bindings: Array<dynamic>): dynamic {
        var device = backend.device;
        var entries = new Array<dynamic>();
        var index = 0;

        for (binding in bindings) {
            var bindingGPU = {
                binding: index++,
                visibility: binding.visibility
            };

            if (binding.isUniformBuffer || binding.isStorageBuffer) {
                var buffer = {};
                if (binding.isStorageBuffer) {
                    buffer.type = WebGPUConstants.GPUBufferBindingType.Storage;
                }
                bindingGPU.buffer = buffer;
            } else if (binding.isSampler) {
                var sampler = {};
                if (binding.texture.isDepthTexture && binding.texture.compareFunction !== null) {
                    sampler.type = 'comparison';
                }
                bindingGPU.sampler = sampler;
            } else if (binding.isSampledTexture && binding.texture.isVideoTexture) {
                bindingGPU.externalTexture = {};
            } else if (binding.isSampledTexture && binding.store) {
                var format = backend.get(binding.texture).texture.format;
                bindingGPU.storageTexture = { format };
            } else if (binding.isSampledTexture) {
                var texture = {};
                if (binding.texture.isDepthTexture) {
                    texture.sampleType = WebGPUConstants.GPUTextureSampleType.Depth;
                } else if (binding.texture.isDataTexture) {
                    var type = binding.texture.type;
                    if (type == IntType) {
                        texture.sampleType = WebGPUConstants.GPUTextureSampleType.SInt;
                    } else if (type == UnsignedIntType) {
                        texture.sampleType = WebGPUConstants.GPUTextureSampleType.UInt;
                    } else if (type == FloatType) {
                        texture.sampleType = WebGPUConstants.GPUTextureSampleType.UnfilterableFloat;
                    }
                }
                if (binding.isSampledCubeTexture) {
                    texture.viewDimension = WebGPUConstants.GPUTextureViewDimension.Cube;
                } else if (binding.texture.isDataArrayTexture) {
                    texture.viewDimension = WebGPUConstants.GPUTextureViewDimension.TwoDArray;
                }
                bindingGPU.texture = texture;
            } else {
                trace("WebGPUBindingUtils: Unsupported binding \"" + binding + "\".");
            }
            entries.push(bindingGPU);
        }
        return device.createBindGroupLayout({ entries });
    }

    public function createBindings(bindings: Array<dynamic>): Void {
        var bindingsData = backend.get(bindings);
        var bindLayoutGPU = createBindingsLayout(bindings);
        var bindGroupGPU = createBindGroup(bindings, bindLayoutGPU);
        bindingsData.layout = bindLayoutGPU;
        bindingsData.group = bindGroupGPU;
        bindingsData.bindings = bindings;
    }

    public function updateBinding(binding: dynamic): Void {
        var device = backend.device;
        var buffer = binding.buffer;
        var bufferGPU = backend.get(binding).buffer;
        device.queue.writeBuffer(bufferGPU, 0, buffer, 0);
    }

    public function createBindGroup(bindings: Array<dynamic>, layoutGPU: dynamic): dynamic {
        var device = backend.device;
        var bindingPoint = 0;
        var entriesGPU = new Array<dynamic>();

        for (binding in bindings) {
            if (binding.isUniformBuffer) {
                var bindingData = backend.get(binding);
                if (bindingData.buffer == null) {
                    var byteLength = binding.byteLength;
                    var usage = WebGPUConstants.GPUBufferUsage.UNIFORM | WebGPUConstants.GPUBufferUsage.COPY_DST;
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
                if (bindingData.buffer == null) {
                    var attribute = binding.attribute;
                    bindingData.buffer = backend.get(attribute).buffer;
                }
                entriesGPU.push({ binding: bindingPoint, resource: { buffer: bindingData.buffer } });
            } else if (binding.isSampler) {
                var textureGPU = backend.get(binding.texture);
                entriesGPU.push({ binding: bindingPoint, resource: textureGPU.sampler });
            } else if (binding.isSampledTexture) {
                var textureData = backend.get(binding.texture);
                var dimensionViewGPU;
                if (binding.isSampledCubeTexture) {
                    dimensionViewGPU = WebGPUConstants.GPUTextureViewDimension.Cube;
                } else if (binding.texture.isDataArrayTexture) {
                    dimensionViewGPU = WebGPUConstants.GPUTextureViewDimension.TwoDArray;
                } else {
                    dimensionViewGPU = WebGPUConstants.GPUTextureViewDimension.TwoD;
                }
                var resourceGPU;
                if (textureData.externalTexture != null) {
                    resourceGPU = device.importExternalTexture({ source: textureData.externalTexture });
                } else {
                    var aspectGPU = WebGPUConstants.GPUTextureAspect.All;
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