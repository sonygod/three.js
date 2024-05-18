package three.js.examples.jsm.csm;

import three.Vector2;
import three.Vector3;
import three.DirectionalLight;
import three.MathUtils;
import three.ShaderChunk;
import three.Matrix4;
import three.Box3;

class CSM {
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

    private var _cameraToLightMatrix:Matrix4;
    private var _lightSpaceFrustum:CSMFrustum;
    private var _center:Vector3;
    private var _bbox:Box3;
    private var _uniformArray:Array<Float>;
    private var _logArray:Array<Float>;
    private var _lightOrientationMatrix:Matrix4;
    private var _lightOrientationMatrixInverse:Matrix4;
    private var _up:Vector3;

    public function new(data:Dynamic) {
        camera = data.camera;
        parent = data.parent;
        cascades = data.cascades || 3;
        maxFar = data.maxFar || 100000;
        mode = data.mode || 'practical';
        shadowMapSize = data.shadowMapSize || 2048;
        shadowBias = data.shadowBias || 0.000001;
        lightDirection = data.lightDirection || new Vector3(1, -1, 1).normalize();
        lightIntensity = data.lightIntensity || 3;
        lightNear = data.lightNear || 1;
        lightFar = data.lightFar || 2000;
        lightMargin = data.lightMargin || 200;
        customSplitsCallback = data.customSplitsCallback;
        fade = false;
        mainFrustum = new CSMFrustum();
        frustums = [];
        breaks = [];
        lights = [];
        shaders = new Map();

        createLights();
        updateFrustums();
        injectInclude();
    }

    private function createLights():Void {
        for (i in 0...cascades) {
            var light = new DirectionalLight(0xffffff, lightIntensity);
            light.castShadow = true;
            light.shadow.mapSize.width = shadowMapSize;
            light.shadow.mapSize.height = shadowMapSize;
            light.shadow.camera.near = lightNear;
            light.shadow.camera.far = lightFar;
            light.shadow.bias = shadowBias;
            parent.add(light);
            parent.add(light.target);
            lights.push(light);
        }
    }

    private function initCascades():Void {
        camera.updateProjectionMatrix();
        mainFrustum.setFromProjectionMatrix(camera.projectionMatrix, maxFar);
        mainFrustum.split(breaks, frustums);
    }

    private function updateShadowBounds():Void {
        for (i in 0...frustums.length) {
            var light = lights[i];
            var shadowCam = light.shadow.camera;
            var frustum = frustums[i];
            var nearVerts = frustum.vertices.near;
            var farVerts = frustum.vertices.far;
            var point1 = farVerts[0];
            var point2:Vector3;
            if (point1.distanceTo(farVerts[2]) > point1.distanceTo(nearVerts[2])) {
                point2 = farVerts[2];
            } else {
                point2 = nearVerts[2];
            }
            var squaredBBWidth = point1.distanceTo(point2);
            if (fade) {
                var camera = this.camera;
                var far = Math.max(camera.far, maxFar);
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
        var far = Math.min(camera.far, maxFar);
        breaks.length = 0;
        switch (mode) {
            case 'uniform':
                uniformSplit(cascades, camera.near, far, breaks);
                break;
            case 'logarithmic':
                logarithmicSplit(cascades, camera.near, far, breaks);
                break;
            case 'practical':
                practicalSplit(cascades, camera.near, far, 0.5, breaks);
                break;
            case 'custom':
                if (customSplitsCallback == null) {
                    console.error('CSM: Custom split scheme callback not defined.');
                }
                customSplitsCallback(cascades, camera.near, far, breaks);
                break;
        }
    }

    private function update():Void {
        var camera = this.camera;
        var frustums = this.frustums;
        _lightOrientationMatrix.lookAt(new Vector3(), lightDirection, _up);
        _lightOrientationMatrixInverse.copy(_lightOrientationMatrix).invert();
        for (i in 0...frustums.length) {
            var light = lights[i];
            var shadowCam = light.shadow.camera;
            var texelWidth = (shadowCam.right - shadowCam.left) / shadowMapSize;
            var texelHeight = (shadowCam.top - shadowCam.bottom) / shadowMapSize;
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
            _center.z = _bbox.max.z + lightMargin;
            _center.x = Math.floor(_center.x / texelWidth) * texelWidth;
            _center.y = Math.floor(_center.y / texelHeight) * texelHeight;
            _center.applyMatrix4(_lightOrientationMatrix);
            light.position.copy(_center);
            light.target.position.copy(_center);
            light.target.position.x += lightDirection.x;
            light.target.position.y += lightDirection.y;
            light.target.position.z += lightDirection.z;
        }
    }

    private function injectInclude():Void {
        ShaderChunk.lights_fragment_begin = CSMShader.lights_fragment_begin;
        ShaderChunk.lights_pars_begin = CSMShader.lights_pars_begin;
    }

    private function setupMaterial(material:Dynamic):Void {
        material.defines = material.defines || {};
        material.defines.USE_CSM = 1;
        material.defines.CSM_CASCADES = cascades;
        if (fade) {
            material.defines.CSM_FADE = '';
        }
        var breaksVec2:Array<Vector2> = [];
        var scope = this;
        var shaders = this.shaders;
        material.onBeforeCompile = function (shader) {
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
        var far = Math.min(camera.far, maxFar);
        var shaders = this.shaders;
        shaders.forEach(function (shader, material) {
            if (shader != null) {
                var uniforms = shader.uniforms;
                this.getExtendedBreaks(uniforms.CSM_cascades.value);
                uniforms.cameraNear.value = camera.near;
                uniforms.shadowFar.value = far;
            }
            if (!fade && 'CSM_FADE' in material.defines) {
                delete material.defines.CSM_FADE;
                material.needsUpdate = true;
            } else if (fade && !('CSM_FADE' in material.defines)) {
                material.defines.CSM_FADE = '';
                material.needsUpdate = true;
            }
        }, this);
    }

    private function getExtendedBreaks(target:Array<Vector2>):Void {
        while (target.length < breaks.length) {
            target.push(new Vector2());
        }
        target.length = breaks.length;
        for (i in 0...cascades) {
            var amount = breaks[i];
            var prev = breaks[i - 1] || 0;
            target[i].x = prev;
            target[i].y = amount;
        }
    }

    private function updateFrustums():Void {
        getBreaks();
        initCascades();
        updateShadowBounds();
        updateUniforms();
    }

    public function remove():Void {
        for (i in 0...lights.length) {
            parent.remove(lights[i].target);
            parent.remove(lights[i]);
        }
    }

    public function dispose():Void {
        var shaders = this.shaders;
        shaders.forEach(function (shader, material) {
            delete material.onBeforeCompile;
            delete material.defines.USE_CSM;
            delete material.defines.CSM_CASCADES;
            delete material.defines.CSM_FADE;
            if (shader != null) {
                delete shader.uniforms.CSM_cascades;
                delete shader.uniforms.cameraNear;
                delete shader.uniforms.shadowFar;
            }
            material.needsUpdate = true;
        });
        shaders.clear();
    }
}