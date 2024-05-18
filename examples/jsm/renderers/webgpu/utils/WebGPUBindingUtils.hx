package three.js.examples.jsm.renderers.webgpu.utils;

import three.js.WebGPUConstants;
import three.FloatType;
import three.IntType;
import three.UnsignedIntType;

class WebGPUBindingUtils {
    private var backend:Dynamic;

    public function new(backend:Dynamic) {
        this.backend = backend;
    }

    public function createBindingsLayout(bindings:Array<Dynamic>):Dynamic {
        var backend = this.backend;
        var device = backend.device;
        var entries:Array<Dynamic> = [];

        var index:Int = 0;

        for (binding in bindings) {
            var bindingGPU:Dynamic = {
                binding: index++,
                visibility: binding.visibility
            };

            if (binding.isUniformBuffer || binding.isStorageBuffer) {
                var buffer:Dynamic = {};
                if (binding.isStorageBuffer) {
                    buffer.type = WebGPUConstants.GPUBufferBindingType.Storage;
                }
                bindingGPU.buffer = buffer;
            } else if (binding.isSampler) {
                var sampler:Dynamic = {};
                if (binding.texture.isDepthTexture) {
                    if (binding.texture.compareFunction != null) {
                        sampler.type = 'comparison';
                    }
                }
                bindingGPU.sampler = sampler;
            } else if (binding.isSampledTexture && binding.texture.isVideoTexture) {
                bindingGPU.externalTexture = {};
            } else if (binding.isSampledTexture && binding.store) {
                var format:Dynamic = this.backend.get(binding.texture).texture.format;
                bindingGPU.storageTexture = { format: format };
            } else if (binding.isSampledTexture) {
                var texture:Dynamic = {};
                if (binding.texture.isDepthTexture) {
                    texture.sampleType = WebGPUConstants.GPUTextureSampleType.Depth;
                } else if (binding.texture.isDataTexture) {
                    var type:Dynamic = binding.texture.type;
                    if (type == FloatType) {
                        // @TODO: Add support for this soon: backend.hasFeature( 'float32-filterable' )
                        texture.sampleType = WebGPUConstants.GPUTextureSampleType.UnfilterableFloat;
                    } else if (type == IntType) {
                        texture.sampleType = WebGPUConstants.GPUTextureSampleType.SInt;
                    } else if (type == UnsignedIntType) {
                        texture.sampleType = WebGPUConstants.GPUTextureSampleType.UInt;
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

        return device.createBindGroupLayout({ entries: entries });
    }

    public function createBindings(bindings:Array<Dynamic>):Void {
        var backend = this.backend;
        var bindingsData:Dynamic = backend.get(bindings);

        var bindLayoutGPU:Dynamic = createBindingsLayout(bindings);
        var bindGroupGPU:Dynamic = createBindGroup(bindings, bindLayoutGPU);

        bindingsData.layout = bindLayoutGPU;
        bindingsData.group = bindGroupGPU;
        bindingsData.bindings = bindings;
    }

    public function updateBinding(binding:Dynamic):Void {
        var backend = this.backend;
        var device = backend.device;

        var buffer:Dynamic = binding.buffer;
        var bufferGPU:Dynamic = backend.get(binding).buffer;

        device.queue.writeBuffer(bufferGPU, 0, buffer, 0);
    }

    public function createBindGroup(bindings:Array<Dynamic>, layoutGPU:Dynamic):Dynamic {
        var backend = this.backend;
        var device = backend.device;

        var bindingPoint:Int = 0;
        var entriesGPU:Array<Dynamic> = [];

        for (binding in bindings) {
            if (binding.isUniformBuffer) {
                var bindingData:Dynamic = backend.get(binding);

                if (bindingData.buffer == null) {
                    var byteLength:Int = binding.byteLength;
                    var usage:Dynamic = WebGPUConstants.GPUBufferUsage.UNIFORM | WebGPUConstants.GPUBufferUsage.COPY_DST;

                    var bufferGPU:Dynamic = device.createBuffer({
                        label: 'bindingBuffer_' + binding.name,
                        size: byteLength,
                        usage: usage
                    });

                    bindingData.buffer = bufferGPU;
                }

                entriesGPU.push({ binding: bindingPoint, resource: { buffer: bindingData.buffer } });
            } else if (binding.isStorageBuffer) {
                var bindingData:Dynamic = backend.get(binding);

                if (bindingData.buffer == null) {
                    var attribute:Dynamic = binding.attribute;
                    //var usage:Dynamic = WebGPUConstants.GPUBufferUsage.STORAGE | WebGPUConstants.GPUBufferUsage.VERTEX | /*WebGPUConstants.GPUBufferUsage.COPY_SRC |*/ WebGPUConstants.GPUBufferUsage.COPY_DST;

                    //backend.attributeUtils.createAttribute( attribute, usage ); // @TODO: Move it to universal renderer

                    bindingData.buffer = backend.get(attribute).buffer;
                }

                entriesGPU.push({ binding: bindingPoint, resource: { buffer: bindingData.buffer } });
            } else if (binding.isSampler) {
                var textureGPU:Dynamic = backend.get(binding.texture);

                entriesGPU.push({ binding: bindingPoint, resource: textureGPU.sampler });
            } else if (binding.isSampledTexture) {
                var textureData:Dynamic = backend.get(binding.texture);

                var dimensionViewGPU:Dynamic;

                if (binding.isSampledCubeTexture) {
                    dimensionViewGPU = WebGPUConstants.GPUTextureViewDimension.Cube;
                } else if (binding.texture.isDataArrayTexture) {
                    dimensionViewGPU = WebGPUConstants.GPUTextureViewDimension.TwoDArray;
                } else {
                    dimensionViewGPU = WebGPUConstants.GPUTextureViewDimension.TwoD;
                }

                var resourceGPU:Dynamic;

                if (textureData.externalTexture != null) {
                    resourceGPU = device.importExternalTexture({ source: textureData.externalTexture });
                } else {
                    var aspectGPU:Dynamic = WebGPUConstants.GPUTextureAspect.All;

                    resourceGPU = textureData.texture.createView({
                        aspect: aspectGPU,
                        dimension: dimensionViewGPU,
                        mipLevelCount: binding.store ? 1 : textureData.mipLevelCount
                    });
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