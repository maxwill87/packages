// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'common.dart';
import 'constants.dart';
import 'legacy_datastore.dart';
import 'legacy_flutter.dart';

/// Convenient class to capture the benchmarks in the Flutter engine repo.
class FlutterEngineMetricPoint extends MetricPoint {
  /// Creates a metric point for the Flutter engine repository.
  ///
  /// The `name`, `value`, and `gitRevision` parameters must not be null.
  FlutterEngineMetricPoint(
    String name,
    double value,
    String gitRevision, {
    Map<String, String> moreTags = const <String, String>{},
  }) : super(
          value,
          <String, String>{
            kNameKey: name,
            kGithubRepoKey: kFlutterEngineRepo,
            kGitRevisionKey: gitRevision,
          }..addAll(moreTags),
        );
}

/// All Flutter performance metrics (framework, engine, ...) should be written
/// to this destination.
class FlutterDestination extends MetricDestination {
  // TODO(liyuqian): change the implementation of this class (without changing
  // its public APIs) to remove `LegacyFlutterDestination` and directly use
  // `SkiaPerfDestination` once the migration is fully done.
  FlutterDestination._(this._legacyDestination);

  /// Creates a [FlutterDestination] from service account JSON.
  static Future<FlutterDestination> makeFromCredentialsJson(
      Map<String, dynamic> json) async {
    final LegacyFlutterDestination legacyDestination =
        LegacyFlutterDestination(await datastoreFromCredentialsJson(json));
    return FlutterDestination._(legacyDestination);
  }

  /// Creates a [FlutterDestination] from an OAuth access token.
  static FlutterDestination makeFromAccessToken(
      String accessToken, String projectId) {
    final LegacyFlutterDestination legacyDestination = LegacyFlutterDestination(
        datastoreFromAccessToken(accessToken, projectId));
    return FlutterDestination._(legacyDestination);
  }

  @override
  Future<void> update(List<MetricPoint> points) async {
    await _legacyDestination.update(points);
  }

  final LegacyFlutterDestination _legacyDestination;
}
