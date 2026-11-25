import 'package:hypomnema/features/journal/data/journal_entry_repository.dart';
import 'package:hypomnema/features/journal/ui/journal_editor.dart';
import 'package:material_ui/material_ui.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({required this.repository, super.key});

  final JournalEntryRepository repository;

  Future<void> _submit({
    required String subject,
    required int mood,
    required String text,
  }) async {
    await repository.save(
      subject: subject,
      mood: mood,
      text: text,
      private: false,
    );
  }

  void _openEditor(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width > 600;
    final editor = JournalEditor(desktop: desktop, onSubmit: _submit);
    if (desktop) {
      showDialog<void>(
        context: context,
        barrierColor: Theme.of(context).colorScheme.scrim,
        builder: (context) => editor,
      );
      return;
    }
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (context) => editor));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        key: const Key('journal-write'),
        onPressed: () => _openEditor(context),
        child: const Text('Write'),
      ),
    );
  }
}
