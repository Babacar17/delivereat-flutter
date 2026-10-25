import 'package:dio/dio.dart';

class AppError {
  final String code;
  final String message;
  AppError(this.code, this.message);

  factory AppError.fromDioException(DioException e) {
    final data = e.response?.data;

    if (e.response?.statusCode == 429) {
      return AppError(
        'RATE_LIMITED',
        'Trop de requêtes, réessayez dans un instant',
      );
    }

    if (data is Map && data['error'] != null) {
      final code = data['error']['code'] ?? 'UNKNOWN';
      final serverMessage = data['error']['message'] ?? 'Erreur inconnue';
      return AppError(code, _translate(code) ?? serverMessage);
    }

    return AppError('NETWORK_ERROR', 'Problème de connexion, réessayez');
  }

  /// Messages français pour les codes documentés par l'API.
  /// Retourne null si le code n'est pas prévu -> on garde le message serveur.
  static String? _translate(String code) {
    switch (code) {
      case 'EMAIL_TAKEN':
        return 'Cette adresse e-mail est déjà utilisée';
      case 'INVALID_CREDENTIALS':
        return 'E-mail ou mot de passe incorrect';
      case 'TOKEN_EXPIRED':
        return 'Votre session a expiré, veuillez vous reconnecter';
      case 'ALREADY_REVIEWED':
        return 'Vous avez déjà laissé un avis pour ce restaurant';
      case 'RESTAURANT_CLOSED':
        return 'Ce restaurant est actuellement fermé';
      case 'MIXED_RESTAURANTS':
        return 'Une commande ne peut concerner qu\'un seul restaurant';
      case 'CANNOT_CANCEL':
        return 'Cette commande ne peut plus être annulée';
      case 'FILE_TOO_LARGE':
        return 'Le fichier dépasse la taille maximale autorisée (2 Mo)';
      case 'VALIDATION_ERROR':
        return 'Certaines informations saisies sont invalides';
      default:
        return null;
    }
  }
}
