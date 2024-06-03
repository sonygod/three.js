#if USE_FOG

import js.html.WebGL.Float32Array;
import js.html.WebGL.Float32;

public var fogColor:Float32Array;
public var vFogDepth:Float;

#if FOG_EXP2

public var fogDensity:Float;

#else

public var fogNear:Float;
public var fogFar:Float;

#endif

#endif