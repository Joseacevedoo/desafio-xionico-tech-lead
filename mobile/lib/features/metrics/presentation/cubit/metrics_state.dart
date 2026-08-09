import 'package:equatable/equatable.dart';

import '../../data/daily_metrics_model.dart';

enum MetricsStatus { initial, loading, success, failure }

class MetricsState extends Equatable {
  const MetricsState({
    this.status = MetricsStatus.initial,
    this.summary,
    this.message,
    this.sessionExpired = false,
  });

  final MetricsStatus status;
  final DailyMetricsModel? summary;
  final String? message;
  final bool sessionExpired;

  MetricsState copyWith({
    MetricsStatus? status,
    DailyMetricsModel? summary,
    String? message,
    bool sessionExpired = false,
  }) {
    return MetricsState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      message: message,
      sessionExpired: sessionExpired,
    );
  }

  @override
  List<Object?> get props => [status, summary, message, sessionExpired];
}
