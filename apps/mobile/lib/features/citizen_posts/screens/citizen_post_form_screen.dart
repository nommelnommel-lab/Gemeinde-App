import 'package:flutter/material.dart';

import '../models/citizen_post.dart';
import '../services/citizen_posts_service.dart';

class CitizenPostFormScreen extends StatefulWidget {
  const CitizenPostFormScreen({
    super.key,
    required this.type,
    required this.postsService,
    this.post,
  });

  final CitizenPostType type;
  final CitizenPostsService postsService;
  final CitizenPost? post;

  @override
  State<CitizenPostFormScreen> createState() => _CitizenPostFormScreenState();
}

class _CitizenPostFormScreenState extends State<CitizenPostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _priceController;
  late final TextEditingController _imagesController;
  late final TextEditingController _imageController;
  late final TextEditingController _locationController;
  late final TextEditingController _contactController;
  late final TextEditingController _helpTypeController;
  late final TextEditingController _timeRangeController;
  late final TextEditingController _ageRangeController;
  late final TextEditingController _roomsController;
  DateTime? _dateTime;
  DateTime? _dateOnly;
  String _apartmentType = 'SEARCH';
  String _lostFoundType = 'LOST';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
    _priceController = TextEditingController();
    _imagesController = TextEditingController();
    _imageController = TextEditingController();
    _locationController = TextEditingController();
    _contactController = TextEditingController();
    _helpTypeController = TextEditingController();
    _timeRangeController = TextEditingController();
    _ageRangeController = TextEditingController();
    _roomsController = TextEditingController();
    _seedFromPost();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _priceController.dispose();
    _imagesController.dispose();
    _imageController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _helpTypeController.dispose();
    _timeRangeController.dispose();
    _ageRangeController.dispose();
    _roomsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _isEditing;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Beitrag bearbeiten · ${widget.type.label}'
              : 'Neuer Beitrag · ${widget.type.label}',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titel'),
              validator: (value) =>
                  _requiredValidator(value, 'Bitte Titel angeben.'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: 'Beschreibung'),
              maxLines: 4,
              validator: (value) =>
                  _requiredValidator(value, 'Bitte Beschreibung angeben.'),
            ),
            const SizedBox(height: 12),
            ..._buildCategoryFields(context),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isEditing
                          ? 'Änderungen speichern'
                          : 'Beitrag veröffentlichen',
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isEditing => widget.post != null;

  List<Widget> _buildCategoryFields(BuildContext context) {
    switch (widget.type) {
      case CitizenPostType.marketplace:
        return [
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Preis (optional)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _imagesController,
            decoration: const InputDecoration(
              labelText: 'Bild-URLs (optional, kommasepariert)',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Ort (optional)'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contactController,
            decoration: const InputDecoration(labelText: 'Kontakt (optional)'),
          ),
        ];
      case CitizenPostType.movingClearance:
        return [
          _buildDateTimeField(
            context,
            label: 'Termin (optional)',
            value: _dateTime,
            onChange: (value) => setState(() => _dateTime = value),
            required: false,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Ort (optional)'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contactController,
            decoration: const InputDecoration(labelText: 'Kontakt (optional)'),
          ),
        ];
      case CitizenPostType.help:
        return [
          TextFormField(
            controller: _helpTypeController,
            decoration: const InputDecoration(labelText: 'Hilfeart (optional)'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _timeRangeController,
            decoration: const InputDecoration(labelText: 'Zeitraum (optional)'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contactController,
            decoration: const InputDecoration(labelText: 'Kontakt (optional)'),
          ),
        ];
      case CitizenPostType.cafeMeetup:
        return [
          _buildDateTimeField(
            context,
            label: 'Termin',
            value: _dateTime,
            onChange: (value) => setState(() => _dateTime = value),
            required: true,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Ort'),
            validator: (value) =>
                _requiredValidator(value, 'Bitte Ort angeben.'),
          ),
        ];
      case CitizenPostType.kidsMeetup:
        return [
          TextFormField(
            controller: _ageRangeController,
            decoration: const InputDecoration(labelText: 'Alter (optional)'),
          ),
          const SizedBox(height: 12),
          _buildDateTimeField(
            context,
            label: 'Termin',
            value: _dateTime,
            onChange: (value) => setState(() => _dateTime = value),
            required: true,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Ort'),
            validator: (value) =>
                _requiredValidator(value, 'Bitte Ort angeben.'),
          ),
        ];
      case CitizenPostType.apartmentSearch:
        return [
          DropdownButtonFormField<String>(
            value: _apartmentType,
            decoration: const InputDecoration(labelText: 'Typ'),
            items: const [
              DropdownMenuItem(value: 'SEARCH', child: Text('Suche')),
              DropdownMenuItem(value: 'OFFER', child: Text('Biete')),
            ],
            onChanged: (value) =>
                setState(() => _apartmentType = value ?? 'SEARCH'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _roomsController,
            decoration: const InputDecoration(labelText: 'Zimmer (optional)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Preis (optional)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contactController,
            decoration: const InputDecoration(labelText: 'Kontakt'),
            validator: (value) =>
                _requiredValidator(value, 'Bitte Kontakt angeben.'),
          ),
        ];
      case CitizenPostType.lostFound:
        return [
          DropdownButtonFormField<String>(
            value: _lostFoundType,
            decoration: const InputDecoration(labelText: 'Typ'),
            items: const [
              DropdownMenuItem(value: 'LOST', child: Text('Verloren')),
              DropdownMenuItem(value: 'FOUND', child: Text('Gefunden')),
            ],
            onChanged: (value) =>
                setState(() => _lostFoundType = value ?? 'LOST'),
          ),
          const SizedBox(height: 12),
          _buildDateField(
            context,
            label: 'Datum',
            value: _dateOnly,
            onChange: (value) => setState(() => _dateOnly = value),
            required: true,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Ort'),
            validator: (value) =>
                _requiredValidator(value, 'Bitte Ort angeben.'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _imageController,
            decoration: const InputDecoration(labelText: 'Bild-URL (optional)'),
          ),
        ];
      case CitizenPostType.rideSharing:
      case CitizenPostType.jobsLocal:
      case CitizenPostType.volunteering:
      case CitizenPostType.giveaway:
      case CitizenPostType.skillExchange:
        return const [];
    }
  }

  void _seedFromPost() {
    final post = widget.post;
    if (post == null) {
      return;
    }
    _titleController.text = post.title;
    _bodyController.text = post.body;
    final metadata = post.metadata;
    _priceController.text = metadata['price']?.toString() ?? '';
    _locationController.text = metadata['location']?.toString() ?? '';
    _contactController.text = metadata['contact']?.toString() ?? '';
    _helpTypeController.text = metadata['helpType']?.toString() ?? '';
    _timeRangeController.text = metadata['timeRange']?.toString() ?? '';
    _ageRangeController.text = metadata['ageRange']?.toString() ?? '';
    _roomsController.text = metadata['rooms']?.toString() ?? '';
    _imageController.text = metadata['image']?.toString() ?? '';
    final images = metadata['images'];
    if (images is List) {
      _imagesController.text = images.join(', ');
    } else {
      _imagesController.text = '';
    }
    _dateTime = _parseDateTime(metadata['dateTime'] ?? metadata['date']);
    _dateOnly = _parseDateTime(metadata['date']);
    _apartmentType = (metadata['type']?.toString().trim().isNotEmpty ?? false)
        ? metadata['type'].toString()
        : _apartmentType;
    _lostFoundType = (metadata['type']?.toString().trim().isNotEmpty ?? false)
        ? metadata['type'].toString()
        : _lostFoundType;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.tryParse(value.toString());
  }

  Widget _buildDateTimeField(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChange,
    required bool required,
  }) {
    return FormField<DateTime>(
      validator: (_) {
        if (required && value == null) {
          return 'Bitte Datum und Uhrzeit auswählen.';
        }
        return null;
      },
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: () async {
              final picked = await _pickDateTime(context, initial: value);
              onChange(picked);
              state.didChange(picked);
            },
            child: Text(
              value == null ? 'Datum wählen' : _formatDateTime(value),
            ),
          ),
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                state.errorText ?? '',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChange,
    required bool required,
  }) {
    return FormField<DateTime>(
      validator: (_) {
        if (required && value == null) {
          return 'Bitte Datum auswählen.';
        }
        return null;
      },
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: () async {
              final picked = await _pickDate(context, initial: value);
              onChange(picked);
              state.didChange(picked);
            },
            child: Text(
              value == null ? 'Datum wählen' : _formatDate(value),
            ),
          ),
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                state.errorText ?? '',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context, {
    DateTime? initial,
  }) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) {
      return null;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? now),
    );
    if (time == null) {
      return DateTime(date.year, date.month, date.day);
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<DateTime?> _pickDate(
    BuildContext context, {
    DateTime? initial,
  }) async {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
  }

  String? _requiredValidator(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');
    return '$day.$month.$year · $hours:$minutes';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);

    final metadata = _buildMetadata();
    final input = CitizenPostInput(
      type: widget.type,
      title: _titleController.text,
      body: _bodyController.text,
      metadata: metadata,
    );

    try {
      final post = _isEditing
          ? await widget.postsService.updatePost(widget.post!.id, input)
          : await widget.postsService.createPost(input);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Beitrag wurde aktualisiert.' : 'Beitrag wurde erstellt.',
          ),
        ),
      );
      Navigator.of(context).pop(post);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Beitrag konnte nicht aktualisiert werden.'
                : 'Beitrag konnte nicht erstellt werden.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Map<String, dynamic> _buildMetadata() {
    final metadata = <String, dynamic>{};
    switch (widget.type) {
      case CitizenPostType.marketplace:
        _addIfNotEmpty(metadata, 'price', _priceController.text);
        final images = _imagesController.text
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList();
        if (images.isNotEmpty) {
          metadata['images'] = images;
        }
        _addIfNotEmpty(metadata, 'location', _locationController.text);
        _addIfNotEmpty(metadata, 'contact', _contactController.text);
        break;
      case CitizenPostType.movingClearance:
        if (_dateTime != null) {
          metadata['dateTime'] = _dateTime!.toIso8601String();
        }
        _addIfNotEmpty(metadata, 'location', _locationController.text);
        _addIfNotEmpty(metadata, 'contact', _contactController.text);
        break;
      case CitizenPostType.help:
        _addIfNotEmpty(metadata, 'helpType', _helpTypeController.text);
        _addIfNotEmpty(metadata, 'timeRange', _timeRangeController.text);
        _addIfNotEmpty(metadata, 'contact', _contactController.text);
        break;
      case CitizenPostType.cafeMeetup:
        if (_dateTime != null) {
          metadata['dateTime'] = _dateTime!.toIso8601String();
        }
        _addIfNotEmpty(metadata, 'location', _locationController.text);
        break;
      case CitizenPostType.kidsMeetup:
        _addIfNotEmpty(metadata, 'ageRange', _ageRangeController.text);
        if (_dateTime != null) {
          metadata['dateTime'] = _dateTime!.toIso8601String();
        }
        _addIfNotEmpty(metadata, 'location', _locationController.text);
        break;
      case CitizenPostType.apartmentSearch:
        metadata['type'] = _apartmentType;
        _addIfNotEmpty(metadata, 'rooms', _roomsController.text);
        _addIfNotEmpty(metadata, 'price', _priceController.text);
        _addIfNotEmpty(metadata, 'contact', _contactController.text);
        break;
      case CitizenPostType.lostFound:
        metadata['type'] = _lostFoundType;
        if (_dateOnly != null) {
          metadata['date'] = _dateOnly!.toIso8601String();
        }
        _addIfNotEmpty(metadata, 'location', _locationController.text);
        _addIfNotEmpty(metadata, 'image', _imageController.text);
        break;
      case CitizenPostType.rideSharing:
      case CitizenPostType.jobsLocal:
      case CitizenPostType.volunteering:
      case CitizenPostType.giveaway:
      case CitizenPostType.skillExchange:
        break;
    }
    return metadata;
  }

  void _addIfNotEmpty(
    Map<String, dynamic> metadata,
    String key,
    String value,
  ) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    metadata[key] = trimmed;
  }
}
