import DataMap from "./DataMap";
import RenderPipeline from "./RenderPipeline";
import ComputePipeline from "./ComputePipeline";
import ProgrammableStage from "./ProgrammableStage";

class Pipelines extends DataMap {

  public backend:Dynamic;
  public nodes:Dynamic;
  public bindings:Dynamic;
  public caches:Map<String, Dynamic>;
  public programs:{vertex:Map<String, ProgrammableStage>, fragment:Map<String, ProgrammableStage>, compute:Map<String, ProgrammableStage>};

  public function new(backend:Dynamic, nodes:Dynamic) {
    super();
    this.backend = backend;
    this.nodes = nodes;
    this.bindings = null;
    this.caches = new Map();
    this.programs = {
      vertex: new Map(),
      fragment: new Map(),
      compute: new Map()
    };
  }

  public function getForCompute(computeNode:Dynamic, bindings:Dynamic):Dynamic {
    var data = this.get(computeNode);

    if (this._needsComputeUpdate(computeNode)) {
      var previousPipeline = data.pipeline;

      if (previousPipeline != null) {
        previousPipeline.usedTimes--;
        previousPipeline.computeProgram.usedTimes--;
      }

      // get shader
      var nodeBuilderState = this.nodes.getForCompute(computeNode);

      // programmable stage
      var stageCompute = this.programs.compute.get(nodeBuilderState.computeShader);

      if (stageCompute == null) {
        if (previousPipeline != null && previousPipeline.computeProgram.usedTimes == 0) this._releaseProgram(previousPipeline.computeProgram);
        stageCompute = new ProgrammableStage(nodeBuilderState.computeShader, 'compute', nodeBuilderState.transforms, nodeBuilderState.nodeAttributes);
        this.programs.compute.set(nodeBuilderState.computeShader, stageCompute);
        this.backend.createProgram(stageCompute);
      }

      // determine compute pipeline
      var cacheKey = this._getComputeCacheKey(computeNode, stageCompute);

      var pipeline = this.caches.get(cacheKey);

      if (pipeline == null) {
        if (previousPipeline != null && previousPipeline.usedTimes == 0) this._releasePipeline(previousPipeline);
        pipeline = this._getComputePipeline(computeNode, stageCompute, cacheKey, bindings);
      }

      // keep track of all used times
      pipeline.usedTimes++;
      stageCompute.usedTimes++;

      //
      data.version = computeNode.version;
      data.pipeline = pipeline;
    }

    return data.pipeline;
  }

  public function getForRender(renderObject:Dynamic, promises:Dynamic = null):Dynamic {
    var backend = this.backend;
    var data = this.get(renderObject);

    if (this._needsRenderUpdate(renderObject)) {
      var previousPipeline = data.pipeline;

      if (previousPipeline != null) {
        previousPipeline.usedTimes--;
        previousPipeline.vertexProgram.usedTimes--;
        previousPipeline.fragmentProgram.usedTimes--;
      }

      // get shader
      var nodeBuilderState = renderObject.getNodeBuilderState();

      // programmable stages
      var stageVertex = this.programs.vertex.get(nodeBuilderState.vertexShader);

      if (stageVertex == null) {
        if (previousPipeline != null && previousPipeline.vertexProgram.usedTimes == 0) this._releaseProgram(previousPipeline.vertexProgram);
        stageVertex = new ProgrammableStage(nodeBuilderState.vertexShader, 'vertex');
        this.programs.vertex.set(nodeBuilderState.vertexShader, stageVertex);
        this.backend.createProgram(stageVertex);
      }

      var stageFragment = this.programs.fragment.get(nodeBuilderState.fragmentShader);

      if (stageFragment == null) {
        if (previousPipeline != null && previousPipeline.fragmentProgram.usedTimes == 0) this._releaseProgram(previousPipeline.fragmentProgram);
        stageFragment = new ProgrammableStage(nodeBuilderState.fragmentShader, 'fragment');
        this.programs.fragment.set(nodeBuilderState.fragmentShader, stageFragment);
        this.backend.createProgram(stageFragment);
      }

      // determine render pipeline
      var cacheKey = this._getRenderCacheKey(renderObject, stageVertex, stageFragment);

      var pipeline = this.caches.get(cacheKey);

      if (pipeline == null) {
        if (previousPipeline != null && previousPipeline.usedTimes == 0) this._releasePipeline(previousPipeline);
        pipeline = this._getRenderPipeline(renderObject, stageVertex, stageFragment, cacheKey, promises);
      } else {
        renderObject.pipeline = pipeline;
      }

      // keep track of all used times
      pipeline.usedTimes++;
      stageVertex.usedTimes++;
      stageFragment.usedTimes++;

      //
      data.pipeline = pipeline;
    }

    return data.pipeline;
  }

