import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/get_dashboard_use_case.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardUseCase _getDashboard;
  final DashboardRepository _repository;

  DashboardBloc({
    required GetDashboardUseCase getDashboard,
    required DashboardRepository repository,
  })  : _getDashboard = getDashboard,
        _repository = repository,
        super(const DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoad);
    on<DashboardRefreshRequested>(_onRefresh);
    on<DashboardLocationToggled>(_onLocationToggled);
  }

  Future<void> _onLoad(
    DashboardLoadRequested _,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    final result = await _getDashboard();
    result.fold(
      (failure) => emit(DashboardError(failure.message)),
      (dashboard) => emit(DashboardLoaded(dashboard)),
    );
  }

  Future<void> _onRefresh(
    DashboardRefreshRequested _,
    Emitter<DashboardState> emit,
  ) async {
    final result = await _getDashboard();
    result.fold(
      (failure) => emit(DashboardError(failure.message)),
      (dashboard) => emit(DashboardLoaded(dashboard)),
    );
  }

  Future<void> _onLocationToggled(
    DashboardLocationToggled event,
    Emitter<DashboardState> emit,
  ) async {
    final result = await _repository.toggleLocationSharing(event.enabled);
    result.fold(
      (failure) => emit(DashboardError(failure.message)),
      (_) {
        if (state is DashboardLoaded) {
          // Reload to reflect updated state
          add(const DashboardRefreshRequested());
        }
      },
    );
  }
}
