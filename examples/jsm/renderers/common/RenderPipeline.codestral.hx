import Pipeline from './Pipeline.hx';

class RenderPipeline extends Pipeline {

    public function new(cacheKey: String, vertexProgram: Dynamic, fragmentProgram: Dynamic) {
        super(cacheKey);
        this.vertexProgram = vertexProgram;
        this.fragmentProgram = fragmentProgram;
    }

    public var vertexProgram: Dynamic;
    public var fragmentProgram: Dynamic;

}