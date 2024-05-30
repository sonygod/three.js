package three.js.examples.javascript.renderers.common;

import DataMap;
import Constants.AttributeType;

class Bindings extends DataMap {
    public var backend:Backend;
    public var textures:TextureManager;
    public var pipelines:Pipelines;
    public var attributes:AttributeManager;
    public var nodes:NodeManager;
    public var info:Info;

    public function new(backend:Backend, nodes:NodeManager, textures:TextureManager, attributes:AttributeManager, pipelines:Pipelines, info:Info) {
        super();
        this.backend = backend;
        this.textures = textures;
        this.pipelines = pipelines;
        this.attributes = attributes;
        this.nodes = nodes;
        this.info = info;
        pipelines.bindings = this; // assign bindings to pipelines
    }

    public function getForRender(renderObject:Object):Bindings {
        var bindings = renderObject.getBindings();
        var data = this.get(renderObject);
        if (data.bindings != bindings) {
            data.bindings = bindings;
            _init(bindings);
            backend.createBindings(bindings);
        }
        return data.bindings;
    }

    public function getForCompute(computeNode:ComputeNode):Bindings {
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

    public function updateForCompute(computeNode:ComputeNode) {
        _update(computeNode, getForCompute(computeNode));
    }

    public function updateForRender(renderObject:Object) {
        _update(renderObject, getForRender(renderObject));
    }

    private function _init(bindings:Array<Binding>) {
        for (binding in bindings) {
            if (binding.isSampledTexture) {
                textures.updateTexture(binding.texture);
            } else if (binding.isStorageBuffer) {
                var attribute = binding.attribute;
                attributes.update(attribute, AttributeType.STORAGE);
            }
        }
    }

    private function _update(object:Object, bindings:Array<Binding>) {
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
                    var textureData = this.get(texture);
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