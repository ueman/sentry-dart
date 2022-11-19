import 'package:flutter/material.dart';
import 'package:sentry/sentry.dart';

import '../sentry_flutter_options.dart';

/// Only works if there's a [Navigator] in the widget tree
void tryShowUserFeedback(SentryId id, UserFeedbackBuilder builder) {
  NavigatorState? navigator;

  void navigationFinder(Element element) {
    if (navigator != null) {
      return;
    }
    final context = element;
    if (context is StatefulElement && context.state is NavigatorState) {
      navigator = context.state as NavigatorState;
      return;
    }
    element.visitChildElements(navigationFinder);
  }

  WidgetsBinding.instance.renderViewElement
      ?.visitChildElements(navigationFinder);
  if (navigator != null) {
    showDialog(
      // TODO: Ignore in SentryNavigatorObserver?
      routeSettings: RouteSettings(name: 'SentryUserFeedbackDialog'),
      context: navigator!.context,
      builder: (context) {
        return builder(context, id);
      },
    );
  }
}