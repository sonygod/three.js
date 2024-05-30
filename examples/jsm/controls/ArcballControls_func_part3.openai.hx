setAnimationCallback( callback : Void->Void ) : Void {
    this._animationCallback = callback;
}

get STATE() : Dynamic<String> {
    return STATE;
}

get STATE_PAN() : String {
    return STATE.PAN;
}

get STATE_ROTATE() : String {
    return STATE.ROTATE;
}

get STATE_ZOOM() : String {
    return STATE.SCALE;
}

get STATE_FOV() : String {
    return STATE.FOV;
}

get STATE_ZROTATE() : String {
    return STATE.ZROTATE;
}

get STATE_ANIMATION_ROTATE() : String {
    return STATE.ANIMATION_ROTATE;
}

get STATE_ANIMATION_FOCUS() : String {
    return STATE.ANIMATION_FOCUS;
}

get STATE_FOCUS() : String {
    return STATE.FOCUS;
}

get STATE_Scale() : String {
    return STATE.SCALE;
}

static var STATE : Dynamic<String> = {
    PAN: 'pan',
    ROTATE: 'rotate',
    ZOOM: 'zoom',
    FOC: 'fov',
    ZROTATE: 'zrotate',
    ANIMATION_ROTATE: 'animation_rotate',
    ANIMATION_FOCUS: 'animation_focus',
    FOCUS: 'focus',
    SCALE: 'scale'
};

//other variables and functions...