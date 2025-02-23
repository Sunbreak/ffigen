// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:ffigen/src/code_generator.dart';

import 'binding.dart';
import 'binding_string.dart';
import 'type.dart';
import 'utils.dart';
import 'writer.dart';

/// A binding for C function.
///
/// For a C function -
/// ```c
/// int sum(int a, int b);
/// ```
/// The Generated dart code is -
/// ```dart
/// int sum(int a, int b) {
///   return _sum(a, b);
/// }
///
/// final _dart_sum _sum = _dylib.lookupFunction<_c_sum, _dart_sum>('sum');
///
/// typedef _c_sum = ffi.Int32 Function(ffi.Int32 a, ffi.Int32 b);
///
/// typedef _dart_sum = int Function(int a, int b);
/// ```
class Func extends LookUpBinding {
  final Type returnType;
  final List<Parameter> parameters;
  final bool exposeSymbolAddress;

  /// [originalName] is looked up in dynamic library, if not
  /// provided, takes the value of [name].
  Func({
    String? usr,
    required String name,
    String? originalName,
    String? dartDoc,
    required this.returnType,
    List<Parameter>? parameters,
    this.exposeSymbolAddress = false,
  })  : parameters = parameters ?? [],
        super(
          usr: usr,
          originalName: originalName,
          name: name,
          dartDoc: dartDoc,
        ) {
    for (var i = 0; i < this.parameters.length; i++) {
      if (this.parameters[i].name.trim() == '') {
        this.parameters[i].name = 'arg$i';
      }
    }
  }

  List<Typedef>? _typedefDependencies;
  @override
  List<Typedef> getTypedefDependencies(Writer w) {
    if (_typedefDependencies == null) {
      _typedefDependencies = <Typedef>[];

      // Add typedef's required by return type.
      final returnTypeBase = returnType.getBaseType();
      if (returnTypeBase.broadType == BroadType.NativeFunction) {
        _typedefDependencies!
            .addAll(returnTypeBase.nativeFunc!.getDependencies());
      }

      // Add typedef's required by parameters.
      for (final p in parameters) {
        final base = p.type.getBaseType();
        if (base.broadType == BroadType.NativeFunction) {
          _typedefDependencies!.addAll(base.nativeFunc!.getDependencies());
        }
      }
      // Add C function typedef.
      _typedefDependencies!.add(cType);
      // Add Dart function typedef.
      _typedefDependencies!.add(dartType);
    }
    return _typedefDependencies!;
  }

  Typedef? _cType, _dartType;
  Typedef get cType => _cType ??= Typedef(
        name: exposeSymbolAddress ? 'Native_$name' : '_c_$name',
        returnType: returnType,
        parameters: parameters,
        typedefType: TypedefType.C,
      );
  Typedef get dartType => _dartType ??= Typedef(
        name: '_dart_$name',
        returnType: returnType,
        parameters: parameters,
        typedefType: TypedefType.Dart,
      );

  @override
  BindingString toBindingString(Writer w) {
    final s = StringBuffer();
    final enclosingFuncName = name;
    final funcVarName = w.wrapperLevelUniqueNamer.makeUnique('_$name');
    final funcPointerName =
        w.wrapperLevelUniqueNamer.makeUnique('_${name}_ptr');

    if (dartDoc != null) {
      s.write(makeDartDoc(dartDoc!));
    }
    // Resolve name conflicts in function parameter names.
    final paramNamer = UniqueNamer({});
    for (final p in parameters) {
      p.name = paramNamer.makeUnique(p.name);
    }
    // Write enclosing function.
    if (w.dartBool && returnType.broadType == BroadType.Boolean) {
      // Use bool return type in enclosing function.
      s.write('bool $enclosingFuncName(\n');
    } else {
      s.write('${returnType.getDartType(w)} $enclosingFuncName(\n');
    }
    for (final p in parameters) {
      if (w.dartBool && p.type.broadType == BroadType.Boolean) {
        // Use bool parameter type in enclosing function.
        s.write('  bool ${p.name},\n');
      } else {
        s.write('  ${p.type.getDartType(w)} ${p.name},\n');
      }
    }
    s.write(') {\n');
    s.write('return $funcVarName');

    s.write('(\n');
    for (final p in parameters) {
      if (w.dartBool && p.type.broadType == BroadType.Boolean) {
        // Convert bool parameter to int before calling.
        s.write('    ${p.name}?1:0,\n');
      } else {
        s.write('    ${p.name},\n');
      }
    }
    if (w.dartBool && returnType.broadType == BroadType.Boolean) {
      // Convert int return type to bool.
      s.write('  )!=0;\n');
    } else {
      s.write('  );\n');
    }
    s.write('}\n');

    // Write function pointer.
    s.write(
        "late final $funcPointerName = ${w.lookupFuncIdentifier}<${w.ffiLibraryPrefix}.NativeFunction<${cType.name}>>('$originalName');\n");
    // Write function variable.
    s.write(
        'late final ${dartType.name} $funcVarName = $funcPointerName.asFunction<${dartType.name}>();\n\n');

    if (exposeSymbolAddress) {
      // Add to SymbolAddress in writer.
      w.symbolAddressWriter.addSymbol(
        type:
            '${w.ffiLibraryPrefix}.Pointer<${w.ffiLibraryPrefix}.NativeFunction<${cType.name}>>',
        name: name,
        ptrName: funcPointerName,
      );
    }
    return BindingString(type: BindingStringType.func, string: s.toString());
  }
}

/// Represents a Parameter, used in [Func] and [Typedef].
class Parameter {
  final String? originalName;
  String name;
  final Type type;

  Parameter({String? originalName, this.name = '', required Type type})
      : originalName = originalName ?? name,
        // A type with broadtype [BroadType.NativeFunction] is wrapped with a
        // pointer because this is a shorthand used in C for Pointer to function.
        type = type.broadType == BroadType.NativeFunction
            ? Type.pointer(type)
            : type;
}
