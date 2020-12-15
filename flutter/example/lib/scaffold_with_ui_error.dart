import 'package:flutter/material.dart';

class ScaffoldWithUiError extends StatelessWidget {
  static Future<void> open(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute<void>(
        settings:
            const RouteSettings(name: 'SecondaryScaffold', arguments: 'foobar'),
        builder: (context) {
          return ScaffoldWithUiError();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SecondaryScaffold'),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: 500,
              width: 300,
              child: Builder(builder: (context) {
                // Causes this error:
                // https://flutter.dev/docs/testing/common-errors#a-renderflex-overflowed
                return Container(
                  child: Row(
                    children: [
                      Icon(Icons.message),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Title",
                              style: Theme.of(context).textTheme.headline4),
                          Text(
                              "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed"
                              " do eiusmod tempor incididunt ut labore et dolore magna "
                              "aliqua. Ut enim ad minim veniam, quis nostrud "
                              "exercitation ullamco laboris nisi ut aliquip ex ea "
                              "commodo consequat."),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
            const Text(
              'You have added a navigation event '
              'to the crash reports breadcrumbs.',
            ),
            MaterialButton(
              child: const Text('Go back'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
