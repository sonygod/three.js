class OpaqueFragment {
    public static var code:String = #if OPAQUE
        diffuseColor.a = 1.0;
    #end

    #if USE_TRANSMISSION
        diffuseColor.a *= material.transmissionAlpha;
    #end

    gl_FragColor = vec4( outgoingLight, diffuseColor.a );
    #end;
}