import Light from './Light.js';

class AmbientLight extends Light {

    public function new(color, intensity) {
        super(color, intensity);

        this.isAmbientLight = true;

        this.type = 'AmbientLight';
    }

}

export type AmbientLight = AmbientLight;