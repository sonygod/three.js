import WebGPUCoordinateSystem from './WebGPUCoordinateSystem';
import { GPUFeatureName, GPUTextureFormat, GPULoadOp, GPUStoreOp, GPUIndexFormat, GPUTextureViewDimension } from './WebGPUConstants';
import WGSLNodeBuilder from './WGSLNodeBuilder';
import Backend from '../common/Backend';
import WebGPUUtils from './WebGPUUtils';
import WebGPUAttributeUtils from './WebGPUAttributeUtils';
import WebGPUBindingUtils from './WebGPUBindingUtils';
import WebGPUPipelineUtils from './WebGPUPipelineUtils';
import WebGPUTextureUtils from './WebGPUTextureUtils';

class WebGPUBackend extends Backend {
	public isWebGPUBackend:Bool;
	public device:GPUDevice;
	public context:GPURenderPassEncoder;
	public colorBuffer:GPURenderPassDescriptor;
	public defaultRenderPassdescriptor:GPURenderPassDescriptor;
	public utils:WebGPUUtils;
	public attributeUtils:WebGPUAttributeUtils;
	public bindingUtils:WebGPUBindingUtils;
	public pipelineUtils:WebGPUPipelineUtils;
	public textureUtils:WebGPUTextureUtils;
	public occludedResolveCache:Map<Int,GPUBuffer>;

	public constructor(parameters:Dynamic = {}) {
		super(parameters);
		this.isWebGPUBackend = true;
		this.parameters.alpha = (parameters.alpha === undefined) ? true : parameters.alpha;
		this.parameters.antialias = (parameters.antialias === true);
		this.parameters.requiredLimits = (parameters.requiredLimits === undefined) ? {} : parameters.requiredLimits;
		this.trackTimestamp = (parameters.trackTimestamp === true);
		this.device = null;
		this.context = null;
		this.colorBuffer = null;
		this.defaultRenderPassdescriptor = null;
		this.utils = new WebGPUUtils(this);
		this.attributeUtils = new WebGPUAttributeUtils(this);
		this.bindingUtils = new WebGPUBindingUtils(this);
		this.pipelineUtils = new WebGPUPipelineUtils(this);
		this.textureUtils = new WebGPUTextureUtils(this);
		this.occludedResolveCache = new Map<Int,GPUBuffer>();
	}

	// ... (rest of the methods)
}