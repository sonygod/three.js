class WebGLRenderer {
    // ...

    public function clear(background:Bool, depth:Bool, stencil:Bool):Void {
        // ...
    }

    public function clearColor():Void {
        this.clear(true, false, false);
    }

    public function clearDepth():Void {
        this.clear(false, true, false);
    }

    public function clearStencil():Void {
        this.clear(false, false, true);
    }

    public function dispose():Void {
        // ...
    }

    public function renderBufferDirect(camera:Camera, scene:Scene, geometry:Geometry, material:Material, object:Object, group:Group):Void {
        // ...
    }

    public function compile(scene:Scene, camera:Camera, targetScene:Scene = null):Set<Material> {
        // ...
    }

    public function compileAsync(scene:Scene, camera:Camera, targetScene:Scene = null):Promise<Scene> {
        // ...
    }
}