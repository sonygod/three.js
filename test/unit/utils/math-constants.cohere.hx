import Math.*;

@:enum(Int)
export class Const {
    static var X = 2;
    static var Y = 3;
    static var Z = 4;
    static var W = 5;

    static inline var NegInf2 = { get_x: $inline "$$this.x = -Infinity;", get_y: $inline "$$this.y = -Infinity;" };
    static inline var PosInf2 = { get_x: $inline "$$this.x = Infinity;", get_y: $inline "$$this.y = Infinity;" };

    static inline var NegOne2 = { get_x: $inline "$$this.x = -1;", get_y: $inline "$$this.y = -1;" };

    static inline var Zero2 = { get_x: $inline "$$this.x = 0;", get_y: $inline "$$this.y = 0;" };
    static inline var One2 = { get_x: $inline "$$this.x = 1;", get_y: $inline "$$this.y = 1;" };
    static inline var Two2 = { get_x: $inline "$$this.x = 2;", get_y: $inline "$$this.y = 2;" };

    static inline var NegInf3 = { get_x: $inline "$$this.x = -Infinity;", get_y: $inline "$$this.y = -Infinity;", get_z: $inline "$$this.z = -Infinity;" };
    static inline var PosInf3 = { get_x: $inline "$$this.x = Infinity;", get_y: $inline "$$this.y = Infinity;", get_z: $inline "$$this.z = Infinity;" };

    static inline var Zero3 = { get_x: $inline "$$this.x = 0;", get_y: $inline "$$this.y = 0;", get_z: $inline "$$this.z = 0;" };
    static inline var One3 = { get_x: $inline "$$this.x = 1;", get_y: $inline "$$this.y = 1;", get_z: $inline "$$this.z = 1;" };
    static inline var Two3 = { get_x: $inline "$$this.x = 2;", get_y: $inline "$$this.y = 2;", get_z: $inline "$$this.z = 2;" };

    static var Eps = 0.0001;
}