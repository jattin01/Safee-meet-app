import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';

// PROTOTYPE MODE: this page renders mock data only — there is no API
// wiring or backend connectivity. Re-connect it to the /sos/contacts
// endpoint before shipping.
class _Contact {
  String name;
  String relationship;
  String phone;
  _Contact({required this.name, required this.relationship, required this.phone});
}

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  final List<_Contact> _contacts = [
    _Contact(name: 'Sarah Johnson', relationship: 'Mother', phone: '+1 (555) 987-6543'),
    _Contact(name: 'Jake Johnson', relationship: 'Brother', phone: '+1 (555) 456-7890'),
    _Contact(name: 'Maria Garcia', relationship: 'Friend', phone: '+1 (555) 321-0987'),
  ];

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

  void _addContact() {
    setState(() {
      _contacts.add(_Contact(
        name: _nameCtrl.text.trim().isEmpty ? 'New Contact' : _nameCtrl.text.trim(),
        relationship: _relationshipCtrl.text.trim().isEmpty ? 'Other' : _relationshipCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      ));
      _nameCtrl.clear();
      _relationshipCtrl.clear();
      _phoneCtrl.clear();
      _showAddForm = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DarkScreenHeader(title: 'Emergency Contacts'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
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
                        Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'These contacts are alerted instantly when you activate SOS or your '
                            'live meeting safety check triggers.',
                            style: TextStyle(color: AppColors.error, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._contacts.asMap().entries.map((e) => _ContactRow(
                        contact: e.value,
                        onDelete: () => setState(() => _contacts.removeAt(e.key)),
                      )),
                  if (_showAddForm)
                    _AddContactForm(
                      nameCtrl: _nameCtrl,
                      relationshipCtrl: _relationshipCtrl,
                      phoneCtrl: _phoneCtrl,
                      onCancel: () => setState(() => _showAddForm = false),
                      onAdd: _addContact,
                    )
                  else
                    GestureDetector(
                      onTap: () => setState(() => _showAddForm = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.textTertiary.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: AppColors.textSecondary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Add Emergency Contact',
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w700),
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
  }
}

class _ContactRow extends StatelessWidget {
  final _Contact contact;
  final VoidCallback onDelete;

  const _ContactRow({required this.contact, required this.onDelete});

  @override
  Widget build(BuildContext context) {
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
            decoration: BoxDecoration(color: AppColors.cardBg, shape: BoxShape.circle),
            child: Icon(Icons.person, color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name,
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${contact.relationship} · ${contact.phone}',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.delete_outline, color: AppColors.error, size: 18),
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
  final VoidCallback onCancel;
  final VoidCallback onAdd;

  const _AddContactForm({
    required this.nameCtrl,
    required this.relationshipCtrl,
    required this.phoneCtrl,
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
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          _FormField(hint: 'Full Name *', controller: nameCtrl),
          const SizedBox(height: 10),
          _FormField(hint: 'Relationship (e.g. Mother)', controller: relationshipCtrl),
          const SizedBox(height: 10),
          _FormField(
            hint: 'Phone Number',
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
                    child: Center(
                      child: Text('Cancel',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text('Add',
                          style:
                              GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
