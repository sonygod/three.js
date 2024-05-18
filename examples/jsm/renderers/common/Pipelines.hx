package three.js.examples.jsm.renderers.common;

import DataMap;
import RenderPipeline;
import ComputePipeline;
import ProgrammableStage;

class Pipelines extends DataMap {
    private var backend:Dynamic;
    private var nodes:Dynamic;

    public function new(backend:Dynamic, nodes:Dynamic) {
        super();
        this.backend = backend;
        this.nodes = nodes;
        this.bindings = null; // set by the bindings
        this.caches = new Map<String, Dynamic>();
        this.programs = {
            vertex: new Map<String, ProgrammableStage>(),
            fragment: new Map<String, ProgrammableStage>(),
            compute: new Map<String, ProgrammableStage>()
        };
    }

    public function getForCompute(computeNode:Dynamic, bindings:Dynamic):ComputePipeline {
        var backend = this.backend;
        var data = this.get(computeNode);
        if (this._needsComputeUpdate(computeNode)) {
            var previousPipeline:ComputePipeline = data.pipeline;
            if (previousPipeline != null) {
                previousPipeline.usedTimes--;
                previousPipeline.computeProgram.usedTimes--;
            }
            var nodeBuilderState = this.nodes.getForCompute(computeNode);
            var stageCompute:ProgrammableStage = this.programs.compute.get(nodeBuilderState.computeShader);
            if (stageCompute == null) {
                if (previousPipeline != null && previousPipeline.usedTimes == 0) this._releaseProgram(previousPipeline.computeProgram);
                stageCompute = new ProgrammableStage(nodeBuilderState.computeShader, 'compute', nodeBuilderState.transforms, nodeBuilderState.nodeAttributes);
                this.programs.compute.set(nodeBuilderState.computeShader, stageCompute);
                backend.createProgram(stageCompute);
            }
            var cacheKey = this._getComputeCacheKey(computeNode, stageCompute);
            var pipeline:ComputePipeline = this.caches.get(cacheKey);
            if (pipeline == null) {
                if (previousPipeline != null && previousPipeline.usedTimes == 0) this._releasePipeline(previousPipeline);
                pipeline = this._getComputePipeline(computeNode, stageCompute, cacheKey, bindings);
            }
            pipeline.usedTimes++;
            stageCompute.usedTimes++;
            data.version = computeNode.version;
            data.pipeline = pipeline;
        }
        return data.pipeline;
    }

    public function getForRender(renderObject:Dynamic, promises:Dynamic = null):RenderPipeline {
        var backend = this.backend;
        var data = this.get(renderObject);
        if (this._needsRenderUpdate(renderObject)) {
            var previousPipeline:RenderPipeline = data.pipeline;
            if (previousPipeline != null) {
                previousPipeline.usedTimes--;
                previousPipeline.vertexProgram.usedTimes--;
                previousPipeline.fragmentProgram.usedTimes--;
            }
            var nodeBuilderState = renderObject.getNodeBuilderState();
            var stageVertex:ProgrammableStage = this.programs.vertex.get(nodeBuilderState.vertexShader);
            if (stageVertex == null) {
                if (previousPipeline != null && previousPipeline.vertexProgram.usedTimes == 0) this._releaseProgram(previousPipeline.vertexProgram);
                stageVertex = new ProgrammableStage(nodeBuilderState.vertexShader, 'vertex');
                this.programs.vertex.set(nodeBuilderState.vertexShader, stageVertex);
                backend.createProgram(stageVertex);
            }
            var stageFragment:ProgrammableStage = this.programs.fragment.get(nodeBuilderState.fragmentShader);
            if (stageFragment == null) {
                if (previousPipeline != null && previousPipeline.fragmentProgram.usedTimes == 0) this._releaseProgram(previousPipeline.fragmentProgram);
                stageFragment = new ProgrammableStage(nodeBuilderState.fragmentShader, 'fragment');
                this.programs.fragment.set(nodeBuilderState.fragmentShader, stageFragment);
                backend.createProgram(stageFragment);
            }
            var cacheKey = this._getRenderCacheKey(renderObject, stageVertex, stageFragment);
            var pipeline:RenderPipeline = this.caches.get(cacheKey);
            if (pipeline == null) {
                if (previousPipeline != null && previousPipeline.usedTimes == 0) this._releasePipeline(previousPipeline);
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

    public function delete(object:Dynamic) {
        var pipeline:Dynamic = this.get(object).pipeline;
        if (pipeline != null) {
            pipeline.usedTimes--;
            if (pipeline.usedTimes == 0) this._releasePipeline(pipeline);
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
        this.caches = new Map<String, Dynamic>();
        this.programs = {
            vertex: new Map<String, ProgrammableStage>(),
            fragment: new Map<String, ProgrammableStage>(),
            compute: new Map<String, ProgrammableStage>()
        };
    }

    public function updateForRender(renderObject:Dynamic) {
        this.getForRender(renderObject);
    }

    private function _getComputePipeline(computeNode:Dynamic, stageCompute:ProgrammableStage, cacheKey:String, bindings:Dynamic):ComputePipeline {
        cacheKey = cacheKey != null ? cacheKey : this._getComputeCacheKey(computeNode, stageCompute);
        var pipeline:ComputePipeline = this.caches.get(cacheKey);
        if (pipeline == null) {
            pipeline = new ComputePipeline(cacheKey, stageCompute);
            this.caches.set(cacheKey, pipeline);
            backend.createComputePipeline(pipeline, bindings);
        }
        return pipeline;
    }

    private function _getRenderPipeline(renderObject:Dynamic, stageVertex:ProgrammableStage, stageFragment:ProgrammableStage, cacheKey:String, promises:Dynamic):RenderPipeline {
        cacheKey = cacheKey != null ? cacheKey : this._getRenderCacheKey(renderObject, stageVertex, stageFragment);
        var pipeline:RenderPipeline = this.caches.get(cacheKey);
        if (pipeline == null) {
            pipeline = new RenderPipeline(cacheKey, stageVertex, stageFragment);
            this.caches.set(cacheKey, pipeline);
            renderObject.pipeline = pipeline;
            backend.createRenderPipeline(renderObject, promises);
        }
        return pipeline;
    }

    private function _getComputeCacheKey(computeNode:Dynamic, stageCompute:ProgrammableStage):String {
        return computeNode.id + ',' + stageCompute.id;
    }

    private function _getRenderCacheKey(renderObject:Dynamic, stageVertex:ProgrammableStage, stageFragment:ProgrammableStage):String {
        return stageVertex.id + ',' + stageFragment.id + ',' + backend.getRenderCacheKey(renderObject);
    }

    private function _releasePipeline(pipeline:Dynamic) {
        this.caches.delete(pipeline.cacheKey);
    }

    private function _releaseProgram(program:Dynamic) {
        var code = program.code;
        var stage = program.stage;
        this.programs[stage].delete(code);
    }

    private function _needsComputeUpdate(computeNode:Dynamic):Bool {
        var data = this.get(computeNode);
        return data.pipeline == null || data.version != computeNode.version;
    }

    private function _needsRenderUpdate(renderObject:Dynamic):Bool {
        var data = this.get(renderObject);
        return data.pipeline == null || backend.needsRenderUpdate(renderObject);
    }
}