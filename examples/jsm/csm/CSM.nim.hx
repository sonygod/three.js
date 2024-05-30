import three.js.examples.jsm.csm.CSMFrustum;
import three.js.examples.jsm.csm.CSMShader;
import three.Vector2;
import three.Vector3;
import three.DirectionalLight;
import three.MathUtils;
import three.ShaderChunk;
import three.Matrix4;
import three.Box3;

class CSM {
    private var _cameraToLightMatrix:Matrix4;
    private var _lightSpaceFrustum:CSMFrustum;
    private var _center:Vector3;
    private var _bbox:Box3;
    private var _uniformArray:Array<Float>;
    private var _logArray:Array<Float>;
    private var _lightOrientationMatrix:Matrix4;
    private var _lightOrientationMatrixInverse:Matrix4;
    private var _up:Vector3;

    public var camera:Dynamic;
    public var parent:Dynamic;
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
    public var lights:Array<DirectionalLight>;
    public var shaders:Map<Dynamic, Dynamic>;

    public function new(data:Dynamic) {
        this.camera = data.camera;
        this.parent = data.parent;
        this.cascades = data.cascades ? data.cascades : 3;
        this.maxFar = data.maxFar ? data.maxFar : 100000;
        this.mode = data.mode ? data.mode : 'practical';
        this.shadowMapSize = data.shadowMapSize ? data.shadowMapSize : 2048;
        this.shadowBias = data.shadowBias ? data.shadowBias : 0.000001;
        this.lightDirection = data.lightDirection ? data.lightDirection : new Vector3(1, -1, 1).normalize();
        this.lightIntensity = data.lightIntensity ? data.lightIntensity : 3;
        this.lightNear = data.lightNear ? data.lightNear : 1;
        this.lightFar = data.lightFar ? data.lightFar : 2000;
        this.lightMargin = data.lightMargin ? data.lightMargin : 200;
        this.customSplitsCallback = data.customSplitsCallback;
        this.fade = false;
        this.mainFrustum = new CSMFrustum();
        this.frustums = [];
        this.breaks = [];
        this.lights = [];
        this.shaders = new Map();
        this.createLights();
        this.updateFrustums();
        this.injectInclude();
    }

    private function createLights():Void {
        for (i in 0...this.cascades) {
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

    private function initCascades():Void {
        this.camera.updateProjectionMatrix();
        this.mainFrustum.setFromProjectionMatrix(this.camera.projectionMatrix, this.maxFar);
        this.mainFrustum.split(this.breaks, this.frustums);
    }

    private function updateShadowBounds():Void {
        for (i in 0...this.frustums.length) {
            var light = this.lights[i];
            var shadowCam = light.shadow.camera;
            var frustum = this.frustums[i];
            var nearVerts = frustum.vertices.near;
            var farVerts = frustum.vertices.far;
            var point1 = farVerts[0];
            var point2;
            if (point1.distanceTo(farVerts[2]) > point1.distanceTo(nearVerts[2])) {
                point2 = farVerts[2];
            } else {
                point2 = nearVerts[2];
            }
            var squaredBBWidth = point1.distanceTo(point2);
            if (this.fade) {
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

    private function getBreaks():Void {
        var camera = this.camera;
        var far = Math.min(camera.far, this.maxFar);
        this.breaks.length = 0;
        switch (this.mode) {
            case 'uniform':
                uniformSplit(this.cascades, camera.near, far, this.breaks);
                break;
            case 'logarithmic':
                logarithmicSplit(this.cascades, camera.near, far, this.breaks);
                break;
            case 'practical':
                practicalSplit(this.cascades, camera.near, far, 0.5, this.breaks);
                break;
            case 'custom':
                if (this.customSplitsCallback === null) trace('CSM: Custom split scheme callback not defined.');
                this.customSplitsCallback(this.cascades, camera.near, far, this.breaks);
                break;
        }
    }

    private function update():Void {
        var camera = this.camera;
        var frustums = this.frustums;
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

    private function injectInclude():Void {
        ShaderChunk.lights_fragment_begin = CSMShader.lights_fragment_begin;
        ShaderChunk.lights_pars_begin = CSMShader.lights_pars_begin;
    }

    private function setupMaterial(material:Dynamic):Void {
        material.defines = material.defines ? material.defines : {};
        material.defines.USE_CSM = 1;
        material.defines.CSM_CASCADES = this.cascades;
        if (this.fade) {
            material.defines.CSM_FADE = '';
        }
        var breaksVec2 = [];
        var scope = this;
        var shaders = this.shaders;
        material.onBeforeCompile = function(shader) {
            var far = Math.min(scope.camera.far, scope.maxFar);
            scope.getExtendedBreaks(breaksVec2);
            shader.uniforms.CSM_cascades = { value: breaksVec2 };
            shader.uniforms.cameraNear = { value: scope.camera.near };
            shader.uniforms.shadowFar = { value: far };
            shaders.set(material, shader);
        };
        shaders.set(material, null);
    }

    private function updateUniforms():Void {
        var far = Math.min(this.camera.far, this.maxFar);
        var shaders = this.shaders;
        shaders.forEach(function(shader, material) {
            if (shader !== null) {
                var uniforms = shader.uniforms;
                this.getExtendedBreaks(uniforms.CSM_cascades.value);
                uniforms.cameraNear.value = this.camera.near;
                uniforms.shadowFar.value = far;
            }
            if (!this.fade && 'CSM_FADE' in material.defines) {
                delete material.defines.CSM_FADE;
                material.needsUpdate = true;
            } else if (this.fade && !('CSM_FADE' in material.defines)) {
                material.defines.CSM_FADE = '';
                material.needsUpdate = true;
            }
        }, this);
    }

    private function getExtendedBreaks(target:Array<Vector2>):Void {
        while (target.length < this.breaks.length) {
            target.push(new Vector2());
        }
        target.length = this.breaks.length;
        for (i in 0...this.cascades) {
            var amount = this.breaks[i];
            var prev = this.breaks[i - 1] ? this.breaks[i - 1] : 0;
            target[i].x = prev;
            target[i].y = amount;
        }
    }

    private function updateFrustums():Void {
        this.getBreaks();
        this.initCascades();
        this.updateShadowBounds();
        this.updateUniforms();
    }

    public function remove():Void {
        for (i in 0...this.lights.length) {
            this.parent.remove(this.lights[i].target);
            this.parent.remove(this.lights[i]);
        }
    }

    public function dispose():Void {
        var shaders = this.shaders;
        shaders.forEach(function(shader, material) {
            delete material.onBeforeCompile;
            delete material.defines.USE_CSM;
            delete material.defines.CSM_CASCADES;
            delete material.defines.CSM_FADE;
            if (shader !== null) {
                delete shader.uniforms.CSM_cascades;
                delete shader.uniforms.cameraNear;
                delete shader.uniforms.shadowFar;
            }
            material.needsUpdate = true;
        });
        shaders.clear();
    }
}