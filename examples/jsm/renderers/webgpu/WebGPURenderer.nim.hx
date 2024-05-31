import WebGPU.WebGPU;

import Renderer.Renderer;
import WebGLBackend.WebGLBackend;
import WebGPUBackend.WebGPUBackend;

class WebGPURenderer extends Renderer {

  public function new(parameters? : Dynamic) {

    var BackendClass;

    if (parameters.forceWebGL) {

      BackendClass = WebGLBackend;

    } else if (WebGPU.isAvailable()) {

      BackendClass = WebGPUBackend;

    } else {

      BackendClass = WebGLBackend;

      trace('WebGPURenderer: WebGPU is not available, running under WebGL2 backend.');

    }

    var backend = Type.createInstance(BackendClass, [parameters]);

    super(backend, parameters);

    this.isWebGPURenderer = true;

  }

}