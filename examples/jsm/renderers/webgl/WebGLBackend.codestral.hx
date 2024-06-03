import js.html.WebGLCoordinateSystem;
import js.html.WebGLRenderingContext;

import GLSLNodeBuilder from './nodes/GLSLNodeBuilder';
import Backend from '../common/Backend';

import WebGLAttributeUtils from './utils/WebGLAttributeUtils';
import WebGLState from './utils/WebGLState';
import WebGLUtils from './utils/WebGLUtils';
import WebGLTextureUtils from './utils/WebGLTextureUtils';
import WebGLExtensions from './utils/WebGLExtensions';
import WebGLCapabilities from './utils/WebGLCapabilities';
import { GLFeatureName } from './utils/WebGLConstants';
import { WebGLBufferRenderer } from './WebGLBufferRenderer';

class WebGLBackend extends Backend {
    private var gl:WebGLRenderingContext;
    private var extensions:WebGLExtensions;
    private var capabilities:WebGLCapabilities;
    private var attributeUtils:WebGLAttributeUtils;
    private var textureUtils:WebGLTextureUtils;
    private var bufferRenderer:WebGLBufferRenderer;
    private var state:WebGLState;
    private var utils:WebGLUtils;
    private var vaoCache:haxe.ds.StringMap<Dynamic>;
    private var transformFeedbackCache:haxe.ds.StringMap<Dynamic>;
    private var discard:Bool;
    private var trackTimestamp:Bool;
    private var disjoint:Dynamic;
    private var parallel:Dynamic;
    private var _currentContext:Dynamic;

    public function new(parameters:js.html.Object = null) {
        super(parameters);
        this.isWebGLBackend = true;
    }

    public function init(renderer:Dynamic) {
        super.init(renderer);

        var glContext:WebGLRenderingContext;
        if (this.parameters.context !== null) {
            glContext = this.parameters.context;
        } else {
            glContext = renderer.domElement.getContext('webgl2');
        }

        this.gl = glContext;
        this.extensions = new WebGLExtensions(this);
        this.capabilities = new WebGLCapabilities(this);
        this.attributeUtils = new WebGLAttributeUtils(this);
        this.textureUtils = new WebGLTextureUtils(this);
        this.bufferRenderer = new WebGLBufferRenderer(this);
        this.state = new WebGLState(this);
        this.utils = new WebGLUtils(this);
        this.vaoCache = new haxe.ds.StringMap<Dynamic>();
        this.transformFeedbackCache = new haxe.ds.StringMap<Dynamic>();
        this.discard = false;
        this.trackTimestamp = (this.parameters.trackTimestamp == true);

        this.extensions.get('EXT_color_buffer_float');
        this.disjoint = this.extensions.get('EXT_disjoint_timer_query_webgl2');
        this.parallel = this.extensions.get('KHR_parallel_shader_compile');
        this._currentContext = null;
    }

    public function get coordinateSystem() {
        return WebGLCoordinateSystem;
    }

    public async function getArrayBufferAsync(attribute:Dynamic) {
        return await this.attributeUtils.getArrayBufferAsync(attribute);
    }

    // ... continue the conversion for the rest of the methods
}