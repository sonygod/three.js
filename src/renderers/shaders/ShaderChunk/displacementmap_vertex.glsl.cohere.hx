#if openfl_gl
#define USE_DISPLACEMENTMAP
#end

#{if USE_DISPLACEMENTMAP}

	transformed += normalize( objectNormal ) * ( texture2D( displacementMap, vDisplacementMapUv ).x * displacementScale + displacementBias );

#{endif}