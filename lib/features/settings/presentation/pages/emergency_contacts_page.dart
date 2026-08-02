import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/shared/utils/safe_bottom_padding.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../domain/entities/emergency_contact_entity.dart';
import '../bloc/emergency_contact_bloc.dart';

class EmergencyContactsPage extends StatelessWidget {
  const EmergencyContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EmergencyContactBloc>()
        ..add(const EmergencyContactsLoadRequested()),
      child: const _EmergencyContactsView(),
    );
  }
}

class _EmergencyContactsView extends StatefulWidget {
  const _EmergencyContactsView();

  @override
  State<_EmergencyContactsView> createState() => _EmergencyContactsViewState();
}

class _EmergencyContactsViewState extends State<_EmergencyContactsView> {
  bool _showAddForm = false;
  final _nameCtrl = TextEditingController();
  final _relationshipCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _relationshipCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submitContact() {
    final name = _nameCtrl.text.trim();
    final relationship = _relationshipCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || relationship.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Full name, relationship and phone number are required.')),
      );
      return;
    }

    context.read<EmergencyContactBloc>().add(
          EmergencyContactAddRequested(
            fullName: name,
            relationship: relationship,
            phoneNumber: phone,
          ),
        );

    _nameCtrl.clear();
    _relationshipCtrl.clear();
    _phoneCtrl.clear();
    setState(() => _showAddForm = false);
  }

  Future<void> _refresh(BuildContext context) {
    final bloc = context.read<EmergencyContactBloc>();
    final done = bloc.stream.firstWhere(
        (s) => s is EmergencyContactLoaded || s is EmergencyContactError);
    bloc.add(const EmergencyContactsLoadRequested());
    return done;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: BlocConsumer<EmergencyContactBloc, EmergencyContactState>(
        listener: (context, state) {
          if (state is EmergencyContactError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final contacts = switch (state) {
            EmergencyContactLoaded(contacts: final c) => c,
            EmergencyContactError(contacts: final c) => c,
            _ => const <EmergencyContactEntity>[],
          };
          final isLoading = state is EmergencyContactLoading;
          final isSubmitting =
              state is EmergencyContactLoaded && state.isSubmitting;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _refresh(context),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const DarkScreenHeader(title: 'Emergency Contacts'),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        20, 24, 20, context.bottomSafePadding(32)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: AppColors.error, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'These contacts are alerted instantly when you activate SOS or your '
                                  'live meeting safety check triggers.',
                                  style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13,
                                      height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (contacts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No emergency contacts yet.',
                                style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ...contacts.map((c) => _ContactRow(
                                contact: c,
                                onDelete: () => context
                                    .read<EmergencyContactBloc>()
                                    .add(EmergencyContactDeleteRequested(c.id)),
                              )),
                        if (_showAddForm)
                          _AddContactForm(
                            nameCtrl: _nameCtrl,
                            relationshipCtrl: _relationshipCtrl,
                            phoneCtrl: _phoneCtrl,
                            isSubmitting: isSubmitting,
                            onCancel: () =>
                                setState(() => _showAddForm = false),
                            onAdd: _submitContact,
                          )
                        else
                          GestureDetector(
                            onTap: () => setState(() => _showAddForm = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.textTertiary
                                        .withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add,
                                      color: AppColors.textSecondary, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add Emergency Contact',
                                    style: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final EmergencyContactEntity contact;
  final VoidCallback onDelete;

  const _ContactRow({required this.contact, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final subtitle = [contact.relationship, contact.phoneNumber]
        .where((s) => s != null && s.isNotEmpty)
        .join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(color: AppColors.cardBg, shape: BoxShape.circle),
            child: Icon(Icons.person, color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.fullName,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle),
              child:
                  Icon(Icons.delete_outline, color: AppColors.error, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddContactForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController relationshipCtrl;
  final TextEditingController phoneCtrl;
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onAdd;

  const _AddContactForm({
    required this.nameCtrl,
    required this.relationshipCtrl,
    required this.phoneCtrl,
    required this.isSubmitting,
    required this.onCancel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Contact',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          _FormField(hint: 'Full Name *', controller: nameCtrl),
          const SizedBox(height: 10),
          _FormField(
              hint: 'Relationship (e.g. Mother) *',
              controller: relationshipCtrl),
          const SizedBox(height: 10),
          _FormField(
            hint: 'Phone Number *',
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isSubmitting ? null : onCancel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12)),
                    child: Center(
                      child: Text('Cancel',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: isSubmitting ? null : onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Add',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _FormField({
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
