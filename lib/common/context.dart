import 'package:handy/enum/enum.dart';
import 'package:handy/l10n/l10n.dart';
import 'package:handy/manager/status_manager.dart';
import 'package:handy/models/state.dart';
import 'package:material_ui/material_ui.dart';

extension AppContextExtension on BuildContext {
  void showNotifier(
    String text, {
    MessageLevel level = MessageLevel.info,
    MessageActionState? actionState,
  }) {
    return findAncestorStateOfType<StatusManagerState>()?.message(
      text,
      level: level,
      actionState: actionState,
    );
  }

  AppLocalizations get appLocalizations => AppLocalizations.of(this);
}
