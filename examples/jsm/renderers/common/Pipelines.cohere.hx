import DataMap from './DataMap.hx';
import RenderPipeline from './RenderPipeline.hx';
import ComputePipeline from './ComputePipeline.hx';
import ProgrammableStage from './ProgrammableStage.hx';

class Pipelines extends DataMap {
    public backend: Backend;
    public nodes: Dynamic;
    public bindings: Dynamic;
    public caches: Map<String, Dynamic>;
    public programs: { vertex: Map<String, ProgrammableStage>, fragment: Map<String, ProgrammableStage>, compute: Map<String, ProgrammableStage> };

    public function new(backend: Backend, nodes: Dynamic) {
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

    public function getForCompute(computeNode: Dynamic, bindings: Dynamic): ComputePipeline {
        const data = this.get(computeNode);
        if (this._needsComputeUpdate(computeNode)) {
            const previousPipeline = data.pipeline;
            if (previousPipeline != null) {
                previousPipeline.usedTimes--;
                previousPipeline.computeProgram.usedTimes--;
            }
            const nodeBuilderState = this.nodes.getForCompute(computeNode);
            let stageCompute = this.programs.compute.get(nodeBuilderState.computeShader);
            if (stageCompute == null) {
                if (previousPipeline != null && previousPipeline.computeProgram.usedTimes == 0) {
                    this._releaseProgram(previousPipeline.computeProgram);
                }
                stageCompute = new ProgrammableStage(nodeBuilderState.computeShader, 'compute', nodeBuilderState.transforms, nodeBuilderState.nodeAttributes);
                this.programs.compute.set(nodeBuilderState.computeShader, stageCompute);
                backend.createProgram(stageCompute);
            }
            const cacheKey = this._getComputeCacheKey(computeNode, stageCompute);
            let pipeline = this.caches.get(cacheKey);
            if (pipeline == null) {
                if (previousPipeline != null && previousPipeline.usedTimes == 0) {
                    this._releasePipeline(computeNode);
                }
                pipeline = this._getComputePipeline(computeNode, stageCompute, cacheKey, bindings);
            }
            pipeline.usedTimes++;
            stageCompute.usedTimes++;
            data.version = computeNode.version;
            data.pipeline = pipeline;
        }
        return data.pipeline;
    }

    public function getForRender(renderObject: Dynamic, promises: Array<Promise<Dynamic>> = null): RenderPipeline {
        const data = this.get(renderObject);
        if (this._needsRenderUpdate(renderObject)) {
            const previousPipeline = data.pipeline;
            if (previousPipeline != null) {
                previousPipeline.usedTimes--;
                previousPipeline.vertexProgram.usedTimes--;
                previousPipeline.fragmentProgram.usedTimes--;
            }
            const nodeBuilderState = renderObject.getNodeBuilderState();
            let stageVertex = this.programs.vertex.get(nodeBuilderState.vertexShader);
            if (stageVertex == null) {
                if (previousPipeline != null && previousPipeline.vertexProgram.usedTimes == 0) {
                    this._releaseProgram(previousPipeline.vertexProgram);
                }
                stageVertex = new ProgrammableStage(nodeBuilderState.vertexShader, 'vertex');
                this.programs.vertex.set(nodeBuilderState.vertexShader, stageVertex);
                backend.createProgram(stageVertex);
            }
            let stageFragment = this.programs.fragment.get(nodeBuilderState.fragmentShader);
            if (stageFragment == null) {
                if (previousPipeline != null && previousPipeline.fragmentProgram.usedTimes == 0) {
                    this._releaseProgram(previousPipeline.fragmentProgram);
                }
                stageFragment = new ProgrammableStage(nodeBuilderState.fragmentShader, 'fragment');
                this.programs.fragment.set(nodeBuilderState.fragmentShader, stageFragment);
                backend.createProgram(stageFragment);
            }
            const cacheKey = this._getRenderCacheKey(renderObject, stageVertex, stageFragment);
            let pipeline = this.caches.get(cacheKey);
            if (pipeline == null) {
                if (previousPipeline != null && previousPipeline.usedTimes == 0) {
                    this._releasePipeline(previousPipeline);
                }
                pipeline = this._getRenderPipeline(renderObject, stageVertex, stageFragment, cacheKey, promises);
            } else {
                renderObject.pipeline = pipeline;
            }
            pipeline.usedTimes++;
            stageVertex.usedTimes++;
            stageFragment.usedTimes++;
            data.pipeline = pipeline;
        }
        return data.pipeline;
    }

    public function delete(object: Dynamic) {
        const pipeline = this.get(object).pipeline;
        if (pipeline != null) {
            pipeline.usedTimes--;
            if (pipeline.usedTimes == 0) {
                this._releasePipeline(pipeline);
            }
            if (pipeline.isComputePipeline) {
                pipeline.computeProgram.usedTimes--;
                if (pipeline.computeProgram.usedTimes == 0) {
                    this._releaseProgram(pipeline.computeProgram);
                }
            } else {
                pipeline.fragmentProgram.usedTimes--;
                pipeline.vertexProgram.usedTimes--;
                if (pipeline.vertexProgram.usedTimes == 0) {
                    this._releaseProgram(pipeline.vertexProgram);
                }
                if (pipeline.fragmentProgram.usedTimes == 0) {
                    this._releaseProgram(pipeline.fragmentProgram);
                }
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

    public function updateForRender(renderObject: Dynamic) {
        this.getForRender(renderObject);
    }

    private function _getComputePipeline(computeNode: Dynamic, stageCompute: ProgrammableStage, cacheKey: String, bindings: Dynamic): ComputePipeline {
        cacheKey = cacheKey ?? this._getComputeCacheKey(computeNode, stageCompute);
        let pipeline = this.caches.get(cacheKey);
        if (pipeline == null) {
            pipeline = new ComputePipeline(cacheKey, stageCompute);
            this.caches.set(cacheKey, pipeline);
            this.backend.createComputePipeline(pipeline, bindings);
        }
        return pipeline;
    }

    private function _getRenderPipeline(renderObject: Dynamic, stageVertex: ProgrammableStage, stageFragment: ProgrammableStage, cacheKey: String, promises: Array<Promise<Dynamic>>): RenderPipeline {
        cacheKey = cacheKey ?? this._getRenderCacheKey(renderObject, stageVertex, stageFragment);
        let pipeline = this.caches.get(cacheKey);
        if (pipeline == null) {
            pipeline = new RenderPipeline(cacheKey, stageVertex, stageFragment);
            this.caches.set(cacheKey, pipeline);
            renderObject.pipeline = pipeline;
            this.backend.createRenderPipeline(renderObject, promises);
        }
        return pipeline;
    }

    private function _getComputeCacheKey(computeNode: Dynamic, stageCompute: ProgrammableStage): String {
        return computeNode.id + ',' + stageCompute.id;
    }

    private function _getRenderCacheKey(renderObject: Dynamic, stageVertex: ProgrammableStage, stageFragment: ProgrammableStage): String {
        return stageVertex.id + ',' + stageFragment.id + ',' + this.backend.getRenderCacheKey(renderObject);
    }

    private function _releasePipeline(pipeline: Dynamic) {
        this.caches.delete(pipeline.cacheKey);
    }

    private function _releaseProgram(program: Dynamic) {
        const code = program.code;
        const stage = program.stage;
        this.programs[stage].delete(code);
    }

    private function _needsComputeUpdate(computeNode: Dynamic): Bool {
        const data = this.get(computeNode);
        return data.pipeline == null || data.version != computeNode.version;
    }

    private function _needsRenderUpdate(renderObject: Dynamic): Bool {
        const data = this.get(renderObject);
        return data.pipeline == null || this.backend.needsRenderUpdate(renderObject);
    }
}