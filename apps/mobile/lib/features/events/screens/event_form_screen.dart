import 'package:flutter/material.dart';

import '../models/event.dart';
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
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  DateTime? _selectedDate;
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titel'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Ort'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Beschreibung'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Datum'),
              subtitle: Text(
                _selectedDate == null
                    ? 'Bitte auswählen'
                    : _formatDate(_selectedDate!),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
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
    );
  }

  Future<void> _pickDate() async {
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
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final location = _locationController.text.trim();
    final description = _descriptionController.text.trim();
    final date = _selectedDate;

    if (title.isEmpty || location.isEmpty || date == null) {
      _showSnackBar('Titel, Ort und Datum sind erforderlich.');
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.event == null) {
        await widget.eventsService.createEvent(
          title: title,
          description: description,
          date: date,
          location: location,
        );
      } else {
        await widget.eventsService.updateEvent(
          widget.event!.id,
          title: title,
          description: description,
          date: date,
          location: location,
        );
      }
      if (!mounted) return;
      _showSnackBar('Event gespeichert.');
      Navigator.of(context).pop(true);
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
