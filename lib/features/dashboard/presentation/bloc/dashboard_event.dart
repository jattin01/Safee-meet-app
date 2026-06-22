import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class DashboardLoadRequested extends DashboardEvent {
  const DashboardLoadRequested();
}

class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested();
}

class DashboardLocationToggled extends DashboardEvent {
  final bool enabled;
  const DashboardLocationToggled(this.enabled);
  @override
  List<Object?> get props => [enabled];
}
