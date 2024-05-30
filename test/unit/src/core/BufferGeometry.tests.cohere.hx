import js.Browser.window;
import js.node.EventEmitter;
import js.node.Buffer;

class BufferGeometry {
    public function new() {
        // ...
    }
}

class BufferAttribute {
    public function new(array: Array<Float>, itemSize: Int) {
        // ...
    }
}

class Float16BufferAttribute {
    public function new(array: Array<Float>, itemSize: Int) {
        // ...
    }
}

class Uint16BufferAttribute {
    public function new(array: Array<Int>, itemSize: Int) {
        // ...
    }
}

class Uint32BufferAttribute {
    public function new(array: Array<Int>, itemSize: Int) {
        // ...
    }
}

class Vector3 {
    public function new(x: Float, y: Float, z: Float) {
        // ...
    }
}

class Matrix4 {
    public function new() {
        // ...
    }

    public function set(
        m1: Float, m2: Float, m3: Float, m4: Float,
        m5: Float, m6: Float, m7: Float, m8: Float,
        m9: Float, m10: Float, m11: Float, m12: Float,
        m13: Float, m14: Float, m15: Float, m16: Float
    ): Void {
        // ...
    }
}

class Quaternion {
    public function new(x: Float, y: Float, z: Float, w: Float) {
        // ...
    }
}

class Sphere {
    public function new(center: Vector3, radius: Float) {
        // ...
    }
}

class EventDispatcher {
    public function new() {
        // ...
    }
}

class DataUtils {
    public static function toHalfFloat(f: Float): Int {
        // ...
    }
}

class QUnit {
    public static function module(name: String, callback: Void->Void): Void {
        // ...
    }
}

class Math {
    public static var PI: Float;
}

class Std {
    public static function is(value: Dynamic, type: Type): Bool {
        // ...
    }
}

class Array<T> {
    public function slice(start: Int, ?end: Int): Array<T> {
        // ...
    }
}

class Float32Array {
    public function new(?array: Array<Float>) {
        // ...
    }
}

class Uint16Array {
    public function new(?array: Array<Int>) {
        // ...
    }
}

class Int {
    public static var MAX_SAFE_INTEGER: Int;
}

class Float {
    public static var EPSILON: Float;
}

class Bool {
    public static var debug: Bool = true;
}

class Void {
}

class Dynamic {
}

class Type {
}

class Int32Array {
    public function new(?array: Array<Int>) {
        // ...
    }
}

class StringBuf {
    public function new() {
        // ...
    }

    public function add(x: Dynamic): Void {
        // ...
    }

    public function toString(): String {
        // ...
    }
}

class Std {
    public static function string(value: Dynamic): String {
        // ...
    }
}

class EReg {
    public function new(pattern: String) {
        // ...
    }

    public function match(s: String): Dynamic {
        // ...
    }
}

class Array<T> {
    public function join(sep: String): String {
        // ...
    }
}

class String {
    public static function fromCharCode(code: Int): String {
        // ...
    }
}

class String {
    public function split(sep: String): Array<String> {
        // ...
    }
}

class Std {
    public static function parseInt(value: String): Int {
        // ...
    }
}

class Std {
    public static function parseFloat(value: String): Float {
        // ...
    }
}

class Array<T> {
    public function concat(other: Array<T>): Array<T> {
        // ...
    }
}

class Array<T> {
    public function map<U>(f: T->U): Array<U> {
        // ...
    }
}

class Array<T> {
    public function filter(f: T->Bool): Array<T> {
        // ...
    }
}

class Std {
    public static function is(value: Dynamic, type: Type): Bool {
        // ...
    }
}

class EReg {
    public function new(pattern: String) {
        // ...
    }

    public function match(s: String): Dynamic {
        // ...
    }
}

class String {
    public function split(sep: String): Array<String> {
        // ...
    }
}

class Std {
    public static function parseInt(value: String): Int {
        // ...
    }
}

class Std {
    public static function parseFloat(value: String): Float {
        // ...
    }
}

class Array<T> {
    public function concat(other: Array<T>): Array<T> {
        // ...
    }
}

class Array<T> {
    public function map<U>(f: T->U): Array<U> {
        // ...
    }
}

class Array<T> {
    public function filter(f: T->Bool): Array<T> {
        // ...
    }
}

class Std {
    public static function is(value: Dynamic, type: Type): Bool {
        // ...
    }
}

