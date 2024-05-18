package three.js.examples.jsm.renderers.common;

import DataMap;
import Constants.AttributeType;

class Bindings extends DataMap {
    public var backend:Dynamic;
    public var textures:Dynamic;
    public var pipelines:Dynamic;
    public var attributes:Dynamic;
    public var nodes:Dynamic;
    public var info:Dynamic;

    public function new(backend:Dynamic, nodes:Dynamic, textures:Dynamic, attributes:Dynamic, pipelines:Dynamic, info:Dynamic) {
        super();
        this.backend = backend;
        this.textures = textures;
        this.pipelines = pipelines;
        this.attributes = attributes;
        this.nodes = nodes;
        this.info = info;

        pipelines.bindings = this; // assign bindings to pipelines
    }

    public function getForRender(renderObject:Dynamic):Dynamic {
        var bindings = renderObject.getBindings();
        var data = this.get(renderObject);

        if (data.bindings != bindings) {
            data.bindings = bindings;
            _init(bindings);
            backend.createBindings(bindings);
        }

        return data.bindings;
    }

    public function getForCompute(computeNode:Dynamic):Dynamic {
        var data = this.get(computeNode);

        if (data.bindings == null) {
            var nodeBuilderState = nodes.getForCompute(computeNode);
            var bindings = nodeBuilderState.bindings;
            data.bindings = bindings;
            _init(bindings);
            backend.createBindings(bindings);
        }

        return data.bindings;
    }

    public function updateForCompute(computeNode:Dynamic):Void {
        _update(computeNode, getForCompute(computeNode));
    }

    public function updateForRender(renderObject:Dynamic):Void {
        _update(renderObject, getForRender(renderObject));
    }

    private function _init(bindings:Array<Dynamic>):Void {
        for (binding in bindings) {
            if (binding.isSampledTexture) {
                textures.updateTexture(binding.texture);
            } else if (binding.isStorageBuffer) {
                var attribute = binding.attribute;
                attributes.update(attribute, AttributeType.STORAGE);
            }
        }
    }

    private function _update(object:Dynamic, bindings:Array<Dynamic>):Void {
        var backend = this.backend;
        var needsBindingsUpdate = false;

        for (binding in bindings) {
            if (binding.isNodeUniformsGroup) {
                var updated = nodes.updateGroup(binding);
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
                    textures.updateTexture(binding.texture);
                }

                var textureData = backend.get(binding.texture);

                if (backend.isWebGPUBackend && textureData.texture == null && textureData.externalTexture == null) {
                    // TODO: Remove this once we found why updated === false isn't bound to a texture in the WebGPU backend
                    trace('Bindings._update: binding should be available:', binding, updated, binding.texture, binding.textureNode.value);

                    textures.updateTexture(binding.texture);
                    needsBindingsUpdate = true;
                }

                if (texture.isStorageTexture) {
                    var textureData = get(texture);

                    if (binding.store) {
                        textureData.needsMipmap = true;
                    } else if (texture.generateMipmaps && textures.needsMipmaps(texture) && textureData.needsMipmap) {
                        backend.generateMipmaps(texture);
                        textureData.needsMipmap = false;
                    }
                }
            }
        }

        if (needsBindingsUpdate) {
            var pipeline = pipelines.getForRender(object);
            backend.updateBindings(bindings, pipeline);
        }
    }
}