import three.js.examples.jsm.capabilities.WebGPU;
import three.js.examples.jsm.renderers.common.Renderer;
import three.js.examples.jsm.renderers.webgl.WebGLBackend;
import three.js.examples.jsm.renderers.webgpu.WebGPUBackend;

class WebGPURenderer extends Renderer {

    public function new(parameters:Dynamic = {}) {

        var BackendClass:Dynamic;

        if (parameters.forceWebGL) {

            BackendClass = WebGLBackend;

        } else if (WebGPU.isAvailable()) {

            BackendClass = WebGPUBackend;

        } else {

            BackendClass = WebGLBackend;

            trace('THREE.WebGPURenderer: WebGPU is not available, running under WebGL2 backend.');

        }

        var backend = new BackendClass(parameters);

        super(backend, parameters);

        this.isWebGPURenderer = true;

    }

}