class EReg {
    public function new(pattern: String) {
        // ...
    }

    public function match(s: String): Dynamic {
        // ...
    }
}

class String {
    public function split(sep: String): Array<String> {
        // ...
    }
}

class Std {
    public static function parseInt(value: String): Int {
        // ...
    }
}

class Std {
    public static function parseFloat(value : String) : Float {
        // ...
    }
}

class Array<T> {
    public function concat(other: Array<T>): Array<T> {
        // ...
    }
}

class Array<T> {
    public function map<U>(f: T->U): Array<U> {
        // ...
    }
}

class Array<T> {
    public function filter(f: T->Bool): Array<T> {
        // ...
    }
}

class Std {
    public static function is(value: Dynamic, type: Type): Bool {
        // ...
    }
}

class EReg {
    public function new(pattern: String) {
        // ...
    }

    public function match(s: String): Dynamic {
        // ...
    }
}

class String {
    public function split(sep: String): Array<String> {
        // ...
    }
}

class Std {
    public static function parseInt(value: String): Int {
        // ...
    }
}

class Std {
    public static function parseFloat(value: String): Float {
        // ...
    }
}

class Array<T> {
    public function concat(other: Array<T>): Array<T> {
        // ...
    }
}

class Array<T> {
    public function map<U>(f: T->U): Array<U> {
        // ...
    }
}

class Array<T> {
    public function filter(f: T->Bool): Array<T> {
        // ...
    }
}

class Std {
    public static function is(value: Dynamic, type: Type): Bool {
        // ...
    }
}

class EReg {
    public function new(pattern: String) {
        // ...
    }

    public function match(s: String): Dynamic {
        // ...
    }
}

class String {
    public function split(sep: String): Array<String> {
        // ...
    }
}

class Std {
    public static function parseInt(value: String): Int {
        // ...
    }
}

class Std {
    public static function parseFloat(value: String): Float {
        // ...
    }
}

class Array<T> {
    public function concat(other: Array<T>): Array<T> {
        // ...
    }
}

class Array<T> {
    public function map<U>(f: T->U): Array<U> {
        // ...
    }
}

class Array<T> {
    public function filter(f: T->Bool): Array<T> {
        // ...
    }
}

class Std {
    public static function is(value: Dynamic, type: Type): Bool {
        // ...
    }
}

class EReg {
    public function new(pattern: String) {
        // ...
    }

    public function match(s: String): Dynamic {
        // ...
    }
}

class String {
    public function split(sep: String): Array<String> {
        // ...
    }
}

class Std {
    public static function parseInt(value: String): Int {
        // ...
    }
}

class Std {
    public static function parseFloat(value: String): Float {
        // ...
    }
}

class Array<T> {
    public function concat(other: Array<T>): Array<T> {
        // ...
    }
}

class Array<T> {
    public function map<U>(f: T->U): Array<U> {
        // ...
    }
}

class Array<T> {
    public function filter(f: T->Bool): Array<T> {
        // ...
    }
}

class Std {
    public static function is(value: Dynamic, type: Type): Bool {
        // ...
    }
}

class EReg {
    public function new(pattern: String) {
        // ...
    }

    public function match(s: String): Dynamic {
        // ...
    }
}

class String {
    public function split(sep: String): Array<String> {
        // ...
    }
}

class Std {
    public static function parseInt(value: String): Int {
        // ...
    }
}

class Std {
    public static function parseFloat(value: String): Float {
        // ...
    }
}

class Array<T> {
    public function concat(other: Array<T>): Array<T> {
        // ...
    }
}

class Array<T> {
    public function map<U>(f: T->U): Array<U> {
        // ...
    }
}

class Array<T> {
    public function filter(f: T->Bool): Array<T> {
        // ...
    }
}

class Std {
    public static function is(value: Dynamic, type: Type): Bool {
        // ...
    }
}

class EReg {
    public function new(pattern: String) {
        // ...
    }

    public function match(s: String): Dynamic {
        // ...
    }
}

class String {
    public function split(sep: String): Array<String> {
        // ...
    }
}

class Std {
    public static function parseInt(value: String): Int {
        // ...
    }
}

class Std {
    public static function parseFloat(value: String): Float {
        // ...
    }
}

class Array<T> {
    public function concat(other: Array<T>): Array<T> {
        // ...
    }
}

class Array<T> {
    public function map<U>(f: T->U): Array<U> {
        // ...
    }
}

