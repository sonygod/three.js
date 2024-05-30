import DataMap.hx;
import RenderPipeline.hx;
import ComputePipeline.hx;
import ProgrammableStage.hx;

class Pipelines extends DataMap {

	public var backend:Dynamic;
	public var nodes:Dynamic;
	public var bindings:Dynamic;
	public var caches:Map<Dynamic, Dynamic>;
	public var programs:Map<Dynamic, Dynamic>;

	public function new(backend:Dynamic, nodes:Dynamic) {
		super();
		this.backend = backend;
		this.nodes = nodes;
		this.bindings = null;
		this.caches = new Map<Dynamic, Dynamic>();
		this.programs = {
			vertex: new Map<Dynamic, Dynamic>(),
			fragment: new Map<Dynamic, Dynamic>(),
			compute: new Map<Dynamic, Dynamic>()
		};
	}

	public function getForCompute(computeNode:Dynamic, bindings:Dynamic):Dynamic {
		var backend = this.backend;
		var data = this.get(computeNode);
		if (this._needsComputeUpdate(computeNode)) {
			var previousPipeline = data.pipeline;
			if (previousPipeline) {
				previousPipeline.usedTimes--;
				previousPipeline.computeProgram.usedTimes--;
			}
			var nodeBuilderState = this.nodes.getForCompute(computeNode);
			var stageCompute = this.programs.compute.get(nodeBuilderState.computeShader);
			if (stageCompute === undefined) {
				if (previousPipeline && previousPipeline.computeProgram.usedTimes === 0) this._releaseProgram(previousPipeline.computeProgram);
				stageCompute = new ProgrammableStage(nodeBuilderState.computeShader, 'compute', nodeBuilderState.transforms, nodeBuilderState.nodeAttributes);
				this.programs.compute.set(nodeBuilderState.computeShader, stageCompute);
				backend.createProgram(stageCompute);
			}
			var cacheKey = this._getComputeCacheKey(computeNode, stageCompute);
			var pipeline = this.caches.get(cacheKey);
			if (pipeline === undefined) {
				if (previousPipeline && previousPipeline.usedTimes === 0) this._releasePipeline(computeNode);
				pipeline = this._getComputePipeline(computeNode, stageCompute, cacheKey, bindings);
			}
			pipeline.usedTimes++;
			stageCompute.usedTimes++;
			data.version = computeNode.version;
			data.pipeline = pipeline;
		}
		return data.pipeline;
	}

	public function getForRender(renderObject:Dynamic, promises:Dynamic):Dynamic {
		var backend = this.backend;
		var data = this.get(renderObject);
		if (this._needsRenderUpdate(renderObject)) {
			var previousPipeline = data.pipeline;
			if (previousPipeline) {
				previousPipeline.usedTimes--;
				previousPipeline.vertexProgram.usedTimes--;
				previousPipeline.fragmentProgram.usedTimes--;
			}
			var nodeBuilderState = renderObject.getNodeBuilderState();
			var stageVertex = this.programs.vertex.get(nodeBuilderState.vertexShader);
			if (stageVertex === undefined) {
				if (previousPipeline && previousPipeline.vertexProgram.usedTimes === 0) this._releaseProgram(previousPipeline.vertexProgram);
				stageVertex = new ProgrammableStage(nodeBuilderState.vertexShader, 'vertex');
				this.programs.vertex.set(nodeBuilderState.vertexShader, stageVertex);
				backend.createProgram(stageVertex);
			}
			var stageFragment = this.programs.fragment.get(nodeBuilderState.fragmentShader);
			if (stageFragment === undefined) {
				if (previousPipeline && previousPipeline.fragmentProgram.usedTimes === 0) this._releaseProgram(previousPipeline.fragmentProgram);
				stageFragment = new ProgrammableStage(nodeBuilderState.fragmentShader, 'fragment');
				this.programs.fragment.set(nodeBuilderState.fragmentShader, stageFragment);
				backend.createProgram(stageFragment);
			}
			var cacheKey = this._getRenderCacheKey(renderObject, stageVertex, stageFragment);
			var pipeline = this.caches.get(cacheKey);
			if (pipeline === undefined) {
				if (previousPipeline && previousPipeline.usedTimes === 0) this._releasePipeline(previousPipeline);
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
		var pipeline = this.get(object).pipeline;
		if (pipeline) {
			pipeline.usedTimes--;
			if (pipeline.usedTimes === 0) this._releasePipeline(pipeline);
			if (pipeline.isComputePipeline) {
				pipeline.computeProgram.usedTimes--;
				if (pipeline.computeProgram.usedTimes === 0) this._releaseProgram(pipeline.computeProgram);
			} else {
				pipeline.fragmentProgram.usedTimes--;
				pipeline.vertexProgram.usedTimes--;
				if (pipeline.vertexProgram.usedTimes === 0) this._releaseProgram(pipeline.vertexProgram);
				if (pipeline.fragmentProgram.usedTimes === 0) this._releaseProgram(pipeline.fragmentProgram);
			}
		}
		super.delete(object);
	}

	public function dispose() {
		super.dispose();
		this.caches = new Map<Dynamic, Dynamic>();
		this.programs = {
			vertex: new Map<Dynamic, Dynamic>(),
			fragment: new Map<Dynamic, Dynamic>(),
			compute: new Map<Dynamic, Dynamic>()
		};
	}

	public function updateForRender(renderObject:Dynamic) {
		this.getForRender(renderObject);
	}

	private function _getComputePipeline(computeNode:Dynamic, stageCompute:Dynamic, cacheKey:Dynamic, bindings:Dynamic):Dynamic {
		cacheKey = cacheKey || this._getComputeCacheKey(computeNode, stageCompute);
		var pipeline = this.caches.get(cacheKey);
		if (pipeline === undefined) {
			pipeline = new ComputePipeline(cacheKey, stageCompute);
			this.caches.set(cacheKey, pipeline);
			this.backend.createComputePipeline(pipeline, bindings);
		}
		return pipeline;
	}

	private function _getRenderPipeline(renderObject:Dynamic, stageVertex:Dynamic, stageFragment:Dynamic, cacheKey:Dynamic, promises:Dynamic):Dynamic {
		cacheKey = cacheKey || this._getRenderCacheKey(renderObject, stageVertex, stageFragment);
		var pipeline = this.caches.get(cacheKey);
		if (pipeline === undefined) {
			pipeline = new RenderPipeline(cacheKey, stageVertex, stageFragment);
			this.caches.set(cacheKey, pipeline);
			renderObject.pipeline = pipeline;
			this.backend.createRenderPipeline(renderObject, promises);
		}
		return pipeline;
	}

	private function _getComputeCacheKey(computeNode:Dynamic, stageCompute:Dynamic):Dynamic {
		return computeNode.id + ',' + stageCompute.id;
	}

	private function _getRenderCacheKey(renderObject:Dynamic, stageVertex:Dynamic, stageFragment:Dynamic):Dynamic {
		return stageVertex.id + ',' + stageFragment.id + ',' + this.backend.getRenderCacheKey(renderObject);
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
		return data.pipeline === undefined || data.version !== computeNode.version;
	}

	private function _needsRenderUpdate(renderObject:Dynamic):Bool {
		var data = this.get(renderObject);
		return data.pipeline === undefined || this.backend.needsRenderUpdate(renderObject);
	}

}