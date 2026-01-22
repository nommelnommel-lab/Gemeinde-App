import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../models/event.dart';
import '../models/event_input.dart';
import '../services/events_service.dart';

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({
    super.key,
    required this.eventsService,
    this.event,
  });

  final EventsService eventsService;
  final Event? event;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _locationController =
        TextEditingController(text: widget.event?.location ?? '');
    _descriptionController =
        TextEditingController(text: widget.event?.description ?? '');
    _selectedDate = widget.event?.date;
    if (widget.event != null) {
      _selectedTime = TimeOfDay.fromDateTime(widget.event!.date);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.event != null;
    final saveLabel = isEdit ? 'Aktualisieren' : 'Erstellen';

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Event bearbeiten' : 'Neues Event')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titel'),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Bitte einen Titel angeben.';
                  }
                  if (trimmed.length < 3) {
                    return 'Bitte einen aussagekräftigen Titel wählen.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Ort'),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Bitte einen Ort angeben.';
                  }
                  if (trimmed.length < 2) {
                    return 'Bitte einen gültigen Ort angeben.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Beschreibung'),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isNotEmpty && trimmed.length < 10) {
                    return 'Bitte eine etwas längere Beschreibung angeben.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              FormField<DateTime>(
                initialValue: _selectedDate,
                validator: (value) {
                  if (value == null) {
                    return 'Bitte ein Datum auswählen.';
                  }
                  return null;
                },
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Datum'),
                        subtitle: Text(
                          _selectedDate == null
                              ? 'Bitte auswählen'
                              : _formatDate(_selectedDate!),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await _pickDate();
                          if (date != null) {
                            field.didChange(date);
                          }
                        },
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 4),
                          child: Text(
                            field.errorText ?? '',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              FormField<TimeOfDay>(
                initialValue: _selectedTime,
                validator: (value) {
                  if (value == null) {
                    return 'Bitte eine Uhrzeit auswählen.';
                  }
                  return null;
                },
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Uhrzeit'),
                        subtitle: Text(
                          _selectedTime == null
                              ? 'Bitte auswählen'
                              : _formatTime(_selectedTime!),
                        ),
                        trailing: const Icon(Icons.schedule),
                        onTap: () async {
                          final time = await _pickTime();
                          if (time != null) {
                            field.didChange(time);
                          }
                        },
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 4),
                          child: Text(
                            field.errorText ?? '',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(saveLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
    return date;
  }

  Future<TimeOfDay?> _pickTime() async {
    final initial = _selectedTime ?? TimeOfDay.fromDateTime(DateTime.now());
    final time = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
    return time;
  }

  Future<void> _save() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final date = _selectedDate;
    final time = _selectedTime;

    if (date == null || time == null) {
      _showSnackBar('Bitte die Pflichtfelder ausfüllen.');
      return;
    }

    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (scheduledAt.isBefore(DateTime.now())) {
      _showSnackBar('Das Event sollte in der Zukunft liegen.');
      return;
    }

    setState(() => _saving = true);
    try {
      final input = EventInput(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: scheduledAt,
        location: _locationController.text.trim(),
      );
      final Event savedEvent;
      if (widget.event == null) {
        savedEvent = await widget.eventsService.createEvent(input);
      } else {
        savedEvent = await widget.eventsService.updateEvent(
          widget.event!.id,
          input,
        );
      }
      if (!mounted) return;
      _showSnackBar('Event gespeichert.');
      AppRouterScope.of(context).pop(savedEvent);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Fehler beim Speichern: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute Uhr';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
