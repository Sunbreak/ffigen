// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
import 'dart:ffi' as ffi;

/// Opaque Dependencies Test
class NativeLibrary {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  NativeLibrary(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  NativeLibrary.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  ffi.Pointer<B> func(
    ffi.Pointer<A> a,
  ) {
    return _func(
      a,
    );
  }

  late final _func_ptr = _lookup<ffi.NativeFunction<_c_func>>('func');
  late final _dart_func _func = _func_ptr.asFunction<_dart_func>();

  ffi.Pointer<UB> func2(
    ffi.Pointer<UA> a,
  ) {
    return _func2(
      a,
    );
  }

  late final _func2_ptr = _lookup<ffi.NativeFunction<_c_func2>>('func2');
  late final _dart_func2 _func2 = _func2_ptr.asFunction<_dart_func2>();
}

class B extends ffi.Opaque {}

class A extends ffi.Opaque {}

class C extends ffi.Opaque {}

class D extends ffi.Struct {
  @ffi.Int32()
  external int a;
}

class E extends ffi.Struct {
  external ffi.Pointer<C> c;

  external D d;
}

class UB extends ffi.Opaque {}

class UA extends ffi.Opaque {}

class UC extends ffi.Opaque {}

class UD extends ffi.Union {
  @ffi.Int32()
  external int a;
}

class UE extends ffi.Union {
  external ffi.Pointer<UC> c;

  external UD d;
}

typedef _c_func = ffi.Pointer<B> Function(
  ffi.Pointer<A> a,
);

typedef _dart_func = ffi.Pointer<B> Function(
  ffi.Pointer<A> a,
);

typedef _c_func2 = ffi.Pointer<UB> Function(
  ffi.Pointer<UA> a,
);

typedef _dart_func2 = ffi.Pointer<UB> Function(
  ffi.Pointer<UA> a,
);
