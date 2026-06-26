import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/doctor_appointment_model.dart';
import '../data/models/doctor_consultation_model.dart';
import '../data/models/doctor_patient_model.dart';
import 'providers/doctor_providers.dart';

class DoctorConsultationScreen extends ConsumerStatefulWidget {
  final DoctorAppointmentModel appointment;

  const DoctorConsultationScreen({super.key, required this.appointment});

  @override
  ConsumerState<DoctorConsultationScreen> createState() =>
      _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState
    extends ConsumerState<DoctorConsultationScreen> {
  final _diagnosisController = TextEditingController();
  final _resultController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _dosageController = TextEditingController();
  final _findingsController = TextEditingController();
  final _recommendationsController = TextEditingController();

  int? _selectedDiagnosisId;
  int? _selectedTreatmentId;
  int? _selectedTreatmentTypeId;
  int? _selectedMedicationId;

  @override
  void dispose() {
    _diagnosisController.dispose();
    _resultController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _dosageController.dispose();
    _findingsController.dispose();
    _recommendationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(
      doctorConsultationProvider(widget.appointment.patientId),
    );
    final action = ref.watch(doctorConsultationActionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Consultation')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            doctorConsultationProvider(widget.appointment.patientId),
          );
          await ref.read(
            doctorConsultationProvider(widget.appointment.patientId).future,
          );
        },
        child: data.when(
          loading: () => const _LoadingConsultation(),
          error: (error, _) => _ErrorConsultation(
            message: _friendlyError(error),
            onRetry: () => ref.invalidate(
              doctorConsultationProvider(widget.appointment.patientId),
            ),
          ),
          data: (consultation) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _AppointmentContextCard(appointment: widget.appointment),
              const SizedBox(height: 16),
              _HistoryPreview(history: consultation.history),
              const SizedBox(height: 16),
              _DiagnosisForm(
                controller: _diagnosisController,
                isLoading: action.isLoading,
                onCreate: _createDiagnosis,
              ),
              const SizedBox(height: 16),
              _TreatmentForm(
                history: consultation.history,
                treatmentTypes: consultation.treatmentTypes,
                selectedDiagnosisId: _selectedDiagnosisId,
                selectedTreatmentTypeId: _selectedTreatmentTypeId,
                resultController: _resultController,
                startDateController: _startDateController,
                endDateController: _endDateController,
                isLoading: action.isLoading,
                onDiagnosisChanged: (value) =>
                    setState(() => _selectedDiagnosisId = value),
                onTreatmentTypeChanged: (value) =>
                    setState(() => _selectedTreatmentTypeId = value),
                onCreate: _createTreatment,
              ),
              const SizedBox(height: 16),
              _MedicationForm(
                history: consultation.history,
                medications: consultation.medications,
                selectedTreatmentId: _selectedTreatmentId,
                selectedMedicationId: _selectedMedicationId,
                dosageController: _dosageController,
                isLoading: action.isLoading,
                onTreatmentChanged: (value) =>
                    setState(() => _selectedTreatmentId = value),
                onMedicationChanged: (value) =>
                    setState(() => _selectedMedicationId = value),
                onAttach: _attachMedication,
              ),
              const SizedBox(height: 16),
              _SummaryForm(
                findingsController: _findingsController,
                recommendationsController: _recommendationsController,
                isLoading: action.isLoading,
                onCreate: _createSummary,
              ),
              const SizedBox(height: 16),
              const _DeferredUploadCard(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createDiagnosis() async {
    final notes = _diagnosisController.text.trim();
    if (notes.isEmpty) {
      _showSnack('Please enter diagnosis notes.', isError: true);
      return;
    }
    final result = await ref
        .read(doctorConsultationActionProvider.notifier)
        .createDiagnosis(
          DoctorDiagnosisCreateRequest(
            appointmentId: widget.appointment.id,
            notes: notes,
          ),
        );
    if (!mounted) return;
    if (result == null) {
      _showSnack(_actionError(), isError: true);
      return;
    }
    _diagnosisController.clear();
    setState(() => _selectedDiagnosisId = result.id);
    ref.invalidate(doctorConsultationProvider(widget.appointment.patientId));
    ref.invalidate(doctorPatientFileProvider(widget.appointment.patientId));
    _showSnack('Diagnosis saved.');
  }

  Future<void> _createTreatment() async {
    final diagnosisId = _selectedDiagnosisId;
    if (diagnosisId == null || diagnosisId <= 0) {
      _showSnack('Select a diagnosis first.', isError: true);
      return;
    }
    final result = await ref
        .read(doctorConsultationActionProvider.notifier)
        .createTreatment(
          DoctorTreatmentCreateRequest(
            diagnosisId: diagnosisId,
            treatmentTypeId: _selectedTreatmentTypeId,
            startDate: _startDateController.text,
            endDate: _endDateController.text,
            result: _resultController.text,
          ),
          patientId: widget.appointment.patientId,
        );
    if (!mounted) return;
    if (result == null) {
      _showSnack(_actionError(), isError: true);
      return;
    }
    setState(() => _selectedTreatmentId = result.id);
    _resultController.clear();
    _startDateController.clear();
    _endDateController.clear();
    _showSnack('Treatment saved.');
  }

  Future<void> _attachMedication() async {
    final treatmentId = _selectedTreatmentId;
    final medicationId = _selectedMedicationId;
    if (treatmentId == null || medicationId == null) {
      _showSnack('Select a treatment and medication first.', isError: true);
      return;
    }
    final ok = await ref
        .read(doctorConsultationActionProvider.notifier)
        .addMedication(
          DoctorTreatmentMedicationRequest(
            treatmentId: treatmentId,
            medicationId: medicationId,
            dosageInstructions: _dosageController.text,
          ),
          patientId: widget.appointment.patientId,
        );
    if (!mounted) return;
    if (!ok) {
      _showSnack(_actionError(), isError: true);
      return;
    }
    _dosageController.clear();
    _showSnack('Medication attached.');
  }

  Future<void> _createSummary() async {
    if (_findingsController.text.trim().isEmpty ||
        _recommendationsController.text.trim().isEmpty) {
      _showSnack('Enter key findings and recommendations.', isError: true);
      return;
    }
    final result = await ref
        .read(doctorConsultationActionProvider.notifier)
        .createSummary(
          DoctorSummaryCreateRequest(
            patientId: widget.appointment.patientId,
            keyFindings: _findingsController.text,
            recommendations: _recommendationsController.text,
          ),
        );
    if (!mounted) return;
    if (result == null) {
      _showSnack(_actionError(), isError: true);
      return;
    }
    _findingsController.clear();
    _recommendationsController.clear();
    _showSnack('Medical summary saved.');
  }

  String _actionError() {
    final error = ref.read(doctorConsultationActionProvider).error;
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 403) return 'You are not allowed to update this file.';
      if (statusCode == 404) {
        return 'The related appointment or patient was not found.';
      }
      if (statusCode == 422) return 'Please check the consultation fields.';
    }
    return 'Could not save consultation data. Please try again.';
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}

class _AppointmentContextCard extends StatelessWidget {
  final DoctorAppointmentModel appointment;

  const _AppointmentContextCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.medical_information)),
        title: Text(appointment.displayPatientName),
        subtitle: Text(
          'Appointment #${appointment.id} • ${appointment.date} ${appointment.time}',
        ),
        trailing: Chip(label: Text(appointment.displayStatus)),
      ),
    );
  }
}

