import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/auth/app_permissions.dart';
import '../../../shared/di/app_services_scope.dart';
import '../models/admin_models.dart';
import '../services/admin_service.dart';
import '../utils/admin_csv_download.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _expiresController =
      TextEditingController(text: '30');
  final Set<String> _selectedResidents = {};
  bool _loading = false;
  List<AdminResident> _residents = [];
  AdminService? _adminService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adminService ??= AppServicesScope.of(context).adminService;
    _loadResidents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _expiresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permissions =
        AppPermissionsScope.maybePermissionsOf(context) ??
            const AppPermissions.empty();
    final adminKey = AppServicesScope.of(context)
        .adminKeyStore
        .getAdminKey(AppServicesScope.of(context).tenantStore.resolveTenantId());
    final hasAdminKey = adminKey != null && adminKey.trim().isNotEmpty;
    final isAdmin = permissions.canManageResidents && hasAdminKey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadResidents,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hasAdminKey)
                _InfoBanner(
                  message:
                      'Kein Admin Key gesetzt. Bitte im Mehr-Tab hinterlegen.',
                )
              else if (!permissions.canManageResidents)
                const _InfoBanner(
                  message:
                      'Admin Key ist gesetzt, aber keine Admin-Berechtigung.',
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Suche (Name)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _loading ? null : _loadResidents,
                  ),
                ),
                onSubmitted: (_) => _loadResidents(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: !isAdmin ? null : _openCreateResidentDialog,
                    child: const Text('Bewohner anlegen'),
                  ),
                  OutlinedButton(
                    onPressed: !isAdmin ? null : _importCsv,
                    child: const Text('CSV importieren'),
                  ),
                  OutlinedButton(
                    onPressed:
                        !isAdmin || _selectedResidents.isEmpty
                            ? null
                            : _openBulkGenerateDialog,
                    child: Text(
                      'Codes erzeugen (${_selectedResidents.length})',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _residents.isEmpty
                        ? const Center(child: Text('Keine Bewohner gefunden.'))
                        : ListView.separated(
                            itemCount: _residents.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 0),
                            itemBuilder: (context, index) {
                              final resident = _residents[index];
                              final selected =
                                  _selectedResidents.contains(resident.id);
                              return CheckboxListTile(
                                value: selected,
                                onChanged: !isAdmin
                                    ? null
                                    : (value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedResidents
                                                .add(resident.id);
                                          } else {
                                            _selectedResidents
                                                .remove(resident.id);
                                          }
                                        });
                                      },
                                title: Text(resident.displayName),
                                subtitle: Text(
                                  '${resident.postalCode} ${resident.houseNumber} • ${resident.status}',
                                ),
                                dense: true,
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadResidents() async {
    final service = _adminService;
    if (service == null) return;
    setState(() => _loading = true);
    try {
      final residents =
          await service.getResidents(query: _searchController.text);
      if (!mounted) return;
      setState(() {
        _residents = residents;
        _selectedResidents.removeWhere(
          (id) => !_residents.any((resident) => resident.id == id),
        );
      });
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openCreateResidentDialog() async {
    final firstName = TextEditingController();
    final lastName = TextEditingController();
    final postalCode = TextEditingController();
    final houseNumber = TextEditingController();

    final result = await showDialog<AdminResidentInput>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bewohner anlegen'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: firstName,
                decoration: const InputDecoration(labelText: 'Vorname'),
              ),
              TextField(
                controller: lastName,
                decoration: const InputDecoration(labelText: 'Nachname'),
              ),
              TextField(
                controller: postalCode,
                decoration: const InputDecoration(labelText: 'PLZ'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: houseNumber,
                decoration: const InputDecoration(labelText: 'Hausnummer'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(
                AdminResidentInput(
                  firstName: firstName.text,
                  lastName: lastName.text,
                  postalCode: postalCode.text,
                  houseNumber: houseNumber.text,
                ),
              );
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    firstName.dispose();
    lastName.dispose();
    postalCode.dispose();
    houseNumber.dispose();

    if (result == null) return;
    try {
      await _adminService!.createResident(result);
      if (!mounted) return;
      _showMessage('Bewohner angelegt.');
      await _loadResidents();
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  Future<void> _importCsv() async {
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );
    final file = selection?.files.single;
    if (file == null) return;
    final bytes = file.bytes;
    if (bytes == null) {
      _showMessage('CSV konnte nicht gelesen werden.');
      return;
    }

    try {
      final summary = await _adminService!.importResidentsFromCsv(
        bytes: bytes,
        filename: file.name,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import abgeschlossen'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Erstellt: ${summary.created}'),
                Text('Übersprungen: ${summary.skipped}'),
                Text('Fehler: ${summary.failed}'),
                if (summary.errors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Fehler:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...summary.errors.map(
                    (error) => Text('Zeile ${error.row}: ${error.message}'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      await _loadResidents();
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  Future<void> _openBulkGenerateDialog() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Codes erzeugen'),
        content: TextField(
          controller: _expiresController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Gültigkeit (Tage)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(_expiresController.text.trim());
              Navigator.of(context).pop(parsed ?? 30);
            },
            child: const Text('Erzeugen'),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      final response = await _adminService!.generateActivationCodes(
        residentIds: _selectedResidents.toList(),
        expiresInDays: result,
      );
      if (!mounted) return;
      final csv = _buildCsv(response);
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Erstellt: ${response.created.length}'),
              Text('Übersprungen: ${response.skipped.length}'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: csv.isEmpty ? null : () => _copyCsv(csv),
                    child: const Text('CSV kopieren'),
                  ),
                  OutlinedButton(
                    onPressed: csv.isEmpty
                        ? null
                        : () => _downloadCsv(
                              csv,
                              filename:
                                  'activation-codes-${DateTime.now().millisecondsSinceEpoch}.csv',
                            ),
                    child: const Text('CSV herunterladen'),
                  ),
                ],
              ),
              if (response.skipped.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Übersprungen:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...response.skipped.map(
                  (entry) => Text('${entry.residentId}: ${entry.reason}'),
                ),
              ],
            ],
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  String _buildCsv(BulkActivationResult result) {
    if (result.created.isEmpty) {
      return '';
    }
    final buffer = StringBuffer(
      'displayName,postalCode,houseNumber,activationCode,expiresAt\n',
    );
    for (final entry in result.created) {
      final resident = _residents.firstWhere(
        (resident) => resident.id == entry.residentId,
        orElse: () => AdminResident(
          id: entry.residentId,
          displayName: '',
          status: '',
          createdAt: '',
          postalCode: '',
          houseNumber: '',
        ),
      );
      buffer.writeln(
        '${_escapeCsv(resident.displayName)},'
        '${_escapeCsv(resident.postalCode)},'
        '${_escapeCsv(resident.houseNumber)},'
        '${_escapeCsv(entry.code)},'
        '${_escapeCsv(entry.expiresAt)}',
      );
    }
    return buffer.toString();
  }

  String _escapeCsv(String value) {
    final needsQuotes = value.contains(',') || value.contains('"');
    final escaped = value.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  Future<void> _copyCsv(String csv) async {
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    _showMessage('CSV in die Zwischenablage kopiert.');
  }

  Future<void> _downloadCsv(String csv, {required String filename}) async {
    try {
      final resultPath = await downloadCsv(filename, csv);
      if (!mounted) return;
      if (resultPath != null) {
        _showMessage('CSV gespeichert: $resultPath');
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage('Download nicht verfügbar. Bitte CSV kopieren.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fehler: $error')),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
