import DataMap from 'three.js.renderers.common.DataMap';
import AttributeType from 'three.js.renderers.common.Constants';

class Bindings extends DataMap {

    public var backend:Dynamic;
    public var nodes:Dynamic;
    public var textures:Dynamic;
    public var attributes:Dynamic;
    public var pipelines:Dynamic;
    public var info:Dynamic;

    public function new(backend:Dynamic, nodes:Dynamic, textures:Dynamic, attributes:Dynamic, pipelines:Dynamic, info:Dynamic) {
        super();

        this.backend = backend;
        this.textures = textures;
        this.pipelines = pipelines;
        this.attributes = attributes;
        this.nodes = nodes;
        this.info = info;

        this.pipelines.bindings = this;
    }

    public function getForRender(renderObject:Dynamic):Dynamic {
        var bindings = renderObject.getBindings();
        var data = this.get(renderObject);

        if (data.bindings !== bindings) {
            data.bindings = bindings;
            this._init(bindings);
            this.backend.createBindings(bindings);
        }

        return data.bindings;
    }

    public function getForCompute(computeNode:Dynamic):Dynamic {
        var data = this.get(computeNode);

        if (data.bindings == null) {
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

    private function _init(bindings:Array<Dynamic>):Void {
        for (binding in bindings) {
            if (binding.isSampledTexture) {
                this.textures.updateTexture(binding.texture);
            } else if (binding.isStorageBuffer) {
                var attribute = binding.attribute;
                this.attributes.update(attribute, AttributeType.STORAGE);
            }
        }
    }

    private function _update(object:Dynamic, bindings:Array<Dynamic>):Void {
        var needsBindingsUpdate = false;

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
                if (this.backend.isWebGPUBackend && textureData.texture == null && textureData.externalTexture == null) {
                    // TODO: Remove this once we found why updated === false isn't bound to a texture in the WebGPU backend
                    trace('Bindings._update: binding should be available: $binding $updated $texture $binding.textureNode.value');
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