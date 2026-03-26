import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../data/models/miner_type.dart';
import '../../../utils/validators.dart';
import '../../providers/miners_provider.dart';

class AddMinerScreen extends ConsumerStatefulWidget {
  const AddMinerScreen({super.key});

  @override
  ConsumerState<AddMinerScreen> createState() => _AddMinerScreenState();
}

class _AddMinerScreenState extends ConsumerState<AddMinerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final _portController = TextEditingController();

  MinerType _selectedType = MinerType.bitaxe;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _portController.text = _selectedType.defaultPort.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _onTypeChanged(MinerType? type) {
    if (type == null) return;
    setState(() {
      _selectedType = type;
      _portController.text = type.defaultPort.toString();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(minersProvider.notifier).addMiner(
            name: _nameController.text.trim(),
            ipAddress: _ipController.text.trim(),
            port: int.parse(_portController.text.trim()),
            type: _selectedType,
          );

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add miner: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Miner',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),

              // -- Miner Type --
              _FieldLabel(text: 'MINER TYPE'),
              const SizedBox(height: AppSpacing.sm),
              _buildTypeDropdown(),

              const SizedBox(height: AppSpacing.xl),

              // -- Name --
              _FieldLabel(text: 'NAME'),
              const SizedBox(height: AppSpacing.sm),
              _buildTextField(
                controller: _nameController,
                hint: 'e.g. BitAxe Living Room',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // -- IP Address --
              _FieldLabel(text: 'IP ADDRESS'),
              const SizedBox(height: AppSpacing.sm),
              _buildTextField(
                controller: _ipController,
                hint: 'e.g. 192.168.1.100',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'IP address is required';
                  }
                  if (!Validators.isValidIpAddress(v.trim())) {
                    return 'Invalid IP address format';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // -- Port --
              _FieldLabel(text: 'PORT'),
              const SizedBox(height: AppSpacing.sm),
              _buildTextField(
                controller: _portController,
                hint: 'e.g. 80',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Port is required';
                  }
                  final port = int.tryParse(v.trim());
                  if (port == null || !Validators.isValidPort(port)) {
                    return 'Invalid port (1-65535)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // -- Submit button --
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : const Text('Add Miner'),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: DropdownButtonFormField<MinerType>(
        initialValue: _selectedType,
        onChanged: _onTypeChanged,
        dropdownColor: AppColors.elevatedDark,
        icon: const Icon(Icons.expand_more_rounded,
            color: AppColors.textSecondary),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding,
            vertical: AppSpacing.md,
          ),
          border: InputBorder.none,
        ),
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        items: MinerType.values.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(type.displayName),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.cardDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.md + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }
}
