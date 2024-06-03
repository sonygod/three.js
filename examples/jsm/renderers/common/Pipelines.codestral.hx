import js.Map;
import js.Array;
import three.examples.jsm.renderers.common.DataMap;
import three.examples.jsm.renderers.common.RenderPipeline;
import three.examples.jsm.renderers.common.ComputePipeline;
import three.examples.jsm.renderers.common.ProgrammableStage;

class Pipelines extends DataMap {

    var backend: Object;
    var nodes: Object;
    var bindings: Object = null;
    var caches: Map<String, Object> = new Map<String, Object>();
    var programs: Object = {
        vertex: new Map<String, Object>(),
        fragment: new Map<String, Object>(),
        compute: new Map<String, Object>()
    };

    public function new(backend: Object, nodes: Object) {
        super();
        this.backend = backend;
        this.nodes = nodes;
    }

    public function getForCompute(computeNode: Object, bindings: Object): Object {
        var data: Object = this.get(computeNode);

        if (this._needsComputeUpdate(computeNode)) {
            var previousPipeline: ComputePipeline = cast data.pipeline;

            if (previousPipeline != null) {
                previousPipeline.usedTimes--;
                previousPipeline.computeProgram.usedTimes--;
            }

            var nodeBuilderState: Object = this.nodes.getForCompute(computeNode);

            var stageCompute: ProgrammableStage = cast this.programs["compute"].get(nodeBuilderState.computeShader);

            if (stageCompute == null) {
                if (previousPipeline != null && previousPipeline.computeProgram.usedTimes == 0) this._releaseProgram(previousPipeline.computeProgram);

                stageCompute = new ProgrammableStage(nodeBuilderState.computeShader, "compute", nodeBuilderState.transforms, nodeBuilderState.nodeAttributes);
                this.programs["compute"].set(nodeBuilderState.computeShader, stageCompute);

                this.backend.createProgram(stageCompute);
            }

            var cacheKey: String = this._getComputeCacheKey(computeNode, stageCompute);

            var pipeline: ComputePipeline = cast this.caches.get(cacheKey);

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

    public function getForRender(renderObject: Object, promises: Array<Object> = null): Object {
        // Similar to getForCompute, but for render pipeline
    }

    public function delete(object: Object): Void {
        // Similar to JavaScript version
    }

    public function dispose(): Void {
        // Similar to JavaScript version
    }

    public function updateForRender(renderObject: Object): Void {
        this.getForRender(renderObject);
    }

    private function _getComputePipeline(computeNode: Object, stageCompute: ProgrammableStage, cacheKey: String, bindings: Object): ComputePipeline {
        // Similar to JavaScript version
    }

    private function _getRenderPipeline(renderObject: Object, stageVertex: ProgrammableStage, stageFragment: ProgrammableStage, cacheKey: String, promises: Array<Object>): RenderPipeline {
        // Similar to JavaScript version
    }

    private function _getComputeCacheKey(computeNode: Object, stageCompute: ProgrammableStage): String {
        // Similar to JavaScript version
    }

    private function _getRenderCacheKey(renderObject: Object, stageVertex: ProgrammableStage, stageFragment: ProgrammableStage): String {
        // Similar to JavaScript version
    }

    private function _releasePipeline(pipeline: Object): Void {
        // Similar to JavaScript version
    }

    private function _releaseProgram(program: Object): Void {
        // Similar to JavaScript version
    }

    private function _needsComputeUpdate(computeNode: Object): Bool {
        // Similar to JavaScript version
    }

    private function _needsRenderUpdate(renderObject: Object): Bool {
        // Similar to JavaScript version
    }
}