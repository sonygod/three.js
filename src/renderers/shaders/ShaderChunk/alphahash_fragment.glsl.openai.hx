package three.shaderlib;

#if alphahash

if (diffuseColor.a < getAlphaHashThreshold(vPosition)) discard;

#end