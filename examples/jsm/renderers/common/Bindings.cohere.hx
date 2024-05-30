import DataMap from './DataMap.hx';
import { AttributeType } from './Constants.hx';

class Bindings extends DataMap {
    public var backend:Backend;
    public var textures:Textures;
    public var pipelines:Pipelines;
    public var attributes:Attributes;
    public var nodes:Nodes;
    public var info:Dynamic;

    public function new(backend:Backend, nodes:Nodes, textures:Textures, attributes:Attributes, pipelines:Pipelines, info:Dynamic) {
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
            this._init(bindings);
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
            this._init(bindings);
            backend.createBindings(bindings);
        }
        return data.bindings;
    }

    public function updateForCompute(computeNode:Dynamic) {
        this._update(computeNode, this.getForCompute(computeNode));
    }

    public function updateForRender(renderObject:Dynamic) {
        this._update(renderObject, this.getForRender(renderObject));
    }

    private function _init(bindings:Array<Dynamic>) {
        for (binding in bindings) {
            if (binding.isSampledTexture) {
                textures.updateTexture(binding.texture);
            } else if (binding.isStorageBuffer) {
                var attribute = binding.attribute;
                attributes.update(attribute, AttributeType.STORAGE);
            }
        }
    }

    private function _update(object:Dynamic, bindings:Array<Dynamic>) {
        var needsBindingsUpdate = false;
        for (binding in bindings) {
            if (binding.isNodeUniformsGroup) {
                if (!nodes.updateGroup(binding)) continue;
            }
            if (binding.isUniformBuffer) {
                if (binding.update()) {
                    backend.updateBinding(binding);
                }
            } else if (binding.isSampler) {
                binding.update();
            } else if (binding.isSampledTexture) {
                var texture = binding.texture;
                if (binding.needsBindingsUpdate) needsBindingsUpdate = true;
                if (binding.update()) {
                    textures.updateTexture(binding.texture);
                }
                var textureData = backend.get(binding.texture);
                if (backend.isWebGPUBackend && textureData.texture == null && textureData.externalTexture == null) {
                    trace('Bindings._update: binding should be available:', binding, binding.texture, binding.textureNode.value);
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

class Export {
    public static function main() {
        return Bindings;
    }
}