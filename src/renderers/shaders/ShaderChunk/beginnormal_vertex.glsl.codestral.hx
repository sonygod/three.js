var ShaderChunk:ShaderChunk = {
    beginnormal_vertex: "vec3 objectNormal = vec3( normal );\n\n#ifdef USE_TANGENT\n\n\tvec3 objectTangent = vec3( tangent.xyz );\n\n#endif\n"
};