import 'package:flutter/material.dart';

/// Global keys so actions can show dialogs / snackbars even after the widget
/// that triggered them has left the tree (e.g. a tile that moved sections).
final appNavigatorKey = GlobalKey<NavigatorState>();
final appMessengerKey = GlobalKey<ScaffoldMessengerState>();
