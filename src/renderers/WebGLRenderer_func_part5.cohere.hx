import js from "js-lib";

class WebGLRenderer {
  public function new() {
    ...
  }

  public function setSize(width:Int, height:Int):Void {
    ...
  }

  public function render(scene:Scene, camera:Camera):Void {
    ...
  }

  public function setRenderTarget(renderTarget:WebGLRenderTarget):Void {
    ...
  }

  public function readRenderTargetPixels(
    renderTarget:WebGLRenderTarget,
    x:Int,
    y:Int,
    width:Int,
    height:Int,
    buffer:ArrayBufferView,
    activeCubeFaceIndex:Int
  ):Void {
    ...
  }

  public function copyFramebufferToTexture(
    texture:Texture,
    position:Vector2,
    level:Int
  ):Void {
    ...
  }

  public function copyTextureToTexture(
    srcTexture:Texture,
    dstTexture:Texture,
    srcRegion:Box2,
    dstPosition:Vector2,
    level:Int
  ):Void {
    ...
  }

  public function copyTextureToTexture3D(
    srcTexture:Texture,
    dstTexture:Texture,
    srcRegion:Box3,
    dstPosition:Vector3,
    level:Int
  ):Void {
    ...
  }

  public function initRenderTarget(target:WebGLRenderTarget):Void {
    ...
  }

  public function initTexture(texture:Texture):Void {
    ...
  }

  public function resetState():Void {
    ...
  }

  public function get outputColorSpace():String {
    ...
  }

  public function set outputColorSpace(colorSpace:String):Void {
    ...
  }

  public function get useLegacyLights():Bool {
    ...
  }

  public function set useLegacyLights(value:Bool):Void {
    ...
  }

  public function get coordinateSystem():WebGLCoordinateSystem {
    ...
  }
}

class WebGLRenderer_Methods {
  public static function markUniformsLightsNeedsUpdate(
    uniforms:Dynamic,
    value:Bool
  ):Void {
    ...
  }

  public static function materialNeedsLights(material:Material):Bool {
    ...
  }

  public static function getActiveCubeFace():Int {
    ...
  }

  public static function getActiveMipmapLevel():Int {
    ...
  }

  public static function getRenderTarget():WebGLRenderTarget {
    ...
  }

  public static function setRenderTargetTextures(
    renderTarget:WebGLRenderTarget,
    colorTexture:WebGLTexture,
    depthTexture:WebGLTexture
  ):Void {
    ...
  }

  public static function setRenderTargetFramebuffer(
    renderTarget:WebGLRenderTarget,
    defaultFramebuffer:WebGLFramebuffer
  ):Void {
    ...
  }

  public static function setRenderTarget(
    renderTarget:WebGLRenderTarget,
    activeCubeFace:Int,
    activeMipmapLevel:Int
  ):Void {
    ...
  }

  public static function readRenderTargetPixelsAsync(
    renderTarget:WebGLRenderTarget,
    x:Int,
    y:Int,
    width:Int,
    height:Int,
    buffer:ArrayBufferView,
    activeCubeFaceIndex:Int
  ):Void {
    ...
  }
}

