package three.js.examples.jvm.renderers.common;

import DataMap;
import RenderPipeline;
import ComputePipeline;
import ProgrammableStage;

class Pipelines extends DataMap<Pipeline> {
    
    public var backend:Backend;
    public var nodes:NodeBuilder;

    public var bindings:Dynamic;
    public var caches:Map<String, Pipeline>;
    public var programs:Map<String, Map<String, ProgrammableStage>>;

    public function new(backend:Backend, nodes:NodeBuilder) {
        super();
        this.backend = backend;
        this.nodes = nodes;
        this.bindings = null; 
        this.caches = new Map();
        this.programs = [
            'vertex' => new Map(),
            'fragment' => new Map(),
            'compute' => new Map()
        ];
    }

    public function getForCompute(computeNode:ComputeNode, bindings:Dynamic):ComputePipeline {
        var data:Pipeline = get(computeNode);
        if (_needsComputeUpdate(computeNode)) {
            var previousPipeline:ComputePipeline = data.pipeline;
            if (previousPipeline != null) {
                previousPipeline.usedTimes--;
                previousPipeline.computeProgram.usedTimes--;
            }
            var nodeBuilderState:NodeBuilderState = nodes.getForCompute(computeNode);
            var stageCompute:ProgrammableStage = programs.compute.get(nodeBuilderState.computeShader);
            if (stageCompute == null) {
                if (previousPipeline != null && previousPipeline.usedTimes == 0) _releaseProgram(previousPipeline.computeProgram);
                stageCompute = new ProgrammableStage(nodeBuilderState.computeShader, 'compute', nodeBuilderState.transforms, nodeBuilderState.nodeAttributes);
                programs.compute.set(nodeBuilderState.computeShader, stageCompute);
                backend.createProgram(stageCompute);
            }
            var cacheKey:String = _getComputeCacheKey(computeNode, stageCompute);
            var pipeline:ComputePipeline = caches.get(cacheKey);
            if (pipeline == null) {
                if (previousPipeline != null && previousPipeline.usedTimes == 0) _releasePipeline(computeNode);
                pipeline = _getComputePipeline(computeNode, stageCompute, cacheKey, bindings);
            }
            pipeline.usedTimes++;
            stageCompute.usedTimes++;
            data.version = computeNode.version;
            data.pipeline = pipeline;
        }
        return data.pipeline;
    }

