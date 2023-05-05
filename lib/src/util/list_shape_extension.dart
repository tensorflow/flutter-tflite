/*
 * Copyright 2023 The TensorFlow Authors. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *             http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

extension ListShape on List {
  /// Reshape list to a another [shape]
  ///
  /// [T] is the type of elements in list
  ///
  /// Returns List<dynamic> if [shape.length] > 5
  /// else returns list with exact type
  ///
  /// Throws [ArgumentError] if number of elements for [shape]
  /// mismatch with current number of elements in list
  List reshape<T>(List<int> shape) {
    var dims = shape.length;
    var numElements = 1;
    for (var i = 0; i < dims; i++) {
      numElements *= shape[i];
    }

    if (numElements != computeNumElements) {
      throw ArgumentError(
          'Total elements mismatch expected: $numElements elements for shape: $shape but found $computeNumElements');
    }

    if (dims <= 5) {
      switch (dims) {
        case 2:
          return _reshape2<T>(shape);
        case 3:
          return _reshape3<T>(shape);
        case 4:
          return _reshape4<T>(shape);
        case 5:
          return _reshape5<T>(shape);
      }
    }

    var reshapedList = flatten<dynamic>();
    for (var i = dims - 1; i > 0; i--) {
      var temp = [];
      for (var start = 0;
          start + shape[i] <= reshapedList.length;
          start += shape[i]) {
        temp.add(reshapedList.sublist(start, start + shape[i]));
      }
      reshapedList = temp;
    }
    return reshapedList;
  }

  List<List<T>> _reshape2<T>(List<int> shape) {
    var flatList = flatten<T>();
    List<List<T>> reshapedList = List.generate(
      shape[0],
      (i) => List.generate(
        shape[1],
        (j) => flatList[i * shape[1] + j],
      ),
    );

    return reshapedList;
  }

  List<List<List<T>>> _reshape3<T>(List<int> shape) {
    var flatList = flatten<T>();
    List<List<List<T>>> reshapedList = List.generate(
      shape[0],
      (i) => List.generate(
        shape[1],
        (j) => List.generate(
          shape[2],
          (k) => flatList[i * shape[1] * shape[2] + j * shape[2] + k],
        ),
      ),
    );

    return reshapedList;
  }

  List<List<List<List<T>>>> _reshape4<T>(List<int> shape) {
    var flatList = flatten<T>();

    List<List<List<List<T>>>> reshapedList = List.generate(
      shape[0],
      (i) => List.generate(
        shape[1],
        (j) => List.generate(
          shape[2],
          (k) => List.generate(
            shape[3],
            (l) => flatList[i * shape[1] * shape[2] * shape[3] +
                j * shape[2] * shape[3] +
                k * shape[3] +
                l],
          ),
        ),
      ),
    );

    return reshapedList;
  }

  List<List<List<List<List<T>>>>> _reshape5<T>(List<int> shape) {
    var flatList = flatten<T>();
    List<List<List<List<List<T>>>>> reshapedList = List.generate(
      shape[0],
      (i) => List.generate(
        shape[1],
        (j) => List.generate(
          shape[2],
          (k) => List.generate(
            shape[3],
            (l) => List.generate(
              shape[4],
              (m) => flatList[i * shape[1] * shape[2] * shape[3] * shape[4] +
                  j * shape[2] * shape[3] * shape[4] +
                  k * shape[3] * shape[4] +
                  l * shape[4] +
                  m],
            ),
          ),
        ),
      ),
    );

    return reshapedList;
  }

  /// Get shape of the list
  List<int> get shape {
    if (isEmpty) {
      return [];
    }
    var list = this as dynamic;
    var shape = <int>[];
    while (list is List) {
      shape.add(list.length);
      list = list.elementAt(0);
    }
    return shape;
  }

  /// Flatten this list, [T] is element type
  /// if not specified List<dynamic> is returned
  List<T> flatten<T>() {
    var flat = <T>[];
    forEach((e) {
      if (e is List) {
        flat.addAll(e.flatten());
      } else if (e is T) {
        flat.add(e);
      } else {
        // Error with typing
      }
    });
    return flat;
  }

  /// Get the total number of elements in list
  int get computeNumElements {
    var n = 1;
    for (var i = 0; i < shape.length; i++) {
      n *= shape[i];
    }
    return n;
  }
}
