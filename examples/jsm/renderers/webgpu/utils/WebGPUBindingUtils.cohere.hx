import js.webgpu.GPUTextureAspect;
import js.webgpu.GPUTextureViewDimension;
import js.webgpu.GPUBufferBindingType;
import js.webgpu.GPUTextureSampleType;
import js.three.FloatType;
import js.three.IntType;
import js.three.UnsignedIntType;

class WebGPUBindingUtils {
    public var backend:Backend;

    public function new(backend:Backend) {
        this.backend = backend;
    }

    public function createBindingsLayout(bindings:Array<dynamic>) : GPUBindGroupLayout {
        var device = backend.device;
        var entries:Array<GPUBindGroupLayoutEntry> = [];
        var index = 0;

        for (binding in bindings) {
            var bindingGPU = { binding: index++, visibility: binding.visibility };

            if (binding.isUniformBuffer || binding.isStorageBuffer) {
                var buffer = { }; // GPUBufferBindingLayout
                if (binding.isStorageBuffer) {
                    buffer.type = GPUBufferBindingType.Storage;
                }
                bindingGPU.buffer = buffer;
            } else if (binding.isSampler) {
                var sampler = { }; // GPUSamplerBindingLayout
                if (binding.texture.isDepthTexture) {
                    if (binding.texture.compareFunction != null) {
                        sampler.type = "comparison";
                    }
                }
                bindingGPU.sampler = sampler;
            } else if (binding.isSampledTexture && binding.texture.isVideoTexture) {
                bindingGPU.externalTexture = { }; // GPUExternalTextureBindingLayout
            } else if (binding.isSampledTexture && binding.store) {
                var format = backend.get(binding.texture).texture.format;
                bindingGPU.storageTexture = { format: format }; // GPUStorageTextureBindingLayout
            } else if (binding.isSampledTexture) {
                var texture = { }; // GPUTextureBindingLayout
                if (binding.texture.isDepthTexture) {
                    texture.sampleType = GPUTextureSampleType.Depth;
                } else if (binding.texture.isDataTexture) {
                    var type = binding.texture.type;
                    if (type == IntType) {
                        texture.sampleType = GPUTextureSampleType.SInt;
                    } else if (type == UnsignedIntType) {
                        texture.sampleType = GPUTextureSampleType.UInt;
                    } else if (type == FloatType) {
                        // @TODO: Add support for this soon: backend.hasFeature('float32-filterable')
                        texture.sampleType = GPUTextureSampleType.UnfilterableFloat;
                    }
                }

                if (binding.isSampledCubeTexture) {
                    texture.viewDimension = GPUTextureViewDimension.Cube;
                } else if (binding.texture.isDataArrayTexture) {
                    texture.viewDimension = GPUTextureViewDimension.TwoDArray;
                }

                bindingGPU.texture = texture;
            } else {
                trace("WebGPUBindingUtils: Unsupported binding \"${binding}\".");
            }

            entries.push(bindingGPU);
        }

        return device.createBindGroupLayout({ entries: entries });
    }

    public function createBindings(bindings:Array<dynamic>) {
        var backend = this.backend;
        var bindingsData = backend.get(bindings);

        // setup (static) binding layout and (dynamic) binding group
        var bindLayoutGPU = this.createBindingsLayout(bindings);
        var bindGroupGPU = this.createBindGroup(bindings, bindLayoutGPU);

        bindingsData.layout = bindLayoutGPU;
        bindingsData.group = bindGroupGPU;
        bindingsData.bindings = bindings;
    }

    public function updateBinding(binding:dynamic) {
        var backend = this.backend;
        var device = backend.device;
        var buffer = binding.buffer;
        var bufferGPU = backend.get(binding).buffer;

        device.queue.writeBuffer(bufferGPU, 0, buffer, 0);
    }

    public function createBindGroup(bindings:Array<dynamic>, layoutGPU:GPUBindGroupLayout) : GPUBindGroup {
        var backend = this.backend;
        var device = backend.device;
        var bindingPoint = 0;
        var entriesGPU = [];

        for (binding in bindings) {
            if (binding.isUniformBuffer) {
                var bindingData = backend.get(binding);
                if (bindingData.buffer == null) {
                    var byteLength = binding.byteLength;
                    var usage = GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST;
                    var bufferGPU = device.createBuffer({
                        label: "bindingBuffer_" + binding.name,
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
                    //const usage = GPUBufferUsage.STORAGE | GPUBufferUsage.VERTEX | /*GPUBufferUsage.COPY_SRC |*/ GPUBufferUsage.COPY_DST;
                    //backend.attributeUtils.createAttribute(attribute, usage); // @TODO: Move it to universal renderer
                    bindingData.buffer = backend.get(attribute).buffer;
                }
                entriesGPU.push({ binding: bindingPoint, resource: { buffer: bindingData.buffer } });
            } else if (binding.isSampler) {
                var textureGPU = backend.get(binding.texture);
                entriesGPU.push({ binding: bindingPoint, resource: textureGPU.sampler });
            } else if (binding.isSampledTexture) {
                var textureData = backend.get(binding.texture);
                var dimensionViewGPU:GPUTextureViewDimension;
                if (binding.isSampledCubeTexture) {
                    dimensionViewGPU = GPUTextureViewDimension.Cube;
                } else if (binding.texture.isDataArrayTexture) {
                    dimensionViewGPU = GPUTextureViewDimension.TwoDArray;
                } else {
                    dimensionViewGPU = GPUTextureViewDimension.TwoD;
                }

                var resourceGPU:GPUBindGroupTexture;
                if (textureData.externalTexture != null) {
                    resourceGPU = device.importExternalTexture({ source: textureData.externalTexture });
                } else {
                    var aspectGPU = GPUTextureAspect.All;
                    resourceGPU = textureData.texture.createView({ aspect: aspectGPU, dimension: dimensionViewGPU, mipLevelCount: if (binding.store) 1 else textureData.mipLevelCount });
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