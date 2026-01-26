import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Deneige Auto'**
  String get appTitle;

  /// No description provided for @common_retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get common_retry;

  /// No description provided for @common_cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get common_cancel;

  /// No description provided for @common_confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get common_confirm;

  /// No description provided for @common_save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get common_save;

  /// No description provided for @common_delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get common_delete;

  /// No description provided for @common_close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get common_close;

  /// No description provided for @common_back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get common_back;

  /// No description provided for @common_next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get common_next;

  /// No description provided for @common_skip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get common_skip;

  /// No description provided for @common_send.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get common_send;

  /// No description provided for @common_yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get common_no;

  /// No description provided for @common_ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get common_loading;

  /// No description provided for @common_error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get common_error;

  /// No description provided for @common_success.
  ///
  /// In fr, this message translates to:
  /// **'Succès'**
  String get common_success;

  /// No description provided for @common_required.
  ///
  /// In fr, this message translates to:
  /// **'Requis'**
  String get common_required;

  /// No description provided for @common_invalid.
  ///
  /// In fr, this message translates to:
  /// **'Invalide'**
  String get common_invalid;

  /// No description provided for @common_today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get common_today;

  /// No description provided for @common_yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get common_yesterday;

  /// No description provided for @common_earlier.
  ///
  /// In fr, this message translates to:
  /// **'Plus tôt'**
  String get common_earlier;

  /// No description provided for @common_details.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get common_details;

  /// No description provided for @common_email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get common_email;

  /// No description provided for @common_phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get common_phone;

  /// No description provided for @common_password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get common_password;

  /// No description provided for @common_name.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get common_name;

  /// No description provided for @common_firstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get common_firstName;

  /// No description provided for @common_address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get common_address;

  /// No description provided for @common_notes.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get common_notes;

  /// No description provided for @common_call.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get common_call;

  /// No description provided for @common_sms.
  ///
  /// In fr, this message translates to:
  /// **'SMS'**
  String get common_sms;

  /// No description provided for @common_understood.
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get common_understood;

  /// No description provided for @common_default.
  ///
  /// In fr, this message translates to:
  /// **'Par défaut'**
  String get common_default;

  /// No description provided for @common_noData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée'**
  String get common_noData;

  /// No description provided for @common_notSpecified.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get common_notSpecified;

  /// No description provided for @common_errorOccurred.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get common_errorOccurred;

  /// No description provided for @common_logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get common_logout;

  /// No description provided for @common_logoutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment vous déconnecter ?'**
  String get common_logoutConfirm;

  /// No description provided for @common_logoutConfirmAccount.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment vous déconnecter de votre compte ?'**
  String get common_logoutConfirmAccount;

  /// No description provided for @onboarding_title1.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur Déneige Auto'**
  String get onboarding_title1;

  /// No description provided for @onboarding_desc1.
  ///
  /// In fr, this message translates to:
  /// **'La solution moderne pour gérer le déneigement de votre véhicule en toute simplicité'**
  String get onboarding_desc1;

  /// No description provided for @onboarding_title2.
  ///
  /// In fr, this message translates to:
  /// **'Réservez en quelques clics'**
  String get onboarding_title2;

  /// No description provided for @onboarding_desc2.
  ///
  /// In fr, this message translates to:
  /// **'Planifiez vos services de déneigement selon vos besoins et votre horaire'**
  String get onboarding_desc2;

  /// No description provided for @onboarding_title3.
  ///
  /// In fr, this message translates to:
  /// **'Suivi en temps réel'**
  String get onboarding_title3;

  /// No description provided for @onboarding_desc3.
  ///
  /// In fr, this message translates to:
  /// **'Suivez l\'avancement du déneigement et recevez des notifications instantanées'**
  String get onboarding_desc3;

  /// No description provided for @onboarding_title4.
  ///
  /// In fr, this message translates to:
  /// **'Paiement sécurisé'**
  String get onboarding_title4;

  /// No description provided for @onboarding_desc4.
  ///
  /// In fr, this message translates to:
  /// **'Payez en toute sécurité et gérez vos factures facilement'**
  String get onboarding_desc4;

  /// No description provided for @onboarding_start.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboarding_start;

  /// No description provided for @login_welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue'**
  String get login_welcome;

  /// No description provided for @login_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous à votre compte'**
  String get login_subtitle;

  /// No description provided for @login_emailHint.
  ///
  /// In fr, this message translates to:
  /// **'exemple@email.com'**
  String get login_emailHint;

  /// No description provided for @login_emailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre email'**
  String get login_emailRequired;

  /// No description provided for @login_emailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get login_emailInvalid;

  /// No description provided for @login_passwordHint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre mot de passe'**
  String get login_passwordHint;

  /// No description provided for @login_passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre mot de passe'**
  String get login_passwordRequired;

  /// No description provided for @login_forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get login_forgotPassword;

  /// No description provided for @login_submit.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get login_submit;

  /// No description provided for @login_noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? '**
  String get login_noAccount;

  /// No description provided for @login_register.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get login_register;

  /// No description provided for @register_title.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get register_title;

  /// No description provided for @register_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre compte pour commencer'**
  String get register_subtitle;

  /// No description provided for @register_firstNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Jean'**
  String get register_firstNameHint;

  /// No description provided for @register_lastNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Dupont'**
  String get register_lastNameHint;

  /// No description provided for @register_phoneHint.
  ///
  /// In fr, this message translates to:
  /// **'+1 (514) 123-4567'**
  String get register_phoneHint;

  /// No description provided for @register_phoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro de téléphone est obligatoire'**
  String get register_phoneRequired;

  /// No description provided for @register_phoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide'**
  String get register_phoneInvalid;

  /// No description provided for @register_verificationCodeSent.
  ///
  /// In fr, this message translates to:
  /// **'Un code de vérification sera envoyé'**
  String get register_verificationCodeSent;

  /// No description provided for @register_passwordMinChars.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 6 caractères'**
  String get register_passwordMinChars;

  /// No description provided for @register_passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un mot de passe'**
  String get register_passwordRequired;

  /// No description provided for @register_confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get register_confirmPassword;

  /// No description provided for @register_confirmPasswordHint.
  ///
  /// In fr, this message translates to:
  /// **'Répétez votre mot de passe'**
  String get register_confirmPasswordHint;

  /// No description provided for @register_confirmPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez confirmer votre mot de passe'**
  String get register_confirmPasswordRequired;

  /// No description provided for @register_passwordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get register_passwordMismatch;

  /// No description provided for @register_acceptTerms.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez accepter les conditions d\'utilisation et la politique de confidentialité'**
  String get register_acceptTerms;

  /// No description provided for @register_snowWorker.
  ///
  /// In fr, this message translates to:
  /// **'Déneigeur'**
  String get register_snowWorker;

  /// No description provided for @register_submit.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get register_submit;

  /// No description provided for @register_hasAccount.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà un compte ? '**
  String get register_hasAccount;

  /// No description provided for @forgotPassword_title.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword_title;

  /// No description provided for @forgotPassword_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe'**
  String get forgotPassword_subtitle;

  /// No description provided for @forgotPassword_emailSent.
  ///
  /// In fr, this message translates to:
  /// **'Email de réinitialisation envoyé !'**
  String get forgotPassword_emailSent;

  /// No description provided for @forgotPassword_emailSentTo.
  ///
  /// In fr, this message translates to:
  /// **'Un email de réinitialisation a été envoyé à'**
  String get forgotPassword_emailSentTo;

  /// No description provided for @forgotPassword_sendLink.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get forgotPassword_sendLink;

  /// No description provided for @forgotPassword_sent.
  ///
  /// In fr, this message translates to:
  /// **'Email envoyé !'**
  String get forgotPassword_sent;

  /// No description provided for @forgotPassword_checkInbox.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre boîte de réception et suivez les instructions pour réinitialiser votre mot de passe.'**
  String get forgotPassword_checkInbox;

  /// No description provided for @forgotPassword_backToLogin.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get forgotPassword_backToLogin;

  /// No description provided for @forgotPassword_resend.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer l\'email'**
  String get forgotPassword_resend;

  /// No description provided for @forgotPassword_rememberPassword.
  ///
  /// In fr, this message translates to:
  /// **'Vous vous souvenez de votre mot de passe ? '**
  String get forgotPassword_rememberPassword;

  /// No description provided for @phoneVerification_title.
  ///
  /// In fr, this message translates to:
  /// **'Vérification'**
  String get phoneVerification_title;

  /// No description provided for @phoneVerification_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification du téléphone'**
  String get phoneVerification_subtitle;

  /// No description provided for @phoneVerification_enterCode.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code à 6 chiffres envoyé au'**
  String get phoneVerification_enterCode;

  /// No description provided for @phoneVerification_invalidCode.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer le code complet à 6 chiffres'**
  String get phoneVerification_invalidCode;

  /// No description provided for @phoneVerification_codeSent.
  ///
  /// In fr, this message translates to:
  /// **'Code de vérification envoyé'**
  String get phoneVerification_codeSent;

  /// No description provided for @phoneVerification_verify.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get phoneVerification_verify;

  /// No description provided for @phoneVerification_noCode.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas reçu le code? '**
  String get phoneVerification_noCode;

  /// No description provided for @phoneVerification_resend.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer'**
  String get phoneVerification_resend;

  /// No description provided for @phoneVerification_resendIn.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer dans {seconds}s'**
  String phoneVerification_resendIn(int seconds);

  /// No description provided for @phoneVerification_changeNumber.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le numéro'**
  String get phoneVerification_changeNumber;

  /// No description provided for @phoneVerification_devCode.
  ///
  /// In fr, this message translates to:
  /// **'Mode dev - Code: {code}'**
  String phoneVerification_devCode(String code);

  /// No description provided for @home_greeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, {name}'**
  String home_greeting(String name);

  /// No description provided for @home_clientHome.
  ///
  /// In fr, this message translates to:
  /// **'Client Home'**
  String get home_clientHome;

  /// No description provided for @home_snowWorkerDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Snow Worker Dashboard'**
  String get home_snowWorkerDashboard;

  /// No description provided for @home_adminDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Admin Dashboard'**
  String get home_adminDashboard;

  /// No description provided for @weather_title.
  ///
  /// In fr, this message translates to:
  /// **'Météo'**
  String get weather_title;

  /// No description provided for @weather_unavailable.
  ///
  /// In fr, this message translates to:
  /// **'Données météo non disponibles'**
  String get weather_unavailable;

  /// No description provided for @weather_humidity.
  ///
  /// In fr, this message translates to:
  /// **'Humidité'**
  String get weather_humidity;

  /// No description provided for @weather_wind.
  ///
  /// In fr, this message translates to:
  /// **'Vent'**
  String get weather_wind;

  /// No description provided for @weather_snowDepth.
  ///
  /// In fr, this message translates to:
  /// **'Neige au sol'**
  String get weather_snowDepth;

  /// No description provided for @weather_snowAlert.
  ///
  /// In fr, this message translates to:
  /// **'Alerte neige'**
  String get weather_snowAlert;

  /// No description provided for @weather_snowAlertDefault.
  ///
  /// In fr, this message translates to:
  /// **'Prévision de chutes de neige importantes'**
  String get weather_snowAlertDefault;

  /// No description provided for @notifications_title.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications_title;

  /// No description provided for @notifications_readAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout lire'**
  String get notifications_readAll;

  /// No description provided for @notifications_empty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get notifications_empty;

  /// No description provided for @notifications_emptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas de nouvelles notifications'**
  String get notifications_emptySubtitle;

  /// No description provided for @notifications_unreadSingular.
  ///
  /// In fr, this message translates to:
  /// **'notification non lue'**
  String get notifications_unreadSingular;

  /// No description provided for @notifications_unreadPlural.
  ///
  /// In fr, this message translates to:
  /// **'notifications non lues'**
  String get notifications_unreadPlural;

  /// No description provided for @notifications_settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres de notification'**
  String get notifications_settings;

  /// No description provided for @reservation_myReservations.
  ///
  /// In fr, this message translates to:
  /// **'Mes réservations'**
  String get reservation_myReservations;

  /// No description provided for @reservation_empty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réservation'**
  String get reservation_empty;

  /// No description provided for @reservation_emptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Commencez par créer votre première réservation'**
  String get reservation_emptySubtitle;

  /// No description provided for @reservation_new.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle réservation'**
  String get reservation_new;

  /// No description provided for @reservation_newShort.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle'**
  String get reservation_newShort;

  /// No description provided for @reservation_parkingSpot.
  ///
  /// In fr, this message translates to:
  /// **'Place {name}'**
  String reservation_parkingSpot(String name);

  /// No description provided for @reservation_details.
  ///
  /// In fr, this message translates to:
  /// **'Détails de la réservation'**
  String get reservation_details;

  /// No description provided for @reservation_notFound.
  ///
  /// In fr, this message translates to:
  /// **'Réservation introuvable'**
  String get reservation_notFound;

  /// No description provided for @reservation_notFoundSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Cette réservation n\'existe plus ou a été supprimée'**
  String get reservation_notFoundSubtitle;

  /// No description provided for @reservation_refresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get reservation_refresh;

  /// No description provided for @reservation_live.
  ///
  /// In fr, this message translates to:
  /// **'EN DIRECT'**
  String get reservation_live;

  /// No description provided for @reservation_statusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente d\'un déneigeur disponible'**
  String get reservation_statusPending;

  /// No description provided for @reservation_statusAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Un déneigeur a été assigné à votre demande'**
  String get reservation_statusAssigned;

  /// No description provided for @reservation_statusEnRoute.
  ///
  /// In fr, this message translates to:
  /// **'{name} est en route vers vous'**
  String reservation_statusEnRoute(String name);

  /// No description provided for @reservation_statusInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Votre véhicule est en cours de déneigement'**
  String get reservation_statusInProgress;

  /// No description provided for @reservation_statusCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Service terminé avec succès'**
  String get reservation_statusCompleted;

  /// No description provided for @reservation_statusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Cette réservation a été annulée'**
  String get reservation_statusCancelled;

  /// No description provided for @reservation_statusDelayed.
  ///
  /// In fr, this message translates to:
  /// **'Le service est en retard'**
  String get reservation_statusDelayed;

  /// No description provided for @reservation_progress.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get reservation_progress;

  /// No description provided for @reservation_shortPending.
  ///
  /// In fr, this message translates to:
  /// **'Attente'**
  String get reservation_shortPending;

  /// No description provided for @reservation_shortAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Assigné'**
  String get reservation_shortAssigned;

  /// No description provided for @reservation_shortEnRoute.
  ///
  /// In fr, this message translates to:
  /// **'En route'**
  String get reservation_shortEnRoute;

  /// No description provided for @reservation_shortInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get reservation_shortInProgress;

  /// No description provided for @reservation_shortCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get reservation_shortCompleted;

  /// No description provided for @reservation_shortCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get reservation_shortCancelled;

  /// No description provided for @reservation_shortDelayed.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get reservation_shortDelayed;

  /// No description provided for @reservation_yourWorker.
  ///
  /// In fr, this message translates to:
  /// **'Votre déneigeur'**
  String get reservation_yourWorker;

  /// No description provided for @reservation_workerAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Déneigeur assigné'**
  String get reservation_workerAssigned;

  /// No description provided for @reservation_map.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get reservation_map;

  /// No description provided for @reservation_chat.
  ///
  /// In fr, this message translates to:
  /// **'Chat'**
  String get reservation_chat;

  /// No description provided for @reservation_userNotAuth.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: utilisateur non authentifié'**
  String get reservation_userNotAuth;

  /// No description provided for @reservation_noWorkerYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun déneigeur assigné pour le moment'**
  String get reservation_noWorkerYet;

  /// No description provided for @reservation_info.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get reservation_info;

  /// No description provided for @reservation_vehicle.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule'**
  String get reservation_vehicle;

  /// No description provided for @reservation_location.
  ///
  /// In fr, this message translates to:
  /// **'Emplacement'**
  String get reservation_location;

  /// No description provided for @reservation_departureTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure de départ souhaitée'**
  String get reservation_departureTime;

  /// No description provided for @reservation_assignedAt.
  ///
  /// In fr, this message translates to:
  /// **'Assignée le'**
  String get reservation_assignedAt;

  /// No description provided for @reservation_startedAt.
  ///
  /// In fr, this message translates to:
  /// **'Commencée le'**
  String get reservation_startedAt;

  /// No description provided for @reservation_completedAt.
  ///
  /// In fr, this message translates to:
  /// **'Terminée le'**
  String get reservation_completedAt;

  /// No description provided for @reservation_servicesRequested.
  ///
  /// In fr, this message translates to:
  /// **'Services demandés'**
  String get reservation_servicesRequested;

  /// No description provided for @reservation_basicSnowRemoval.
  ///
  /// In fr, this message translates to:
  /// **'Déneigement de base'**
  String get reservation_basicSnowRemoval;

  /// No description provided for @reservation_snowDepthCm.
  ///
  /// In fr, this message translates to:
  /// **'Profondeur de neige: {depth} cm'**
  String reservation_snowDepthCm(String depth);

  /// No description provided for @reservation_photos.
  ///
  /// In fr, this message translates to:
  /// **'Photos du service'**
  String get reservation_photos;

  /// No description provided for @reservation_afterPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Résultat final'**
  String get reservation_afterPhoto;

  /// No description provided for @reservation_photoUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Photo non disponible'**
  String get reservation_photoUnavailable;

  /// No description provided for @reservation_tapToEnlarge.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez pour agrandir'**
  String get reservation_tapToEnlarge;

  /// No description provided for @reservation_beforePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Avant le service'**
  String get reservation_beforePhoto;

  /// No description provided for @reservation_totalPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix total'**
  String get reservation_totalPrice;

  /// No description provided for @reservation_tipAmount.
  ///
  /// In fr, this message translates to:
  /// **'+{amount}\$ pourboire'**
  String reservation_tipAmount(String amount);

  /// No description provided for @reservation_urgent.
  ///
  /// In fr, this message translates to:
  /// **'URGENT'**
  String get reservation_urgent;

  /// No description provided for @reservation_yourRating.
  ///
  /// In fr, this message translates to:
  /// **'Votre évaluation'**
  String get reservation_yourRating;

  /// No description provided for @reservation_rateService.
  ///
  /// In fr, this message translates to:
  /// **'Évaluer le service'**
  String get reservation_rateService;

  /// No description provided for @reservation_rateSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Partagez votre expérience et ajoutez un pourboire'**
  String get reservation_rateSubtitle;

  /// No description provided for @reservation_edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la réservation'**
  String get reservation_edit;

  /// No description provided for @reservation_cancelReservation.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la réservation'**
  String get reservation_cancelReservation;

  /// No description provided for @reservation_cancelFullRefund.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement complet - Aucun frais'**
  String get reservation_cancelFullRefund;

  /// No description provided for @reservation_cancelHalfRefund.
  ///
  /// In fr, this message translates to:
  /// **'Le déneigeur est en route.\nFrais d\'annulation: 50% ({amount}\$)'**
  String reservation_cancelHalfRefund(String amount);

  /// No description provided for @reservation_cancelNoRefund.
  ///
  /// In fr, this message translates to:
  /// **'Le travail a commencé.\nAucun remboursement (100% facturé)'**
  String get reservation_cancelNoRefund;

  /// No description provided for @reservation_cancelConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler?'**
  String get reservation_cancelConfirmTitle;

  /// No description provided for @reservation_cancelConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir annuler cette réservation?'**
  String get reservation_cancelConfirmMessage;

  /// No description provided for @reservation_cancelKeep.
  ///
  /// In fr, this message translates to:
  /// **'Non, garder'**
  String get reservation_cancelKeep;

  /// No description provided for @reservation_cancelYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui, annuler'**
  String get reservation_cancelYes;

  /// No description provided for @reservation_phoneUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone non disponible'**
  String get reservation_phoneUnavailable;

  /// No description provided for @reservation_noShowReported.
  ///
  /// In fr, this message translates to:
  /// **'Signalement envoyé'**
  String get reservation_noShowReported;

  /// No description provided for @reservation_reportNoShow.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un no-show'**
  String get reservation_reportNoShow;

  /// No description provided for @reservation_modifiedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Réservation modifiée avec succès'**
  String get reservation_modifiedSuccess;

  /// No description provided for @reservation_editTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la réservation'**
  String get reservation_editTitle;

  /// No description provided for @reservation_editImpossible.
  ///
  /// In fr, this message translates to:
  /// **'Modification impossible'**
  String get reservation_editImpossible;

  /// No description provided for @reservation_editImpossibleMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette réservation ne peut plus être modifiée.\nSeules les réservations en attente peuvent être éditées.'**
  String get reservation_editImpossibleMessage;

  /// No description provided for @reservation_editSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifiez les informations ci-dessous'**
  String get reservation_editSubtitle;

  /// No description provided for @reservation_selectVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner un véhicule'**
  String get reservation_selectVehicle;

  /// No description provided for @reservation_selectSpot.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une place'**
  String get reservation_selectSpot;

  /// No description provided for @reservation_vehicleAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse du véhicule'**
  String get reservation_vehicleAddress;

  /// No description provided for @reservation_addressHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 123 Rue Principale, Montréal, QC'**
  String get reservation_addressHint;

  /// No description provided for @reservation_gpsRecorded.
  ///
  /// In fr, this message translates to:
  /// **'Position GPS enregistrée'**
  String get reservation_gpsRecorded;

  /// No description provided for @reservation_addressValidated.
  ///
  /// In fr, this message translates to:
  /// **'Adresse validée avec succès'**
  String get reservation_addressValidated;

  /// No description provided for @reservation_addressNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Adresse non trouvée. Veuillez réessayer.'**
  String get reservation_addressNotFound;

  /// No description provided for @reservation_addressError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la recherche de l\'adresse'**
  String get reservation_addressError;

  /// No description provided for @reservation_selectDateTime.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une date et heure'**
  String get reservation_selectDateTime;

  /// No description provided for @reservation_noDateSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune date sélectionnée'**
  String get reservation_noDateSelected;

  /// No description provided for @reservation_serviceOptions.
  ///
  /// In fr, this message translates to:
  /// **'Options de service'**
  String get reservation_serviceOptions;

  /// No description provided for @reservation_windowScraping.
  ///
  /// In fr, this message translates to:
  /// **'Grattage des vitres'**
  String get reservation_windowScraping;

  /// No description provided for @reservation_doorDeicing.
  ///
  /// In fr, this message translates to:
  /// **'Déglaçage des portes'**
  String get reservation_doorDeicing;

  /// No description provided for @reservation_wheelClearing.
  ///
  /// In fr, this message translates to:
  /// **'Dégagement des roues'**
  String get reservation_wheelClearing;

  /// No description provided for @reservation_roofSnowRemoval.
  ///
  /// In fr, this message translates to:
  /// **'Déneigement du toit'**
  String get reservation_roofSnowRemoval;

  /// No description provided for @reservation_saltSpreading.
  ///
  /// In fr, this message translates to:
  /// **'Épandage de sel'**
  String get reservation_saltSpreading;

  /// No description provided for @reservation_lightsCleanup.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyage phares/feux'**
  String get reservation_lightsCleanup;

  /// No description provided for @reservation_perimeterClearing.
  ///
  /// In fr, this message translates to:
  /// **'Dégagement périmètre'**
  String get reservation_perimeterClearing;

  /// No description provided for @reservation_exhaustCheck.
  ///
  /// In fr, this message translates to:
  /// **'Vérif. échappement'**
  String get reservation_exhaustCheck;

  /// No description provided for @reservation_originalPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix original'**
  String get reservation_originalPrice;

  /// No description provided for @reservation_modifying.
  ///
  /// In fr, this message translates to:
  /// **'Modification en cours...'**
  String get reservation_modifying;

  /// No description provided for @reservation_noChanges.
  ///
  /// In fr, this message translates to:
  /// **'Aucune modification'**
  String get reservation_noChanges;

  /// No description provided for @reservation_saveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get reservation_saveChanges;

  /// No description provided for @reservation_continue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get reservation_continue;

  /// No description provided for @reservation_viewSummary.
  ///
  /// In fr, this message translates to:
  /// **'Voir le résumé'**
  String get reservation_viewSummary;

  /// No description provided for @reservation_confirmAndPay.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer et payer'**
  String get reservation_confirmAndPay;

  /// No description provided for @reservation_cancelNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la réservation?'**
  String get reservation_cancelNewTitle;

  /// No description provided for @reservation_cancelNewWarning.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir quitter? Les informations saisies seront perdues.'**
  String get reservation_cancelNewWarning;

  /// No description provided for @reservation_noContinue.
  ///
  /// In fr, this message translates to:
  /// **'Non, continuer'**
  String get reservation_noContinue;

  /// No description provided for @reservation_yesCancel.
  ///
  /// In fr, this message translates to:
  /// **'Oui, annuler'**
  String get reservation_yesCancel;

  /// No description provided for @reservation_paymentMethod.
  ///
  /// In fr, this message translates to:
  /// **'Méthode de paiement'**
  String get reservation_paymentMethod;

  /// No description provided for @reservation_creditCard.
  ///
  /// In fr, this message translates to:
  /// **'Carte de crédit'**
  String get reservation_creditCard;

  /// No description provided for @reservation_creditCardSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Visa, Mastercard, Amex'**
  String get reservation_creditCardSubtitle;

  /// No description provided for @reservation_creatingReservation.
  ///
  /// In fr, this message translates to:
  /// **'Création de la réservation...'**
  String get reservation_creatingReservation;

  /// No description provided for @reservation_securePayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement sécurisé par Stripe'**
  String get reservation_securePayment;

  /// No description provided for @service_windowScraping5.
  ///
  /// In fr, this message translates to:
  /// **'+5\$'**
  String get service_windowScraping5;

  /// No description provided for @service_doorDeicing3.
  ///
  /// In fr, this message translates to:
  /// **'+3\$'**
  String get service_doorDeicing3;

  /// No description provided for @service_wheelClearing4.
  ///
  /// In fr, this message translates to:
  /// **'+4\$'**
  String get service_wheelClearing4;

  /// No description provided for @vehicle_myVehicles.
  ///
  /// In fr, this message translates to:
  /// **'Mes véhicules'**
  String get vehicle_myVehicles;

  /// No description provided for @vehicle_empty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun véhicule enregistré'**
  String get vehicle_empty;

  /// No description provided for @vehicle_emptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez votre premier véhicule pour\ncommencer à utiliser le service'**
  String get vehicle_emptySubtitle;

  /// No description provided for @vehicle_add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un véhicule'**
  String get vehicle_add;

  /// No description provided for @vehicle_photoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Photo du véhicule'**
  String get vehicle_photoTitle;

  /// No description provided for @vehicle_photoDescription.
  ///
  /// In fr, this message translates to:
  /// **'Cette photo sera visible par le déneigeur'**
  String get vehicle_photoDescription;

  /// No description provided for @vehicle_takePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get vehicle_takePhoto;

  /// No description provided for @vehicle_takePhotoSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser l\'appareil photo'**
  String get vehicle_takePhotoSubtitle;

  /// No description provided for @vehicle_choosePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une photo'**
  String get vehicle_choosePhoto;

  /// No description provided for @vehicle_choosePhotoSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Depuis la galerie'**
  String get vehicle_choosePhotoSubtitle;

  /// No description provided for @vehicle_removePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la photo'**
  String get vehicle_removePhoto;

  /// No description provided for @vehicle_removePhotoSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la photo sélectionnée'**
  String get vehicle_removePhotoSubtitle;

  /// No description provided for @vehicle_deleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le véhicule'**
  String get vehicle_deleteTitle;

  /// No description provided for @vehicle_deleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer ce véhicule ?'**
  String get vehicle_deleteConfirm;

  /// No description provided for @vehicle_tapToAddPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Touchez pour ajouter une photo'**
  String get vehicle_tapToAddPhoto;

  /// No description provided for @vehicle_newVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau véhicule'**
  String get vehicle_newVehicle;

  /// No description provided for @vehicle_brand.
  ///
  /// In fr, this message translates to:
  /// **'Marque'**
  String get vehicle_brand;

  /// No description provided for @vehicle_brandHint.
  ///
  /// In fr, this message translates to:
  /// **'Toyota'**
  String get vehicle_brandHint;

  /// No description provided for @vehicle_model.
  ///
  /// In fr, this message translates to:
  /// **'Modèle'**
  String get vehicle_model;

  /// No description provided for @vehicle_modelHint.
  ///
  /// In fr, this message translates to:
  /// **'Camry'**
  String get vehicle_modelHint;

  /// No description provided for @vehicle_year.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get vehicle_year;

  /// No description provided for @vehicle_yearHint.
  ///
  /// In fr, this message translates to:
  /// **'2024'**
  String get vehicle_yearHint;

  /// No description provided for @vehicle_plate.
  ///
  /// In fr, this message translates to:
  /// **'Plaque'**
  String get vehicle_plate;

  /// No description provided for @vehicle_plateHint.
  ///
  /// In fr, this message translates to:
  /// **'ABC 123'**
  String get vehicle_plateHint;

  /// No description provided for @vehicle_type.
  ///
  /// In fr, this message translates to:
  /// **'Type de véhicule'**
  String get vehicle_type;

  /// No description provided for @vehicle_color.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get vehicle_color;

  /// No description provided for @vehicle_setDefault.
  ///
  /// In fr, this message translates to:
  /// **'Définir comme véhicule par défaut'**
  String get vehicle_setDefault;

  /// No description provided for @vehicle_addSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter le véhicule'**
  String get vehicle_addSubmit;

  /// No description provided for @vehicle_addedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule ajouté avec succès'**
  String get vehicle_addedSuccess;

  /// No description provided for @vehicle_photoError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la sélection de la photo'**
  String get vehicle_photoError;

  /// No description provided for @vehicle_colorWhite.
  ///
  /// In fr, this message translates to:
  /// **'Blanc'**
  String get vehicle_colorWhite;

  /// No description provided for @vehicle_colorBlack.
  ///
  /// In fr, this message translates to:
  /// **'Noir'**
  String get vehicle_colorBlack;

  /// No description provided for @vehicle_colorGray.
  ///
  /// In fr, this message translates to:
  /// **'Gris'**
  String get vehicle_colorGray;

  /// No description provided for @vehicle_colorRed.
  ///
  /// In fr, this message translates to:
  /// **'Rouge'**
  String get vehicle_colorRed;

  /// No description provided for @vehicle_colorBlue.
  ///
  /// In fr, this message translates to:
  /// **'Bleu'**
  String get vehicle_colorBlue;

  /// No description provided for @vehicle_colorGreen.
  ///
  /// In fr, this message translates to:
  /// **'Vert'**
  String get vehicle_colorGreen;

  /// No description provided for @vehicle_colorYellow.
  ///
  /// In fr, this message translates to:
  /// **'Jaune'**
  String get vehicle_colorYellow;

  /// No description provided for @vehicle_colorOrange.
  ///
  /// In fr, this message translates to:
  /// **'Orange'**
  String get vehicle_colorOrange;

  /// No description provided for @vehicle_colorSilver.
  ///
  /// In fr, this message translates to:
  /// **'Argent'**
  String get vehicle_colorSilver;

  /// No description provided for @vehicle_colorBrown.
  ///
  /// In fr, this message translates to:
  /// **'Brun'**
  String get vehicle_colorBrown;

  /// No description provided for @vehicle_colorBeige.
  ///
  /// In fr, this message translates to:
  /// **'Beige'**
  String get vehicle_colorBeige;

  /// No description provided for @profile_title.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get profile_title;

  /// No description provided for @profile_defaultName.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get profile_defaultName;

  /// No description provided for @profile_defaultEmail.
  ///
  /// In fr, this message translates to:
  /// **'email@example.com'**
  String get profile_defaultEmail;

  /// No description provided for @profile_myVehicles.
  ///
  /// In fr, this message translates to:
  /// **'Mes véhicules'**
  String get profile_myVehicles;

  /// No description provided for @profile_manageVehicles.
  ///
  /// In fr, this message translates to:
  /// **'Gérer mes véhicules'**
  String get profile_manageVehicles;

  /// No description provided for @profile_payments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get profile_payments;

  /// No description provided for @profile_paymentHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique et méthodes'**
  String get profile_paymentHistory;

  /// No description provided for @profile_myDisputes.
  ///
  /// In fr, this message translates to:
  /// **'Mes litiges'**
  String get profile_myDisputes;

  /// No description provided for @profile_disputesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Signalements et réclamations'**
  String get profile_disputesSubtitle;

  /// No description provided for @profile_notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get profile_notifications;

  /// No description provided for @profile_settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get profile_settings;

  /// No description provided for @profile_settingsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Préférences de l\'app'**
  String get profile_settingsSubtitle;

  /// No description provided for @profile_helpSupport.
  ///
  /// In fr, this message translates to:
  /// **'Aide et support'**
  String get profile_helpSupport;

  /// No description provided for @profile_helpSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'FAQ et contact'**
  String get profile_helpSubtitle;

  /// No description provided for @chat_typing.
  ///
  /// In fr, this message translates to:
  /// **'En train d\'écrire...'**
  String get chat_typing;

  /// No description provided for @chat_noMessages.
  ///
  /// In fr, this message translates to:
  /// **'Aucun message'**
  String get chat_noMessages;

  /// No description provided for @chat_startConversation.
  ///
  /// In fr, this message translates to:
  /// **'Commencez la conversation!'**
  String get chat_startConversation;

  /// No description provided for @chat_inputHint.
  ///
  /// In fr, this message translates to:
  /// **'Écrire un message...'**
  String get chat_inputHint;

  /// No description provided for @aiChat_title.
  ///
  /// In fr, this message translates to:
  /// **'Assistant IA'**
  String get aiChat_title;

  /// No description provided for @aiChat_newConversation.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle conversation'**
  String get aiChat_newConversation;

  /// No description provided for @aiChat_unavailable.
  ///
  /// In fr, this message translates to:
  /// **'L\'assistant IA est temporairement indisponible'**
  String get aiChat_unavailable;

  /// No description provided for @aiChat_startConversation.
  ///
  /// In fr, this message translates to:
  /// **'Commencez une conversation'**
  String get aiChat_startConversation;

  /// No description provided for @aiChat_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Posez vos questions sur Déneige Auto'**
  String get aiChat_subtitle;

  /// No description provided for @aiChat_inputHint.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez votre message...'**
  String get aiChat_inputHint;

  /// No description provided for @settings_title.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings_title;

  /// No description provided for @settings_notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get settings_notifications;

  /// No description provided for @settings_pushNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications push'**
  String get settings_pushNotifications;

  /// No description provided for @settings_pushNotificationsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir des alertes sur votre appareil'**
  String get settings_pushNotificationsDesc;

  /// No description provided for @settings_sounds.
  ///
  /// In fr, this message translates to:
  /// **'Sons'**
  String get settings_sounds;

  /// No description provided for @settings_soundsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Activer les sons de notification'**
  String get settings_soundsDesc;

  /// No description provided for @settings_appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get settings_appearance;

  /// No description provided for @settings_darkTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème sombre'**
  String get settings_darkTheme;

  /// No description provided for @settings_darkThemeDesc.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser le thème sombre'**
  String get settings_darkThemeDesc;

  /// No description provided for @settings_language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settings_language;

  /// No description provided for @settings_languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get settings_languageFrench;

  /// No description provided for @settings_languageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get settings_languageEnglish;

  /// No description provided for @settings_account.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get settings_account;

  /// No description provided for @settings_editProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get settings_editProfile;

  /// No description provided for @settings_legal.
  ///
  /// In fr, this message translates to:
  /// **'Légal'**
  String get settings_legal;

  /// No description provided for @settings_legalMentions.
  ///
  /// In fr, this message translates to:
  /// **'Mentions légales'**
  String get settings_legalMentions;

  /// No description provided for @settings_legalSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'CGU, confidentialité, vos droits'**
  String get settings_legalSubtitle;

  /// No description provided for @settings_about.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get settings_about;

  /// No description provided for @settings_appVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version de l\'application'**
  String get settings_appVersion;

  /// No description provided for @settings_privacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get settings_privacyPolicy;

  /// No description provided for @settings_termsOfService.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get settings_termsOfService;

  /// No description provided for @settings_deleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get settings_deleteAccount;

  /// No description provided for @settings_deleteAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get settings_deleteAccountTitle;

  /// No description provided for @settings_deleteAccountWarning.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible. Toutes vos données seront supprimées.'**
  String get settings_deleteAccountWarning;

  /// No description provided for @settings_deleteAccountConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.'**
  String get settings_deleteAccountConfirm;

  /// No description provided for @settings_passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe requis'**
  String get settings_passwordRequired;

  /// No description provided for @settings_enterPassword.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre mot de passe pour confirmer:'**
  String get settings_enterPassword;

  /// No description provided for @support_title.
  ///
  /// In fr, this message translates to:
  /// **'Aide et Support'**
  String get support_title;

  /// No description provided for @support_faq.
  ///
  /// In fr, this message translates to:
  /// **'FAQ'**
  String get support_faq;

  /// No description provided for @support_contact.
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get support_contact;

  /// No description provided for @support_all.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get support_all;

  /// No description provided for @support_submitRequest.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get support_submitRequest;

  /// No description provided for @support_yourMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre message'**
  String get support_yourMessage;

  /// No description provided for @support_writeResponse.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez écrire une réponse'**
  String get support_writeResponse;

  /// No description provided for @support_respond.
  ///
  /// In fr, this message translates to:
  /// **'Répondre'**
  String get support_respond;

  /// No description provided for @support_respondToRequest.
  ///
  /// In fr, this message translates to:
  /// **'Répondre à la demande'**
  String get support_respondToRequest;

  /// No description provided for @rating_question.
  ///
  /// In fr, this message translates to:
  /// **'Comment s\'est passé le déneigement ?'**
  String get rating_question;

  /// No description provided for @rating_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre avis aide à améliorer le service'**
  String get rating_subtitle;

  /// No description provided for @rating_1star.
  ///
  /// In fr, this message translates to:
  /// **'Très insatisfait'**
  String get rating_1star;

  /// No description provided for @rating_2stars.
  ///
  /// In fr, this message translates to:
  /// **'Insatisfait'**
  String get rating_2stars;

  /// No description provided for @rating_3stars.
  ///
  /// In fr, this message translates to:
  /// **'Correct'**
  String get rating_3stars;

  /// No description provided for @rating_4stars.
  ///
  /// In fr, this message translates to:
  /// **'Satisfait'**
  String get rating_4stars;

  /// No description provided for @rating_5stars.
  ///
  /// In fr, this message translates to:
  /// **'Excellent !'**
  String get rating_5stars;

  /// No description provided for @rating_tapToRate.
  ///
  /// In fr, this message translates to:
  /// **'Touchez pour noter'**
  String get rating_tapToRate;

  /// No description provided for @rating_selectRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une note'**
  String get rating_selectRequired;

  /// No description provided for @rating_commentHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un commentaire (optionnel)'**
  String get rating_commentHint;

  /// No description provided for @rating_submit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer mon avis'**
  String get rating_submit;

  /// No description provided for @rating_later.
  ///
  /// In fr, this message translates to:
  /// **'Peut-être plus tard'**
  String get rating_later;

  /// No description provided for @rating_workerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déneigeur'**
  String get rating_workerTitle;

  /// No description provided for @suspension_title.
  ///
  /// In fr, this message translates to:
  /// **'Compte Suspendu'**
  String get suspension_title;

  /// No description provided for @suspension_reason.
  ///
  /// In fr, this message translates to:
  /// **'Raison:'**
  String get suspension_reason;

  /// No description provided for @suspension_until.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'au: {date}'**
  String suspension_until(String date);

  /// No description provided for @suspension_contactSupport.
  ///
  /// In fr, this message translates to:
  /// **'Contactez le support au \"deneigeauto@yahoo.com\" si vous pensez qu\'il s\'agit d\'une erreur.'**
  String get suspension_contactSupport;

  /// No description provided for @worker_available.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get worker_available;

  /// No description provided for @worker_offline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get worker_offline;

  /// No description provided for @worker_verificationPending.
  ///
  /// In fr, this message translates to:
  /// **'Vérification en cours'**
  String get worker_verificationPending;

  /// No description provided for @worker_verificationPendingMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vos documents sont en cours d\'analyse. Vous serez notifié une fois la vérification terminée.'**
  String get worker_verificationPendingMessage;

  /// No description provided for @worker_verificationRejected.
  ///
  /// In fr, this message translates to:
  /// **'Vérification refusée'**
  String get worker_verificationRejected;

  /// No description provided for @worker_verificationRejectedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vos documents n\'ont pas été approuvés. Veuillez resoumettre des documents valides.'**
  String get worker_verificationRejectedMessage;

  /// No description provided for @worker_verificationExpired.
  ///
  /// In fr, this message translates to:
  /// **'Vérification expirée'**
  String get worker_verificationExpired;

  /// No description provided for @worker_verificationExpiredMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre vérification a expiré. Veuillez resoumettre vos documents.'**
  String get worker_verificationExpiredMessage;

  /// No description provided for @worker_verificationRequired.
  ///
  /// In fr, this message translates to:
  /// **'Vérification requise'**
  String get worker_verificationRequired;

  /// No description provided for @worker_verificationRequiredMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre identité pour pouvoir accepter des jobs de déneigement.'**
  String get worker_verificationRequiredMessage;

  /// No description provided for @worker_verify.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get worker_verify;

  /// No description provided for @worker_youAreAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes disponible'**
  String get worker_youAreAvailable;

  /// No description provided for @worker_youAreOffline.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes hors ligne'**
  String get worker_youAreOffline;

  /// No description provided for @worker_receivingJobs.
  ///
  /// In fr, this message translates to:
  /// **'Vous recevez les nouveaux jobs'**
  String get worker_receivingJobs;

  /// No description provided for @worker_activateToReceive.
  ///
  /// In fr, this message translates to:
  /// **'Activez pour recevoir des jobs'**
  String get worker_activateToReceive;

  /// No description provided for @worker_jobsCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Jobs terminés'**
  String get worker_jobsCompleted;

  /// No description provided for @worker_todayLabel.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get worker_todayLabel;

  /// No description provided for @worker_ratingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get worker_ratingLabel;

  /// No description provided for @worker_myActiveJobs.
  ///
  /// In fr, this message translates to:
  /// **'Mes jobs actifs'**
  String get worker_myActiveJobs;

  /// No description provided for @worker_activeJobSingular.
  ///
  /// In fr, this message translates to:
  /// **'actif'**
  String get worker_activeJobSingular;

  /// No description provided for @worker_activeJobPlural.
  ///
  /// In fr, this message translates to:
  /// **'actifs'**
  String get worker_activeJobPlural;

  /// No description provided for @worker_availableJobs.
  ///
  /// In fr, this message translates to:
  /// **'Jobs disponibles'**
  String get worker_availableJobs;

  /// No description provided for @worker_newJob.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau job!'**
  String get worker_newJob;

  /// No description provided for @worker_newJobs.
  ///
  /// In fr, this message translates to:
  /// **'{count} nouveaux jobs!'**
  String worker_newJobs(int count);

  /// No description provided for @worker_configureEquipment.
  ///
  /// In fr, this message translates to:
  /// **'Configurez votre équipement'**
  String get worker_configureEquipment;

  /// No description provided for @worker_configureEquipmentMessage.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez vos équipements pour voir les jobs disponibles.'**
  String get worker_configureEquipmentMessage;

  /// No description provided for @worker_configure.
  ///
  /// In fr, this message translates to:
  /// **'Configurer'**
  String get worker_configure;

  /// No description provided for @worker_waitingForJobs.
  ///
  /// In fr, this message translates to:
  /// **'En attente de jobs...'**
  String get worker_waitingForJobs;

  /// No description provided for @worker_waitingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les nouveaux jobs apparaîtront ici automatiquement'**
  String get worker_waitingSubtitle;

  /// No description provided for @worker_addMoreEquipment.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez plus d\'équipements pour recevoir plus de jobs.'**
  String get worker_addMoreEquipment;

  /// No description provided for @worker_autoRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualisation auto. toutes les 15s'**
  String get worker_autoRefresh;

  /// No description provided for @worker_oops.
  ///
  /// In fr, this message translates to:
  /// **'Oups!'**
  String get worker_oops;

  /// No description provided for @worker_badge.
  ///
  /// In fr, this message translates to:
  /// **'Déneigeur'**
  String get worker_badge;

  /// No description provided for @worker_equipment.
  ///
  /// In fr, this message translates to:
  /// **'Équipement'**
  String get worker_equipment;

  /// No description provided for @worker_preferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get worker_preferences;

  /// No description provided for @worker_equipShovel.
  ///
  /// In fr, this message translates to:
  /// **'Pelle'**
  String get worker_equipShovel;

  /// No description provided for @worker_equipBroom.
  ///
  /// In fr, this message translates to:
  /// **'Balai'**
  String get worker_equipBroom;

  /// No description provided for @worker_equipScraper.
  ///
  /// In fr, this message translates to:
  /// **'Grattoir'**
  String get worker_equipScraper;

  /// No description provided for @worker_equipSaltSpreader.
  ///
  /// In fr, this message translates to:
  /// **'Sel/Épandeur'**
  String get worker_equipSaltSpreader;

  /// No description provided for @worker_equipSnowBlower.
  ///
  /// In fr, this message translates to:
  /// **'Souffleuse'**
  String get worker_equipSnowBlower;

  /// No description provided for @worker_equipRoofBroom.
  ///
  /// In fr, this message translates to:
  /// **'Balai toit'**
  String get worker_equipRoofBroom;

  /// No description provided for @worker_equipCloth.
  ///
  /// In fr, this message translates to:
  /// **'Chiffon'**
  String get worker_equipCloth;

  /// No description provided for @worker_equipDeicer.
  ///
  /// In fr, this message translates to:
  /// **'Déglacant'**
  String get worker_equipDeicer;

  /// No description provided for @worker_maxSimultaneousJobs.
  ///
  /// In fr, this message translates to:
  /// **'Jobs simultanés max'**
  String get worker_maxSimultaneousJobs;

  /// No description provided for @worker_maxSimultaneousJobsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de jobs actifs en même temps'**
  String get worker_maxSimultaneousJobsDesc;

  /// No description provided for @worker_notifNewJobs.
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux jobs'**
  String get worker_notifNewJobs;

  /// No description provided for @worker_notifUrgentJobs.
  ///
  /// In fr, this message translates to:
  /// **'Jobs urgents'**
  String get worker_notifUrgentJobs;

  /// No description provided for @worker_notifTipsReceived.
  ///
  /// In fr, this message translates to:
  /// **'Pourboires reçus'**
  String get worker_notifTipsReceived;

  /// No description provided for @worker_helpSupport.
  ///
  /// In fr, this message translates to:
  /// **'Aide et support'**
  String get worker_helpSupport;

  /// No description provided for @worker_jobDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails du job'**
  String get worker_jobDetails;

  /// No description provided for @worker_clientCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Le client a annulé la réservation'**
  String get worker_clientCancelled;

  /// No description provided for @worker_jobCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Job annulé'**
  String get worker_jobCancelled;

  /// No description provided for @worker_clientCancelledMessage.
  ///
  /// In fr, this message translates to:
  /// **'Le client a annulé cette réservation.'**
  String get worker_clientCancelledMessage;

  /// No description provided for @worker_cancelledMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette réservation a été annulée.'**
  String get worker_cancelledMessage;

  /// No description provided for @worker_cancelReason.
  ///
  /// In fr, this message translates to:
  /// **'Raison: {reason}'**
  String worker_cancelReason(String reason);

  /// No description provided for @worker_backToDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Retour au tableau de bord'**
  String get worker_backToDashboard;

  /// No description provided for @worker_client.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get worker_client;

  /// No description provided for @worker_googleMaps.
  ///
  /// In fr, this message translates to:
  /// **'Google Maps'**
  String get worker_googleMaps;

  /// No description provided for @worker_waze.
  ///
  /// In fr, this message translates to:
  /// **'Waze'**
  String get worker_waze;

  /// No description provided for @worker_service.
  ///
  /// In fr, this message translates to:
  /// **'Service'**
  String get worker_service;

  /// No description provided for @worker_snowRemoval.
  ///
  /// In fr, this message translates to:
  /// **'Déneigement'**
  String get worker_snowRemoval;

  /// No description provided for @worker_options.
  ///
  /// In fr, this message translates to:
  /// **'Options:'**
  String get worker_options;

  /// No description provided for @worker_pricing.
  ///
  /// In fr, this message translates to:
  /// **'Tarification'**
  String get worker_pricing;

  /// No description provided for @worker_tip.
  ///
  /// In fr, this message translates to:
  /// **'Pourboire'**
  String get worker_tip;

  /// No description provided for @worker_clientNotes.
  ///
  /// In fr, this message translates to:
  /// **'Notes du client'**
  String get worker_clientNotes;

  /// No description provided for @worker_jobAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Job accepté avec succès!'**
  String get worker_jobAccepted;

  /// No description provided for @worker_acceptJob.
  ///
  /// In fr, this message translates to:
  /// **'Accepter ce job'**
  String get worker_acceptJob;

  /// No description provided for @worker_cancelJobTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le job?'**
  String get worker_cancelJobTitle;

  /// No description provided for @worker_cancelJobWarning.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne serez pas payé pour ce job.\nLes annulations fréquentes peuvent entraîner une suspension.'**
  String get worker_cancelJobWarning;

  /// No description provided for @worker_cancelReason_label.
  ///
  /// In fr, this message translates to:
  /// **'Raison de l\'annulation:'**
  String get worker_cancelReason_label;

  /// No description provided for @worker_cancelDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails supplémentaires (optionnel)'**
  String get worker_cancelDetails;

  /// No description provided for @worker_cancelConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer l\'annulation'**
  String get worker_cancelConfirm;

  /// No description provided for @worker_cancelVehicleBreakdown.
  ///
  /// In fr, this message translates to:
  /// **'Panne de véhicule'**
  String get worker_cancelVehicleBreakdown;

  /// No description provided for @worker_cancelVehicleBreakdownDesc.
  ///
  /// In fr, this message translates to:
  /// **'Mon véhicule est en panne ou a un problème mécanique'**
  String get worker_cancelVehicleBreakdownDesc;

  /// No description provided for @worker_cancelMedicalEmergency.
  ///
  /// In fr, this message translates to:
  /// **'Urgence médicale'**
  String get worker_cancelMedicalEmergency;

  /// No description provided for @worker_cancelMedicalEmergencyDesc.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai une urgence médicale personnelle'**
  String get worker_cancelMedicalEmergencyDesc;

  /// No description provided for @worker_cancelDangerousWeather.
  ///
  /// In fr, this message translates to:
  /// **'Conditions météo dangereuses'**
  String get worker_cancelDangerousWeather;

  /// No description provided for @worker_cancelDangerousWeatherDesc.
  ///
  /// In fr, this message translates to:
  /// **'Les conditions météo rendent le trajet dangereux'**
  String get worker_cancelDangerousWeatherDesc;

  /// No description provided for @worker_cancelRoadBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Route bloquée'**
  String get worker_cancelRoadBlocked;

  /// No description provided for @worker_cancelRoadBlockedDesc.
  ///
  /// In fr, this message translates to:
  /// **'La route vers le client est bloquée ou inaccessible'**
  String get worker_cancelRoadBlockedDesc;

  /// No description provided for @worker_cancelFamilyEmergency.
  ///
  /// In fr, this message translates to:
  /// **'Urgence familiale'**
  String get worker_cancelFamilyEmergency;

  /// No description provided for @worker_cancelFamilyEmergencyDesc.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai une urgence familiale'**
  String get worker_cancelFamilyEmergencyDesc;

  /// No description provided for @worker_cancelEquipmentFailure.
  ///
  /// In fr, this message translates to:
  /// **'Équipement défaillant'**
  String get worker_cancelEquipmentFailure;

  /// No description provided for @worker_cancelEquipmentFailureDesc.
  ///
  /// In fr, this message translates to:
  /// **'Mon équipement de déneigement est défaillant'**
  String get worker_cancelEquipmentFailureDesc;

  /// No description provided for @worker_settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get worker_settingsTitle;

  /// No description provided for @worker_myEquipment.
  ///
  /// In fr, this message translates to:
  /// **'Mon équipement'**
  String get worker_myEquipment;

  /// No description provided for @worker_snowShovel.
  ///
  /// In fr, this message translates to:
  /// **'Pelle à neige'**
  String get worker_snowShovel;

  /// No description provided for @worker_snowBroom.
  ///
  /// In fr, this message translates to:
  /// **'Balai à neige'**
  String get worker_snowBroom;

  /// No description provided for @worker_iceScraper.
  ///
  /// In fr, this message translates to:
  /// **'Grattoir à glace'**
  String get worker_iceScraper;

  /// No description provided for @worker_myVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Mon véhicule'**
  String get worker_myVehicle;

  /// No description provided for @worker_workPreferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences de travail'**
  String get worker_workPreferences;

  /// No description provided for @worker_preferredZones.
  ///
  /// In fr, this message translates to:
  /// **'Zones préférées'**
  String get worker_preferredZones;

  /// No description provided for @worker_notifReception.
  ///
  /// In fr, this message translates to:
  /// **'Notification de réception'**
  String get worker_notifReception;

  /// No description provided for @worker_otherVehicleType.
  ///
  /// In fr, this message translates to:
  /// **'Autre type de véhicule'**
  String get worker_otherVehicleType;

  /// No description provided for @worker_earningsCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminés'**
  String get worker_earningsCompleted;

  /// No description provided for @worker_earningsAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Assignés'**
  String get worker_earningsAssigned;

  /// No description provided for @worker_noJobs.
  ///
  /// In fr, this message translates to:
  /// **'Aucun job disponible'**
  String get worker_noJobs;

  /// No description provided for @worker_noJobsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les nouveaux jobs apparaîtront ici'**
  String get worker_noJobsSubtitle;

  /// No description provided for @worker_noAssignedJobs.
  ///
  /// In fr, this message translates to:
  /// **'Aucun job assigné'**
  String get worker_noAssignedJobs;

  /// No description provided for @worker_noAssignedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Acceptez des jobs disponibles pour les voir ici'**
  String get worker_noAssignedSubtitle;

  /// No description provided for @worker_jobs.
  ///
  /// In fr, this message translates to:
  /// **'Jobs'**
  String get worker_jobs;

  /// No description provided for @verification_title.
  ///
  /// In fr, this message translates to:
  /// **'Vérification d\'identité'**
  String get verification_title;

  /// No description provided for @verification_verifyIdentity.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre identité'**
  String get verification_verifyIdentity;

  /// No description provided for @verification_idDocument.
  ///
  /// In fr, this message translates to:
  /// **'Pièce d\'identité'**
  String get verification_idDocument;

  /// No description provided for @verification_idDocumentDesc.
  ///
  /// In fr, this message translates to:
  /// **'Photographiez le recto (et verso si disponible) de votre pièce d\'identité'**
  String get verification_idDocumentDesc;

  /// No description provided for @verification_selfie.
  ///
  /// In fr, this message translates to:
  /// **'Selfie'**
  String get verification_selfie;

  /// No description provided for @verification_selfieDesc.
  ///
  /// In fr, this message translates to:
  /// **'Prenez un selfie pour confirmer que vous êtes bien la personne sur la pièce d\'identité'**
  String get verification_selfieDesc;

  /// No description provided for @verification_autoVerification.
  ///
  /// In fr, this message translates to:
  /// **'Vérification automatique'**
  String get verification_autoVerification;

  /// No description provided for @verification_autoVerificationDesc.
  ///
  /// In fr, this message translates to:
  /// **'Notre système vérifie vos documents en quelques minutes'**
  String get verification_autoVerificationDesc;

  /// No description provided for @verification_acceptedDocuments.
  ///
  /// In fr, this message translates to:
  /// **'Documents acceptés'**
  String get verification_acceptedDocuments;

  /// No description provided for @verification_permanentResident.
  ///
  /// In fr, this message translates to:
  /// **'Carte de résident permanent'**
  String get verification_permanentResident;

  /// No description provided for @verification_startVerification.
  ///
  /// In fr, this message translates to:
  /// **'Commencer la vérification'**
  String get verification_startVerification;

  /// No description provided for @verification_verified.
  ///
  /// In fr, this message translates to:
  /// **'Identité vérifiée'**
  String get verification_verified;

  /// No description provided for @verification_verifiedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez maintenant accepter des jobs de déneigement'**
  String get verification_verifiedMessage;

  /// No description provided for @verification_pendingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification en cours'**
  String get verification_pendingTitle;

  /// No description provided for @verification_rejectedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification refusée'**
  String get verification_rejectedTitle;

  /// No description provided for @verification_expiredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification expirée'**
  String get verification_expiredTitle;

  /// No description provided for @verification_renew.
  ///
  /// In fr, this message translates to:
  /// **'Renouveler ma vérification'**
  String get verification_renew;

  /// No description provided for @verification_useCamera.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser la caméra'**
  String get verification_useCamera;

  /// No description provided for @verification_captureIdFront.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez photographier le recto de votre pièce d\'identité'**
  String get verification_captureIdFront;

  /// No description provided for @verification_selfieFaceComparison.
  ///
  /// In fr, this message translates to:
  /// **'Nous comparerons votre visage avec votre pièce d\'identité'**
  String get verification_selfieFaceComparison;

  /// No description provided for @verification_summary.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif'**
  String get verification_summary;

  /// No description provided for @verification_submitForVerification.
  ///
  /// In fr, this message translates to:
  /// **'Soumettre pour vérification'**
  String get verification_submitForVerification;

  /// No description provided for @verification_submitted.
  ///
  /// In fr, this message translates to:
  /// **'Documents soumis avec succès. Vérification en cours...'**
  String get verification_submitted;

  /// No description provided for @dispute_myDisputes.
  ///
  /// In fr, this message translates to:
  /// **'Mes litiges'**
  String get dispute_myDisputes;

  /// No description provided for @dispute_all.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get dispute_all;

  /// No description provided for @dispute_open.
  ///
  /// In fr, this message translates to:
  /// **'Ouverts'**
  String get dispute_open;

  /// No description provided for @dispute_underReview.
  ///
  /// In fr, this message translates to:
  /// **'En examen'**
  String get dispute_underReview;

  /// No description provided for @dispute_resolved.
  ///
  /// In fr, this message translates to:
  /// **'Résolus'**
  String get dispute_resolved;

  /// No description provided for @dispute_details.
  ///
  /// In fr, this message translates to:
  /// **'Détails du litige'**
  String get dispute_details;

  /// No description provided for @dispute_resolutionExpectedBefore.
  ///
  /// In fr, this message translates to:
  /// **'Résolution attendue avant'**
  String get dispute_resolutionExpectedBefore;

  /// No description provided for @dispute_resolution.
  ///
  /// In fr, this message translates to:
  /// **'Résolution'**
  String get dispute_resolution;

  /// No description provided for @dispute_decision.
  ///
  /// In fr, this message translates to:
  /// **'Décision'**
  String get dispute_decision;

  /// No description provided for @dispute_respondentResponse.
  ///
  /// In fr, this message translates to:
  /// **'Réponse du défendeur'**
  String get dispute_respondentResponse;

  /// No description provided for @dispute_noResponse.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réponse'**
  String get dispute_noResponse;

  /// No description provided for @dispute_recommendedDecision.
  ///
  /// In fr, this message translates to:
  /// **'Décision recommandée'**
  String get dispute_recommendedDecision;

  /// No description provided for @dispute_suggestedRefund.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement suggéré'**
  String get dispute_suggestedRefund;

  /// No description provided for @dispute_respond.
  ///
  /// In fr, this message translates to:
  /// **'Répondre'**
  String get dispute_respond;

  /// No description provided for @dispute_reportProblem.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un problème'**
  String get dispute_reportProblem;

  /// No description provided for @dispute_problemType.
  ///
  /// In fr, this message translates to:
  /// **'Type de problème'**
  String get dispute_problemType;

  /// No description provided for @dispute_reservation.
  ///
  /// In fr, this message translates to:
  /// **'Réservation'**
  String get dispute_reservation;

  /// No description provided for @dispute_amountPaid.
  ///
  /// In fr, this message translates to:
  /// **'Montant payé'**
  String get dispute_amountPaid;

  /// No description provided for @dispute_createError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la création du litige'**
  String get dispute_createError;

  /// No description provided for @dispute_created.
  ///
  /// In fr, this message translates to:
  /// **'Litige créé'**
  String get dispute_created;

  /// No description provided for @dispute_describeRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez décrire le problème'**
  String get dispute_describeRequired;

  /// No description provided for @dispute_amountExceedsPaid.
  ///
  /// In fr, this message translates to:
  /// **'Le montant ne peut pas dépasser le prix payé'**
  String get dispute_amountExceedsPaid;

  /// No description provided for @dispute_amountMustBePositive.
  ///
  /// In fr, this message translates to:
  /// **'Le montant doit être positif'**
  String get dispute_amountMustBePositive;

  /// No description provided for @dispute_respondTitle.
  ///
  /// In fr, this message translates to:
  /// **'Répondre au litige'**
  String get dispute_respondTitle;

  /// No description provided for @dispute_yourResponse.
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse'**
  String get dispute_yourResponse;

  /// No description provided for @dispute_deadlineExpired.
  ///
  /// In fr, this message translates to:
  /// **'Délai dépassé'**
  String get dispute_deadlineExpired;

  /// No description provided for @dispute_deadlineExpiredMessage.
  ///
  /// In fr, this message translates to:
  /// **'Le délai de réponse est dépassé'**
  String get dispute_deadlineExpiredMessage;

  /// No description provided for @dispute_responseDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Délai de réponse'**
  String get dispute_responseDeadline;

  /// No description provided for @dispute_complaintReceived.
  ///
  /// In fr, this message translates to:
  /// **'Plainte reçue'**
  String get dispute_complaintReceived;

  /// No description provided for @dispute_writeResponse.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez écrire votre réponse'**
  String get dispute_writeResponse;

  /// No description provided for @dispute_sendResponse.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer ma réponse'**
  String get dispute_sendResponse;

  /// No description provided for @dispute_responseError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'envoi de la réponse'**
  String get dispute_responseError;

  /// No description provided for @dispute_responseSent.
  ///
  /// In fr, this message translates to:
  /// **'Réponse envoyée'**
  String get dispute_responseSent;

  /// No description provided for @dispute_addEvidence.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des preuves'**
  String get dispute_addEvidence;

  /// No description provided for @dispute_multipleSelection.
  ///
  /// In fr, this message translates to:
  /// **'Sélection multiple possible'**
  String get dispute_multipleSelection;

  /// No description provided for @dispute_evidenceAdded.
  ///
  /// In fr, this message translates to:
  /// **'Preuves ajoutées'**
  String get dispute_evidenceAdded;

  /// No description provided for @dispute_tipsPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Photos claires et bien éclairées'**
  String get dispute_tipsPhotos;

  /// No description provided for @dispute_tipsScreenshots.
  ///
  /// In fr, this message translates to:
  /// **'Captures d\'écran de communications'**
  String get dispute_tipsScreenshots;

  /// No description provided for @dispute_tipsTimestamp.
  ///
  /// In fr, this message translates to:
  /// **'Photos horodatées si possible'**
  String get dispute_tipsTimestamp;

  /// No description provided for @admin_dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Dashboard'**
  String get admin_dashboard;

  /// No description provided for @admin_reservations.
  ///
  /// In fr, this message translates to:
  /// **'Réservations'**
  String get admin_reservations;

  /// No description provided for @admin_reservationsManagement.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des réservations'**
  String get admin_reservationsManagement;

  /// No description provided for @admin_users.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs'**
  String get admin_users;

  /// No description provided for @admin_workers.
  ///
  /// In fr, this message translates to:
  /// **'Déneigeurs'**
  String get admin_workers;

  /// No description provided for @admin_workersManagement.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des déneigeurs'**
  String get admin_workersManagement;

  /// No description provided for @admin_reports.
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get admin_reports;

  /// No description provided for @admin_support.
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get admin_support;

  /// No description provided for @admin_verifications.
  ///
  /// In fr, this message translates to:
  /// **'Vérifications'**
  String get admin_verifications;

  /// No description provided for @admin_verificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifications d\'identité'**
  String get admin_verificationsTitle;

  /// No description provided for @admin_ai.
  ///
  /// In fr, this message translates to:
  /// **'IA'**
  String get admin_ai;

  /// No description provided for @admin_stripeAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Comptes Stripe'**
  String get admin_stripeAccounts;

  /// No description provided for @admin_all.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get admin_all;

  /// No description provided for @admin_pending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get admin_pending;

  /// No description provided for @admin_assigned.
  ///
  /// In fr, this message translates to:
  /// **'Assignées'**
  String get admin_assigned;

  /// No description provided for @admin_inProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get admin_inProgress;

  /// No description provided for @admin_completed.
  ///
  /// In fr, this message translates to:
  /// **'Terminées'**
  String get admin_completed;

  /// No description provided for @admin_cancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulées'**
  String get admin_cancelled;

  /// No description provided for @admin_noReservations.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réservation trouvée'**
  String get admin_noReservations;

  /// No description provided for @admin_refund.
  ///
  /// In fr, this message translates to:
  /// **'Rembourser'**
  String get admin_refund;

  /// No description provided for @admin_pageOf.
  ///
  /// In fr, this message translates to:
  /// **'Page {current} / {total}'**
  String admin_pageOf(int current, int total);

  /// No description provided for @admin_reservationInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations de la réservation'**
  String get admin_reservationInfo;

  /// No description provided for @admin_id.
  ///
  /// In fr, this message translates to:
  /// **'ID'**
  String get admin_id;

  /// No description provided for @admin_plannedDate.
  ///
  /// In fr, this message translates to:
  /// **'Date prévue'**
  String get admin_plannedDate;

  /// No description provided for @admin_createdAt.
  ///
  /// In fr, this message translates to:
  /// **'Créée le'**
  String get admin_createdAt;

  /// No description provided for @admin_completedAt.
  ///
  /// In fr, this message translates to:
  /// **'Terminée le'**
  String get admin_completedAt;

  /// No description provided for @admin_cancelledAt.
  ///
  /// In fr, this message translates to:
  /// **'Annulée le'**
  String get admin_cancelledAt;

  /// No description provided for @admin_parkingSpot.
  ///
  /// In fr, this message translates to:
  /// **'Place de parking'**
  String get admin_parkingSpot;

  /// No description provided for @admin_financialDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails financiers'**
  String get admin_financialDetails;

  /// No description provided for @admin_totalPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix total'**
  String get admin_totalPrice;

  /// No description provided for @admin_platformFee.
  ///
  /// In fr, this message translates to:
  /// **'Commission plateforme'**
  String get admin_platformFee;

  /// No description provided for @admin_workerPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement déneigeur'**
  String get admin_workerPayment;

  /// No description provided for @admin_paymentStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut paiement'**
  String get admin_paymentStatus;

  /// No description provided for @admin_refunded.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé'**
  String get admin_refunded;

  /// No description provided for @admin_client.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get admin_client;

  /// No description provided for @admin_workerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Déneigeur'**
  String get admin_workerLabel;

  /// No description provided for @admin_note.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get admin_note;

  /// No description provided for @admin_color.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get admin_color;

  /// No description provided for @admin_plateNumber.
  ///
  /// In fr, this message translates to:
  /// **'Plaque'**
  String get admin_plateNumber;

  /// No description provided for @admin_services.
  ///
  /// In fr, this message translates to:
  /// **'Services'**
  String get admin_services;

  /// No description provided for @admin_cancellationReason.
  ///
  /// In fr, this message translates to:
  /// **'Raison d\'annulation'**
  String get admin_cancellationReason;

  /// No description provided for @admin_proceedRefund.
  ///
  /// In fr, this message translates to:
  /// **'Procéder au remboursement'**
  String get admin_proceedRefund;

  /// No description provided for @admin_refundTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rembourser la réservation'**
  String get admin_refundTitle;

  /// No description provided for @admin_maxAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant maximum:'**
  String get admin_maxAmount;

  /// No description provided for @admin_refundAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant à rembourser'**
  String get admin_refundAmount;

  /// No description provided for @admin_reasonOptional.
  ///
  /// In fr, this message translates to:
  /// **'Raison (optionnel)'**
  String get admin_reasonOptional;

  /// No description provided for @admin_invalidAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide'**
  String get admin_invalidAmount;

  /// No description provided for @admin_noUsers.
  ///
  /// In fr, this message translates to:
  /// **'Aucun utilisateur trouvé'**
  String get admin_noUsers;

  /// No description provided for @admin_verified.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiés'**
  String get admin_verified;

  /// No description provided for @admin_noWorkers.
  ///
  /// In fr, this message translates to:
  /// **'Aucun déneigeur trouvé'**
  String get admin_noWorkers;

  /// No description provided for @admin_suspendWorker.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre le déneigeur'**
  String get admin_suspendWorker;

  /// No description provided for @admin_duration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get admin_duration;

  /// No description provided for @admin_workerStats.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques Déneigeur'**
  String get admin_workerStats;

  /// No description provided for @admin_totalSpent.
  ///
  /// In fr, this message translates to:
  /// **'Total dépensé'**
  String get admin_totalSpent;

  /// No description provided for @admin_viewDetails.
  ///
  /// In fr, this message translates to:
  /// **'Voir les détails'**
  String get admin_viewDetails;

  /// No description provided for @admin_resolvedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Résolues'**
  String get admin_resolvedLabel;

  /// No description provided for @admin_topWorkers.
  ///
  /// In fr, this message translates to:
  /// **'Top Déneigeurs'**
  String get admin_topWorkers;

  /// No description provided for @admin_noWorkersYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun déneigeur pour le moment'**
  String get admin_noWorkersYet;

  /// No description provided for @admin_workersOnly.
  ///
  /// In fr, this message translates to:
  /// **'Déneigeurs uniquement'**
  String get admin_workersOnly;

  /// No description provided for @admin_adminLogout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion Admin'**
  String get admin_adminLogout;

  /// No description provided for @admin_completionRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de complétion'**
  String get admin_completionRate;

  /// No description provided for @admin_activity.
  ///
  /// In fr, this message translates to:
  /// **'Activité'**
  String get admin_activity;

  /// No description provided for @admin_refreshStripe.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser les données Stripe'**
  String get admin_refreshStripe;

  /// No description provided for @admin_paymentsReceived.
  ///
  /// In fr, this message translates to:
  /// **'Paiements reçus'**
  String get admin_paymentsReceived;

  /// No description provided for @admin_workerTransfers.
  ///
  /// In fr, this message translates to:
  /// **'Transferts déneigeurs'**
  String get admin_workerTransfers;

  /// No description provided for @admin_totalReservations.
  ///
  /// In fr, this message translates to:
  /// **'Total Réservations'**
  String get admin_totalReservations;

  /// No description provided for @admin_statusDistribution.
  ///
  /// In fr, this message translates to:
  /// **'Répartition par statut'**
  String get admin_statusDistribution;

  /// No description provided for @admin_noDataAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Pas de données disponibles'**
  String get admin_noDataAvailable;

  /// No description provided for @admin_keyMetrics.
  ///
  /// In fr, this message translates to:
  /// **'Métriques clés'**
  String get admin_keyMetrics;

  /// No description provided for @admin_avgRevenuePerReservation.
  ///
  /// In fr, this message translates to:
  /// **'Revenu moyen par réservation'**
  String get admin_avgRevenuePerReservation;

  /// No description provided for @admin_activeWorkers.
  ///
  /// In fr, this message translates to:
  /// **'Déneigeurs actifs'**
  String get admin_activeWorkers;

  /// No description provided for @admin_cancelledReservations.
  ///
  /// In fr, this message translates to:
  /// **'Réservations annulées'**
  String get admin_cancelledReservations;

  /// No description provided for @admin_workerPayments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements déneigeurs'**
  String get admin_workerPayments;

  /// No description provided for @admin_paid.
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get admin_paid;

  /// No description provided for @admin_syncResult.
  ///
  /// In fr, this message translates to:
  /// **'Résultat de la synchronisation'**
  String get admin_syncResult;

  /// No description provided for @admin_approved.
  ///
  /// In fr, this message translates to:
  /// **'Approuvé'**
  String get admin_approved;

  /// No description provided for @admin_rejected.
  ///
  /// In fr, this message translates to:
  /// **'Rejeté'**
  String get admin_rejected;

  /// No description provided for @admin_expired.
  ///
  /// In fr, this message translates to:
  /// **'Expiré'**
  String get admin_expired;

  /// No description provided for @admin_approvedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Approuvées'**
  String get admin_approvedLabel;

  /// No description provided for @admin_rejectedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rejetées'**
  String get admin_rejectedLabel;

  /// No description provided for @admin_noPendingVerifications.
  ///
  /// In fr, this message translates to:
  /// **'Aucune vérification en attente'**
  String get admin_noPendingVerifications;

  /// No description provided for @admin_noVerifications.
  ///
  /// In fr, this message translates to:
  /// **'Aucune vérification trouvée'**
  String get admin_noVerifications;

  /// No description provided for @admin_previousDecision.
  ///
  /// In fr, this message translates to:
  /// **'Décision précédente'**
  String get admin_previousDecision;

  /// No description provided for @admin_documentAuthenticity.
  ///
  /// In fr, this message translates to:
  /// **'Authenticité document'**
  String get admin_documentAuthenticity;

  /// No description provided for @admin_detectedIssues.
  ///
  /// In fr, this message translates to:
  /// **'Problèmes détectés'**
  String get admin_detectedIssues;

  /// No description provided for @admin_verificationApproved.
  ///
  /// In fr, this message translates to:
  /// **'Vérification approuvée'**
  String get admin_verificationApproved;

  /// No description provided for @admin_verificationRejected.
  ///
  /// In fr, this message translates to:
  /// **'Vérification rejetée'**
  String get admin_verificationRejected;

  /// No description provided for @admin_rejectVerification.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter la vérification'**
  String get admin_rejectVerification;

  /// No description provided for @admin_nonCompliant.
  ///
  /// In fr, this message translates to:
  /// **'Vérification non conforme'**
  String get admin_nonCompliant;

  /// No description provided for @admin_resolved.
  ///
  /// In fr, this message translates to:
  /// **'Résolu'**
  String get admin_resolved;

  /// No description provided for @admin_closed.
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get admin_closed;

  /// No description provided for @accountType_welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue ! Sélectionnez votre type de compte'**
  String get accountType_welcome;

  /// No description provided for @accountType_client.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get accountType_client;

  /// No description provided for @accountType_clientSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Je cherche un service de déneigement'**
  String get accountType_clientSubtitle;

  /// No description provided for @accountType_snowWorker.
  ///
  /// In fr, this message translates to:
  /// **'Déneigeur'**
  String get accountType_snowWorker;

  /// No description provided for @accountType_snowWorkerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Je propose mes services de déneigement'**
  String get accountType_snowWorkerSubtitle;

  /// No description provided for @register_accountLabel.
  ///
  /// In fr, this message translates to:
  /// **'Compte {role}'**
  String register_accountLabel(String role);

  /// No description provided for @resetPassword_title.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get resetPassword_title;

  /// No description provided for @resetPassword_successTitle.
  ///
  /// In fr, this message translates to:
  /// **'Succès !'**
  String get resetPassword_successTitle;

  /// No description provided for @resetPassword_description.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre nouveau mot de passe'**
  String get resetPassword_description;

  /// No description provided for @resetPassword_successDescription.
  ///
  /// In fr, this message translates to:
  /// **'Votre mot de passe a été réinitialisé avec succès. Vous allez être redirigé vers la page de connexion.'**
  String get resetPassword_successDescription;

  /// No description provided for @resetPassword_newPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get resetPassword_newPassword;

  /// No description provided for @resetPassword_resetButton.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le mot de passe'**
  String get resetPassword_resetButton;

  /// No description provided for @resetPassword_resetSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe réinitialisé avec succès !'**
  String get resetPassword_resetSuccess;

  /// No description provided for @resetPassword_resetDone.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe réinitialisé !'**
  String get resetPassword_resetDone;

  /// No description provided for @resetPassword_canNowLogin.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez maintenant vous connecter avec votre nouveau mot de passe.'**
  String get resetPassword_canNowLogin;

  /// No description provided for @resetPassword_goToLogin.
  ///
  /// In fr, this message translates to:
  /// **'Aller à la connexion'**
  String get resetPassword_goToLogin;

  /// No description provided for @resetPassword_minChars.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 6 caractères'**
  String get resetPassword_minChars;

  /// No description provided for @resetPassword_strengthWeak.
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get resetPassword_strengthWeak;

  /// No description provided for @resetPassword_strengthMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get resetPassword_strengthMedium;

  /// No description provided for @resetPassword_strengthStrong.
  ///
  /// In fr, this message translates to:
  /// **'Fort'**
  String get resetPassword_strengthStrong;

  /// No description provided for @privacy_title.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacy_title;

  /// No description provided for @terms_title.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get terms_title;

  /// No description provided for @privacy_lastUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour: Janvier 2025'**
  String get privacy_lastUpdate;

  /// No description provided for @terms_lastUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour: Janvier 2025'**
  String get terms_lastUpdate;

  /// No description provided for @clientHome_greetingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour,'**
  String get clientHome_greetingLabel;

  /// No description provided for @clientHome_quickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get clientHome_quickActions;

  /// No description provided for @clientHome_book.
  ///
  /// In fr, this message translates to:
  /// **'Réserver'**
  String get clientHome_book;

  /// No description provided for @clientHome_myAppointments.
  ///
  /// In fr, this message translates to:
  /// **'Mes RDV'**
  String get clientHome_myAppointments;

  /// No description provided for @clientHome_upcomingReservations.
  ///
  /// In fr, this message translates to:
  /// **'Prochaines réservations'**
  String get clientHome_upcomingReservations;

  /// No description provided for @clientHome_viewAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get clientHome_viewAll;

  /// No description provided for @clientHome_bookFirstSnowRemoval.
  ///
  /// In fr, this message translates to:
  /// **'Réservez votre premier déneigement'**
  String get clientHome_bookFirstSnowRemoval;

  /// No description provided for @clientHome_workerApproaching.
  ///
  /// In fr, this message translates to:
  /// **'Déneigeur en approche'**
  String get clientHome_workerApproaching;

  /// No description provided for @clientHome_unknown.
  ///
  /// In fr, this message translates to:
  /// **'Inconnu'**
  String get clientHome_unknown;

  /// No description provided for @clientHome_navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get clientHome_navHome;

  /// No description provided for @clientHome_navActivities.
  ///
  /// In fr, this message translates to:
  /// **'Activités'**
  String get clientHome_navActivities;

  /// No description provided for @clientHome_navProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get clientHome_navProfile;

  /// No description provided for @clientHome_ratingThanks.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre évaluation!'**
  String get clientHome_ratingThanks;

  /// No description provided for @clientHome_ratingError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer l\'évaluation. Veuillez réessayer.'**
  String get clientHome_ratingError;

  /// No description provided for @clientHome_tipError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer le pourboire. Veuillez réessayer.'**
  String get clientHome_tipError;

  /// No description provided for @clientHome_tipSent.
  ///
  /// In fr, this message translates to:
  /// **'Pourboire de {amount}\$ envoyé à {name}'**
  String clientHome_tipSent(String amount, String name);

  /// No description provided for @clientHome_tipErrorPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Erreur pourboire: {message}'**
  String clientHome_tipErrorPrefix(String message);

  /// No description provided for @clientHome_errorPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {message}'**
  String clientHome_errorPrefix(String message);

  /// No description provided for @clientHome_theWorker.
  ///
  /// In fr, this message translates to:
  /// **'le déneigeur'**
  String get clientHome_theWorker;

  /// No description provided for @clientHome_mySubscription.
  ///
  /// In fr, this message translates to:
  /// **'Mon\nabonnement'**
  String get clientHome_mySubscription;

  /// No description provided for @weather_snowDepthValue.
  ///
  /// In fr, this message translates to:
  /// **'{depth} cm au sol'**
  String weather_snowDepthValue(String depth);

  /// No description provided for @worker_jobsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Disponibles'**
  String get worker_jobsAvailable;

  /// No description provided for @worker_jobsMyJobs.
  ///
  /// In fr, this message translates to:
  /// **'Mes jobs'**
  String get worker_jobsMyJobs;

  /// No description provided for @worker_accept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get worker_accept;

  /// No description provided for @admin_loadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get admin_loadError;

  /// No description provided for @admin_administration.
  ///
  /// In fr, this message translates to:
  /// **'Administration'**
  String get admin_administration;

  /// No description provided for @admin_sendNotification.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer notification'**
  String get admin_sendNotification;

  /// No description provided for @admin_disputes.
  ///
  /// In fr, this message translates to:
  /// **'Litiges'**
  String get admin_disputes;

  /// No description provided for @admin_aiIntelligence.
  ///
  /// In fr, this message translates to:
  /// **'Intelligence IA'**
  String get admin_aiIntelligence;

  /// No description provided for @admin_quickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get admin_quickActions;

  /// No description provided for @admin_notify.
  ///
  /// In fr, this message translates to:
  /// **'Notifier'**
  String get admin_notify;

  /// No description provided for @admin_toProcess.
  ///
  /// In fr, this message translates to:
  /// **'À traiter'**
  String get admin_toProcess;

  /// No description provided for @admin_revenue.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get admin_revenue;

  /// No description provided for @admin_total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get admin_total;

  /// No description provided for @admin_thisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get admin_thisMonth;

  /// No description provided for @admin_grossCommission.
  ///
  /// In fr, this message translates to:
  /// **'Commission brute (25%)'**
  String get admin_grossCommission;

  /// No description provided for @admin_stripeFees.
  ///
  /// In fr, this message translates to:
  /// **'Frais Stripe'**
  String get admin_stripeFees;

  /// No description provided for @admin_netCommission.
  ///
  /// In fr, this message translates to:
  /// **'Commission nette'**
  String get admin_netCommission;

  /// No description provided for @admin_tips.
  ///
  /// In fr, this message translates to:
  /// **'Pourboires'**
  String get admin_tips;

  /// No description provided for @admin_viewAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous'**
  String get admin_viewAll;

  /// No description provided for @admin_notifTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get admin_notifTitle;

  /// No description provided for @admin_notifMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get admin_notifMessage;

  /// No description provided for @admin_notifRecipients.
  ///
  /// In fr, this message translates to:
  /// **'Destinataires'**
  String get admin_notifRecipients;

  /// No description provided for @admin_allUsers.
  ///
  /// In fr, this message translates to:
  /// **'Tous les utilisateurs'**
  String get admin_allUsers;

  /// No description provided for @admin_clientsOnly.
  ///
  /// In fr, this message translates to:
  /// **'Clients uniquement'**
  String get admin_clientsOnly;

  /// No description provided for @admin_fillAllFields.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez remplir tous les champs'**
  String get admin_fillAllFields;

  /// No description provided for @admin_logoutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment vous déconnecter du panneau d\'administration ?'**
  String get admin_logoutConfirm;

  /// No description provided for @admin_clientsAndWorkers.
  ///
  /// In fr, this message translates to:
  /// **'{clients} clients, {workers} déneigeurs'**
  String admin_clientsAndWorkers(int clients, int workers);

  /// No description provided for @admin_todayCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} aujourd\'hui'**
  String admin_todayCount(int count);

  /// No description provided for @admin_completedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} terminées'**
  String admin_completedCount(int count);

  /// No description provided for @admin_pendingCountLabel.
  ///
  /// In fr, this message translates to:
  /// **'{count} en attente'**
  String admin_pendingCountLabel(int count);

  /// No description provided for @admin_reservationsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} réservations'**
  String admin_reservationsCount(int count);

  /// No description provided for @admin_newRequestsToday.
  ///
  /// In fr, this message translates to:
  /// **'{count} nouvelle(s) demande(s) aujourd\'hui'**
  String admin_newRequestsToday(int count);

  /// No description provided for @common_add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get common_add;

  /// No description provided for @common_description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get common_description;

  /// No description provided for @dispute_imageLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'image'**
  String get dispute_imageLoadError;

  /// No description provided for @dispute_addPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get dispute_addPhoto;

  /// No description provided for @dispute_chooseFromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir depuis la galerie'**
  String get dispute_chooseFromGallery;

  /// No description provided for @dispute_claimedAmountOptional.
  ///
  /// In fr, this message translates to:
  /// **'Montant réclamé (optionnel)'**
  String get dispute_claimedAmountOptional;

  /// No description provided for @dispute_photosEvidence.
  ///
  /// In fr, this message translates to:
  /// **'Photos (preuves)'**
  String get dispute_photosEvidence;

  /// No description provided for @dispute_workerNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Déneigeur: {name}'**
  String dispute_workerNameLabel(String name);

  /// No description provided for @dispute_describeInDetail.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez le problème en détail...'**
  String get dispute_describeInDetail;

  /// No description provided for @dispute_descriptionTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Description trop courte (minimum 20 caractères)'**
  String get dispute_descriptionTooShort;

  /// No description provided for @dispute_invalidAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide'**
  String get dispute_invalidAmount;

  /// No description provided for @dispute_submit.
  ///
  /// In fr, this message translates to:
  /// **'Soumettre le litige'**
  String get dispute_submit;

  /// No description provided for @dispute_submitSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Votre litige a été soumis avec succès. Notre équipe va l\'examiner et vous tiendra informé de l\'avancement.'**
  String get dispute_submitSuccess;

  /// No description provided for @dispute_workerResponseDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Le déneigeur a 48h pour répondre à votre plainte.'**
  String get dispute_workerResponseDeadline;

  /// No description provided for @dispute_addPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des photos'**
  String get dispute_addPhotos;

  /// No description provided for @dispute_addAnotherPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une autre photo'**
  String get dispute_addAnotherPhoto;

  /// No description provided for @dispute_maxPhotosHint.
  ///
  /// In fr, this message translates to:
  /// **'Maximum 5 photos. Les photos aident à traiter votre demande plus rapidement.'**
  String get dispute_maxPhotosHint;

  /// No description provided for @worker_myPayments.
  ///
  /// In fr, this message translates to:
  /// **'Mes paiements'**
  String get worker_myPayments;

  /// No description provided for @worker_configureBankAccount.
  ///
  /// In fr, this message translates to:
  /// **'Configurer mon compte bancaire'**
  String get worker_configureBankAccount;

  /// No description provided for @worker_saltSpreaderLabel.
  ///
  /// In fr, this message translates to:
  /// **'Épandeur de sel'**
  String get worker_saltSpreaderLabel;

  /// No description provided for @worker_snowBlowerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Souffleuse'**
  String get worker_snowBlowerLabel;

  /// No description provided for @worker_vehicleCar.
  ///
  /// In fr, this message translates to:
  /// **'Voiture'**
  String get worker_vehicleCar;

  /// No description provided for @worker_vehicleTruck.
  ///
  /// In fr, this message translates to:
  /// **'Camionnette'**
  String get worker_vehicleTruck;

  /// No description provided for @worker_vehicleAtv.
  ///
  /// In fr, this message translates to:
  /// **'VTT / Quad'**
  String get worker_vehicleAtv;

  /// No description provided for @worker_vehicleOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get worker_vehicleOther;

  /// No description provided for @worker_vehicleCarDesc.
  ///
  /// In fr, this message translates to:
  /// **'Petites entrées, stationnements'**
  String get worker_vehicleCarDesc;

  /// No description provided for @worker_vehicleTruckDesc.
  ///
  /// In fr, this message translates to:
  /// **'Grandes entrées, équipement lourd'**
  String get worker_vehicleTruckDesc;

  /// No description provided for @worker_vehicleAtvDesc.
  ///
  /// In fr, this message translates to:
  /// **'Accès difficile, terrains variés'**
  String get worker_vehicleAtvDesc;

  /// No description provided for @worker_recommendedJobs.
  ///
  /// In fr, this message translates to:
  /// **'Recommandé: 2-3 jobs'**
  String get worker_recommendedJobs;

  /// No description provided for @worker_notifNewJobsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Alerte pour les nouveaux jobs disponibles'**
  String get worker_notifNewJobsDesc;

  /// No description provided for @worker_notifUrgentJobsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Alertes prioritaires'**
  String get worker_notifUrgentJobsDesc;

  /// No description provided for @worker_addZone.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une zone'**
  String get worker_addZone;

  /// No description provided for @worker_zoneName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la zone'**
  String get worker_zoneName;

  /// No description provided for @worker_zoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Trois-Rivières Ouest'**
  String get worker_zoneHint;

  /// No description provided for @worker_account.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get worker_account;

  /// No description provided for @worker_logoutConfirmWorker.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment vous déconnecter de votre compte déneigeur ?'**
  String get worker_logoutConfirmWorker;

  /// No description provided for @worker_priorityNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications prioritaires'**
  String get worker_priorityNotifications;

  /// No description provided for @worker_history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get worker_history;

  /// No description provided for @worker_yourCompletedJobs.
  ///
  /// In fr, this message translates to:
  /// **'Vos jobs terminés'**
  String get worker_yourCompletedJobs;

  /// No description provided for @worker_filterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get worker_filterAll;

  /// No description provided for @worker_filterThisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get worker_filterThisWeek;

  /// No description provided for @worker_filterThisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get worker_filterThisMonth;

  /// No description provided for @worker_filterWithTip.
  ///
  /// In fr, this message translates to:
  /// **'Avec pourboire'**
  String get worker_filterWithTip;

  /// No description provided for @worker_noHistory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun job dans l\'historique'**
  String get worker_noHistory;

  /// No description provided for @worker_completedJobsAppearHere.
  ///
  /// In fr, this message translates to:
  /// **'Vos jobs terminés apparaîtront ici'**
  String get worker_completedJobsAppearHere;

  /// No description provided for @worker_dateUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Date inconnue'**
  String get worker_dateUnknown;

  /// No description provided for @worker_completedStatus.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get worker_completedStatus;

  /// No description provided for @worker_revenueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get worker_revenueLabel;

  /// No description provided for @worker_clientRating.
  ///
  /// In fr, this message translates to:
  /// **'Évaluation client:'**
  String get worker_clientRating;

  /// No description provided for @worker_returnToDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Retourner au dashboard'**
  String get worker_returnToDashboard;

  /// No description provided for @worker_photoSelectionError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la sélection de la photo'**
  String get worker_photoSelectionError;

  /// No description provided for @worker_notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get worker_notifications;

  /// No description provided for @worker_tipsReceived.
  ///
  /// In fr, this message translates to:
  /// **'Pourboires reçus'**
  String get worker_tipsReceived;

  /// No description provided for @admin_userManagement.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des utilisateurs'**
  String get admin_userManagement;

  /// No description provided for @admin_searchUser.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un utilisateur...'**
  String get admin_searchUser;

  /// No description provided for @admin_clientsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get admin_clientsLabel;

  /// No description provided for @admin_adminsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Admins'**
  String get admin_adminsLabel;

  /// No description provided for @admin_suspended.
  ///
  /// In fr, this message translates to:
  /// **'Suspendu'**
  String get admin_suspended;

  /// No description provided for @admin_jobsCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Jobs terminés'**
  String get admin_jobsCompleted;

  /// No description provided for @admin_averageRating.
  ///
  /// In fr, this message translates to:
  /// **'Note moyenne'**
  String get admin_averageRating;

  /// No description provided for @admin_totalEarnings.
  ///
  /// In fr, this message translates to:
  /// **'Gains totaux'**
  String get admin_totalEarnings;

  /// No description provided for @admin_warnings.
  ///
  /// In fr, this message translates to:
  /// **'Avertissements'**
  String get admin_warnings;

  /// No description provided for @admin_clientStats.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques Client'**
  String get admin_clientStats;

  /// No description provided for @admin_registeredAt.
  ///
  /// In fr, this message translates to:
  /// **'Inscrit le'**
  String get admin_registeredAt;

  /// No description provided for @admin_accountSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Compte suspendu'**
  String get admin_accountSuspended;

  /// No description provided for @admin_suspendUser.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre l\'utilisateur'**
  String get admin_suspendUser;

  /// No description provided for @admin_liftSuspension.
  ///
  /// In fr, this message translates to:
  /// **'Lever la suspension'**
  String get admin_liftSuspension;

  /// No description provided for @admin_aboutToSuspend.
  ///
  /// In fr, this message translates to:
  /// **'Vous allez suspendre {name}'**
  String admin_aboutToSuspend(String name);

  /// No description provided for @admin_1day.
  ///
  /// In fr, this message translates to:
  /// **'1 jour'**
  String get admin_1day;

  /// No description provided for @admin_3days.
  ///
  /// In fr, this message translates to:
  /// **'3 jours'**
  String get admin_3days;

  /// No description provided for @admin_7days.
  ///
  /// In fr, this message translates to:
  /// **'7 jours'**
  String get admin_7days;

  /// No description provided for @admin_14days.
  ///
  /// In fr, this message translates to:
  /// **'14 jours'**
  String get admin_14days;

  /// No description provided for @admin_30days.
  ///
  /// In fr, this message translates to:
  /// **'30 jours'**
  String get admin_30days;

  /// No description provided for @admin_1year.
  ///
  /// In fr, this message translates to:
  /// **'1 an'**
  String get admin_1year;

  /// No description provided for @admin_suspend.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre'**
  String get admin_suspend;

  /// No description provided for @admin_reason.
  ///
  /// In fr, this message translates to:
  /// **'Raison: {reason}'**
  String admin_reason(String reason);

  /// No description provided for @admin_suspendedUntil.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'au: {date}'**
  String admin_suspendedUntil(String date);

  /// No description provided for @payment_title.
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get payment_title;

  /// No description provided for @payment_amountToPay.
  ///
  /// In fr, this message translates to:
  /// **'Montant à payer'**
  String get payment_amountToPay;

  /// No description provided for @payment_useNewCard.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser une nouvelle carte'**
  String get payment_useNewCard;

  /// No description provided for @payment_expires.
  ///
  /// In fr, this message translates to:
  /// **'Expire {date}'**
  String payment_expires(String date);

  /// No description provided for @payment_securePayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement sécurisé'**
  String get payment_securePayment;

  /// No description provided for @payment_securePaymentDetails.
  ///
  /// In fr, this message translates to:
  /// **'SSL 256-bit · PCI DSS · Propulsé par Stripe'**
  String get payment_securePaymentDetails;

  /// No description provided for @payment_payAmount.
  ///
  /// In fr, this message translates to:
  /// **'Payer {amount} \$'**
  String payment_payAmount(String amount);

  /// No description provided for @payment_success.
  ///
  /// In fr, this message translates to:
  /// **'Paiement réussi !'**
  String get payment_success;

  /// No description provided for @payment_cancelled.
  ///
  /// In fr, this message translates to:
  /// **'Paiement annulé'**
  String get payment_cancelled;

  /// No description provided for @payment_failedRetry.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement a échoué. Vérifiez votre carte et réessayez.'**
  String get payment_failedRetry;

  /// No description provided for @payment_payments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get payment_payments;

  /// No description provided for @payment_historyTab.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get payment_historyTab;

  /// No description provided for @payment_methodsTab.
  ///
  /// In fr, this message translates to:
  /// **'Méthodes'**
  String get payment_methodsTab;

  /// No description provided for @payment_totalSpent.
  ///
  /// In fr, this message translates to:
  /// **'Total dépensé'**
  String get payment_totalSpent;

  /// No description provided for @payment_transactions.
  ///
  /// In fr, this message translates to:
  /// **'transactions'**
  String get payment_transactions;

  /// No description provided for @payment_noPayments.
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement'**
  String get payment_noPayments;

  /// No description provided for @payment_transactionsAppearHere.
  ///
  /// In fr, this message translates to:
  /// **'Vos transactions apparaîtront ici'**
  String get payment_transactionsAppearHere;

  /// No description provided for @payment_noCardsRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Aucune carte enregistrée'**
  String get payment_noCardsRegistered;

  /// No description provided for @payment_addCardToFacilitate.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez une carte pour faciliter vos paiements'**
  String get payment_addCardToFacilitate;

  /// No description provided for @payment_setDefault.
  ///
  /// In fr, this message translates to:
  /// **'Définir par défaut'**
  String get payment_setDefault;

  /// No description provided for @payment_deleteCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la carte'**
  String get payment_deleteCardTitle;

  /// No description provided for @payment_deleteCardConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer la carte {number} ?'**
  String payment_deleteCardConfirm(String number);

  /// No description provided for @payment_addCard.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une carte'**
  String get payment_addCard;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
