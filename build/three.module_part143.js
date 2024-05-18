class BooleanKeyframeTrack extends KeyframeTrack {

	// No interpolation parameter because only InterpolateDiscrete is valid.
	constructor( name, times, values ) {

		super( name, times, values );

	}

}