import three.Cameras.Camera;
import three.Lights.DirectionalLight;
import three.Lights.Light;
import three.Math.Box3;
import three.Math.MathUtils;
import three.Math.Matrix4;
import three.Math.Vector2;
import three.Math.Vector3;
import three.Scenes.Scene;
import three.ShaderChunk;

class CSM {
    public static var _cameraToLightMatrix(default, null) = new Matrix4();
    public static var _lightSpaceFrustum(default, null) = new CSMFrustum();
    public static var _center(default, null) = new Vector3();
    public static var _bbox(default, null) = new Box3();
    public static var _uniformArray(default, null) = [];
    public static var _logArray(default, null) = [];
    public static var _lightOrientationMatrix(default, null) = new Matrix4();
    public static var _lightOrientationMatrixInverse(default, null) = new Matrix4();
    public static var _up(default, null) = new Vector3(0, 1, 0);

    public var camera:Camera;
    public var parent:Scene;
    public var cascades:Int;
    public var maxFar:Float;
    public var mode:String;
    public var shadowMapSize:Int;
    public var shadowBias:Float;
    public var lightDirection:Vector3;
    public var lightIntensity:Float;
    public var lightNear:Float;
    public var lightFar:Float;
    public var lightMargin:Float;
    public var customSplitsCallback:Dynamic;
    public var fade:Bool;
    public var mainFrustum:CSMFrustum;
    public var frustums:Array<CSMFrustum>;
    public var breaks:Array<Float>;
    public var lights:Array<Light>;
    public var shaders:Map<Dynamic, Dynamic>;

    public function new(data:Dynamic) {
        this.camera = data.camera;
        this.parent = data.parent;
        this.cascades = data.cascades != null ? data.cascades : 3;
        this.maxFar = data.maxFar != null ? data.maxFar : 100000;
        this.mode = data.mode != null ? data.mode : 'practical';
        this.shadowMapSize = data.shadowMapSize != null ? data.shadowMapSize : 2048;
        this.shadowBias = data.shadowBias != null ? data.shadowBias : 0.000001;
        this.lightDirection = data.lightDirection != null ? data.lightDirection : new Vector3(1, -1, 1).normalize();
        this.lightIntensity = data.lightIntensity != null ? data.lightIntensity : 3;
        this.lightNear = data.lightNear != null ? data.lightNear : 1;
        this.lightFar = data.lightFar != null ? data.lightFar : 2000;
        this.lightMargin = data.lightMargin != null ? data.lightMargin : 200;
        this.customSplitsCallback = data.customSplitsCallback;
        this.fade = false;
        this.mainFrustum = new CSMFrustum();
        this.frustums = [];
        this.breaks = [];
        this.lights = [];
        this.shaders = new Map();
        createLights();
        updateFrustums();
        injectInclude();
    }

    function createLights() {
        for (i in 0...cascades) {
            var light = new DirectionalLight(0xffffff, this.lightIntensity);
            light.castShadow = true;
            light.shadow.mapSize.width = this.shadowMapSize;
            light.shadow.mapSize.height = this.shadowMapSize;
            light.shadow.camera.near = this.lightNear;
            light.shadow.camera.far = this.lightFar;
            light.shadow.bias = this.shadowBias;
            this.parent.add(light);
            this.parent.add(light.target);
            this.lights.push(light);
        }
    }

    function initCascades() {
        var camera = this.camera;
        camera.updateProjectionMatrix();
        this.mainFrustum.setFromProjectionMatrix(camera.projectionMatrix, this.maxFar);
        this.mainFrustum.split(this.breaks, this.frustums);
    }