    public function getForRender(renderObject:RenderObject, promises:Null<Array<Promise>> = null):RenderPipeline {
        var data:Pipeline = get(renderObject);
        if (_needsRenderUpdate(renderObject)) {
            var previousPipeline:RenderPipeline = data.pipeline;
            if (previousPipeline != null) {
                previousPipeline.usedTimes--;
                previousPipeline.vertexProgram.usedTimes--;
                previousPipeline.fragmentProgram.usedTimes--;
            }
            var nodeBuilderState:NodeBuilderState = renderObject.getNodeBuilderState();
            var stageVertex:ProgrammableStage = programs.vertex.get(nodeBuilderState.vertexShader);
            if (stageVertex == null) {
                if (previousPipeline != null && previousPipeline.vertexProgram.usedTimes == 0) _releaseProgram(previousPipeline.vertexProgram);
                stageVertex = new ProgrammableStage(nodeBuilderState.vertexShader, 'vertex');
                programs.vertex.set(nodeBuilderState.vertexShader, stageVertex);
                backend.createProgram(stageVertex);
            }
            var stageFragment:ProgrammableStage = programs.fragment.get(nodeBuilderState.fragmentShader);
            if (stageFragment == null) {
                if (previousPipeline != null && previousPipeline.fragmentProgram.usedTimes == 0) _releaseProgram(previousPipeline.fragmentProgram);
                stageFragment = new ProgrammableStage(nodeBuilderState.fragmentShader, 'fragment');
                programs.fragment.set(nodeBuilderState.fragmentShader, stageFragment);
                backend.createProgram(stageFragment);
            }
            var cacheKey:String = _getRenderCacheKey(renderObject, stageVertex, stageFragment);
            var pipeline:RenderPipeline = caches.get(cacheKey);
            if (pipeline == null) {
                if (previousPipeline != null && previousPipeline.usedTimes == 0) _releasePipeline(previousPipeline);
                pipeline = _getRenderPipeline(renderObject, stageVertex, stageFragment, cacheKey, promises);
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
        var pipeline:Pipeline = get(object).pipeline;
        if (pipeline != null) {
            pipeline.usedTimes--;
            if (pipeline.usedTimes == 0) _releasePipeline(pipeline);
            if (pipeline.isComputePipeline) {
                pipeline.computeProgram.usedTimes--;
                if (pipeline.computeProgram.usedTimes == 0) _releaseProgram(pipeline.computeProgram);
            } else {
                pipeline.fragmentProgram.usedTimes--;
                pipeline.vertexProgram.usedTimes--;
                if (pipeline.vertexProgram.usedTimes == 0) _releaseProgram(pipeline.vertexProgram);
                if (pipeline.fragmentProgram.usedTimes == 0) _releaseProgram(pipeline.fragmentProgram);
            }
        }
        super.delete(object);
    }

    public function dispose() {
        super.dispose();
        caches = new Map();
        programs = [
            'vertex' => new Map(),
            'fragment' => new Map(),
            'compute' => new Map()
        ];
    }

    public function updateForRender(renderObject:RenderObject) {
        getForRender(renderObject);
    }

    private function _getComputePipeline(computeNode:ComputeNode, stageCompute:ProgrammableStage, cacheKey:String, bindings:Dynamic):ComputePipeline {
        cacheKey = cacheKey != null ? cacheKey : _getComputeCacheKey(computeNode, stageCompute);
        var pipeline:ComputePipeline = caches.get(cacheKey);
        if (pipeline == null) {
            pipeline = new ComputePipeline(cacheKey, stageCompute);
            caches.set(cacheKey, pipeline);
            backend.createComputePipeline(pipeline, bindings);
        }
        return pipeline;
    }

    private function _getRenderPipeline(renderObject:RenderObject, stageVertex:ProgrammableStage, stageFragment:ProgrammableStage, cacheKey:String, promises:Null<Array<Promise>>):RenderPipeline {
        cacheKey = cacheKey != null ? cacheKey : _getRenderCacheKey(renderObject, stageVertex, stageFragment);
        var pipeline:RenderPipeline = caches.get(cacheKey);
        if (pipeline == null) {
            pipeline = new RenderPipeline(cacheKey, stageVertex, stageFragment);
            caches.set(cacheKey, pipeline);
            renderObject.pipeline = pipeline;
            backend.createRenderPipeline(renderObject, promises);
        }
        return pipeline;
    }

    private function _getComputeCacheKey(computeNode:ComputeNode, stageCompute:ProgrammableStage):String {
        return computeNode.id + ',' + stageCompute.id;
    }

    private function _getRenderCacheKey(renderObject:RenderObject, stageVertex:ProgrammableStage, stageFragment:ProgrammableStage):String {
        return stageVertex.id + ',' + stageFragment.id + ',' + backend.getRenderCacheKey(renderObject);
    }

    private function _releasePipeline(pipeline:Pipeline) {
        caches.remove(pipeline.cacheKey);
    }

    private function _releaseProgram(program:ProgrammableStage) {
        var code:String = program.code;
        var stage:String = program.stage;
        programs[stage].remove(code);
    }

    private function _needsComputeUpdate(computeNode:ComputeNode):Bool {
        var data:Pipeline = get(computeNode);
        return data.pipeline == null || data.version != computeNode.version;
    }

    private function _needsRenderUpdate(renderObject:RenderObject):Bool {
        var data:Pipeline = get(renderObject);
        return data.pipeline == null || backend.needsRenderUpdate(renderObject);
    }
}