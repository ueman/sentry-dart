import 'package:meta/meta.dart';

import '_io_get_isolate_name.dart'
    if (dart.library.js_interop) '_web_get_isolate_name.dart' as isolate_getter;

@internal
String? getIsolateName() => isolate_getter.getIsolateName();