class WebGLRenderer_Statics {
  public static var _currentActiveCubeFace:Int;
  public static var _currentActiveMipmapLevel:Int;
  public static var _currentRenderTarget:WebGLRenderTarget;
  public static var _currentViewport:Vector4;
  public static var _currentScissor:Vector4;
  public static var _currentScissorTest:Bool;
  public static var _currentMaterialId:Int;
  public static var _currentWidth:Int;
  public static var _currentHeight:Int;
  public static var _currentPixelRatio:Float;
  public static var _currentRenderer:WebGLRenderer;
  public static var _currentCamera:Camera;
  public static var _currentProgram:WebGLProgram;
  public static var _currentGeometryGroupHash:Int;
  public static var _currentMaterial:Material;
  public static var _currentMaterialProperties:Dynamic;
  public static var _currentGeometry:BufferGeometry;
  public static var _currentGeometryGroup:Int;
  public static var _currentRenderState:Dynamic;
  public static var _currentLineWidth:Float;
  public static var _currentPolygonOffsetFactor:Float;
  public static var _currentPolygonOffsetUnits:Float;
  public static var _allocatedTextureUnits:Int;
  public static var _currentTextureUnit:Int;
  public static var _currentBoundTextures:Array<WebGLTexture>;
  public static var _currentTexture:Texture;
  public static var _currentTextureSlot:Int;
  public static var _currentWrapS:Int;
  public static var _currentWrapT:Int;
  public static var _currentWrapR:Int;
  public static var _currentMagFilter:Int;
  public static var _currentMinFilter:Int;
  public static var _currentAnisotropy:Int;
  public static var _currentFormat:Int;
  public static var _currentType:Int;
  public static var _currentFlipY:Bool;
  public static var _currentPremultiplyAlpha:Bool;
  public static var _currentUnpackAlignment:Int;
  public static var _currentUnpackColorspaceConversion:Int;
  public static var _currentUnpackFlipY:Bool;
  public static var _currentUnpackPremultiplyAlpha:Bool;
  public static var _currentUnpackSkipPixels:Int;
  public static var _currentUnpackSkipRows:Int;
  public static var _currentUnpackSkipImages:Int;
  public static var _currentPixelUnpackBuffer:ArrayBufferView;
  public static var _currentPixelPackBuffer:ArrayBufferView;
  public static var _currentFramebuffer:WebGLFramebuffer;
  public static var _currentDrawBuffers:Dynamic;
  public static var _currentReadBuffer:Int;
  public static var _currentDepthTexture:WebGLTexture;
  public static var _currentDepthRenderbuffer:WebGLRenderbuffer;
  public static var _currentDepthTextureType:Int;
  public static var _currentDepthTextureFormat:Int;
  public static var _currentStencilTexture:WebGLTexture;
  public static var _currentStencilRenderbuffer:WebGLRenderbuffer;
  public static var _currentStencilTextureFormat:Int;
  public static var _currentStencilTextureType:Int;
  public static var _currentDepthStencilTexture:WebGLTexture;
  public static var _currentDepthStencilRenderbuffer:WebGLRenderbuffer;
  public static var _currentDepthStencilTextureFormat:Int;
  public static var _currentDepthStencilTextureType:Int;
  public static var _currentCompressedTextureFormats:Array<Int>;
  public static var _currentBoundUniforms:Dynamic;
  public static var _currentAttributes:Dynamic;
  public static var _currentElements:Dynamic;
  public static var _currentArrayCamera:ArrayCamera;
  public static var _currentArrayCameraProjectionMatrix:Float32Array;
  public static var _currentArrayCameraWorldMatrix:Float32Array;
  public static var _currentArrayCameraNormalMatrix:Float32Array;
  public static var _currentArrayCameraMatrixWorldInverse:Float32Array;
  public static var _currentArrayCameraViewProjectionMatrix:Float32Array;
  public static var _currentArrayCameraWorldMatrixInverse:Float32Array;
  public static var _currentArrayCameraFrustum:Float32Array;
  public static var _currentArrayCameraWorldMatrixArray:Float32Array;
  public static var _currentArrayCameraNormalMatrixArray:Float32Array;
  public static var _currentArrayCameraProjectionMatrixArray:Float32Array;
  public static var _currentArrayCameraViewProjectionMatrixArray:Float32Array;
  public static var _currentArrayCameraWorldMatrixInverseArray:Float32Array;
  public static var _currentArrayCameraFrustumArray:Float32Array;
  public static var _currentArrayLight:ArrayLight;
  public static var _currentArrayLightColor:Float32Array;
  public static var _currentArrayLightPosition:Float32Array;
  public static var _currentArrayLightDirection:Float32Array;
  public static var _currentArrayLightDistance:Float32Array;
  public static var _currentArrayLightIntensity:Float32Array;
  public static var _currentArrayLightShadow:Float32Array;
  public static var _currentArrayLightShadowBias:Float32Array;
  public static var _currentArrayLightShadowRadius:Float32Array;
  public static var _currentArrayLightShadowMapSize:Float32Array;
  public static var _currentArrayLightShadowCameraNear:Float32Array;
  public static var _currentArrayLightShadowCameraFar:Float32Array;
  public static var _currentArrayLightShadowCameraVisible:Float32Array;
  public static var _currentArrayLightShadowCameraPosition:Float32Array;
  public static var _currentArrayLightShadowCameraUp:Float32Array;
  public static var _currentArrayLightShadowCameraTarget:Float32Array;
  public static var _currentArrayLightShadowCameraLeft:Float32Array;
  public static var _currentArrayLightShadowCameraRight:Float32Array;
  public static var _currentArrayLightShadowCameraBottom:Float32Array;
  public static var _currentArrayLightShadowCameraTop:Float32Array;
  public static var _currentArrayLightShadowMatrix:Float32Array;
  public static var _currentArrayLightShadowMatrixArray:Float32Array;
  public static var _currentArrayLightShadowCamera:Array<Camera>;
  public static var _currentArrayLightShadowMap:Array<WebGLTexture>;
  public static var _currentArrayLightShadowMapSize:Array<Vector2>;
  public static var _currentArrayLightShadowCameraNearArray:Array<Float>;
  public static var _currentArrayLightShadowCameraFarArray:Array<Float>;
  public static var _currentArrayLightShadowCameraVisibleArray:Array<Bool>;
  public static var _currentArrayLightShadowCameraPositionArray:Array<Vector3>;
  public static var _currentArrayLightShadowCameraTargetArray:Array<Vector3>;
  public static var _currentArrayLightShadowCameraUpArray:Array<Vector3>;
  public static var _currentArrayLightShadowCameraLeftArray:Array<Float>;
  public static var _currentArrayLightShadowCameraRightArray:Array<Float>;
  public static var _currentArrayLightShadowCameraBottomArray:Array<Float>;
  public static var _currentArrayLightShadowCameraTopArray:Array<Float>;
  public static var _currentArrayLightShadowCameraProjectionMatrix:Float32Array;
  public static var _currentArrayLightShadowCameraProjectionMatrixArray:Float32Array;
  public static var _currentArrayLightShadowCameraViewMatrix:Float32Array;
  public static var _currentArrayLightShadowCameraViewMatrixArray:Float32Array;
  public static var _currentArrayLightShadowCameraInverseMatrix:Float32Array;
  public static var _currentArrayLightShadowCameraInverseMatrixArray:Float32Array;
  public static var _currentArrayPointLightPositions:Float32Array;
  public static var _currentArrayPointLightColors:Float32Array;
  public static var _currentArrayPointLightDecays:Float32Array;
  public static var _currentArrayPointLightDistances:Float32Array;
  public static var _currentArrayPointLightIntensities:Float32Array;
  public static var _currentArraySpotLightPositions:Float32Array;
  public static var _currentArraySpotLightDirections:Float32Array;
  public static var _currentArraySpotLightColors:Float32Array;
  public static var _currentArraySpotLightDistances:Float32Array;
  public static var _currentArraySpotLightAngles:Float32Array;
  public static var _currentArraySpotLightExponents:Float32Array;
  public static var _currentArraySpotLightDecays:Float32Array;
  public static var _currentArraySpotLightIntensities:Float32Array;
  public static var _currentArrayRectAreaLightPositions:Float32Array;
  public static var _currentArrayRectAreaLightColors:Float32Array;
  public static var _currentArrayRectAreaLightSizes:Float32Array;
  public static var _currentArrayHemisphereLightPositions:Float32Array;
  public static var _currentArrayHemisphereLightColors:Float32Array;
  public static var _currentArrayDirectionalLightDirections:Float32Array;
  public static var _currentArrayDirectionalLightColors:Float32Array;
  public static var _currentArrayDirectionalLightPositions:Float32Array;
  public static var _currentArrayDirectionalLightTargets:Float32Array;
  public static var _currentArrayDirectionalShadow:Float32Array;
  public static var _currentArrayDirectionalShadowBias:Float32Array;
  public static var _currentArrayDirectionalShadowRadius:Float32Array;
  public static var _currentArrayDirectionalShadowMapSize:Float32Array;
  public static var _currentArrayDirectionalShadowMatrix:Float32Array;
  public static var _currentArrayDirectionalShadowMatrixArray:Float32Array;
  public static var _currentArrayDirectionalShadowCamera:Array<Camera>;
  public static var _currentArrayDirectionalShadowMap:Array<WebGLTexture>;
  public static var _currentArrayDirectionalShadowMapSize:Array<Vector2>;
  public static var _currentArrayDirectionalShadowCameraNearArray:Array<Float>;
  public static var _currentArrayDirectionalShadowCameraFarArray:Array<Float>;
  public static var _currentArrayDirectionalShadowCameraVisibleArray:Array<Bool>;
  public static var _currentArrayDirectionalShadowCameraPositionArray:Array<Vector3>;
  public static var _currentArrayDirectionalShadowCameraTargetArray:Array<Vector3>;
  public static var _currentArrayDirectionalShadowCameraUpArray:Array<Vector3>;
  public static var _currentArrayDirectionalShadowCameraLeftArray:Array<Float>;
  public static var _currentArrayDirectionalShadowCameraRightArray:Array<Float>;
  public static var _currentArrayDirectionalShadowCameraBottomArray:Array<Float>;
  public static var _currentArrayDirectionalShadowCameraTopArray:Array<Float>;
  public static var _currentArrayDirectionalShadowCameraProjectionMatrix:Float32Array;
  public static var _currentArrayDirectionalShadowCameraProjectionMatrixArray:Float32Array;
  public static var _currentArrayDirectionalShadowCameraViewMatrix:Float32Array;
  public static var _currentArrayDirectionalShadowCameraViewMatrixArray:Float32Array;
  public static var _currentArrayDirectionalShadowCameraInverseMatrix:Float32Array;
  public static var _currentArrayDirectionalShadowCameraInverseMatrixArray:Float32Array;
  public static var _currentArraySkinIndices:Float32Array;
  public static var _currentArraySkinWeights:Float32Array;
  public static var _currentArrayDefaultAttributeValuesFloat32:Float32Array;
  public static var _currentArrayDefaultAttributeValuesInt16:Int16Array;
  public static var _currentArrayDefaultAttributeValuesInt32:Int32Array;
  public static var _currentArrayDefaultAttributeValuesUint32:Uint32Array;
  public static var _currentArrayVertex:Float32Array;
  public static var _currentArrayColor:Float32Array;
  public static var _currentColor:Float32Array;
  public static var _currentNormal:Float32Array;
  public static var _currentTangent:Float32Array;
  public static var _currentUV:Float32Array;
  public static var _currentUV2:Float32Array;
  public static var _currentUV3:Float32Array;
  public static var _currentUV4:Float32Array;
  public static var _currentUV5:Float32Array;
  public static var _currentUV6:Float32Array;
  public static var _currentUV7:Float32Array;
  public static var _currentUV8:Float32Array;
  public static var _currentPosition:Float32Array;
  public static var _currentScale:Float32Array;
  public static var _currentWeight:Float32Array;
  public static var _currentLineDistance:Float32Array;
  public static var _currentLineColor:Float32Array;
  public static var _currentPointSize:Float32Array;
  public static var _currentPointColor:Float32Array;
  public static var _currentPointDistance:Float32Array;
  public static var _currentModelMatrix:Float32Array;
  public static var _currentModelViewMatrix:Float32Array;
  public static var _currentNormalMatrix:Float32Array;
  public static var _currentViewMatrix:Float32Array;
  public static var _currentProjectionMatrix:Float32Array;
  public static var _currentModelViewProjectionMatrix:Float32Array;
  public static var _currentModelMatrixArray:Float32Array;
  public static var _currentModelViewMatrixArray:Float32Array;
  public static var _currentNormalMatrixArray:Float32Array;
  public static var _currentViewMatrixArray:Float32Array;
  public static var _currentProjectionMatrixArray:Float32Array;
  public static var _currentModelViewProjectionMatrixArray:Float32Array;
  public static var _currentLineWidth:Float32Array;
  public static var _currentLineDistanceArray:Float32Array;
  public static var _currentLineColorArray:Float32Array;
  public static var _currentPointSizeArray:Float32Array;
  public static var _currentPointColorArray:Float32Array;
  public static var _currentPointDistanceArray:Float32Array;
  public static var _currentFogDensity:Float;
  public static var _currentFogNear:Float;
  public static var _currentFogFar:Float;
  public static var _currentFogColor:Float32Array;
  public static var _currentFogType:Int;
  public static var _currentFogDensityArray:Float32Array;
  public static var _currentFogNearArray:Float32Array;
  public static var _currentFogFarArray:Float32Array;
  public static var _currentFogColorArray:Float32Array;
  public static var _currentFogTypeArray:Int32Array;
  public static var _currentShadowMatrix:Float32Array;
  public static var _currentShadowNormalBiasMatrix:Float32Array;
  public static var _currentShadowMatrixArray:Float3