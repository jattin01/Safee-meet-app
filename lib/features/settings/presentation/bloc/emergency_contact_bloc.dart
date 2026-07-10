import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/emergency_contact_entity.dart';
import '../../domain/repositories/emergency_contact_repository.dart';

// ── Events ─────────────────────────────────────────────────────────────────
abstract class EmergencyContactEvent extends Equatable {
  const EmergencyContactEvent();
  @override
  List<Object?> get props => [];
}

class EmergencyContactsLoadRequested extends EmergencyContactEvent {
  const EmergencyContactsLoadRequested();
}

class EmergencyContactAddRequested extends EmergencyContactEvent {
  final String fullName;
  final String relationship;
  final String phoneNumber;

  const EmergencyContactAddRequested({
    required this.fullName,
    required this.relationship,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [fullName, relationship, phoneNumber];
}

class EmergencyContactDeleteRequested extends EmergencyContactEvent {
  final String contactId;
  const EmergencyContactDeleteRequested(this.contactId);

  @override
  List<Object?> get props => [contactId];
}

// ── States ─────────────────────────────────────────────────────────────────
abstract class EmergencyContactState extends Equatable {
  const EmergencyContactState();
  @override
  List<Object?> get props => [];
}

class EmergencyContactInitial extends EmergencyContactState {
  const EmergencyContactInitial();
}

class EmergencyContactLoading extends EmergencyContactState {
  const EmergencyContactLoading();
}

class EmergencyContactLoaded extends EmergencyContactState {
  final List<EmergencyContactEntity> contacts;
  final bool isSubmitting;

  const EmergencyContactLoaded(this.contacts, {this.isSubmitting = false});

  @override
  List<Object?> get props => [contacts, isSubmitting];
}

class EmergencyContactError extends EmergencyContactState {
  final String message;
  final List<EmergencyContactEntity> contacts;

  const EmergencyContactError(this.message, {this.contacts = const []});

  @override
  List<Object?> get props => [message, contacts];
}

// ── BLoC ───────────────────────────────────────────────────────────────────
class EmergencyContactBloc extends Bloc<EmergencyContactEvent, EmergencyContactState> {
  final EmergencyContactRepository _repository;

  EmergencyContactBloc(this._repository) : super(const EmergencyContactInitial()) {
    on<EmergencyContactsLoadRequested>(_onLoad);
    on<EmergencyContactAddRequested>(_onAdd);
    on<EmergencyContactDeleteRequested>(_onDelete);
  }

  List<EmergencyContactEntity> get _currentContacts {
    final s = state;
    if (s is EmergencyContactLoaded) return s.contacts;
    if (s is EmergencyContactError) return s.contacts;
    return const [];
  }

  Future<void> _onLoad(
    EmergencyContactsLoadRequested event,
    Emitter<EmergencyContactState> emit,
  ) async {
    emit(const EmergencyContactLoading());
    final result = await _repository.getContacts();
    result.fold(
      (failure) => emit(EmergencyContactError(failure.message)),
      (contacts) => emit(EmergencyContactLoaded(contacts)),
    );
  }

  Future<void> _onAdd(
    EmergencyContactAddRequested event,
    Emitter<EmergencyContactState> emit,
  ) async {
    emit(EmergencyContactLoaded(_currentContacts, isSubmitting: true));
    final result = await _repository.addContact(
      fullName: event.fullName,
      relationship: event.relationship,
      phoneNumber: event.phoneNumber,
    );
    result.fold(
      (failure) => emit(EmergencyContactError(failure.message, contacts: _currentContacts)),
      (contact) => emit(EmergencyContactLoaded([..._currentContacts, contact])),
    );
  }

  Future<void> _onDelete(
    EmergencyContactDeleteRequested event,
    Emitter<EmergencyContactState> emit,
  ) async {
    final previous = _currentContacts;
    emit(EmergencyContactLoaded(previous, isSubmitting: true));
    final result = await _repository.deleteContact(event.contactId);
    result.fold(
      (failure) => emit(EmergencyContactError(failure.message, contacts: previous)),
      (_) => emit(EmergencyContactLoaded(
        previous.where((c) => c.id != event.contactId).toList(),
      )),
    );
  }
}