class Array<T> {
    public function filter(f: T->Bool): Array<T> {
        // ...
    }
}

class Std {
    public static function is(value: Dynamic, type: Type): Bool {
        // ...
    }
}

class EReg {
    public function new(pattern: String) {
        // ...
    }

    public function match(s: String): Dynamic {
        // ...
    }
}

class String {
    public function split(sep: String): Array<String> {
        // ...
    }
}

class Std {
    public static function parseInt(value: String): Int {
        // ...
    }
}

class Std {
    public static function parseFloat(value: String): Float {
        // ...
    }
}

class Array<T> {
    public function concat(other: Array<T>): Array<T> {
        // ...
    }
}

class Array<T> {
    public function map<U>(f: T->U): Array<U> {
        // ...
    }
}

class Array<T> {
    public function filter(f: T->Bool): Array<T> {
        // ...
    }
}

class Std {
    public static function is(value: Dynamic, type: Type): Bool {
        // ...
    }
}

class EReg {
    public function new(pattern: String) {
        // ...
    }

    public function match(s: String): Dynamic {
        // ...
    }
}

class String {
    public function split(sep: String): Array<String> {
        // ...
    }
}

class Std {
    public static function parseInt(value: String): Int {
        // ...
    }
}

class Std {
    public static function parseFloat(value: String): Float {
        // ...
    }
}

class Array<T> {
    public function concat(other: Array<T>): Array<T> {
        // ...
    }
}

class Array<T> {
    public function map<U>(f: T->U): Array<U> {
        // ...
    }
}

class Array<T> {
    public function filter(f: T->Bool): Array<T> {
        // ...
    }
}

class Std {
    public static function is(value: Dynamic, type: Type): Bool {
        // ...
    }
}

class EReg {
    public function new(pattern: String) {
        // ...
    }

    public function match(s: String): Dynamic {
        // ...
    }
}

class String {
    public function split(sep: String): Array<String> {
        // ...
    }
}

class Std {
    public static function parseInt(value: String): Int {
        // ...
    }
}

class Std {
    public static function parseFloat(value: String): Float {
        // ...
    }
}

class Array<T> {
    public function concat(other: Array<T>): Array<T> {
        // ...
    }
}

class Array<T> {
    public function map<U>(f: T->U): Array<U> {
        // ...
    }
}

class Array<T> {
    public function filter(f: T->Bool): Array<T> {
        // ...
    }
}

class Std {
    public static function is(value: Dynamic, type: Type): Bool {
        // ...
    }
}

class EReg {
    public function new(pattern: String) {
        // ...
    }

    public function match(s: String): Dynamic {
        // ...
    }
}

class String {
    public function split(sep: String): Array<String> {
        // ...
    }
}

class Std {
    public static function parseInt(value: String): Int {
        // ...
    }
}

class Std {
    public static function parseFloat(value: String): Float {
        // ...
    }
}

class Array<T> {
    public function concat(other: Array<T>): Array<T> {
        // ...
    }
}

class Array<T> {
    public function map<U>(f: T->U): Array<U> {
        // ...
    }
}

class Array<T> {
    public function filter(f: T->Bool): Array<T> {
        // ...
    }
}

class Std {
    public static function is(value: Dynamic, type: Type): Bool {
        // ...
    }
}

class EReg {
    public function new(pattern: String) {
        // ...
    }

    public function match(s: String): Dynamic {
        // ...
    }
}

class String {
    public function split(sep: String): Array<String> {
        // ...
    }
}

class Std {
    public static function parseInt(value: String): Int {
        // ...
    }
}

class Std {
    public static function parseFloat(value: String): Float {
        // ...
    }
}

class Array<T> {
    public function concat(other: Array<T>): Array<T> {
        // ...
    }
}

class Array<T> {
    public function map<U>(f: T->U): Array<U> {
        // ...
    }
}

class Array<T> {
    public function filter(f: T->Bool): Array<T> {
        // ...
    }
}

class Std {
    public static function is(value: Dynamic, type: Type): Bool {
        // ...
    }
}

class EReg {
    public function new(pattern: String) {
        // ...
    }

    public function match(s: String): Dynamic {
        // ...
    }
}

class String {
    public function split(sep: String): Array<String> {
        // ...
    }
}

class Std {
    public static function parseInt(value: String): Int {
        // ...
    }
}

class Std {
    public