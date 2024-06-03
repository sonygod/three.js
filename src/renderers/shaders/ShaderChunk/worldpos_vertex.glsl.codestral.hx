class WorldPosVertexShader {
    static function getShaderCode():String {
        return '''
        #if defined( USE_ENVMAP ) || defined( DISTANCE ) || defined ( USE_SHADOWMAP ) || defined ( USE_TRANSMISSION ) || NUM_SPOT_LIGHT_COORDS > 0

            var worldPosition:Float = new Float(4);
            worldPosition[0] = transformed.x;
            worldPosition[1] = transformed.y;
            worldPosition[2] = transformed.z;
            worldPosition[3] = 1.0;

            #ifdef USE_BATCHING

                worldPosition = batchingMatrix.multiply(worldPosition);

            #endif

            #ifdef USE_INSTANCING

                worldPosition = instanceMatrix.multiply(worldPosition);

            #endif

            worldPosition = modelMatrix.multiply(worldPosition);

        #endif
        ''';
    }
}