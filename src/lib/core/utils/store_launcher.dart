import 'package:url_launcher/url_launcher.dart';

const kPlayStorePackageId = 'shadow.gossip_garden';

Future<bool> openPlayStoreListing() async {
  final marketUri = Uri.parse('market://details?id=$kPlayStorePackageId');
  if (await canLaunchUrl(marketUri)) {
    return launchUrl(marketUri, mode: LaunchMode.externalApplication);
  }

  final webUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=$kPlayStorePackageId',
  );
  if (await canLaunchUrl(webUri)) {
    return launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  return false;
}
