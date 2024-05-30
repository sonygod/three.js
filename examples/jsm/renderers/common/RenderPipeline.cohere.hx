import Pipeline from './Pipeline.hx';

class RenderPipeline extends Pipeline {
	public function new(cacheKey: String, vertexProgram: String, fragmentProgram: String) {
		super(cacheKey);
		this.vertexProgram = vertexProgram;
		this.fragmentProgram = fragmentProgram;
	}
}

export default RenderPipeline;