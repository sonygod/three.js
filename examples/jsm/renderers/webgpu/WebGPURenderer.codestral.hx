import WebGPU from 'three.js.capabilities.WebGPU';
import Renderer from 'three.js.renderers.common.Renderer';
import WebGLBackend from 'three.js.renderers.webgl.WebGLBackend';
import WebGPUBackend from 'three.js.renderers.webgpu.WebGPUBackend';

class WebGPURenderer extends Renderer {

    public function new(parameters:Dynamic = {}) {
        var BackendClass:Class<Dynamic>;

        if(Reflect.hasField(parameters, "forceWebGL") && parameters.forceWebGL) {
            BackendClass = WebGLBackend;
        } else if(WebGPU.isAvailable()) {
            BackendClass = WebGPUBackend;
        } else {
            BackendClass = WebGLBackend;
            trace('THREE.WebGPURenderer: WebGPU is not available, running under WebGL2 backend.');
        }

        var backend = Type.createInstance(BackendClass, [parameters]);
        super(backend, parameters);

        this.isWebGPURenderer = true;
    }

}