class _HistoryPreview extends StatelessWidget {
  final DoctorConsultationHistoryModel history;

  const _HistoryPreview({required this.history});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Previous history',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${history.diagnoses.length} diagnoses • ${history.treatments.length} treatments',
            ),
            if (history.diagnoses.isNotEmpty)
              Text('Latest: ${history.diagnoses.last.notes}'),
          ],
        ),
      ),
    );
  }
}

class _DiagnosisForm extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onCreate;

  const _DiagnosisForm({
    required this.controller,
    required this.isLoading,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Create diagnosis',
      children: [
        TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Diagnosis notes'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: isLoading ? null : onCreate,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save diagnosis'),
        ),
      ],
    );
  }
}

class _TreatmentForm extends StatelessWidget {
  final DoctorConsultationHistoryModel history;
  final List<DoctorTreatmentTypeModel> treatmentTypes;
  final int? selectedDiagnosisId;
  final int? selectedTreatmentTypeId;
  final TextEditingController resultController;
  final TextEditingController startDateController;
  final TextEditingController endDateController;
  final bool isLoading;
  final ValueChanged<int?> onDiagnosisChanged;
  final ValueChanged<int?> onTreatmentTypeChanged;
  final VoidCallback onCreate;

  const _TreatmentForm({
    required this.history,
    required this.treatmentTypes,
    required this.selectedDiagnosisId,
    required this.selectedTreatmentTypeId,
    required this.resultController,
    required this.startDateController,
    required this.endDateController,
    required this.isLoading,
    required this.onDiagnosisChanged,
    required this.onTreatmentTypeChanged,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Create treatment',
      children: [
        DropdownButtonFormField<int>(
          initialValue: selectedDiagnosisId,
          decoration: const InputDecoration(labelText: 'Diagnosis'),
          items: history.diagnoses
              .map(
                (item) => DropdownMenuItem(
                  value: item.id,
                  child: Text(
                    item.notes.isEmpty ? 'Diagnosis #${item.id}' : item.notes,
                  ),
                ),
              )
              .toList(),
          onChanged: onDiagnosisChanged,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: selectedTreatmentTypeId,
          decoration: const InputDecoration(labelText: 'Treatment type'),
          items: treatmentTypes
              .map(
                (item) =>
                    DropdownMenuItem(value: item.id, child: Text(item.name)),
              )
              .toList(),
          onChanged: onTreatmentTypeChanged,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: startDateController,
          decoration: const InputDecoration(
            labelText: 'Start date (YYYY-MM-DD)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: endDateController,
          decoration: const InputDecoration(labelText: 'End date (optional)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: resultController,
          decoration: const InputDecoration(labelText: 'Result / notes'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: isLoading ? null : onCreate,
          icon: const Icon(Icons.healing_outlined),
          label: const Text('Save treatment'),
        ),
      ],
    );
  }
}

class _MedicationForm extends StatelessWidget {
  final DoctorConsultationHistoryModel history;
  final List<DoctorMedicationModel> medications;
  final int? selectedTreatmentId;
  final int? selectedMedicationId;
  final TextEditingController dosageController;
  final bool isLoading;
  final ValueChanged<int?> onTreatmentChanged;
  final ValueChanged<int?> onMedicationChanged;
  final VoidCallback onAttach;

  const _MedicationForm({
    required this.history,
    required this.medications,
    required this.selectedTreatmentId,
    required this.selectedMedicationId,
    required this.dosageController,
    required this.isLoading,
    required this.onTreatmentChanged,
    required this.onMedicationChanged,
    required this.onAttach,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Attach medication',
      children: [
        DropdownButtonFormField<int>(
          initialValue: selectedTreatmentId,
          decoration: const InputDecoration(labelText: 'Treatment'),
          items: history.treatments
              .map(
                (item) => DropdownMenuItem(
                  value: item.id,
                  child: Text(
                    item.description.isEmpty
                        ? 'Treatment #${item.id}'
                        : item.description,
                  ),
                ),
              )
              .toList(),
          onChanged: onTreatmentChanged,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: selectedMedicationId,
          decoration: const InputDecoration(labelText: 'Medication'),
          items: medications
              .map(
                (item) =>
                    DropdownMenuItem(value: item.id, child: Text(item.name)),
              )
              .toList(),
          onChanged: onMedicationChanged,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: dosageController,
          decoration: const InputDecoration(labelText: 'Dosage instructions'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onAttach,
          icon: const Icon(Icons.medication_outlined),
          label: const Text('Attach medication'),
        ),
      ],
    );
  }
}

class _SummaryForm extends StatelessWidget {
  final TextEditingController findingsController;
  final TextEditingController recommendationsController;
  final bool isLoading;
  final VoidCallback onCreate;

  const _SummaryForm({
    required this.findingsController,
    required this.recommendationsController,
    required this.isLoading,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Medical summary',
      children: [
        TextField(
          controller: findingsController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Key findings'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: recommendationsController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Recommendations'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onCreate,
          icon: const Icon(Icons.summarize_outlined),
          label: const Text('Save summary'),
        ),
      ],
    );
  }
}

class _DeferredUploadCard extends StatelessWidget {
  const _DeferredUploadCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'EHR/document upload is deferred until a safe file picker and upload UX is added.',
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _LoadingConsultation extends StatelessWidget {
  const _LoadingConsultation();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 260),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ErrorConsultation extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorConsultation({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.cloud_off_outlined, size: 48),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Center(
          child: FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ],
    );
  }
}

String _friendlyError(Object error) {
  return 'We could not load consultation data. Pull to refresh or try again.';
}