    function updateShadowBounds() {
        var frustums = this.frustums;
        for (i in 0...frustums.length) {
            var light = this.lights[i];
            var shadowCam = light.shadow.camera;
            var frustum = this.frustums[i];
            // Get the two points that represent that furthest points on the frustum assuming
            // that's either the diagonal across the far plane or the diagonal across the whole
            // frustum itself.
            var nearVerts = frustum.vertices.near;
            var farVerts = frustum.vertices.far;
            var point1 = farVerts[0];
            var point2:Vector3 = null;
            if (point1.distanceTo(farVerts[2]) > point1.distanceTo(nearVerts[2])) {
                point2 = farVerts[2];
            } else {
                point2 = nearVerts[2];
            }
            var squaredBBWidth = point1.distanceTo(point2);
            if (this.fade) {
                // expand the shadow extents by the fade margin if fade is enabled.
                var camera = this.camera;
                var far = Math.max(camera.far, this.maxFar);
                var linearDepth = frustum.vertices.far[0].z / (far - camera.near);
                var margin = 0.25 * Math.pow(linearDepth, 2.0) * (far - camera.near);
                squaredBBWidth += margin;
            }
            shadowCam.left = -squaredBBWidth / 2;
            shadowCam.right = squaredBBWidth / 2;
            shadowCam.top = squaredBBWidth / 2;
            shadowCam.bottom = -squaredBBWidth / 2;
            shadowCam.updateProjectionMatrix();
        }
    }

    function getBreaks() {
        var camera = this.camera;
        var far = Math.min(camera.far, this.maxFar);
        this.breaks = [];
        switch (this.mode) {
            case 'uniform':
                uniformSplit(this.cascades, camera.near, far, this.breaks);
            case 'logarithmic':
                logarithmicSplit(this.cascades, camera.near, far, this.breaks);
            case 'practical':
                practicalSplit(this.cascades, camera.near, far, 0.5, this.breaks);
            case 'custom':
                if (this.customSplitsCallback == null) {
                    trace('CSM: Custom split scheme callback not defined.');
                }
                this.customSplitsCallback(this.cascades, camera.near, far, this.breaks);
        }
    }

    function uniformSplit(amount:Int, near:Float, far:Float, target:Array<Float>) {
        for (i in 1...amount) {
            target.push((near + (far - near) * i / amount) / far);
        }
        target.push(1);
    }

    function logarithmicSplit(amount:Int, near:Float, far:Float, target:Array<Float>) {
        for (i in 1...amount) {
            target.push((near * Math.pow((far / near), (i / amount))) / far);
        }
        target.push(1);
    }

    function practicalSplit(amount:Int, near:Float, far:Float, lambda:Float, target:Array<Float>) {
        _uniformArray = [];
        _logArray = [];
        logarithmicSplit(amount, near, far, _logArray);
        uniformSplit(amount, near, far, _uniformArray);
        for (i in 1...amount) {
            target.push(MathUtils.lerp(_uniformArray[i - 1], _logArray[i - 1], lambda));
        }
        target.push(1);
    }

    public function update() {
        var camera = this.camera;
        var frustums = this.frustums;
        // for each frustum we need to find its min-max box aligned with the light orientation
        // the position in _lightOrientationMatrix does not matter, as we transform there and back
        _lightOrientationMatrix.lookAt(new Vector3(), this.lightDirection, _up);
        _lightOrientationMatrixInverse.copy(_lightOrientationMatrix).invert();
        for (i in 0...frustums.length) {
            var light = this.lights[i];
            var shadowCam = light.shadow.camera;
            var texelWidth = (shadowCam.right - shadowCam.left) / this.shadowMapSize;
            var texelHeight = (shadowCam.top - shadowCam.bottom) / this.shadowMapSize;
            _cameraToLightMatrix.multiplyMatrices(_lightOrientationMatrixInverse, camera.matrixWorld);
            frustums[i].toSpace(_cameraToLightMatrix, _lightSpaceFrustum);
            var nearVerts = _lightSpaceFrustum.vertices.near;
            var farVerts = _lightSpaceFrustum.vertices.far;
            _bbox.makeEmpty();
            for (j in 0...4) {
                _bbox.expandByPoint(nearVerts[j]);
                _bbox.expandByPoint(farVerts[j]);
            }
            _bbox.getCenter(_center);
            _center.z = _bbox.max.z + this.lightMargin;
            _center.x = Math.floor(_center.x / texelWidth) * texelWidth;
            _center.y = Math.floor(_center.y / texelHeight) * texelHeight;
            _center.applyMatrix4(_lightOrientationMatrix);
            light.position.copy(_center);
            light.target.position.copy(_center);
            light.target.position.x += this.lightDirection.x;
            light.target.position.y += this.lightDirection.y;
            light.target.position.z += this.lightDirection.z;
        }
    }

