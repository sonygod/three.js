import Binding from './Binding.hx';

class Sampler extends Binding {

    public var texture: dynamic;
    public var version: Int;

    public function new(name: String, texture: dynamic = null) {
        super(name);

        this.texture = texture;
        this.version = texture != null ? texture.version : 0;

        this.isSampler = true;
    }

}