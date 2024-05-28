@:glsl
class WorldPosVertex {
  #if (defined(USE_ENVMAP) || defined(DISTANCE) || defined(USE_SHADOWMAP) || defined(USE_TRANSMISSION) || NUM_SPOT_LIGHT_COORDS > 0)

  var worldPosition:Vec4 = vec4(transformed, 1.0);

  #ifdef USE_BATCHING
  worldPosition = batchingMatrix * worldPosition;
  #endif

  #ifdef USE_INSTANCING
  worldPosition = instanceMatrix * worldPosition;
  #endif

  worldPosition = modelMatrix * worldPosition;

  #end
}