  public function delete(object:Dynamic) {
    var pipeline = this.get(object).pipeline;

    if (pipeline != null) {
      // pipeline
      pipeline.usedTimes--;

      if (pipeline.usedTimes == 0) this._releasePipeline(pipeline);

      // programs
      if (pipeline.isComputePipeline) {
        pipeline.computeProgram.usedTimes--;

        if (pipeline.computeProgram.usedTimes == 0) this._releaseProgram(pipeline.computeProgram);
      } else {
        pipeline.fragmentProgram.usedTimes--;
        pipeline.vertexProgram.usedTimes--;

        if (pipeline.vertexProgram.usedTimes == 0) this._releaseProgram(pipeline.vertexProgram);
        if (pipeline.fragmentProgram.usedTimes == 0) this._releaseProgram(pipeline.fragmentProgram);
      }
    }

    super.delete(object);
  }

  public function dispose() {
    super.dispose();
    this.caches = new Map();
    this.programs = {
      vertex: new Map(),
      fragment: new Map(),
      compute: new Map()
    };
  }

  public function updateForRender(renderObject:Dynamic) {
    this.getForRender(renderObject);
  }

  public function _getComputePipeline(computeNode:Dynamic, stageCompute:ProgrammableStage, cacheKey:String, bindings:Dynamic):Dynamic {
    // check for existing pipeline
    cacheKey = cacheKey != null ? cacheKey : this._getComputeCacheKey(computeNode, stageCompute);

    var pipeline = this.caches.get(cacheKey);

    if (pipeline == null) {
      pipeline = new ComputePipeline(cacheKey, stageCompute);
      this.caches.set(cacheKey, pipeline);
      this.backend.createComputePipeline(pipeline, bindings);
    }

    return pipeline;
  }

  public function _getRenderPipeline(renderObject:Dynamic, stageVertex:ProgrammableStage, stageFragment:ProgrammableStage, cacheKey:String, promises:Dynamic):Dynamic {
    // check for existing pipeline
    cacheKey = cacheKey != null ? cacheKey : this._getRenderCacheKey(renderObject, stageVertex, stageFragment);

    var pipeline = this.caches.get(cacheKey);

    if (pipeline == null) {
      pipeline = new RenderPipeline(cacheKey, stageVertex, stageFragment);
      this.caches.set(cacheKey, pipeline);
      renderObject.pipeline = pipeline;
      this.backend.createRenderPipeline(renderObject, promises);
    }

    return pipeline;
  }

  public function _getComputeCacheKey(computeNode:Dynamic, stageCompute:ProgrammableStage):String {
    return computeNode.id + ',' + stageCompute.id;
  }

  public function _getRenderCacheKey(renderObject:Dynamic, stageVertex:ProgrammableStage, stageFragment:ProgrammableStage):String {
    return stageVertex.id + ',' + stageFragment.id + ',' + this.backend.getRenderCacheKey(renderObject);
  }

  public function _releasePipeline(pipeline:Dynamic) {
    this.caches.delete(pipeline.cacheKey);
  }

  public function _releaseProgram(program:ProgrammableStage) {
    var code = program.code;
    var stage = program.stage;

    this.programs[stage].delete(code);
  }

  public function _needsComputeUpdate(computeNode:Dynamic):Bool {
    var data = this.get(computeNode);
    return data.pipeline == null || data.version != computeNode.version;
  }

  public function _needsRenderUpdate(renderObject:Dynamic):Bool {
    var data = this.get(renderObject);
    return data.pipeline == null || this.backend.needsRenderUpdate(renderObject);
  }

}

export default Pipelines;