    function injectInclude() {
        ShaderChunk.lights_fragment_begin = CSMShader.lights_fragment_begin;
        ShaderChunk.lights_pars_begin = CSMShader.lights_pars_begin;
    }

    public function setupMaterial(material:Dynamic) {
        material.defines = material.defines != null ? material.defines : {};
        material.defines.USE_CSM = 1;
        material.defines.CSM_CASCADES = this.cascades;
        if (this.fade) {
            material.defines.CSM_FADE = '';
        }
        var breaksVec2:Array<Vector2> = [];
        var scope = this;
        var shaders = this.shaders;
        material.onBeforeCompile = function(shader) {
            var far = Math.min(scope.camera.far, scope.maxFar);
            scope.getExtendedBreaks(breaksVec2);
            // @ts-ignore
            shader.uniforms.CSM_cascades = {
                value: breaksVec2
            };
            // @ts-ignore
            shader.uniforms.cameraNear = {
                value: scope.camera.near
            };
            // @ts-ignore
            shader.uniforms.shadowFar = {
                value: far
            };
            shaders.set(material, shader);
        };
        shaders.set(material, null);
    }

    public function updateUniforms() {
        var far = Math.min(this.camera.far, this.maxFar);
        var shaders = this.shaders;
        shaders.keyValueIterator().forEach(function(item) {
            var shader = item.value;
            var material = item.key;
            if (shader != null) {
                var uniforms = shader.uniforms;
                this.getExtendedBreaks(uniforms.CSM_cascades.value);
                uniforms.cameraNear.value = this.camera.near;
                uniforms.shadowFar.value = far;
            }
            if (!this.fade && material.defines.hasOwnProperty("CSM_FADE")) {
                Reflect.deleteField(material.defines, "CSM_FADE");
                material.needsUpdate = true;
            } else if (this.fade && !material.defines.hasOwnProperty("CSM_FADE")) {
                material.defines.CSM_FADE = '';
                material.needsUpdate = true;
            }
        });
    }

    function getExtendedBreaks(target:Array<Vector2>) {
        while (target.length < this.breaks.length) {
            target.push(new Vector2());
        }
        target.length = this.breaks.length;
        for (i in 0...this.cascades) {
            var amount = this.breaks[i];
            var prev = i > 0 ? this.breaks[i - 1] : 0;
            target[i].x = prev;
            target[i].y = amount;
        }
    }

    public function updateFrustums() {
        this.getBreaks();
        this.initCascades();
        this.updateShadowBounds();
        this.updateUniforms();
    }

    public function remove() {
        for (i in 0...this.lights.length) {
            this.parent.remove(this.lights[i].target);
            this.parent.remove(this.lights[i]);
        }
    }

    public function dispose() {
        var shaders = this.shaders;
        shaders.keyValueIterator().forEach(function(item) {
            var shader = item.value;
            var material = item.key;
            Reflect.deleteField(material, "onBeforeCompile");
            Reflect.deleteField(material.defines, "USE_CSM");
            Reflect.deleteField(material.defines, "CSM_CASCADES");
            Reflect.deleteField(material.defines, "CSM_FADE");
            if (shader != null) {
                Reflect.deleteField(shader.uniforms, "CSM_cascades");
                Reflect.deleteField(shader.uniforms, "cameraNear");
                Reflect.deleteField(shader.uniforms, "shadowFar");
            }
            material.needsUpdate = true;
        });
        shaders.clear();
    }
}