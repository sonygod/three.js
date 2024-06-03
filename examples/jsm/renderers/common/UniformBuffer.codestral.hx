import Buffer from './Buffer';

class UniformBuffer extends Buffer {

    public function new(name: String, buffer: Dynamic = null) {
        super(name, buffer);

        this.isUniformBuffer = true;
    }

}

export default UniformBuffer;