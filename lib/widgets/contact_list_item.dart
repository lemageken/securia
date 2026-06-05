// lib/widgets/contact_list_item.dart

import 'package:flutter/material.dart';
import 'package:easy_url_launcher/easy_url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:securia/models/item_model.dart';
import 'package:securia/config/app_config.dart';
import 'package:securia/core/constants.dart';

class ContactListItem extends StatelessWidget {
  final Item item;

  const ContactListItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final appConfig = Provider.of<AppConfig>(context);

    return Container(
      padding: const EdgeInsets.all(5.0),
      child: Card(
        elevation: appConfig.itemCardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(appConfig.itemCardBorderRadius),
        ),
        color: appConfig.itemCardBackgroundColor,
        child: ListTile(
          onTap: () {
            if (item.tph != null) {
              showDialog(
                context: context,
                builder: (context) =>
                    _buildActionDialog(context, item, appConfig),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Numéro de téléphone non disponible pour cet élément.',
                  ),
                ),
              );
            }
          },
          leading: Image.asset(AppConstants.logoPolicePath),
          title: Text(
            item.name,
            style: TextStyle(
              fontWeight: appConfig.itemTitleFontWeight,
              fontSize: appConfig.itemTitleFontSize,
              color: appConfig.itemTitleColor,
            ),
          ),
          subtitle: item.tph != null
              ? Text(
                  item.tph!,
                  style: TextStyle(
                    fontSize: appConfig.itemSubtitleFontSize,
                    fontStyle: appConfig.itemSubtitleFontStyle,
                    color: appConfig.itemSubtitleColor,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildActionDialog(
    BuildContext context,
    Item item,
    AppConfig appConfig,
  ) {
    return AlertDialog(
      title: Text(item.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (appConfig.showDialogImage)
            Container(
              color: appConfig.dialogImageBackgroundColor,
              child: Image.asset(AppConstants.logoPolicePath),
            ),
          Text('Numéro: ${item.tph}'),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            // Capturer NavigatorState et ScaffoldMessengerState avant l'opération asynchrone
            final navigator = Navigator.of(context);
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            if (item.tph != null) {
              try {
                await EasyLauncher.call(number: item.tph!);
                navigator.pop();
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Impossible d\'appeler. Vérifiez le format du numéro ou l\'app appel.',
                    ),
                  ),
                );
              }
            }
          },
          child: Text(appConfig.callButtonText),
        ),
        ElevatedButton(
          onPressed: () async {
            // Capturer NavigatorState et ScaffoldMessengerState avant l'opération asynchrone
            final navigator = Navigator.of(context);
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            if (item.tph != null) {
              try {
                await EasyLauncher.sms(number: item.tph!);
                navigator.pop();
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Impossible d\'envoyer un message. Vérifiez le format du numéro ou l\'app SMS.',
                    ),
                  ),
                );
              }
            }
          },
          child: Text(appConfig.messageButtonText),
        ),
      ],
    );
  }
}
