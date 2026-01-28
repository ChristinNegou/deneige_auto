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

  /// No description provided for @clientHome_userNotAuth.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: utilisateur non authentifié'**
  String get clientHome_userNotAuth;

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

  /// No description provided for @notifSettings_enabled.
  ///
  /// In fr, this message translates to:
  /// **'Les notifications sont activées'**
  String get notifSettings_enabled;

  /// No description provided for @notifSettings_disabled.
  ///
  /// In fr, this message translates to:
  /// **'Les notifications sont désactivées'**
  String get notifSettings_disabled;

  /// No description provided for @notifSettings_sounds.
  ///
  /// In fr, this message translates to:
  /// **'Sons'**
  String get notifSettings_sounds;

  /// No description provided for @notifSettings_soundsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Jouer un son pour les nouvelles notifications'**
  String get notifSettings_soundsDesc;

  /// No description provided for @notifSettings_vibration.
  ///
  /// In fr, this message translates to:
  /// **'Vibration'**
  String get notifSettings_vibration;

  /// No description provided for @notifSettings_vibrationDesc.
  ///
  /// In fr, this message translates to:
  /// **'Vibrer pour les nouvelles notifications'**
  String get notifSettings_vibrationDesc;

  /// No description provided for @notifSettings_badge.
  ///
  /// In fr, this message translates to:
  /// **'Badge'**
  String get notifSettings_badge;

  /// No description provided for @notifSettings_badgeDesc.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le compteur sur l\'icône de l\'app'**
  String get notifSettings_badgeDesc;

  /// No description provided for @notifSettings_preview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get notifSettings_preview;

  /// No description provided for @notifSettings_previewDesc.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le contenu des notifications'**
  String get notifSettings_previewDesc;

  /// No description provided for @notifSettings_quietMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode silencieux'**
  String get notifSettings_quietMode;

  /// No description provided for @notifSettings_quietModeDesc.
  ///
  /// In fr, this message translates to:
  /// **'Pas de notifications pendant les heures définies'**
  String get notifSettings_quietModeDesc;

  /// No description provided for @notifSettings_hours.
  ///
  /// In fr, this message translates to:
  /// **'Heures'**
  String get notifSettings_hours;

  /// No description provided for @notifSettings_hoursRange.
  ///
  /// In fr, this message translates to:
  /// **'De {start} à {end}'**
  String notifSettings_hoursRange(String start, String end);

  /// No description provided for @notifSettings_quietModeActive.
  ///
  /// In fr, this message translates to:
  /// **'Mode silencieux actuellement actif'**
  String get notifSettings_quietModeActive;

  /// No description provided for @notifSettings_urgentAlways.
  ///
  /// In fr, this message translates to:
  /// **'Les notifications urgentes seront toujours envoyées'**
  String get notifSettings_urgentAlways;

  /// No description provided for @notifSettings_notifTypes.
  ///
  /// In fr, this message translates to:
  /// **'Types de notifications'**
  String get notifSettings_notifTypes;

  /// No description provided for @notifSettings_disableAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout désactiver'**
  String get notifSettings_disableAll;

  /// No description provided for @notifSettings_enableAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout activer'**
  String get notifSettings_enableAll;

  /// No description provided for @notifSettings_critical.
  ///
  /// In fr, this message translates to:
  /// **'Critique'**
  String get notifSettings_critical;

  /// No description provided for @notifSettings_resetSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser les paramètres'**
  String get notifSettings_resetSettings;

  /// No description provided for @notifSettings_quietHoursTitle.
  ///
  /// In fr, this message translates to:
  /// **'Heures du mode silencieux'**
  String get notifSettings_quietHoursTitle;

  /// No description provided for @notifSettings_start.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get notifSettings_start;

  /// No description provided for @notifSettings_end.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get notifSettings_end;

  /// No description provided for @notifSettings_resetConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser?'**
  String get notifSettings_resetConfirm;

  /// No description provided for @notifSettings_resetConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Tous les paramètres de notification seront remis à leurs valeurs par défaut.'**
  String get notifSettings_resetConfirmMessage;

  /// No description provided for @notifSettings_resetDone.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres réinitialisés'**
  String get notifSettings_resetDone;

  /// No description provided for @notifSettings_reset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get notifSettings_reset;

  /// No description provided for @notif_justNow.
  ///
  /// In fr, this message translates to:
  /// **'À l\'instant'**
  String get notif_justNow;

  /// No description provided for @notif_minutesAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {minutes} min'**
  String notif_minutesAgo(int minutes);

  /// No description provided for @notif_hoursAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {hours} h'**
  String notif_hoursAgo(int hours);

  /// No description provided for @notif_daysAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {days} j'**
  String notif_daysAgo(int days);

  /// No description provided for @notif_weeksAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {weeks} sem'**
  String notif_weeksAgo(int weeks);

  /// No description provided for @notif_now.
  ///
  /// In fr, this message translates to:
  /// **'maintenant'**
  String get notif_now;

  /// No description provided for @notif_urgent.
  ///
  /// In fr, this message translates to:
  /// **'Urgent'**
  String get notif_urgent;

  /// No description provided for @notifType_reservationAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Tâche acceptée'**
  String get notifType_reservationAssigned;

  /// No description provided for @notifType_workerEnRoute.
  ///
  /// In fr, this message translates to:
  /// **'Déneigeur en route'**
  String get notifType_workerEnRoute;

  /// No description provided for @notifType_workStarted.
  ///
  /// In fr, this message translates to:
  /// **'Travail commencé'**
  String get notifType_workStarted;

  /// No description provided for @notifType_workCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Travail terminé'**
  String get notifType_workCompleted;

  /// No description provided for @notifType_reservationCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Réservation annulée'**
  String get notifType_reservationCancelled;

  /// No description provided for @notifType_paymentSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Paiement réussi'**
  String get notifType_paymentSuccess;

  /// No description provided for @notifType_paymentFailed.
  ///
  /// In fr, this message translates to:
  /// **'Paiement échoué'**
  String get notifType_paymentFailed;

  /// No description provided for @notifType_refundProcessed.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement'**
  String get notifType_refundProcessed;

  /// No description provided for @notifType_weatherAlert.
  ///
  /// In fr, this message translates to:
  /// **'Alerte météo'**
  String get notifType_weatherAlert;

  /// No description provided for @notifType_urgentRequest.
  ///
  /// In fr, this message translates to:
  /// **'Urgent'**
  String get notifType_urgentRequest;

  /// No description provided for @notifType_workerMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get notifType_workerMessage;

  /// No description provided for @notifType_newMessage.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau message'**
  String get notifType_newMessage;

  /// No description provided for @notifType_tipReceived.
  ///
  /// In fr, this message translates to:
  /// **'Pourboire reçu'**
  String get notifType_tipReceived;

  /// No description provided for @notifType_rating.
  ///
  /// In fr, this message translates to:
  /// **'Évaluation'**
  String get notifType_rating;

  /// No description provided for @notifType_systemNotification.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get notifType_systemNotification;

  /// No description provided for @notifCategory_reservations.
  ///
  /// In fr, this message translates to:
  /// **'Réservations'**
  String get notifCategory_reservations;

  /// No description provided for @notifCategory_payments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get notifCategory_payments;

  /// No description provided for @notifCategory_alerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes'**
  String get notifCategory_alerts;

  /// No description provided for @notifCategory_communications.
  ///
  /// In fr, this message translates to:
  /// **'Communications'**
  String get notifCategory_communications;

  /// No description provided for @notifDesc_reservationAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Quand un déneigeur accepte votre demande'**
  String get notifDesc_reservationAssigned;

  /// No description provided for @notifDesc_workerEnRoute.
  ///
  /// In fr, this message translates to:
  /// **'Quand le déneigeur est en route'**
  String get notifDesc_workerEnRoute;

  /// No description provided for @notifDesc_workStarted.
  ///
  /// In fr, this message translates to:
  /// **'Quand le déneigement commence'**
  String get notifDesc_workStarted;

  /// No description provided for @notifDesc_workCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Quand le déneigement est terminé'**
  String get notifDesc_workCompleted;

  /// No description provided for @notifDesc_reservationCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Quand une réservation est annulée'**
  String get notifDesc_reservationCancelled;

  /// No description provided for @notifDesc_paymentSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation de paiement réussi'**
  String get notifDesc_paymentSuccess;

  /// No description provided for @notifDesc_paymentFailed.
  ///
  /// In fr, this message translates to:
  /// **'Alerte de paiement échoué'**
  String get notifDesc_paymentFailed;

  /// No description provided for @notifDesc_refundProcessed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation de remboursement'**
  String get notifDesc_refundProcessed;

  /// No description provided for @notifDesc_weatherAlert.
  ///
  /// In fr, this message translates to:
  /// **'Alertes météo neige'**
  String get notifDesc_weatherAlert;

  /// No description provided for @notifDesc_urgentRequest.
  ///
  /// In fr, this message translates to:
  /// **'Demandes urgentes'**
  String get notifDesc_urgentRequest;

  /// No description provided for @notifDesc_workerMessage.
  ///
  /// In fr, this message translates to:
  /// **'Messages du déneigeur'**
  String get notifDesc_workerMessage;

  /// No description provided for @notifDesc_newMessage.
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux messages de chat'**
  String get notifDesc_newMessage;

  /// No description provided for @notifDesc_tipReceived.
  ///
  /// In fr, this message translates to:
  /// **'Pourboires reçus'**
  String get notifDesc_tipReceived;

  /// No description provided for @notifDesc_rating.
  ///
  /// In fr, this message translates to:
  /// **'Évaluations reçues'**
  String get notifDesc_rating;

  /// No description provided for @notifDesc_systemNotification.
  ///
  /// In fr, this message translates to:
  /// **'Mises à jour système'**
  String get notifDesc_systemNotification;

  /// No description provided for @notifAction_viewDetails.
  ///
  /// In fr, this message translates to:
  /// **'Voir les détails'**
  String get notifAction_viewDetails;

  /// No description provided for @notifAction_trackReservation.
  ///
  /// In fr, this message translates to:
  /// **'Suivre la réservation'**
  String get notifAction_trackReservation;

  /// No description provided for @notifAction_viewProgress.
  ///
  /// In fr, this message translates to:
  /// **'Voir la progression'**
  String get notifAction_viewProgress;

  /// No description provided for @notifAction_managePayments.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les paiements'**
  String get notifAction_managePayments;

  /// No description provided for @notifAction_viewHistory.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'historique'**
  String get notifAction_viewHistory;

  /// No description provided for @notifAction_newReservation.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle réservation'**
  String get notifAction_newReservation;

  /// No description provided for @notifAction_bookNow.
  ///
  /// In fr, this message translates to:
  /// **'Réserver maintenant'**
  String get notifAction_bookNow;

  /// No description provided for @notifAction_viewJobs.
  ///
  /// In fr, this message translates to:
  /// **'Voir les jobs'**
  String get notifAction_viewJobs;

  /// No description provided for @notifAction_openChat.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le chat'**
  String get notifAction_openChat;

  /// No description provided for @notifAction_reply.
  ///
  /// In fr, this message translates to:
  /// **'Répondre'**
  String get notifAction_reply;

  /// No description provided for @notifAction_viewRating.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'évaluation'**
  String get notifAction_viewRating;

  /// No description provided for @notifAction_viewMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voir le message'**
  String get notifAction_viewMessage;

  /// No description provided for @notifAction_userNotAuthenticated.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: utilisateur non authentifié'**
  String get notifAction_userNotAuthenticated;

  /// No description provided for @notifAction_defaultUser.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get notifAction_defaultUser;

  /// No description provided for @notif_allMarkedRead.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les notifications marquées comme lues'**
  String get notif_allMarkedRead;

  /// No description provided for @notif_allDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les notifications supprimées'**
  String get notif_allDeleted;

  /// No description provided for @notif_noReadToDelete.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification lue à supprimer'**
  String get notif_noReadToDelete;

  /// No description provided for @notif_someNotDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Certaines notifications n\'ont pas pu être supprimées'**
  String get notif_someNotDeleted;

  /// No description provided for @notif_deletedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} notification(s) supprimée(s)'**
  String notif_deletedCount(int count);

  /// No description provided for @notif_autoDeleteEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Suppression automatique activée ({seconds}s)'**
  String notif_autoDeleteEnabled(int seconds);

  /// No description provided for @notif_autoDeleteDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Suppression automatique désactivée'**
  String get notif_autoDeleteDisabled;

  /// No description provided for @notif_errorLoading.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement'**
  String get notif_errorLoading;

  /// No description provided for @notif_errorRefreshing.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du rafraîchissement'**
  String get notif_errorRefreshing;

  /// No description provided for @notif_errorLoadingNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des notifications'**
  String get notif_errorLoadingNotifications;

  /// No description provided for @notif_errorCountingUnread.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du comptage des notifications non lues'**
  String get notif_errorCountingUnread;

  /// No description provided for @notif_errorMarkingRead.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du marquage de la notification'**
  String get notif_errorMarkingRead;

  /// No description provided for @notif_errorMarkingAllRead.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du marquage des notifications'**
  String get notif_errorMarkingAllRead;

  /// No description provided for @notif_errorDeleting.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la suppression de la notification'**
  String get notif_errorDeleting;

  /// No description provided for @notif_errorDeletingAll.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la suppression des notifications'**
  String get notif_errorDeletingAll;

  /// No description provided for @notif_connectionTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Délai de connexion dépassé. Vérifiez votre connexion.'**
  String get notif_connectionTimeout;

  /// No description provided for @notif_cannotConnect.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de se connecter au serveur.'**
  String get notif_cannotConnect;

  /// No description provided for @notif_serverError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur serveur est survenue.'**
  String get notif_serverError;

  /// No description provided for @suspension_accountSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Compte Suspendu'**
  String get suspension_accountSuspended;

  /// No description provided for @suspension_understood.
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get suspension_understood;

  /// No description provided for @support_helpAndSupport.
  ///
  /// In fr, this message translates to:
  /// **'Aide et Support'**
  String get support_helpAndSupport;

  /// No description provided for @support_faqTab.
  ///
  /// In fr, this message translates to:
  /// **'FAQ'**
  String get support_faqTab;

  /// No description provided for @support_contactTab.
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get support_contactTab;

  /// No description provided for @support_needHelp.
  ///
  /// In fr, this message translates to:
  /// **'Besoin d\'aide?'**
  String get support_needHelp;

  /// No description provided for @support_teamResponse.
  ///
  /// In fr, this message translates to:
  /// **'Notre équipe vous répondra dans les 24-48h'**
  String get support_teamResponse;

  /// No description provided for @support_subject.
  ///
  /// In fr, this message translates to:
  /// **'Sujet'**
  String get support_subject;

  /// No description provided for @support_message.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get support_message;

  /// No description provided for @support_messageHint.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez votre problème ou question en détail...'**
  String get support_messageHint;

  /// No description provided for @support_messageRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un message'**
  String get support_messageRequired;

  /// No description provided for @support_messageMinLength.
  ///
  /// In fr, this message translates to:
  /// **'Le message doit contenir au moins 10 caractères'**
  String get support_messageMinLength;

  /// No description provided for @support_send.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get support_send;

  /// No description provided for @support_contactDirectly.
  ///
  /// In fr, this message translates to:
  /// **'Ou contactez-nous directement:'**
  String get support_contactDirectly;

  /// No description provided for @support_messageSent.
  ///
  /// In fr, this message translates to:
  /// **'Votre message a été envoyé avec succès'**
  String get support_messageSent;

  /// No description provided for @support_workerBadge.
  ///
  /// In fr, this message translates to:
  /// **'Déneigeur'**
  String get support_workerBadge;

  /// No description provided for @support_workerGeneral.
  ///
  /// In fr, this message translates to:
  /// **'Général'**
  String get support_workerGeneral;

  /// No description provided for @support_workerJobs.
  ///
  /// In fr, this message translates to:
  /// **'Jobs'**
  String get support_workerJobs;

  /// No description provided for @support_workerPayments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get support_workerPayments;

  /// No description provided for @support_workerAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get support_workerAccount;

  /// No description provided for @support_workerSupport.
  ///
  /// In fr, this message translates to:
  /// **'Support Déneigeurs'**
  String get support_workerSupport;

  /// No description provided for @support_workerTeamResponse.
  ///
  /// In fr, this message translates to:
  /// **'Notre équipe répond sous 24-48h'**
  String get support_workerTeamResponse;

  /// No description provided for @support_workerSubjectBug.
  ///
  /// In fr, this message translates to:
  /// **'Problème technique'**
  String get support_workerSubjectBug;

  /// No description provided for @support_workerSubjectQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Question générale'**
  String get support_workerSubjectQuestion;

  /// No description provided for @support_workerSubjectSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion d\'amélioration'**
  String get support_workerSubjectSuggestion;

  /// No description provided for @support_workerSubjectOther.
  ///
  /// In fr, this message translates to:
  /// **'Problème de paiement / Autre'**
  String get support_workerSubjectOther;

  /// No description provided for @support_subjectBug.
  ///
  /// In fr, this message translates to:
  /// **'Signalement de bug'**
  String get support_subjectBug;

  /// No description provided for @support_subjectQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Question'**
  String get support_subjectQuestion;

  /// No description provided for @support_subjectSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion'**
  String get support_subjectSuggestion;

  /// No description provided for @support_subjectOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get support_subjectOther;

  /// No description provided for @support_statusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get support_statusPending;

  /// No description provided for @support_statusInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get support_statusInProgress;

  /// No description provided for @support_statusResolved.
  ///
  /// In fr, this message translates to:
  /// **'Résolu'**
  String get support_statusResolved;

  /// No description provided for @support_statusClosed.
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get support_statusClosed;

  /// No description provided for @faqCat_general.
  ///
  /// In fr, this message translates to:
  /// **'Général'**
  String get faqCat_general;

  /// No description provided for @faqCat_reservations.
  ///
  /// In fr, this message translates to:
  /// **'Réservations'**
  String get faqCat_reservations;

  /// No description provided for @faqCat_payments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get faqCat_payments;

  /// No description provided for @faqCat_disputes.
  ///
  /// In fr, this message translates to:
  /// **'Litiges'**
  String get faqCat_disputes;

  /// No description provided for @faqCat_account.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get faqCat_account;

  /// No description provided for @faq_q1.
  ///
  /// In fr, this message translates to:
  /// **'Comment fonctionne Deneige Auto?'**
  String get faq_q1;

  /// No description provided for @faq_a1.
  ///
  /// In fr, this message translates to:
  /// **'Deneige Auto vous permet de réserver un service de déneigement pour votre véhicule. Créez une réservation en sélectionnant votre véhicule, son emplacement, la date et l\'heure souhaitées. Un déneigeur disponible dans votre zone sera assigné et viendra déneiger votre véhicule.'**
  String get faq_a1;

  /// No description provided for @faq_q2.
  ///
  /// In fr, this message translates to:
  /// **'Dans quelles zones le service est-il disponible?'**
  String get faq_q2;

  /// No description provided for @faq_a2.
  ///
  /// In fr, this message translates to:
  /// **'Actuellement, notre service est disponible dans la grande région de Montréal et ses environs. Nous élargissons continuellement notre zone de couverture. Consultez la carte dans l\'application pour voir si votre emplacement est couvert.'**
  String get faq_a2;

  /// No description provided for @faq_q3.
  ///
  /// In fr, this message translates to:
  /// **'Quelles sont les heures de service?'**
  String get faq_q3;

  /// No description provided for @faq_a3.
  ///
  /// In fr, this message translates to:
  /// **'Notre service est disponible 7 jours sur 7, de 5h00 à 22h00. Les horaires peuvent varier pendant les périodes de tempête intense.'**
  String get faq_a3;

  /// No description provided for @faq_q4.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce que l\'Assistant IA?'**
  String get faq_q4;

  /// No description provided for @faq_a4.
  ///
  /// In fr, this message translates to:
  /// **'L\'Assistant IA est votre aide virtuel disponible 24/7 dans l\'application. Il peut répondre à vos questions sur le service, vous aider à résoudre des problèmes, donner des conseils et vous informer sur les conditions météo actuelles et prévues dans votre région.'**
  String get faq_a4;

  /// No description provided for @faq_q5.
  ///
  /// In fr, this message translates to:
  /// **'Comment utiliser l\'Assistant IA?'**
  String get faq_q5;

  /// No description provided for @faq_a5.
  ///
  /// In fr, this message translates to:
  /// **'Accédez à l\'Assistant IA depuis le menu principal ou en appuyant sur l\'icône de chat. Posez vos questions en langage naturel et l\'assistant vous répondra instantanément. Il peut vous aider avec les réservations, les litiges, les paiements et bien plus.'**
  String get faq_a5;

  /// No description provided for @faq_q6.
  ///
  /// In fr, this message translates to:
  /// **'L\'Assistant IA peut-il me donner la météo?'**
  String get faq_q6;

  /// No description provided for @faq_a6.
  ///
  /// In fr, this message translates to:
  /// **'Oui! L\'Assistant IA a accès aux données météo en temps réel. Demandez-lui simplement \"Quelle est la météo?\" ou \"Va-t-il neiger demain?\" pour obtenir les prévisions actuelles et à venir dans votre région.'**
  String get faq_a6;

  /// No description provided for @faq_q7.
  ///
  /// In fr, this message translates to:
  /// **'Comment faire une réservation?'**
  String get faq_q7;

  /// No description provided for @faq_a7.
  ///
  /// In fr, this message translates to:
  /// **'1. Ouvrez l\'application et appuyez sur \"Nouvelle réservation\"\n2. Sélectionnez votre véhicule ou ajoutez-en un nouveau\n3. Indiquez l\'emplacement du véhicule\n4. Choisissez la date et l\'heure\n5. Sélectionnez les options souhaitées\n6. Confirmez et payez'**
  String get faq_a7;

  /// No description provided for @faq_q8.
  ///
  /// In fr, this message translates to:
  /// **'Puis-je annuler ma réservation?'**
  String get faq_q8;

  /// No description provided for @faq_a8.
  ///
  /// In fr, this message translates to:
  /// **'Oui, vous pouvez annuler votre réservation selon les conditions suivantes:\n• Plus de 24h avant: remboursement complet\n• Entre 12h et 24h avant: remboursement de 50%\n• Moins de 12h avant: aucun remboursement'**
  String get faq_a8;

  /// No description provided for @faq_q9.
  ///
  /// In fr, this message translates to:
  /// **'Comment savoir quand le déneigeur arrive?'**
  String get faq_q9;

  /// No description provided for @faq_a9.
  ///
  /// In fr, this message translates to:
  /// **'Vous recevrez une notification push lorsque le déneigeur sera en route vers votre véhicule. Vous pouvez également suivre sa position en temps réel sur la carte dans l\'application.'**
  String get faq_a9;

  /// No description provided for @faq_q10.
  ///
  /// In fr, this message translates to:
  /// **'Que faire si le déneigeur ne trouve pas mon véhicule?'**
  String get faq_q10;

  /// No description provided for @faq_a10.
  ///
  /// In fr, this message translates to:
  /// **'Assurez-vous d\'avoir bien décrit l\'emplacement de votre véhicule. Le déneigeur vous contactera via la messagerie de l\'application s\'il a des difficultés. Vous pouvez aussi ajouter une photo de votre véhicule pour faciliter son identification.'**
  String get faq_a10;

  /// No description provided for @faq_q11.
  ///
  /// In fr, this message translates to:
  /// **'Quels modes de paiement sont acceptés?'**
  String get faq_q11;

  /// No description provided for @faq_a11.
  ///
  /// In fr, this message translates to:
  /// **'Nous acceptons les cartes de crédit Visa, Mastercard et American Express. Le paiement est traité de manière sécurisée via Stripe.'**
  String get faq_a11;

  /// No description provided for @faq_q12.
  ///
  /// In fr, this message translates to:
  /// **'Comment obtenir un remboursement?'**
  String get faq_q12;

  /// No description provided for @faq_a12.
  ///
  /// In fr, this message translates to:
  /// **'Les remboursements sont automatiquement traités selon notre politique d\'annulation. Pour les cas spéciaux (service non satisfaisant, etc.), contactez notre support via la section \"Aide et Support\".'**
  String get faq_a12;

  /// No description provided for @faq_q13.
  ///
  /// In fr, this message translates to:
  /// **'Puis-je ajouter un pourboire?'**
  String get faq_q13;

  /// No description provided for @faq_a13.
  ///
  /// In fr, this message translates to:
  /// **'Oui! Après la fin du service, vous avez la possibilité d\'ajouter un pourboire au déneigeur. Cette option apparaît sur l\'écran de notation du service.'**
  String get faq_a13;

  /// No description provided for @faq_q14.
  ///
  /// In fr, this message translates to:
  /// **'Comment gérer mes cartes de paiement?'**
  String get faq_q14;

  /// No description provided for @faq_a14.
  ///
  /// In fr, this message translates to:
  /// **'Rendez-vous dans Profil > Paiements > Méthodes de paiement. Vous pouvez y ajouter, supprimer ou définir une carte par défaut.'**
  String get faq_a14;

  /// No description provided for @faq_q15.
  ///
  /// In fr, this message translates to:
  /// **'Que faire si le déneigeur n\'est pas venu?'**
  String get faq_q15;

  /// No description provided for @faq_a15.
  ///
  /// In fr, this message translates to:
  /// **'Si le déneigeur assigné n\'est pas venu à l\'heure prévue, vous pouvez signaler un \"no-show\" directement depuis les détails de la réservation. Le bouton \"Signaler un no-show\" apparaît 30 minutes après l\'heure de départ prévue. Si le no-show est confirmé, vous serez remboursé intégralement.'**
  String get faq_a15;

  /// No description provided for @faq_q16.
  ///
  /// In fr, this message translates to:
  /// **'Comment créer un litige?'**
  String get faq_q16;

  /// No description provided for @faq_a16.
  ///
  /// In fr, this message translates to:
  /// **'Pour créer un litige:\n1. Allez dans Profil > Mes litiges > Créer un litige\n2. Sélectionnez la réservation concernée\n3. Choisissez le type de problème (travail incomplet, qualité insuffisante, dommage, etc.)\n4. Décrivez la situation en détail\n5. Ajoutez des photos comme preuves\n6. Indiquez le montant réclamé si applicable\n7. Soumettez votre litige'**
  String get faq_a16;

  /// No description provided for @faq_q17.
  ///
  /// In fr, this message translates to:
  /// **'Quels types de litiges puis-je signaler?'**
  String get faq_q17;

  /// No description provided for @faq_a17.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez signaler plusieurs types de problèmes:\n• Déneigeur non venu (no-show)\n• Travail incomplet\n• Qualité insuffisante\n• Retard important\n• Dommage causé à votre véhicule\n• Mauvais emplacement déneigé\n• Surfacturation\n• Comportement inapproprié\n• Autre problème'**
  String get faq_a17;

  /// No description provided for @faq_q18.
  ///
  /// In fr, this message translates to:
  /// **'Comment ajouter des preuves à mon litige?'**
  String get faq_q18;

  /// No description provided for @faq_a18.
  ///
  /// In fr, this message translates to:
  /// **'Les preuves renforcent votre dossier. Dans les détails du litige, appuyez sur \"Ajouter des preuves\" pour:\n• Prendre des photos ou les choisir depuis votre galerie (jusqu\'à 10 photos)\n• Ajouter une description détaillée\n\nConseils: prenez des photos claires, bien éclairées et horodatées si possible.'**
  String get faq_a18;

  /// No description provided for @faq_q19.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce que l\'analyse IA des litiges?'**
  String get faq_q19;

  /// No description provided for @faq_a19.
  ///
  /// In fr, this message translates to:
  /// **'Notre système utilise l\'intelligence artificielle pour analyser objectivement les litiges. L\'IA examine les preuves (photos, descriptions, données GPS, historique), évalue la force des arguments et propose une recommandation. Cette analyse aide notre équipe à prendre des décisions justes et rapides.'**
  String get faq_a19;

  /// No description provided for @faq_q20.
  ///
  /// In fr, this message translates to:
  /// **'Combien de temps ai-je pour signaler un problème?'**
  String get faq_q20;

  /// No description provided for @faq_a20.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez 24 heures après la fin du service pour signaler un problème ou un no-show. Passé ce délai, vous pouvez toujours contacter le support, mais le traitement pourrait être plus long.'**
  String get faq_a20;

  /// No description provided for @faq_q21.
  ///
  /// In fr, this message translates to:
  /// **'Comment suivre l\'état de mon litige?'**
  String get faq_q21;

  /// No description provided for @faq_a21.
  ///
  /// In fr, this message translates to:
  /// **'Rendez-vous dans Profil > Mes litiges pour voir tous vos litiges et leur statut: Ouvert, En examen, En attente de réponse, Résolu. Vous recevrez une notification dès qu\'une décision sera prise.'**
  String get faq_a21;

  /// No description provided for @faq_q22.
  ///
  /// In fr, this message translates to:
  /// **'Puis-je faire appel d\'une décision?'**
  String get faq_q22;

  /// No description provided for @faq_a22.
  ///
  /// In fr, this message translates to:
  /// **'Oui, si vous n\'êtes pas satisfait de la décision prise, vous pouvez faire appel dans les 7 jours suivant la résolution. Allez dans les détails du litige et appuyez sur \"Faire appel\". Expliquez pourquoi vous contestez la décision.'**
  String get faq_a22;

  /// No description provided for @faq_q23.
  ///
  /// In fr, this message translates to:
  /// **'Comment sont traités les remboursements suite à un litige?'**
  String get faq_q23;

  /// No description provided for @faq_a23.
  ///
  /// In fr, this message translates to:
  /// **'Si le litige est résolu en votre faveur, le remboursement est automatiquement traité sur votre méthode de paiement originale. Le délai est généralement de 3-5 jours ouvrables selon votre banque.'**
  String get faq_a23;

  /// No description provided for @faq_q24.
  ///
  /// In fr, this message translates to:
  /// **'Comment modifier mes informations personnelles?'**
  String get faq_q24;

  /// No description provided for @faq_a24.
  ///
  /// In fr, this message translates to:
  /// **'Allez dans Profil > Modifier le profil pour changer votre nom, numéro de téléphone ou photo de profil.'**
  String get faq_a24;

  /// No description provided for @faq_q25.
  ///
  /// In fr, this message translates to:
  /// **'Comment ajouter ou supprimer un véhicule?'**
  String get faq_q25;

  /// No description provided for @faq_a25.
  ///
  /// In fr, this message translates to:
  /// **'Rendez-vous dans Profil > Mes véhicules. Appuyez sur \"+\" pour ajouter un nouveau véhicule ou faites glisser vers la gauche sur un véhicule existant pour le supprimer.'**
  String get faq_a25;

  /// No description provided for @faq_q26.
  ///
  /// In fr, this message translates to:
  /// **'Comment supprimer mon compte?'**
  String get faq_q26;

  /// No description provided for @faq_a26.
  ///
  /// In fr, this message translates to:
  /// **'Allez dans Paramètres > Supprimer mon compte. Cette action est irréversible et supprimera toutes vos données.'**
  String get faq_a26;

  /// No description provided for @faq_q27.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai oublié mon mot de passe, que faire?'**
  String get faq_q27;

  /// No description provided for @faq_a27.
  ///
  /// In fr, this message translates to:
  /// **'Sur l\'écran de connexion, appuyez sur \"Mot de passe oublié?\". Entrez votre email et vous recevrez un lien pour réinitialiser votre mot de passe.'**
  String get faq_a27;

  /// No description provided for @wfaq_q1.
  ///
  /// In fr, this message translates to:
  /// **'Comment devenir déneigeur sur Deneige Auto?'**
  String get wfaq_q1;

  /// No description provided for @wfaq_a1.
  ///
  /// In fr, this message translates to:
  /// **'Pour devenir déneigeur, vous devez créer un compte en tant que déneigeur, compléter votre profil avec vos informations personnelles, ajouter votre équipement disponible et configurer votre compte bancaire pour recevoir vos paiements.'**
  String get wfaq_a1;

  /// No description provided for @wfaq_q2.
  ///
  /// In fr, this message translates to:
  /// **'Quelles sont les conditions pour être déneigeur?'**
  String get wfaq_q2;

  /// No description provided for @wfaq_a2.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez avoir au moins 18 ans, posséder un équipement de déneigement de base (pelle, balai, grattoir), être disponible pendant les périodes de neige et avoir un compte bancaire canadien pour recevoir vos paiements.'**
  String get wfaq_a2;

  /// No description provided for @wfaq_q3.
  ///
  /// In fr, this message translates to:
  /// **'Puis-je choisir mes zones de travail?'**
  String get wfaq_q3;

  /// No description provided for @wfaq_a3.
  ///
  /// In fr, this message translates to:
  /// **'Oui! Dans vos paramètres, vous pouvez définir vos zones préférées. Vous recevrez des notifications prioritaires pour les jobs dans ces zones, mais vous pouvez aussi accepter des jobs ailleurs.'**
  String get wfaq_a3;

  /// No description provided for @wfaq_q4.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce que l\'Assistant IA?'**
  String get wfaq_q4;

  /// No description provided for @wfaq_a4.
  ///
  /// In fr, this message translates to:
  /// **'L\'Assistant IA est votre aide virtuel disponible 24/7 dans l\'application. Il peut répondre à vos questions sur les jobs, vous aider à résoudre des problèmes, donner des conseils pour améliorer votre service et vous informer sur les conditions météo pour planifier votre journée.'**
  String get wfaq_a4;

  /// No description provided for @wfaq_q5.
  ///
  /// In fr, this message translates to:
  /// **'Comment utiliser l\'Assistant IA?'**
  String get wfaq_q5;

  /// No description provided for @wfaq_a5.
  ///
  /// In fr, this message translates to:
  /// **'Accédez à l\'Assistant IA depuis le menu principal. Posez vos questions en langage naturel:\n• \"Quels jobs sont disponibles près de moi?\"\n• \"Comment répondre à un litige?\"\n• \"Quelle météo est prévue demain?\"\n• \"Comment améliorer mon score?\"\nL\'assistant vous répondra instantanément.'**
  String get wfaq_a5;

  /// No description provided for @wfaq_q6.
  ///
  /// In fr, this message translates to:
  /// **'L\'Assistant IA peut-il m\'aider avec la météo?'**
  String get wfaq_q6;

  /// No description provided for @wfaq_a6.
  ///
  /// In fr, this message translates to:
  /// **'Oui! L\'Assistant IA a accès aux prévisions météo en temps réel. Demandez-lui les conditions actuelles ou les prévisions pour planifier vos disponibilités. Vous pouvez ainsi anticiper les journées de forte demande lors des tempêtes de neige.'**
  String get wfaq_a6;

  /// No description provided for @wfaq_q7.
  ///
  /// In fr, this message translates to:
  /// **'Comment recevoir des jobs?'**
  String get wfaq_q7;

  /// No description provided for @wfaq_a7.
  ///
  /// In fr, this message translates to:
  /// **'Activez votre disponibilité dans l\'application. Vous recevrez des notifications push pour les nouveaux jobs disponibles dans votre zone. Vous pouvez alors accepter ou refuser chaque job.'**
  String get wfaq_a7;

  /// No description provided for @wfaq_q8.
  ///
  /// In fr, this message translates to:
  /// **'Puis-je accepter plusieurs jobs en même temps?'**
  String get wfaq_q8;

  /// No description provided for @wfaq_a8.
  ///
  /// In fr, this message translates to:
  /// **'Oui, vous pouvez gérer jusqu\'à 5 jobs simultanément. Dans vos paramètres, définissez le nombre maximum de jobs actifs que vous souhaitez avoir en même temps. Nous recommandons 2-3 jobs pour un service optimal.'**
  String get wfaq_a8;

  /// No description provided for @wfaq_q9.
  ///
  /// In fr, this message translates to:
  /// **'Comment annuler un job accepté?'**
  String get wfaq_q9;

  /// No description provided for @wfaq_a9.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez annuler un job avant de commencer le travail. Allez dans les détails du job et appuyez sur \"Annuler\". Attention: des annulations fréquentes peuvent affecter votre score et votre visibilité.'**
  String get wfaq_a9;

  /// No description provided for @wfaq_q10.
  ///
  /// In fr, this message translates to:
  /// **'Que faire si je ne trouve pas le véhicule?'**
  String get wfaq_q10;

  /// No description provided for @wfaq_a10.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez la messagerie intégrée pour contacter le client. Si le véhicule est introuvable après 15 minutes et sans réponse du client, vous pouvez signaler le problème et annuler le job sans pénalité.'**
  String get wfaq_a10;

  /// No description provided for @wfaq_q11.
  ///
  /// In fr, this message translates to:
  /// **'Comment signaler un problème avec un job?'**
  String get wfaq_q11;

  /// No description provided for @wfaq_a11.
  ///
  /// In fr, this message translates to:
  /// **'Dans les détails du job, appuyez sur \"Signaler un problème\". Décrivez la situation et ajoutez des photos si nécessaire. Notre équipe examinera votre signalement rapidement.'**
  String get wfaq_a11;

  /// No description provided for @wfaq_q12.
  ///
  /// In fr, this message translates to:
  /// **'Comment suis-je payé?'**
  String get wfaq_q12;

  /// No description provided for @wfaq_a12.
  ///
  /// In fr, this message translates to:
  /// **'Les paiements sont effectués automatiquement via Stripe Connect. Après chaque job complété, le montant est transféré sur votre compte bancaire dans un délai de 2-7 jours ouvrables.'**
  String get wfaq_a12;

  /// No description provided for @wfaq_q13.
  ///
  /// In fr, this message translates to:
  /// **'Comment configurer mon compte bancaire?'**
  String get wfaq_q13;

  /// No description provided for @wfaq_a13.
  ///
  /// In fr, this message translates to:
  /// **'Allez dans Paramètres > Mes paiements > Configuration Stripe. Suivez les étapes pour vérifier votre identité et ajouter vos coordonnées bancaires. Ce processus est sécurisé et obligatoire pour recevoir vos paiements.'**
  String get wfaq_a13;

  /// No description provided for @wfaq_q14.
  ///
  /// In fr, this message translates to:
  /// **'Comment sont calculés mes gains?'**
  String get wfaq_q14;

  /// No description provided for @wfaq_a14.
  ///
  /// In fr, this message translates to:
  /// **'Vos gains dépendent du type de service (déneigement standard, avec options), de la taille du véhicule et de la distance. Vous voyez le montant exact avant d\'accepter chaque job. Deneige Auto prélève une commission de 15%.'**
  String get wfaq_a14;

  /// No description provided for @wfaq_q15.
  ///
  /// In fr, this message translates to:
  /// **'Comment fonctionnent les pourboires?'**
  String get wfaq_q15;

  /// No description provided for @wfaq_a15.
  ///
  /// In fr, this message translates to:
  /// **'Les clients peuvent laisser un pourboire après le service. Les pourboires sont 100% pour vous, sans commission. Vous recevez une notification et le montant est ajouté à votre prochain paiement.'**
  String get wfaq_a15;

  /// No description provided for @wfaq_q16.
  ///
  /// In fr, this message translates to:
  /// **'Où voir mon historique de gains?'**
  String get wfaq_q16;

  /// No description provided for @wfaq_a16.
  ///
  /// In fr, this message translates to:
  /// **'Allez dans l\'onglet \"Gains\" pour voir vos revenus quotidiens, hebdomadaires et mensuels. Vous pouvez aussi voir le détail de chaque job et les pourboires reçus.'**
  String get wfaq_a16;

  /// No description provided for @wfaq_q17.
  ///
  /// In fr, this message translates to:
  /// **'Que se passe-t-il si un client me signale un no-show?'**
  String get wfaq_q17;

  /// No description provided for @wfaq_a17.
  ///
  /// In fr, this message translates to:
  /// **'Si un client signale que vous n\'êtes pas venu, vous recevrez une notification et aurez l\'opportunité de répondre. Si vous avez marqué \"En route\" dans l\'application, cela sera pris en compte. Les faux signalements de clients sont aussi sanctionnés.'**
  String get wfaq_a17;

  /// No description provided for @wfaq_q18.
  ///
  /// In fr, this message translates to:
  /// **'Comment répondre à un litige?'**
  String get wfaq_q18;

  /// No description provided for @wfaq_a18.
  ///
  /// In fr, this message translates to:
  /// **'Pour répondre à un litige:\n1. Allez dans Profil > Mes litiges\n2. Ouvrez le litige concerné\n3. Appuyez sur \"Répondre au litige\"\n4. Expliquez votre version des faits en détail\n5. Ajoutez des photos comme preuves (avant/après, captures d\'écran, etc.)\n6. Soumettez votre réponse\n\nVous avez généralement 48 heures pour répondre.'**
  String get wfaq_a18;

  /// No description provided for @wfaq_q19.
  ///
  /// In fr, this message translates to:
  /// **'Comment ajouter des preuves à ma défense?'**
  String get wfaq_q19;

  /// No description provided for @wfaq_a19.
  ///
  /// In fr, this message translates to:
  /// **'Les preuves sont essentielles pour défendre votre position. Dans les détails du litige, utilisez \"Ajouter des preuves\" pour:\n• Photos avant/après le déneigement\n• Captures d\'écran de communications\n• Photos horodatées sur le site\n• Tout document pertinent\n\nVous pouvez ajouter jusqu\'à 10 photos et une description détaillée.'**
  String get wfaq_a19;

  /// No description provided for @wfaq_q20.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce que l\'analyse IA des litiges?'**
  String get wfaq_q20;

  /// No description provided for @wfaq_a20.
  ///
  /// In fr, this message translates to:
  /// **'Notre système utilise l\'intelligence artificielle pour analyser objectivement chaque litige. L\'IA examine:\n• Les photos et preuves des deux parties\n• Les données GPS et timestamps\n• L\'historique du client et du déneigeur\n• La cohérence des déclarations\n\nCette analyse aide à prendre des décisions justes. Si l\'IA détecte un faux signalement, cela joue en votre faveur.'**
  String get wfaq_a20;

  /// No description provided for @wfaq_q21.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi prendre des photos avant/après est important?'**
  String get wfaq_q21;

  /// No description provided for @wfaq_a21.
  ///
  /// In fr, this message translates to:
  /// **'Les photos avant/après sont vos meilleures preuves:\n• Elles documentent l\'état initial et le travail accompli\n• L\'IA peut analyser la qualité du déneigement\n• En cas de litige, elles prouvent votre travail\n• Elles sont horodatées automatiquement\n\nPrenez l\'habitude de photographier chaque job!'**
  String get wfaq_a21;

  /// No description provided for @wfaq_q22.
  ///
  /// In fr, this message translates to:
  /// **'Quelles sont les conséquences d\'un litige contre moi?'**
  String get wfaq_q22;

  /// No description provided for @wfaq_a22.
  ///
  /// In fr, this message translates to:
  /// **'Les conséquences dépendent de la décision et de votre historique:\n• Premier avertissement: notification\n• Récidive: suspension temporaire (3-7 jours)\n• Problèmes répétés: suspension prolongée (30 jours)\n• Cas graves: exclusion permanente\n\nMaintenez un bon service pour éviter les litiges.'**
  String get wfaq_a22;

  /// No description provided for @wfaq_q23.
  ///
  /// In fr, this message translates to:
  /// **'Comment contester une décision défavorable?'**
  String get wfaq_q23;

  /// No description provided for @wfaq_a23.
  ///
  /// In fr, this message translates to:
  /// **'Si vous n\'êtes pas d\'accord avec la décision prise sur un litige, vous pouvez faire appel dans les 7 jours. Fournissez des preuves supplémentaires (photos, messages, etc.) pour appuyer votre contestation.'**
  String get wfaq_a23;

  /// No description provided for @wfaq_q24.
  ///
  /// In fr, this message translates to:
  /// **'Comment signaler un client problématique?'**
  String get wfaq_q24;

  /// No description provided for @wfaq_a24.
  ///
  /// In fr, this message translates to:
  /// **'Si un client est abusif, introuvable malgré vos efforts, ou fait de fausses réclamations, vous pouvez le signaler dans les détails du job. Notre équipe examinera la situation et pourra sanctionner le client si nécessaire.'**
  String get wfaq_a24;

  /// No description provided for @wfaq_q25.
  ///
  /// In fr, this message translates to:
  /// **'Mon paiement est-il affecté pendant un litige?'**
  String get wfaq_q25;

  /// No description provided for @wfaq_a25.
  ///
  /// In fr, this message translates to:
  /// **'Pendant l\'examen d\'un litige, le paiement correspondant peut être temporairement retenu. Une fois la décision prise:\n• Litige en votre faveur: paiement complet versé\n• Litige contre vous: remboursement au client (partiel ou total selon la décision)'**
  String get wfaq_a25;

  /// No description provided for @wfaq_q26.
  ///
  /// In fr, this message translates to:
  /// **'Comment protéger mon score de fiabilité?'**
  String get wfaq_q26;

  /// No description provided for @wfaq_a26.
  ///
  /// In fr, this message translates to:
  /// **'Pour maintenir un bon score:\n• Arrivez à l\'heure (marquez \"En route\" dans l\'app)\n• Prenez des photos avant/après chaque job\n• Communiquez avec le client en cas de problème\n• Complétez le travail selon les standards demandés\n• Évitez les annulations de dernière minute'**
  String get wfaq_a26;

  /// No description provided for @wfaq_q27.
  ///
  /// In fr, this message translates to:
  /// **'Comment modifier mon équipement disponible?'**
  String get wfaq_q27;

  /// No description provided for @wfaq_a27.
  ///
  /// In fr, this message translates to:
  /// **'Dans Paramètres ou dans votre Profil, vous pouvez cocher/décocher les équipements que vous possédez: pelle, balai, grattoir, épandeur de sel, souffleuse. Cela aide à vous assigner les jobs appropriés.'**
  String get wfaq_a27;

  /// No description provided for @wfaq_q28.
  ///
  /// In fr, this message translates to:
  /// **'Comment changer mes notifications?'**
  String get wfaq_q28;

  /// No description provided for @wfaq_a28.
  ///
  /// In fr, this message translates to:
  /// **'Dans Paramètres > Notifications, vous pouvez activer/désactiver les alertes pour: nouveaux jobs, jobs urgents et pourboires reçus.'**
  String get wfaq_a28;

  /// No description provided for @wfaq_q29.
  ///
  /// In fr, this message translates to:
  /// **'Comment améliorer mon score déneigeur?'**
  String get wfaq_q29;

  /// No description provided for @wfaq_a29.
  ///
  /// In fr, this message translates to:
  /// **'Votre score est basé sur: la qualité du service (évaluations clients), le taux d\'acceptation des jobs, la ponctualité et le taux de complétion. Offrez un service de qualité et soyez fiable pour améliorer votre score.'**
  String get wfaq_a29;

  /// No description provided for @wfaq_q30.
  ///
  /// In fr, this message translates to:
  /// **'Puis-je prendre une pause de l\'application?'**
  String get wfaq_q30;

  /// No description provided for @wfaq_a30.
  ///
  /// In fr, this message translates to:
  /// **'Oui! Désactivez simplement votre disponibilité dans l\'application. Vous ne recevrez plus de notifications de jobs. Réactivez quand vous êtes prêt à travailler.'**
  String get wfaq_a30;

  /// No description provided for @adminDash_quickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get adminDash_quickActions;

  /// No description provided for @adminDash_users.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs'**
  String get adminDash_users;

  /// No description provided for @adminDash_reservations.
  ///
  /// In fr, this message translates to:
  /// **'Réservations'**
  String get adminDash_reservations;

  /// No description provided for @adminDash_notify.
  ///
  /// In fr, this message translates to:
  /// **'Notifier'**
  String get adminDash_notify;

  /// No description provided for @adminDash_support.
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get adminDash_support;

  /// No description provided for @adminDash_clientsWorkers.
  ///
  /// In fr, this message translates to:
  /// **'{clients} clients, {workers} déneigeurs'**
  String adminDash_clientsWorkers(int clients, int workers);

  /// No description provided for @adminDash_todayCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} aujourd\'hui'**
  String adminDash_todayCount(int count);

  /// No description provided for @adminDash_pending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get adminDash_pending;

  /// No description provided for @adminDash_toProcess.
  ///
  /// In fr, this message translates to:
  /// **'À traiter'**
  String get adminDash_toProcess;

  /// No description provided for @adminDash_completionRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de complétion'**
  String get adminDash_completionRate;

  /// No description provided for @adminDash_completedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} terminées'**
  String adminDash_completedCount(int count);

  /// No description provided for @adminDash_pendingCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} en attente'**
  String adminDash_pendingCount(int count);

  /// No description provided for @adminDash_total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get adminDash_total;

  /// No description provided for @adminDash_inProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get adminDash_inProgress;

  /// No description provided for @adminDash_resolved.
  ///
  /// In fr, this message translates to:
  /// **'Résolues'**
  String get adminDash_resolved;

  /// No description provided for @adminDash_newRequestsToday.
  ///
  /// In fr, this message translates to:
  /// **'{count} nouvelle(s) demande(s) aujourd\'hui'**
  String adminDash_newRequestsToday(int count);

  /// No description provided for @adminDash_revenue.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get adminDash_revenue;

  /// No description provided for @adminDash_reservationCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} réservations'**
  String adminDash_reservationCount(int count);

  /// No description provided for @adminDash_thisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get adminDash_thisMonth;

  /// No description provided for @adminDash_grossCommission.
  ///
  /// In fr, this message translates to:
  /// **'Commission brute (25%)'**
  String get adminDash_grossCommission;

  /// No description provided for @adminDash_stripeFees.
  ///
  /// In fr, this message translates to:
  /// **'Frais Stripe'**
  String get adminDash_stripeFees;

  /// No description provided for @adminDash_netCommission.
  ///
  /// In fr, this message translates to:
  /// **'Commission nette'**
  String get adminDash_netCommission;

  /// No description provided for @adminDash_tips.
  ///
  /// In fr, this message translates to:
  /// **'Pourboires'**
  String get adminDash_tips;

  /// No description provided for @adminDash_topWorkers.
  ///
  /// In fr, this message translates to:
  /// **'Top Déneigeurs'**
  String get adminDash_topWorkers;

  /// No description provided for @adminDash_viewAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous'**
  String get adminDash_viewAll;

  /// No description provided for @adminDash_noWorkers.
  ///
  /// In fr, this message translates to:
  /// **'Aucun déneigeur pour le moment'**
  String get adminDash_noWorkers;

  /// No description provided for @adminDash_sendNotification.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer une notification'**
  String get adminDash_sendNotification;

  /// No description provided for @adminDash_title.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get adminDash_title;

  /// No description provided for @adminDash_messageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get adminDash_messageLabel;

  /// No description provided for @adminDash_recipients.
  ///
  /// In fr, this message translates to:
  /// **'Destinataires'**
  String get adminDash_recipients;

  /// No description provided for @adminDash_allUsers.
  ///
  /// In fr, this message translates to:
  /// **'Tous les utilisateurs'**
  String get adminDash_allUsers;

  /// No description provided for @adminDash_clientsOnly.
  ///
  /// In fr, this message translates to:
  /// **'Clients uniquement'**
  String get adminDash_clientsOnly;

  /// No description provided for @adminDash_workersOnly.
  ///
  /// In fr, this message translates to:
  /// **'Déneigeurs uniquement'**
  String get adminDash_workersOnly;

  /// No description provided for @adminDash_cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get adminDash_cancel;

  /// No description provided for @adminDash_sendBtn.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get adminDash_sendBtn;

  /// No description provided for @adminDash_fillAllFields.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez remplir tous les champs'**
  String get adminDash_fillAllFields;

  /// No description provided for @adminDash_adminLogout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion Admin'**
  String get adminDash_adminLogout;

  /// No description provided for @adminDash_logoutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment vous déconnecter du panneau d\'administration ?'**
  String get adminDash_logoutConfirm;

  /// No description provided for @adminDash_logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get adminDash_logout;

  /// No description provided for @addVehicle_title.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un véhicule'**
  String get addVehicle_title;

  /// No description provided for @addVehicle_tapAddPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Touchez pour ajouter une photo'**
  String get addVehicle_tapAddPhoto;

  /// No description provided for @addVehicle_newVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau véhicule'**
  String get addVehicle_newVehicle;

  /// No description provided for @addVehicle_photoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Photo du véhicule'**
  String get addVehicle_photoTitle;

  /// No description provided for @addVehicle_photoVisibleWorker.
  ///
  /// In fr, this message translates to:
  /// **'Cette photo sera visible par le déneigeur'**
  String get addVehicle_photoVisibleWorker;

  /// No description provided for @addVehicle_takePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get addVehicle_takePhoto;

  /// No description provided for @addVehicle_useCamera.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser l\'appareil photo'**
  String get addVehicle_useCamera;

  /// No description provided for @addVehicle_choosePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une photo'**
  String get addVehicle_choosePhoto;

  /// No description provided for @addVehicle_fromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Depuis la galerie'**
  String get addVehicle_fromGallery;

  /// No description provided for @addVehicle_deletePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la photo'**
  String get addVehicle_deletePhoto;

  /// No description provided for @addVehicle_removeSelected.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la photo sélectionnée'**
  String get addVehicle_removeSelected;

  /// No description provided for @addVehicle_make.
  ///
  /// In fr, this message translates to:
  /// **'Marque'**
  String get addVehicle_make;

  /// No description provided for @addVehicle_model.
  ///
  /// In fr, this message translates to:
  /// **'Modèle'**
  String get addVehicle_model;

  /// No description provided for @addVehicle_year.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get addVehicle_year;

  /// No description provided for @addVehicle_plate.
  ///
  /// In fr, this message translates to:
  /// **'Plaque'**
  String get addVehicle_plate;

  /// No description provided for @addVehicle_required.
  ///
  /// In fr, this message translates to:
  /// **'Requis'**
  String get addVehicle_required;

  /// No description provided for @addVehicle_invalid.
  ///
  /// In fr, this message translates to:
  /// **'Invalide'**
  String get addVehicle_invalid;

  /// No description provided for @addVehicle_vehicleType.
  ///
  /// In fr, this message translates to:
  /// **'Type de véhicule'**
  String get addVehicle_vehicleType;

  /// No description provided for @addVehicle_color.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get addVehicle_color;

  /// No description provided for @addVehicle_setDefault.
  ///
  /// In fr, this message translates to:
  /// **'Définir comme véhicule par défaut'**
  String get addVehicle_setDefault;

  /// No description provided for @addVehicle_addBtn.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter le véhicule'**
  String get addVehicle_addBtn;

  /// No description provided for @addVehicle_colorWhite.
  ///
  /// In fr, this message translates to:
  /// **'Blanc'**
  String get addVehicle_colorWhite;

  /// No description provided for @addVehicle_colorBlack.
  ///
  /// In fr, this message translates to:
  /// **'Noir'**
  String get addVehicle_colorBlack;

  /// No description provided for @addVehicle_colorGray.
  ///
  /// In fr, this message translates to:
  /// **'Gris'**
  String get addVehicle_colorGray;

  /// No description provided for @addVehicle_colorSilver.
  ///
  /// In fr, this message translates to:
  /// **'Argent'**
  String get addVehicle_colorSilver;

  /// No description provided for @addVehicle_colorRed.
  ///
  /// In fr, this message translates to:
  /// **'Rouge'**
  String get addVehicle_colorRed;

  /// No description provided for @addVehicle_colorBlue.
  ///
  /// In fr, this message translates to:
  /// **'Bleu'**
  String get addVehicle_colorBlue;

  /// No description provided for @addVehicle_colorGreen.
  ///
  /// In fr, this message translates to:
  /// **'Vert'**
  String get addVehicle_colorGreen;

  /// No description provided for @addVehicle_colorBrown.
  ///
  /// In fr, this message translates to:
  /// **'Brun'**
  String get addVehicle_colorBrown;

  /// No description provided for @addVehicle_colorBeige.
  ///
  /// In fr, this message translates to:
  /// **'Beige'**
  String get addVehicle_colorBeige;

  /// No description provided for @addCard_title.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une carte'**
  String get addCard_title;

  /// No description provided for @addCard_securePayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement sécurisé'**
  String get addCard_securePayment;

  /// No description provided for @addCard_protectedByStripe.
  ///
  /// In fr, this message translates to:
  /// **'Vos informations sont protégées par Stripe'**
  String get addCard_protectedByStripe;

  /// No description provided for @addCard_cardInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations de la carte'**
  String get addCard_cardInfo;

  /// No description provided for @addCard_cardNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de carte'**
  String get addCard_cardNumber;

  /// No description provided for @addCard_setDefault.
  ///
  /// In fr, this message translates to:
  /// **'Définir comme méthode par défaut'**
  String get addCard_setDefault;

  /// No description provided for @addCard_usedForFuture.
  ///
  /// In fr, this message translates to:
  /// **'Utilisée pour vos futurs paiements'**
  String get addCard_usedForFuture;

  /// No description provided for @addCard_encryptedSecure.
  ///
  /// In fr, this message translates to:
  /// **'Données cryptées et sécurisées. Numéro de carte jamais stocké.'**
  String get addCard_encryptedSecure;

  /// No description provided for @addCard_addBtn.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter la carte'**
  String get addCard_addBtn;

  /// No description provided for @addCard_errorAdding.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ajouter cette carte. Vérifiez les informations et réessayez.'**
  String get addCard_errorAdding;

  /// No description provided for @verify_title.
  ///
  /// In fr, this message translates to:
  /// **'Vérification d\'identité'**
  String get verify_title;

  /// No description provided for @verify_heading.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre identité'**
  String get verify_heading;

  /// No description provided for @verify_description.
  ///
  /// In fr, this message translates to:
  /// **'Pour la sécurité de tous, nous devons vérifier votre identité avant que vous puissiez accepter des jobs.'**
  String get verify_description;

  /// No description provided for @verify_step1Title.
  ///
  /// In fr, this message translates to:
  /// **'Pièce d\'identité'**
  String get verify_step1Title;

  /// No description provided for @verify_step1Desc.
  ///
  /// In fr, this message translates to:
  /// **'Photographiez le recto (et verso si disponible) de votre pièce d\'identité'**
  String get verify_step1Desc;

  /// No description provided for @verify_step2Title.
  ///
  /// In fr, this message translates to:
  /// **'Selfie'**
  String get verify_step2Title;

  /// No description provided for @verify_step2Desc.
  ///
  /// In fr, this message translates to:
  /// **'Prenez un selfie pour confirmer que vous êtes bien la personne sur la pièce d\'identité'**
  String get verify_step2Desc;

  /// No description provided for @verify_step3Title.
  ///
  /// In fr, this message translates to:
  /// **'Vérification automatique'**
  String get verify_step3Title;

  /// No description provided for @verify_step3Desc.
  ///
  /// In fr, this message translates to:
  /// **'Notre système vérifie vos documents en quelques minutes'**
  String get verify_step3Desc;

  /// No description provided for @verify_acceptedDocs.
  ///
  /// In fr, this message translates to:
  /// **'Documents acceptés'**
  String get verify_acceptedDocs;

  /// No description provided for @verify_driverLicense.
  ///
  /// In fr, this message translates to:
  /// **'Permis de conduire'**
  String get verify_driverLicense;

  /// No description provided for @verify_healthCard.
  ///
  /// In fr, this message translates to:
  /// **'Carte d\'assurance maladie'**
  String get verify_healthCard;

  /// No description provided for @verify_passport.
  ///
  /// In fr, this message translates to:
  /// **'Passeport'**
  String get verify_passport;

  /// No description provided for @verify_permanentResident.
  ///
  /// In fr, this message translates to:
  /// **'Carte de résident permanent'**
  String get verify_permanentResident;

  /// No description provided for @verify_startBtn.
  ///
  /// In fr, this message translates to:
  /// **'Commencer la vérification'**
  String get verify_startBtn;

  /// No description provided for @verify_approved.
  ///
  /// In fr, this message translates to:
  /// **'Identité vérifiée'**
  String get verify_approved;

  /// No description provided for @verify_approvedDesc.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez maintenant accepter des jobs de déneigement'**
  String get verify_approvedDesc;

  /// No description provided for @verify_expiresOn.
  ///
  /// In fr, this message translates to:
  /// **'Expire le {date}'**
  String verify_expiresOn(String date);

  /// No description provided for @verify_pendingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification en cours'**
  String get verify_pendingTitle;

  /// No description provided for @verify_pendingDesc.
  ///
  /// In fr, this message translates to:
  /// **'Nous analysons vos documents. Cela peut prendre quelques minutes.'**
  String get verify_pendingDesc;

  /// No description provided for @verify_refresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get verify_refresh;

  /// No description provided for @verify_rejectedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification refusée'**
  String get verify_rejectedTitle;

  /// No description provided for @verify_attemptsRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Tentatives restantes: {count}'**
  String verify_attemptsRemaining(int count);

  /// No description provided for @verify_resubmit.
  ///
  /// In fr, this message translates to:
  /// **'Resoumettre mes documents'**
  String get verify_resubmit;

  /// No description provided for @verify_maxAttempts.
  ///
  /// In fr, this message translates to:
  /// **'Nombre maximum de tentatives atteint'**
  String get verify_maxAttempts;

  /// No description provided for @verify_contactSupport.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez contacter le support pour assistance.'**
  String get verify_contactSupport;

  /// No description provided for @verify_expiredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification expirée'**
  String get verify_expiredTitle;

  /// No description provided for @verify_expiredDesc.
  ///
  /// In fr, this message translates to:
  /// **'Votre vérification d\'identité a expiré. Veuillez resoumettre vos documents.'**
  String get verify_expiredDesc;

  /// No description provided for @verify_renewBtn.
  ///
  /// In fr, this message translates to:
  /// **'Renouveler ma vérification'**
  String get verify_renewBtn;

  /// No description provided for @worker_revenue.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get worker_revenue;

  /// No description provided for @worker_urgentCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} urgent'**
  String worker_urgentCount(int count);

  /// No description provided for @worker_myRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Mes revenus'**
  String get worker_myRevenue;

  /// No description provided for @resDetail_errorPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {message}'**
  String resDetail_errorPrefix(String message);

  /// No description provided for @resDetail_ratingSuccessTipError.
  ///
  /// In fr, this message translates to:
  /// **'Évaluation envoyée, mais erreur pourboire: {message}'**
  String resDetail_ratingSuccessTipError(String message);

  /// No description provided for @resDetail_tipSent.
  ///
  /// In fr, this message translates to:
  /// **'Merci! Pourboire de {amount}\$ envoyé'**
  String resDetail_tipSent(String amount);

  /// No description provided for @resDetail_ratingSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre évaluation!'**
  String get resDetail_ratingSuccess;

  /// No description provided for @activities_title.
  ///
  /// In fr, this message translates to:
  /// **'Activités'**
  String get activities_title;

  /// No description provided for @activities_inProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get activities_inProgress;

  /// No description provided for @activities_completed.
  ///
  /// In fr, this message translates to:
  /// **'Terminées'**
  String get activities_completed;

  /// No description provided for @activities_emptyCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité terminée'**
  String get activities_emptyCompleted;

  /// No description provided for @activities_emptyInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité en cours'**
  String get activities_emptyInProgress;

  /// No description provided for @activities_emptyCompletedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos déneigements terminés apparaîtront ici'**
  String get activities_emptyCompletedSubtitle;

  /// No description provided for @activities_emptyInProgressSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos déneigements en cours apparaîtront ici'**
  String get activities_emptyInProgressSubtitle;

  /// No description provided for @activities_total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get activities_total;

  /// No description provided for @reservationSuccess_title.
  ///
  /// In fr, this message translates to:
  /// **'Réservation confirmée !'**
  String get reservationSuccess_title;

  /// No description provided for @reservationSuccess_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande de déneigement a été enregistrée avec succès.'**
  String get reservationSuccess_subtitle;

  /// No description provided for @reservationSuccess_reservationNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de réservation'**
  String get reservationSuccess_reservationNumber;

  /// No description provided for @reservationSuccess_nextSteps.
  ///
  /// In fr, this message translates to:
  /// **'Prochaines étapes'**
  String get reservationSuccess_nextSteps;

  /// No description provided for @reservationSuccess_step1.
  ///
  /// In fr, this message translates to:
  /// **'1. Un déneigeur sera assigné sous peu'**
  String get reservationSuccess_step1;

  /// No description provided for @reservationSuccess_step2.
  ///
  /// In fr, this message translates to:
  /// **'2. Vous recevrez une notification'**
  String get reservationSuccess_step2;

  /// No description provided for @reservationSuccess_step3.
  ///
  /// In fr, this message translates to:
  /// **'3. Suivez l\'avancement en temps réel'**
  String get reservationSuccess_step3;

  /// No description provided for @reservationSuccess_backToHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get reservationSuccess_backToHome;

  /// No description provided for @reservationSuccess_viewReservations.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes réservations'**
  String get reservationSuccess_viewReservations;

  /// No description provided for @step1_vehicle.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule'**
  String get step1_vehicle;

  /// No description provided for @step1_location.
  ///
  /// In fr, this message translates to:
  /// **'Emplacement'**
  String get step1_location;

  /// No description provided for @step1_assignedSpot.
  ///
  /// In fr, this message translates to:
  /// **'Place assignée'**
  String get step1_assignedSpot;

  /// No description provided for @step1_haveSpotNumber.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai un numéro de place'**
  String get step1_haveSpotNumber;

  /// No description provided for @step1_freeLocation.
  ///
  /// In fr, this message translates to:
  /// **'Emplacement libre'**
  String get step1_freeLocation;

  /// No description provided for @step1_describeLocation.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez où se trouve le véhicule'**
  String get step1_describeLocation;

  /// No description provided for @step1_noVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun véhicule'**
  String get step1_noVehicle;

  /// No description provided for @step1_addFirstVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez votre premier véhicule'**
  String get step1_addFirstVehicle;

  /// No description provided for @step1_addVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un véhicule'**
  String get step1_addVehicle;

  /// No description provided for @step1_chipFrontBuilding.
  ///
  /// In fr, this message translates to:
  /// **'Devant le bâtiment'**
  String get step1_chipFrontBuilding;

  /// No description provided for @step1_chipNearEntrance.
  ///
  /// In fr, this message translates to:
  /// **'Près de l\'entrée'**
  String get step1_chipNearEntrance;

  /// No description provided for @step1_chipVisitorZone.
  ///
  /// In fr, this message translates to:
  /// **'Zone visiteurs'**
  String get step1_chipVisitorZone;

  /// No description provided for @step1_chipRearParking.
  ///
  /// In fr, this message translates to:
  /// **'Stationnement arrière'**
  String get step1_chipRearParking;

  /// No description provided for @step2_gpsPosition.
  ///
  /// In fr, this message translates to:
  /// **'Position GPS'**
  String get step2_gpsPosition;

  /// No description provided for @step2_address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get step2_address;

  /// No description provided for @step2_searching.
  ///
  /// In fr, this message translates to:
  /// **'Recherche en cours...'**
  String get step2_searching;

  /// No description provided for @step2_positionDetected.
  ///
  /// In fr, this message translates to:
  /// **'Position détectée'**
  String get step2_positionDetected;

  /// No description provided for @step2_positionUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Position non disponible, activez votre GPS'**
  String get step2_positionUnavailable;

  /// No description provided for @step2_pleaseWait.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez patienter'**
  String get step2_pleaseWait;

  /// No description provided for @step2_checkAddress.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez l\'adresse ci-dessous'**
  String get step2_checkAddress;

  /// No description provided for @step2_enterManually.
  ///
  /// In fr, this message translates to:
  /// **'Entrez l\'adresse manuellement'**
  String get step2_enterManually;

  /// No description provided for @step2_refresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get step2_refresh;

  /// No description provided for @step2_retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get step2_retry;

  /// No description provided for @step2_addressValidated.
  ///
  /// In fr, this message translates to:
  /// **'Adresse validée'**
  String get step2_addressValidated;

  /// No description provided for @step2_validateAddress.
  ///
  /// In fr, this message translates to:
  /// **'Valider l\'adresse'**
  String get step2_validateAddress;

  /// No description provided for @step2_addressTip.
  ///
  /// In fr, this message translates to:
  /// **'L\'adresse aide nos déneigeurs à localiser votre véhicule'**
  String get step2_addressTip;

  /// No description provided for @step3_departureDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de départ'**
  String get step3_departureDate;

  /// No description provided for @step3_departureTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure de départ'**
  String get step3_departureTime;

  /// No description provided for @step3_selectDate.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une date'**
  String get step3_selectDate;

  /// No description provided for @step3_selectTime.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une heure'**
  String get step3_selectTime;

  /// No description provided for @step3_urgentReservation.
  ///
  /// In fr, this message translates to:
  /// **'Réservation urgente'**
  String get step3_urgentReservation;

  /// No description provided for @step3_urgencyFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais d\'urgence de 40% appliqués'**
  String get step3_urgencyFee;

  /// No description provided for @step4_additionalOptions.
  ///
  /// In fr, this message translates to:
  /// **'Options supplementaires'**
  String get step4_additionalOptions;

  /// No description provided for @step4_snowDepth.
  ///
  /// In fr, this message translates to:
  /// **'Profondeur de neige'**
  String get step4_snowDepth;

  /// No description provided for @step4_summary.
  ///
  /// In fr, this message translates to:
  /// **'Recapitulatif'**
  String get step4_summary;

  /// No description provided for @step5_location.
  ///
  /// In fr, this message translates to:
  /// **'Localisation'**
  String get step5_location;

  /// No description provided for @step5_yourReservation.
  ///
  /// In fr, this message translates to:
  /// **'Votre réservation'**
  String get step5_yourReservation;

  /// No description provided for @step5_total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get step5_total;

  /// No description provided for @step5_ourGuarantees.
  ///
  /// In fr, this message translates to:
  /// **'Nos garanties'**
  String get step5_ourGuarantees;

  /// No description provided for @step5_freeCancellation.
  ///
  /// In fr, this message translates to:
  /// **'Annulation gratuite'**
  String get step5_freeCancellation;

  /// No description provided for @step5_upTo2hBefore.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'à 2h avant'**
  String get step5_upTo2hBefore;

  /// No description provided for @step5_qualityGuarantee.
  ///
  /// In fr, this message translates to:
  /// **'Garantie qualité'**
  String get step5_qualityGuarantee;

  /// No description provided for @step5_satisfiedOrRefunded.
  ///
  /// In fr, this message translates to:
  /// **'Satisfait ou remboursé'**
  String get step5_satisfiedOrRefunded;

  /// No description provided for @step5_photosAfter.
  ///
  /// In fr, this message translates to:
  /// **'Photos après'**
  String get step5_photosAfter;

  /// No description provided for @step5_proofOfService.
  ///
  /// In fr, this message translates to:
  /// **'Preuve de service'**
  String get step5_proofOfService;

  /// No description provided for @step5_punctuality.
  ///
  /// In fr, this message translates to:
  /// **'Ponctualité'**
  String get step5_punctuality;

  /// No description provided for @step5_discountIfLate.
  ///
  /// In fr, this message translates to:
  /// **'Remise si retard'**
  String get step5_discountIfLate;

  /// No description provided for @month_jan.
  ///
  /// In fr, this message translates to:
  /// **'JAN'**
  String get month_jan;

  /// No description provided for @month_feb.
  ///
  /// In fr, this message translates to:
  /// **'FÉV'**
  String get month_feb;

  /// No description provided for @month_mar.
  ///
  /// In fr, this message translates to:
  /// **'MAR'**
  String get month_mar;

  /// No description provided for @month_apr.
  ///
  /// In fr, this message translates to:
  /// **'AVR'**
  String get month_apr;

  /// No description provided for @month_may.
  ///
  /// In fr, this message translates to:
  /// **'MAI'**
  String get month_may;

  /// No description provided for @month_jun.
  ///
  /// In fr, this message translates to:
  /// **'JUIN'**
  String get month_jun;

  /// No description provided for @month_jul.
  ///
  /// In fr, this message translates to:
  /// **'JUIL'**
  String get month_jul;

  /// No description provided for @month_aug.
  ///
  /// In fr, this message translates to:
  /// **'AOÛ'**
  String get month_aug;

  /// No description provided for @month_sep.
  ///
  /// In fr, this message translates to:
  /// **'SEP'**
  String get month_sep;

  /// No description provided for @month_oct.
  ///
  /// In fr, this message translates to:
  /// **'OCT'**
  String get month_oct;

  /// No description provided for @month_nov.
  ///
  /// In fr, this message translates to:
  /// **'NOV'**
  String get month_nov;

  /// No description provided for @month_dec.
  ///
  /// In fr, this message translates to:
  /// **'DÉC'**
  String get month_dec;

  /// No description provided for @profile_photoUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil mise à jour'**
  String get profile_photoUpdated;

  /// No description provided for @profile_phoneVerified.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone vérifié et mis à jour'**
  String get profile_phoneVerified;

  /// No description provided for @profile_verify.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get profile_verify;

  /// No description provided for @subscription_selectedPlan.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez sélectionné le plan {planName}'**
  String subscription_selectedPlan(String planName);

  /// No description provided for @subscription_comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Cette fonctionnalité sera bientôt disponible.'**
  String get subscription_comingSoon;

  /// No description provided for @subscription_planSelected.
  ///
  /// In fr, this message translates to:
  /// **'Plan {planName} sélectionné'**
  String subscription_planSelected(String planName);

  /// No description provided for @legal_legalNotices.
  ///
  /// In fr, this message translates to:
  /// **'Mentions légales'**
  String get legal_legalNotices;

  /// No description provided for @legal_appUsageRules.
  ///
  /// In fr, this message translates to:
  /// **'Règles d\'utilisation de l\'application'**
  String get legal_appUsageRules;

  /// No description provided for @worker_photoSentSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Photo envoyée avec succès!'**
  String get worker_photoSentSuccess;

  /// No description provided for @worker_positionConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Position confirmée!'**
  String get worker_positionConfirmed;

  /// No description provided for @worker_coordinatesUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées non disponibles'**
  String get worker_coordinatesUnavailable;

  /// No description provided for @worker_phoneUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone non disponible'**
  String get worker_phoneUnavailable;

  /// No description provided for @worker_userNotAuth.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: utilisateur non authentifié'**
  String get worker_userNotAuth;

  /// No description provided for @worker_iArrived.
  ///
  /// In fr, this message translates to:
  /// **'Je suis arrivé'**
  String get worker_iArrived;

  /// No description provided for @worker_startJob.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get worker_startJob;

  /// No description provided for @worker_openGps.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir GPS'**
  String get worker_openGps;

  /// No description provided for @worker_finishJob.
  ///
  /// In fr, this message translates to:
  /// **'Terminer le job'**
  String get worker_finishJob;

  /// No description provided for @worker_inFavorOfComplainant.
  ///
  /// In fr, this message translates to:
  /// **'En faveur du plaignant'**
  String get worker_inFavorOfComplainant;

  /// No description provided for @worker_inFavorOfDefendant.
  ///
  /// In fr, this message translates to:
  /// **'En faveur du defenseur'**
  String get worker_inFavorOfDefendant;

  /// No description provided for @worker_fullRefund.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement complet'**
  String get worker_fullRefund;

  /// No description provided for @worker_partialRefund.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement partiel'**
  String get worker_partialRefund;

  /// No description provided for @worker_noAction.
  ///
  /// In fr, this message translates to:
  /// **'Aucune action'**
  String get worker_noAction;

  /// No description provided for @worker_mutualAgreement.
  ///
  /// In fr, this message translates to:
  /// **'Accord mutuel'**
  String get worker_mutualAgreement;

  /// No description provided for @worker_warningAction.
  ///
  /// In fr, this message translates to:
  /// **'Avertissement'**
  String get worker_warningAction;

  /// No description provided for @worker_permanentBan.
  ///
  /// In fr, this message translates to:
  /// **'Bannissement permanent'**
  String get worker_permanentBan;

  /// No description provided for @worker_selectDecision.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez une décision'**
  String get worker_selectDecision;

  /// No description provided for @worker_disputeResolvedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Litige résolu avec succès'**
  String get worker_disputeResolvedSuccess;

  /// No description provided for @summary_reservationSummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé de la réservation'**
  String get summary_reservationSummary;

  /// No description provided for @summary_spot.
  ///
  /// In fr, this message translates to:
  /// **'Place'**
  String get summary_spot;

  /// No description provided for @summary_departure.
  ///
  /// In fr, this message translates to:
  /// **'Départ'**
  String get summary_departure;

  /// No description provided for @summary_options.
  ///
  /// In fr, this message translates to:
  /// **'Options'**
  String get summary_options;

  /// No description provided for @summary_snow.
  ///
  /// In fr, this message translates to:
  /// **'Neige'**
  String get summary_snow;

  /// No description provided for @summary_place.
  ///
  /// In fr, this message translates to:
  /// **'Place {number}'**
  String summary_place(String number);

  /// No description provided for @option_windowScraping.
  ///
  /// In fr, this message translates to:
  /// **'Grattage des vitres'**
  String get option_windowScraping;

  /// No description provided for @option_doorDeicing.
  ///
  /// In fr, this message translates to:
  /// **'Déglaçage des portes'**
  String get option_doorDeicing;

  /// No description provided for @option_wheelClearance.
  ///
  /// In fr, this message translates to:
  /// **'Dégagement des roues'**
  String get option_wheelClearance;

  /// No description provided for @option_roofClearing.
  ///
  /// In fr, this message translates to:
  /// **'Déneigement du toit'**
  String get option_roofClearing;

  /// No description provided for @option_saltSpreading.
  ///
  /// In fr, this message translates to:
  /// **'Épandage de sel'**
  String get option_saltSpreading;

  /// No description provided for @option_lightsCleaning.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyage phares/feux'**
  String get option_lightsCleaning;

  /// No description provided for @option_perimeterClearance.
  ///
  /// In fr, this message translates to:
  /// **'Dégagement périmètre'**
  String get option_perimeterClearance;

  /// No description provided for @option_exhaustCheck.
  ///
  /// In fr, this message translates to:
  /// **'Vérif. échappement'**
  String get option_exhaustCheck;

  /// No description provided for @option_windowScrapingShort.
  ///
  /// In fr, this message translates to:
  /// **'Vitres'**
  String get option_windowScrapingShort;

  /// No description provided for @option_doorDeicingShort.
  ///
  /// In fr, this message translates to:
  /// **'Portes'**
  String get option_doorDeicingShort;

  /// No description provided for @option_wheelClearanceShort.
  ///
  /// In fr, this message translates to:
  /// **'Roues'**
  String get option_wheelClearanceShort;

  /// No description provided for @option_roofClearingShort.
  ///
  /// In fr, this message translates to:
  /// **'Toit'**
  String get option_roofClearingShort;

  /// No description provided for @option_saltSpreadingShort.
  ///
  /// In fr, this message translates to:
  /// **'Sel'**
  String get option_saltSpreadingShort;

  /// No description provided for @option_lightsCleaningShort.
  ///
  /// In fr, this message translates to:
  /// **'Phares'**
  String get option_lightsCleaningShort;

  /// No description provided for @option_perimeterClearanceShort.
  ///
  /// In fr, this message translates to:
  /// **'Périmètre'**
  String get option_perimeterClearanceShort;

  /// No description provided for @option_exhaustCheckShort.
  ///
  /// In fr, this message translates to:
  /// **'Échapp.'**
  String get option_exhaustCheckShort;

  /// No description provided for @option_windowScrapingDesc.
  ///
  /// In fr, this message translates to:
  /// **'Grattage complet de toutes les vitres'**
  String get option_windowScrapingDesc;

  /// No description provided for @option_doorDeicingDesc.
  ///
  /// In fr, this message translates to:
  /// **'Dégivrage des poignées et serrures'**
  String get option_doorDeicingDesc;

  /// No description provided for @option_wheelClearanceDesc.
  ///
  /// In fr, this message translates to:
  /// **'Dégagement de la neige autour des roues'**
  String get option_wheelClearanceDesc;

  /// No description provided for @option_roofClearingDesc.
  ///
  /// In fr, this message translates to:
  /// **'Enlever la neige accumulée sur le toit'**
  String get option_roofClearingDesc;

  /// No description provided for @option_saltSpreadingDesc.
  ///
  /// In fr, this message translates to:
  /// **'Application de sel autour du véhicule'**
  String get option_saltSpreadingDesc;

  /// No description provided for @option_lightsCleaningDesc.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyage des phares et feux arrière'**
  String get option_lightsCleaningDesc;

  /// No description provided for @option_perimeterClearanceDesc.
  ///
  /// In fr, this message translates to:
  /// **'Déneigement complet autour du véhicule'**
  String get option_perimeterClearanceDesc;

  /// No description provided for @option_exhaustCheckDesc.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier que l\'échappement est dégagé'**
  String get option_exhaustCheckDesc;

  /// No description provided for @price_baseSnowRemoval.
  ///
  /// In fr, this message translates to:
  /// **'Déneigement de base'**
  String get price_baseSnowRemoval;

  /// No description provided for @price_vehicleAdjustment.
  ///
  /// In fr, this message translates to:
  /// **'Ajustement véhicule'**
  String get price_vehicleAdjustment;

  /// No description provided for @price_parkingAdjustment.
  ///
  /// In fr, this message translates to:
  /// **'Ajustement place'**
  String get price_parkingAdjustment;

  /// No description provided for @price_snowSurcharge.
  ///
  /// In fr, this message translates to:
  /// **'Supplément neige'**
  String get price_snowSurcharge;

  /// No description provided for @price_additionalOptions.
  ///
  /// In fr, this message translates to:
  /// **'Options supplémentaires'**
  String get price_additionalOptions;

  /// No description provided for @price_urgencyFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais d\'urgence (40%)'**
  String get price_urgencyFee;

  /// No description provided for @price_subtotal.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get price_subtotal;

  /// No description provided for @price_serviceFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais de service'**
  String get price_serviceFee;

  /// No description provided for @price_insuranceFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais d\'assurance'**
  String get price_insuranceFee;

  /// No description provided for @price_taxesCalculatedFor.
  ///
  /// In fr, this message translates to:
  /// **'Taxes calculées pour: {province}'**
  String price_taxesCalculatedFor(String province);

  /// No description provided for @price_totalToPay.
  ///
  /// In fr, this message translates to:
  /// **'Total à payer'**
  String get price_totalToPay;

  /// No description provided for @price_taxesIncluded.
  ///
  /// In fr, this message translates to:
  /// **'Taxes incluses'**
  String get price_taxesIncluded;

  /// No description provided for @price_urgentBanner.
  ///
  /// In fr, this message translates to:
  /// **'Réservation urgente - Frais majorés'**
  String get price_urgentBanner;

  /// No description provided for @snow_estimatedDepth.
  ///
  /// In fr, this message translates to:
  /// **'Profondeur de neige estimée'**
  String get snow_estimatedDepth;

  /// No description provided for @snow_optionalHelper.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel - Aide à estimer le temps requis'**
  String get snow_optionalHelper;

  /// No description provided for @ai_estimationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Estimation IA'**
  String get ai_estimationTitle;

  /// No description provided for @ai_estimationSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Prix suggéré basé sur la demande'**
  String get ai_estimationSubtitle;

  /// No description provided for @ai_priceFactors.
  ///
  /// In fr, this message translates to:
  /// **'Facteurs de prix'**
  String get ai_priceFactors;

  /// No description provided for @ai_urgency.
  ///
  /// In fr, this message translates to:
  /// **'Urgence'**
  String get ai_urgency;

  /// No description provided for @ai_weather.
  ///
  /// In fr, this message translates to:
  /// **'Météo'**
  String get ai_weather;

  /// No description provided for @ai_demand.
  ///
  /// In fr, this message translates to:
  /// **'Demande'**
  String get ai_demand;

  /// No description provided for @ai_zone.
  ///
  /// In fr, this message translates to:
  /// **'Zone'**
  String get ai_zone;

  /// No description provided for @ai_estimationLoading.
  ///
  /// In fr, this message translates to:
  /// **'Estimation IA en cours...'**
  String get ai_estimationLoading;

  /// No description provided for @ai_estimationUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Estimation IA non disponible'**
  String get ai_estimationUnavailable;

  /// No description provided for @worker_yesStart.
  ///
  /// In fr, this message translates to:
  /// **'Oui, commencer'**
  String get worker_yesStart;

  /// No description provided for @dispute_addEvidenceButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des preuves'**
  String get dispute_addEvidenceButton;

  /// No description provided for @dispute_addEvidenceError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'ajout des preuves'**
  String get dispute_addEvidenceError;

  /// No description provided for @dispute_addEvidenceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une preuve'**
  String get dispute_addEvidenceTitle;

  /// No description provided for @dispute_additionalDetailsOptional.
  ///
  /// In fr, this message translates to:
  /// **'Détails supplémentaires (optionnel)'**
  String get dispute_additionalDetailsOptional;

  /// No description provided for @dispute_addMorePhotos.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter plus de photos'**
  String get dispute_addMorePhotos;

  /// No description provided for @dispute_addPhotoOrDescription.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez au moins une photo ou une description'**
  String get dispute_addPhotoOrDescription;

  /// No description provided for @dispute_addPhotosInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des photos pour appuyer votre réponse (photos du travail effectué, captures d\'écran de conversation, etc.)'**
  String get dispute_addPhotosInstruction;

  /// No description provided for @dispute_aiAnalysis.
  ///
  /// In fr, this message translates to:
  /// **'Analyse IA'**
  String get dispute_aiAnalysis;

  /// No description provided for @dispute_amount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get dispute_amount;

  /// No description provided for @dispute_appeal.
  ///
  /// In fr, this message translates to:
  /// **'Faire appel'**
  String get dispute_appeal;

  /// No description provided for @dispute_appealExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Expliquez pourquoi vous contestez cette décision (minimum 50 caractères):'**
  String get dispute_appealExplanation;

  /// No description provided for @dispute_appealJustificationHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre justification...'**
  String get dispute_appealJustificationHint;

  /// No description provided for @dispute_appealSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Appel soumis avec succès'**
  String get dispute_appealSubmitted;

  /// No description provided for @dispute_attachedPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Photos jointes'**
  String get dispute_attachedPhotos;

  /// No description provided for @dispute_cannotSendReportRetry.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer le signalement. Veuillez réessayer.'**
  String get dispute_cannotSendReportRetry;

  /// No description provided for @dispute_cannotSendResponseRetry.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer la réponse. Veuillez réessayer.'**
  String get dispute_cannotSendResponseRetry;

  /// No description provided for @dispute_claimedAmountValue.
  ///
  /// In fr, this message translates to:
  /// **'Montant réclamé: {amount} \$'**
  String dispute_claimedAmountValue(String amount);

  /// No description provided for @dispute_confidencePercent.
  ///
  /// In fr, this message translates to:
  /// **'{percent}%'**
  String dispute_confidencePercent(int percent);

  /// No description provided for @dispute_confirmNoShowRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez confirmer l\'absence du déneigeur avant de soumettre'**
  String get dispute_confirmNoShowRequired;

  /// No description provided for @dispute_confirmNoShowStatement.
  ///
  /// In fr, this message translates to:
  /// **'Je confirme que le déneigeur ne s\'est pas présenté pour le service prévu.'**
  String get dispute_confirmNoShowStatement;

  /// No description provided for @dispute_deadlines.
  ///
  /// In fr, this message translates to:
  /// **'Délais'**
  String get dispute_deadlines;

  /// No description provided for @dispute_decisionFavorClaimant.
  ///
  /// In fr, this message translates to:
  /// **'En votre faveur'**
  String get dispute_decisionFavorClaimant;

  /// No description provided for @dispute_decisionFavorRespondent.
  ///
  /// In fr, this message translates to:
  /// **'En faveur du défenseur'**
  String get dispute_decisionFavorRespondent;

  /// No description provided for @dispute_decisionFullRefund.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement complet'**
  String get dispute_decisionFullRefund;

  /// No description provided for @dispute_decisionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Décision: {decision}'**
  String dispute_decisionLabel(String decision);

  /// No description provided for @dispute_decisionMutualAgreement.
  ///
  /// In fr, this message translates to:
  /// **'Accord mutuel'**
  String get dispute_decisionMutualAgreement;

  /// No description provided for @dispute_decisionNoAction.
  ///
  /// In fr, this message translates to:
  /// **'Aucune action'**
  String get dispute_decisionNoAction;

  /// No description provided for @dispute_decisionPartialRefund.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement partiel'**
  String get dispute_decisionPartialRefund;

  /// No description provided for @dispute_describeEvidenceHint.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez les preuves fournies...'**
  String get dispute_describeEvidenceHint;

  /// No description provided for @dispute_describeSituationHint.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez la situation...'**
  String get dispute_describeSituationHint;

  /// No description provided for @dispute_descriptionOptional.
  ///
  /// In fr, this message translates to:
  /// **'Description (optionnelle)'**
  String get dispute_descriptionOptional;

  /// No description provided for @dispute_evidenceAddedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vos preuves ont été ajoutées au dossier du litige.'**
  String get dispute_evidenceAddedMessage;

  /// No description provided for @dispute_evidenceCount.
  ///
  /// In fr, this message translates to:
  /// **'Preuves ({count})'**
  String dispute_evidenceCount(int count);

  /// No description provided for @dispute_evidenceStrength.
  ///
  /// In fr, this message translates to:
  /// **'Force des preuves'**
  String get dispute_evidenceStrength;

  /// No description provided for @dispute_evidenceTips.
  ///
  /// In fr, this message translates to:
  /// **'Conseils pour de bonnes preuves'**
  String get dispute_evidenceTips;

  /// No description provided for @dispute_expired.
  ///
  /// In fr, this message translates to:
  /// **'Expiré'**
  String get dispute_expired;

  /// No description provided for @dispute_falseReportWarning.
  ///
  /// In fr, this message translates to:
  /// **'Les faux signalements peuvent entraîner des sanctions sur votre compte.'**
  String get dispute_falseReportWarning;

  /// No description provided for @dispute_filterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get dispute_filterAll;

  /// No description provided for @dispute_filterOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouverts'**
  String get dispute_filterOpen;

  /// No description provided for @dispute_filterResolved.
  ///
  /// In fr, this message translates to:
  /// **'Résolus'**
  String get dispute_filterResolved;

  /// No description provided for @dispute_filterUnderReview.
  ///
  /// In fr, this message translates to:
  /// **'En examen'**
  String get dispute_filterUnderReview;

  /// No description provided for @dispute_imagesLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les images'**
  String get dispute_imagesLoadError;

  /// No description provided for @dispute_keyFindings.
  ///
  /// In fr, this message translates to:
  /// **'Constats clés:'**
  String get dispute_keyFindings;

  /// No description provided for @dispute_maxPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Maximum 10 photos'**
  String get dispute_maxPhotos;

  /// No description provided for @dispute_minCharsRequired.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 50 caractères requis'**
  String get dispute_minCharsRequired;

  /// No description provided for @dispute_noDisputes.
  ///
  /// In fr, this message translates to:
  /// **'Aucun litige'**
  String get dispute_noDisputes;

  /// No description provided for @dispute_noDisputesMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez aucun litige en cours. C\'est une bonne nouvelle!'**
  String get dispute_noDisputesMessage;

  /// No description provided for @dispute_notAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Non assigné'**
  String get dispute_notAssigned;

  /// No description provided for @dispute_notFound.
  ///
  /// In fr, this message translates to:
  /// **'Litige introuvable'**
  String get dispute_notFound;

  /// No description provided for @dispute_notFoundMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ce litige est introuvable ou a été supprimé.'**
  String get dispute_notFoundMessage;

  /// No description provided for @dispute_notifiedOfDecision.
  ///
  /// In fr, this message translates to:
  /// **'Vous serez notifié de la décision finale.'**
  String get dispute_notifiedOfDecision;

  /// No description provided for @dispute_notifiedWhenResolved.
  ///
  /// In fr, this message translates to:
  /// **'Vous serez notifié lorsque le dossier sera résolu.'**
  String get dispute_notifiedWhenResolved;

  /// No description provided for @dispute_openDate.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'ouverture'**
  String get dispute_openDate;

  /// No description provided for @dispute_photoCount.
  ///
  /// In fr, this message translates to:
  /// **'{count}/10 photos'**
  String dispute_photoCount(int count);

  /// No description provided for @dispute_photosLabel.
  ///
  /// In fr, this message translates to:
  /// **'Photos'**
  String get dispute_photosLabel;

  /// No description provided for @dispute_priority.
  ///
  /// In fr, this message translates to:
  /// **'Priorité'**
  String get dispute_priority;

  /// No description provided for @dispute_priorityHigh.
  ///
  /// In fr, this message translates to:
  /// **'Haute'**
  String get dispute_priorityHigh;

  /// No description provided for @dispute_priorityLow.
  ///
  /// In fr, this message translates to:
  /// **'Basse'**
  String get dispute_priorityLow;

  /// No description provided for @dispute_priorityMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne'**
  String get dispute_priorityMedium;

  /// No description provided for @dispute_priorityUrgent.
  ///
  /// In fr, this message translates to:
  /// **'Urgente'**
  String get dispute_priorityUrgent;

  /// No description provided for @dispute_reasoning.
  ///
  /// In fr, this message translates to:
  /// **'Raisonnement'**
  String get dispute_reasoning;

  /// No description provided for @dispute_refund.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement'**
  String get dispute_refund;

  /// No description provided for @dispute_refundAmount.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement: {amount} \$'**
  String dispute_refundAmount(String amount);

  /// No description provided for @dispute_refundIfConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Si l\'absence est confirmée, vous recevrez un remboursement de {amount} \$.'**
  String dispute_refundIfConfirmed(String amount);

  /// No description provided for @dispute_remainingTimeDaysHours.
  ///
  /// In fr, this message translates to:
  /// **'{days}j {hours}h restantes'**
  String dispute_remainingTimeDaysHours(int days, int hours);

  /// No description provided for @dispute_remainingTimeHoursMin.
  ///
  /// In fr, this message translates to:
  /// **'{hours}h {minutes}min restantes'**
  String dispute_remainingTimeHoursMin(int hours, int minutes);

  /// No description provided for @dispute_remainingTimeMin.
  ///
  /// In fr, this message translates to:
  /// **'{minutes}min restantes'**
  String dispute_remainingTimeMin(int minutes);

  /// No description provided for @dispute_reportAutoConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Votre signalement a été automatiquement confirmé. Un remboursement sera effectué.'**
  String get dispute_reportAutoConfirmed;

  /// No description provided for @dispute_reportNoShow.
  ///
  /// In fr, this message translates to:
  /// **'Signaler une absence'**
  String get dispute_reportNoShow;

  /// No description provided for @dispute_reportNoShowButton.
  ///
  /// In fr, this message translates to:
  /// **'Signaler l\'absence'**
  String get dispute_reportNoShowButton;

  /// No description provided for @dispute_reportSent.
  ///
  /// In fr, this message translates to:
  /// **'Signalement envoyé'**
  String get dispute_reportSent;

  /// No description provided for @dispute_reportUnderReview.
  ///
  /// In fr, this message translates to:
  /// **'Votre signalement a été soumis et sera examiné par notre équipe.'**
  String get dispute_reportUnderReview;

  /// No description provided for @dispute_reservationDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails de la réservation'**
  String get dispute_reservationDetails;

  /// No description provided for @dispute_resolvedCannotAddEvidence.
  ///
  /// In fr, this message translates to:
  /// **'Ce litige est résolu ou fermé. Vous ne pouvez plus ajouter de preuves.'**
  String get dispute_resolvedCannotAddEvidence;

  /// No description provided for @dispute_resolvedOn.
  ///
  /// In fr, this message translates to:
  /// **'Résolu le {date}'**
  String dispute_resolvedOn(String date);

  /// No description provided for @dispute_responseDeadlinePassed.
  ///
  /// In fr, this message translates to:
  /// **'Délai de réponse dépassé'**
  String get dispute_responseDeadlinePassed;

  /// No description provided for @dispute_responseExpectedBefore.
  ///
  /// In fr, this message translates to:
  /// **'Réponse attendue avant'**
  String get dispute_responseExpectedBefore;

  /// No description provided for @dispute_responseHint.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez votre réponse ici...'**
  String get dispute_responseHint;

  /// No description provided for @dispute_responseInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Expliquez votre version des faits. Soyez précis et factuel.'**
  String get dispute_responseInstruction;

  /// No description provided for @dispute_responseSentMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse a été enregistrée. L\'administrateur va examiner le litige et prendra une décision.'**
  String get dispute_responseSentMessage;

  /// No description provided for @dispute_responseTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse est trop courte (minimum 50 caractères)'**
  String get dispute_responseTooShort;

  /// No description provided for @dispute_riskFactors.
  ///
  /// In fr, this message translates to:
  /// **'Facteurs de risque'**
  String get dispute_riskFactors;

  /// No description provided for @dispute_scheduledTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure prévue'**
  String get dispute_scheduledTime;

  /// No description provided for @dispute_snowWorkerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Déneigeur'**
  String get dispute_snowWorkerLabel;

  /// No description provided for @dispute_submitAppeal.
  ///
  /// In fr, this message translates to:
  /// **'Soumettre l\'appel'**
  String get dispute_submitAppeal;

  /// No description provided for @dispute_submitEvidence.
  ///
  /// In fr, this message translates to:
  /// **'Soumettre les preuves'**
  String get dispute_submitEvidence;

  /// No description provided for @dispute_submittedOn.
  ///
  /// In fr, this message translates to:
  /// **'Soumis le {date}'**
  String dispute_submittedOn(String date);

  /// No description provided for @dispute_takePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get dispute_takePhoto;

  /// No description provided for @dispute_tipsRelevantDocs.
  ///
  /// In fr, this message translates to:
  /// **'Tout document pertinent'**
  String get dispute_tipsRelevantDocs;

  /// No description provided for @dispute_viewDetails.
  ///
  /// In fr, this message translates to:
  /// **'Voir les détails'**
  String get dispute_viewDetails;

  /// No description provided for @dispute_workerDidNotCome.
  ///
  /// In fr, this message translates to:
  /// **'Le déneigeur ne s\'est pas présenté'**
  String get dispute_workerDidNotCome;

  /// No description provided for @dispute_workerDidNotComeDesc.
  ///
  /// In fr, this message translates to:
  /// **'Signalez que le déneigeur {name} ne s\'est pas présenté pour le service prévu.'**
  String dispute_workerDidNotComeDesc(String name);

  /// No description provided for @worker_accountAlreadyConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte est déjà configuré!'**
  String get worker_accountAlreadyConfigured;

  /// No description provided for @worker_accountConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Compte configuré'**
  String get worker_accountConfigured;

  /// No description provided for @worker_accountDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Compte supprimé'**
  String get worker_accountDeleted;

  /// No description provided for @worker_accountsConfiguredCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} compte(s) configuré(s)'**
  String worker_accountsConfiguredCount(int count);

  /// No description provided for @worker_accountSetAsPrimary.
  ///
  /// In fr, this message translates to:
  /// **'Compte défini comme principal'**
  String get worker_accountSetAsPrimary;

  /// No description provided for @worker_accountVerified.
  ///
  /// In fr, this message translates to:
  /// **'Compte vérifié'**
  String get worker_accountVerified;

  /// No description provided for @worker_actions.
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get worker_actions;

  /// No description provided for @worker_actionSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Action réussie'**
  String get worker_actionSuccess;

  /// No description provided for @worker_activeJob.
  ///
  /// In fr, this message translates to:
  /// **'Job actif'**
  String get worker_activeJob;

  /// No description provided for @worker_addAccount.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un compte'**
  String get worker_addAccount;

  /// No description provided for @worker_addBankAccountToReceive.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez un compte bancaire pour recevoir vos gains'**
  String get worker_addBankAccountToReceive;

  /// No description provided for @worker_additionalDetailsOptional.
  ///
  /// In fr, this message translates to:
  /// **'Détails supplémentaires (optionnel)'**
  String get worker_additionalDetailsOptional;

  /// No description provided for @worker_arrivedConfirmedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes à {distanceMeters}m du véhicule.\n\nVous pouvez maintenant commencer le travail.'**
  String worker_arrivedConfirmedMessage(int distanceMeters);

  /// No description provided for @worker_automaticTransfers.
  ///
  /// In fr, this message translates to:
  /// **'Virements automatiques'**
  String get worker_automaticTransfers;

  /// No description provided for @worker_balance.
  ///
  /// In fr, this message translates to:
  /// **'Solde'**
  String get worker_balance;

  /// No description provided for @worker_bankAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Comptes bancaires'**
  String get worker_bankAccounts;

  /// No description provided for @worker_basicInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations de base'**
  String get worker_basicInfo;

  /// No description provided for @worker_cameraPermissionError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de prendre la photo. Vérifiez les permissions de la caméra.'**
  String get worker_cameraPermissionError;

  /// No description provided for @worker_cancelJobQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le job?'**
  String get worker_cancelJobQuestion;

  /// No description provided for @worker_cancelReasonEquipmentFailure.
  ///
  /// In fr, this message translates to:
  /// **'Équipement défaillant'**
  String get worker_cancelReasonEquipmentFailure;

  /// No description provided for @worker_cancelReasonEquipmentFailureDesc.
  ///
  /// In fr, this message translates to:
  /// **'Mon équipement de déneigement est défaillant'**
  String get worker_cancelReasonEquipmentFailureDesc;

  /// No description provided for @worker_cancelReasonFamilyEmergency.
  ///
  /// In fr, this message translates to:
  /// **'Urgence familiale'**
  String get worker_cancelReasonFamilyEmergency;

  /// No description provided for @worker_cancelReasonFamilyEmergencyDesc.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai une urgence familiale'**
  String get worker_cancelReasonFamilyEmergencyDesc;

  /// No description provided for @worker_cancelReasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Raison de l\'annulation:'**
  String get worker_cancelReasonLabel;

  /// No description provided for @worker_cancelReasonMedicalEmergency.
  ///
  /// In fr, this message translates to:
  /// **'Urgence médicale'**
  String get worker_cancelReasonMedicalEmergency;

  /// No description provided for @worker_cancelReasonMedicalEmergencyDesc.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai une urgence médicale personnelle'**
  String get worker_cancelReasonMedicalEmergencyDesc;

  /// No description provided for @worker_cancelReasonRoadBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Route bloquée'**
  String get worker_cancelReasonRoadBlocked;

  /// No description provided for @worker_cancelReasonRoadBlockedDesc.
  ///
  /// In fr, this message translates to:
  /// **'La route vers le client est bloquée ou inaccessible'**
  String get worker_cancelReasonRoadBlockedDesc;

  /// No description provided for @worker_cancelReasonSevereWeather.
  ///
  /// In fr, this message translates to:
  /// **'Conditions météo dangereuses'**
  String get worker_cancelReasonSevereWeather;

  /// No description provided for @worker_cancelReasonSevereWeatherDesc.
  ///
  /// In fr, this message translates to:
  /// **'Les conditions météo rendent le trajet dangereux'**
  String get worker_cancelReasonSevereWeatherDesc;

  /// No description provided for @worker_cancelReasonVehicleBreakdown.
  ///
  /// In fr, this message translates to:
  /// **'Panne de véhicule'**
  String get worker_cancelReasonVehicleBreakdown;

  /// No description provided for @worker_cancelReasonVehicleBreakdownDesc.
  ///
  /// In fr, this message translates to:
  /// **'Mon véhicule est en panne ou a un problème mécanique'**
  String get worker_cancelReasonVehicleBreakdownDesc;

  /// No description provided for @worker_cancelThisJob.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ce job'**
  String get worker_cancelThisJob;

  /// No description provided for @worker_cancelWarning.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne serez pas payé pour ce job.\nLes annulations fréquentes peuvent entraîner une suspension.'**
  String get worker_cancelWarning;

  /// No description provided for @worker_cannotDeterminePosition.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de déterminer votre position. Activez la localisation et réessayez.'**
  String get worker_cannotDeterminePosition;

  /// No description provided for @worker_cannotOpenStripeLink.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le lien Stripe'**
  String get worker_cannotOpenStripeLink;

  /// No description provided for @worker_canNowFinish.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez maintenant terminer'**
  String get worker_canNowFinish;

  /// No description provided for @worker_configureNow.
  ///
  /// In fr, this message translates to:
  /// **'Configurer maintenant'**
  String get worker_configureNow;

  /// No description provided for @worker_configurePayments.
  ///
  /// In fr, this message translates to:
  /// **'Configurez vos paiements'**
  String get worker_configurePayments;

  /// No description provided for @worker_confirmCancellation.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer l\'annulation'**
  String get worker_confirmCancellation;

  /// No description provided for @worker_confirmCompleteJob.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir marquer ce job comme terminé?'**
  String get worker_confirmCompleteJob;

  /// No description provided for @worker_connectingToStripe.
  ///
  /// In fr, this message translates to:
  /// **'Connexion à Stripe...'**
  String get worker_connectingToStripe;

  /// No description provided for @worker_continueSetup.
  ///
  /// In fr, this message translates to:
  /// **'Continuer la configuration'**
  String get worker_continueSetup;

  /// No description provided for @worker_deleteAccountConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer le compte se terminant par {last4}?'**
  String worker_deleteAccountConfirm(String last4);

  /// No description provided for @worker_deleteAccountQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce compte?'**
  String get worker_deleteAccountQuestion;

  /// No description provided for @worker_depositsIn23Days.
  ///
  /// In fr, this message translates to:
  /// **'Dépôts sous 2-3 jours ouvrables'**
  String get worker_depositsIn23Days;

  /// No description provided for @worker_documentsRequired.
  ///
  /// In fr, this message translates to:
  /// **'Documents requis'**
  String get worker_documentsRequired;

  /// No description provided for @worker_documentsSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Documents soumis'**
  String get worker_documentsSubmitted;

  /// No description provided for @worker_documentsVerified.
  ///
  /// In fr, this message translates to:
  /// **'Documents vérifiés'**
  String get worker_documentsVerified;

  /// No description provided for @worker_enlarge.
  ///
  /// In fr, this message translates to:
  /// **'Agrandir'**
  String get worker_enlarge;

  /// No description provided for @worker_enRoute.
  ///
  /// In fr, this message translates to:
  /// **'En route'**
  String get worker_enRoute;

  /// No description provided for @worker_fundsDepositedInfo.
  ///
  /// In fr, this message translates to:
  /// **'Les fonds sont déposés sur votre compte bancaire sous 2-3 jours ouvrables.'**
  String get worker_fundsDepositedInfo;

  /// No description provided for @worker_goodJob.
  ///
  /// In fr, this message translates to:
  /// **'Bon travail!'**
  String get worker_goodJob;

  /// No description provided for @worker_headToClient.
  ///
  /// In fr, this message translates to:
  /// **'Dirigez-vous vers le client'**
  String get worker_headToClient;

  /// No description provided for @worker_howItWorks.
  ///
  /// In fr, this message translates to:
  /// **'Comment ça fonctionne'**
  String get worker_howItWorks;

  /// No description provided for @worker_identityVerificationInfo.
  ///
  /// In fr, this message translates to:
  /// **'Pour recevoir vos paiements, Stripe doit vérifier votre identité. Préparez les documents suivants:'**
  String get worker_identityVerificationInfo;

  /// No description provided for @worker_jobCompletedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Job terminé avec succès!'**
  String get worker_jobCompletedSuccess;

  /// No description provided for @worker_jobStarted.
  ///
  /// In fr, this message translates to:
  /// **'Job démarré!'**
  String get worker_jobStarted;

  /// No description provided for @worker_locationError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de localisation'**
  String get worker_locationError;

  /// No description provided for @worker_locationPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Permission de localisation refusée'**
  String get worker_locationPermissionDenied;

  /// No description provided for @worker_locationPermissionDeniedForever.
  ///
  /// In fr, this message translates to:
  /// **'Permission de localisation refusée définitivement. Activez-la dans les paramètres.'**
  String get worker_locationPermissionDeniedForever;

  /// No description provided for @worker_manageBankAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Gérer mes comptes bancaires'**
  String get worker_manageBankAccounts;

  /// No description provided for @worker_noBankAccount.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte bancaire'**
  String get worker_noBankAccount;

  /// No description provided for @worker_noBankAccountWarning.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte bancaire configuré. Ajoutez-en un pour recevoir vos gains.'**
  String get worker_noBankAccountWarning;

  /// No description provided for @worker_noGpsConfirmArrival.
  ///
  /// In fr, this message translates to:
  /// **'Ce job n\'a pas de coordonnées GPS enregistrées.\n\nConfirmez-vous être arrivé à l\'emplacement indiqué?'**
  String get worker_noGpsConfirmArrival;

  /// No description provided for @worker_notChargedForJob.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne serez pas facturé pour ce job.'**
  String get worker_notChargedForJob;

  /// No description provided for @worker_paymentDistribution.
  ///
  /// In fr, this message translates to:
  /// **'Répartition des paiements'**
  String get worker_paymentDistribution;

  /// No description provided for @worker_paymentExample.
  ///
  /// In fr, this message translates to:
  /// **'Exemple: Pour un job à 50\$, vous recevez {amount}\$'**
  String worker_paymentExample(String amount);

  /// No description provided for @worker_payments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get worker_payments;

  /// No description provided for @worker_paymentsActive.
  ///
  /// In fr, this message translates to:
  /// **'Paiements actifs'**
  String get worker_paymentsActive;

  /// No description provided for @worker_payoutsActive.
  ///
  /// In fr, this message translates to:
  /// **'Virements actifs'**
  String get worker_payoutsActive;

  /// No description provided for @worker_photoId.
  ///
  /// In fr, this message translates to:
  /// **'Pièce d\'identité avec photo'**
  String get worker_photoId;

  /// No description provided for @worker_photoIdDesc.
  ///
  /// In fr, this message translates to:
  /// **'Permis de conduire, passeport ou carte d\'identité'**
  String get worker_photoIdDesc;

  /// No description provided for @worker_photoOfCompletedWork.
  ///
  /// In fr, this message translates to:
  /// **'Photo du travail terminé'**
  String get worker_photoOfCompletedWork;

  /// No description provided for @worker_photoRequired.
  ///
  /// In fr, this message translates to:
  /// **'Photo requise'**
  String get worker_photoRequired;

  /// No description provided for @worker_photoRequirements.
  ///
  /// In fr, this message translates to:
  /// **'Exigences pour les photos'**
  String get worker_photoRequirements;

  /// No description provided for @worker_photoUploadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer la photo. Vérifiez votre connexion.'**
  String get worker_photoUploadError;

  /// No description provided for @worker_platformCommission.
  ///
  /// In fr, this message translates to:
  /// **'Commission plateforme'**
  String get worker_platformCommission;

  /// No description provided for @worker_poweredByStripe.
  ///
  /// In fr, this message translates to:
  /// **'Propulsé par Stripe'**
  String get worker_poweredByStripe;

  /// No description provided for @worker_poweredByStripeLeader.
  ///
  /// In fr, this message translates to:
  /// **'Propulsé par Stripe, leader mondial des paiements'**
  String get worker_poweredByStripeLeader;

  /// No description provided for @worker_pressEnRouteToStart.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur \"En route\" pour commencer'**
  String get worker_pressEnRouteToStart;

  /// No description provided for @worker_primary.
  ///
  /// In fr, this message translates to:
  /// **'Principal'**
  String get worker_primary;

  /// No description provided for @worker_primaryAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte principal'**
  String get worker_primaryAccount;

  /// No description provided for @worker_primaryAccountInfo.
  ///
  /// In fr, this message translates to:
  /// **'Vos gains seront déposés sur le compte marqué comme principal.'**
  String get worker_primaryAccountInfo;

  /// No description provided for @worker_proofOfAddress.
  ///
  /// In fr, this message translates to:
  /// **'Preuve d\'adresse'**
  String get worker_proofOfAddress;

  /// No description provided for @worker_proofOfAddressDesc.
  ///
  /// In fr, this message translates to:
  /// **'Facture de services publics ou relevé bancaire récent'**
  String get worker_proofOfAddressDesc;

  /// No description provided for @worker_readyToReceive.
  ///
  /// In fr, this message translates to:
  /// **'Prêt à recevoir des paiements'**
  String get worker_readyToReceive;

  /// No description provided for @worker_receiveEarningsDirectly.
  ///
  /// In fr, this message translates to:
  /// **'Recevez vos gains directement'**
  String get worker_receiveEarningsDirectly;

  /// No description provided for @worker_reqColorPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo en couleur (format JPG ou PNG)'**
  String get worker_reqColorPhoto;

  /// No description provided for @worker_reqNameDobVisible.
  ///
  /// In fr, this message translates to:
  /// **'Nom et date de naissance lisibles'**
  String get worker_reqNameDobVisible;

  /// No description provided for @worker_reqNotExpired.
  ///
  /// In fr, this message translates to:
  /// **'Document non expiré'**
  String get worker_reqNotExpired;

  /// No description provided for @worker_reqOriginalDoc.
  ///
  /// In fr, this message translates to:
  /// **'Document original, pas une photocopie'**
  String get worker_reqOriginalDoc;

  /// No description provided for @worker_retakePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get worker_retakePhoto;

  /// No description provided for @worker_securePayments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements sécurisés'**
  String get worker_securePayments;

  /// No description provided for @worker_sendDocumentsToActivate.
  ///
  /// In fr, this message translates to:
  /// **'Envoyez vos documents d\'identité pour activer les virements.'**
  String get worker_sendDocumentsToActivate;

  /// No description provided for @worker_sending.
  ///
  /// In fr, this message translates to:
  /// **'Envoi...'**
  String get worker_sending;

  /// No description provided for @worker_sendMyDocuments.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer mes documents'**
  String get worker_sendMyDocuments;

  /// No description provided for @worker_setAsPrimary.
  ///
  /// In fr, this message translates to:
  /// **'Définir comme principal'**
  String get worker_setAsPrimary;

  /// No description provided for @worker_statusUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Inconnu'**
  String get worker_statusUnknown;

  /// No description provided for @worker_statusUpdatedEnRoute.
  ///
  /// In fr, this message translates to:
  /// **'Statut mis à jour: En route'**
  String get worker_statusUpdatedEnRoute;

  /// No description provided for @worker_step1ClientPays.
  ///
  /// In fr, this message translates to:
  /// **'Le client paie'**
  String get worker_step1ClientPays;

  /// No description provided for @worker_step1Subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement est traité par Stripe'**
  String get worker_step1Subtitle;

  /// No description provided for @worker_step1SubtitleShort.
  ///
  /// In fr, this message translates to:
  /// **'Paiement traité par Stripe'**
  String get worker_step1SubtitleShort;

  /// No description provided for @worker_step2AutoDistribution.
  ///
  /// In fr, this message translates to:
  /// **'Répartition automatique'**
  String get worker_step2AutoDistribution;

  /// No description provided for @worker_step2Distribution.
  ///
  /// In fr, this message translates to:
  /// **'Répartition'**
  String get worker_step2Distribution;

  /// No description provided for @worker_step2Subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre part est calculée instantanément'**
  String get worker_step2Subtitle;

  /// No description provided for @worker_step2SubtitleShort.
  ///
  /// In fr, this message translates to:
  /// **'Votre part est calculée'**
  String get worker_step2SubtitleShort;

  /// No description provided for @worker_step3Deposit.
  ///
  /// In fr, this message translates to:
  /// **'Dépôt'**
  String get worker_step3Deposit;

  /// No description provided for @worker_step3DepositToAccount.
  ///
  /// In fr, this message translates to:
  /// **'Dépôt sur votre compte'**
  String get worker_step3DepositToAccount;

  /// No description provided for @worker_step3Subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Sous 2-3 jours ouvrables'**
  String get worker_step3Subtitle;

  /// No description provided for @worker_stripeResponse.
  ///
  /// In fr, this message translates to:
  /// **'Réponse Stripe: {response}'**
  String worker_stripeResponse(String response);

  /// No description provided for @worker_stripeVerifying.
  ///
  /// In fr, this message translates to:
  /// **'Stripe vérifie vos informations'**
  String get worker_stripeVerifying;

  /// No description provided for @worker_takePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get worker_takePhoto;

  /// No description provided for @worker_takePhotoBeforeFinish.
  ///
  /// In fr, this message translates to:
  /// **'Prenez une photo avant de terminer'**
  String get worker_takePhotoBeforeFinish;

  /// No description provided for @worker_timeElapsed.
  ///
  /// In fr, this message translates to:
  /// **'Temps écoulé'**
  String get worker_timeElapsed;

  /// No description provided for @worker_tooFar.
  ///
  /// In fr, this message translates to:
  /// **'Trop loin'**
  String get worker_tooFar;

  /// No description provided for @worker_tooFarMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes à {distanceMeters}m du véhicule.\n\nVous devez être à moins de {maxRadius}m pour confirmer votre arrivée.\n\nContinuez à vous rapprocher.'**
  String worker_tooFarMessage(int distanceMeters, int maxRadius);

  /// No description provided for @worker_verificationInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Vérification en cours'**
  String get worker_verificationInProgress;

  /// No description provided for @worker_verificationTimeInfo.
  ///
  /// In fr, this message translates to:
  /// **'La vérification peut prendre quelques minutes à 24 heures.'**
  String get worker_verificationTimeInfo;

  /// No description provided for @worker_verifyingPosition.
  ///
  /// In fr, this message translates to:
  /// **'Vérification de votre position...'**
  String get worker_verifyingPosition;

  /// No description provided for @worker_viewStatusOnStripe.
  ///
  /// In fr, this message translates to:
  /// **'Voir le statut sur Stripe'**
  String get worker_viewStatusOnStripe;

  /// No description provided for @worker_viewStripeDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Voir mon dashboard Stripe'**
  String get worker_viewStripeDashboard;

  /// No description provided for @worker_workInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Travail en cours...'**
  String get worker_workInProgress;

  /// No description provided for @worker_youReceive.
  ///
  /// In fr, this message translates to:
  /// **'Vous recevez'**
  String get worker_youReceive;

  /// No description provided for @verification_addPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get verification_addPhoto;

  /// No description provided for @verification_backOptional.
  ///
  /// In fr, this message translates to:
  /// **'Verso (optionnel)'**
  String get verification_backOptional;

  /// No description provided for @verification_backSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Si votre document a un verso'**
  String get verification_backSubtitle;

  /// No description provided for @verification_captureBack.
  ///
  /// In fr, this message translates to:
  /// **'Photographier le verso'**
  String get verification_captureBack;

  /// No description provided for @verification_captureFront.
  ///
  /// In fr, this message translates to:
  /// **'Photographier le recto'**
  String get verification_captureFront;

  /// No description provided for @verification_choosePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une photo'**
  String get verification_choosePhoto;

  /// No description provided for @verification_continueToSelfie.
  ///
  /// In fr, this message translates to:
  /// **'Continuer vers le selfie'**
  String get verification_continueToSelfie;

  /// No description provided for @verification_fromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Depuis la galerie'**
  String get verification_fromGallery;

  /// No description provided for @verification_frontRequired.
  ///
  /// In fr, this message translates to:
  /// **'Recto (obligatoire)'**
  String get verification_frontRequired;

  /// No description provided for @verification_frontSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Face avec votre photo'**
  String get verification_frontSubtitle;

  /// No description provided for @verification_idBack.
  ///
  /// In fr, this message translates to:
  /// **'Pièce d\'identité (verso)'**
  String get verification_idBack;

  /// No description provided for @verification_idFront.
  ///
  /// In fr, this message translates to:
  /// **'Pièce d\'identité (recto)'**
  String get verification_idFront;

  /// No description provided for @verification_photoTips.
  ///
  /// In fr, this message translates to:
  /// **'Placez le document sur une surface plane, assurez-vous d\'avoir un bon éclairage, évitez les reflets et les ombres, capturez tout le document.'**
  String get verification_photoTips;

  /// No description provided for @verification_photoTipsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conseils pour une bonne photo'**
  String get verification_photoTipsTitle;

  /// No description provided for @verification_privacyNote.
  ///
  /// In fr, this message translates to:
  /// **'Vos documents seront analysés de manière sécurisée et supprimés après vérification.'**
  String get verification_privacyNote;

  /// No description provided for @verification_retake.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get verification_retake;

  /// No description provided for @verification_selfieInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Regardez directement la caméra, gardez un visage neutre, assurez-vous d\'avoir un bon éclairage, retirez lunettes de soleil et chapeau.'**
  String get verification_selfieInstructions;

  /// No description provided for @verification_selfieRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez prendre un selfie'**
  String get verification_selfieRequired;

  /// No description provided for @verification_takeSelfie.
  ///
  /// In fr, this message translates to:
  /// **'Prenez un selfie'**
  String get verification_takeSelfie;

  /// No description provided for @verification_takeSelfieBtn.
  ///
  /// In fr, this message translates to:
  /// **'Prendre le selfie'**
  String get verification_takeSelfieBtn;

  /// No description provided for @verification_yourSelfie.
  ///
  /// In fr, this message translates to:
  /// **'Votre selfie'**
  String get verification_yourSelfie;

  /// No description provided for @profile_changePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo de profil'**
  String get profile_changePhoto;

  /// No description provided for @profile_chooseFromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir depuis la galerie'**
  String get profile_chooseFromGallery;

  /// No description provided for @profile_deletePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la photo'**
  String get profile_deletePhoto;

  /// No description provided for @profile_deletePhotoConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer votre photo de profil?'**
  String get profile_deletePhotoConfirm;

  /// No description provided for @profile_editTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get profile_editTitle;

  /// No description provided for @profile_emailNotEditable.
  ///
  /// In fr, this message translates to:
  /// **'L\'email ne peut pas être modifié'**
  String get profile_emailNotEditable;

  /// No description provided for @profile_firstNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le prénom est requis'**
  String get profile_firstNameRequired;

  /// No description provided for @profile_lastNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est requis'**
  String get profile_lastNameRequired;

  /// No description provided for @profile_personalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get profile_personalInfo;

  /// No description provided for @profile_phoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Format de téléphone invalide'**
  String get profile_phoneInvalid;

  /// No description provided for @profile_photoSelectionError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la sélection: {error}'**
  String profile_photoSelectionError(String error);

  /// No description provided for @profile_saveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get profile_saveChanges;

  /// No description provided for @profile_smsVerification.
  ///
  /// In fr, this message translates to:
  /// **'Vérification SMS'**
  String get profile_smsVerification;

  /// No description provided for @profile_smsVerificationNote.
  ///
  /// In fr, this message translates to:
  /// **'Un code SMS sera envoyé pour vérifier le nouveau numéro'**
  String get profile_smsVerificationNote;

  /// No description provided for @profile_takePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get profile_takePhoto;

  /// No description provided for @profile_verificationCodeSentTo.
  ///
  /// In fr, this message translates to:
  /// **'Un code de vérification a été envoyé au:'**
  String get profile_verificationCodeSentTo;

  /// No description provided for @subscription_basic.
  ///
  /// In fr, this message translates to:
  /// **'Basique'**
  String get subscription_basic;

  /// No description provided for @subscription_basicFeature1.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'à 5 déneigements/mois'**
  String get subscription_basicFeature1;

  /// No description provided for @subscription_basicFeature2.
  ///
  /// In fr, this message translates to:
  /// **'Priorité normale'**
  String get subscription_basicFeature2;

  /// No description provided for @subscription_basicFeature3.
  ///
  /// In fr, this message translates to:
  /// **'Support par email'**
  String get subscription_basicFeature3;

  /// No description provided for @subscription_choosePlan.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre plan'**
  String get subscription_choosePlan;

  /// No description provided for @subscription_choosePlanBtn.
  ///
  /// In fr, this message translates to:
  /// **'Choisir ce plan'**
  String get subscription_choosePlanBtn;

  /// No description provided for @subscription_month.
  ///
  /// In fr, this message translates to:
  /// **'mois'**
  String get subscription_month;

  /// No description provided for @subscription_planTitle.
  ///
  /// In fr, this message translates to:
  /// **'Plan {planName}'**
  String subscription_planTitle(String planName);

  /// No description provided for @subscription_premium.
  ///
  /// In fr, this message translates to:
  /// **'Premium'**
  String get subscription_premium;

  /// No description provided for @subscription_premiumFeature1.
  ///
  /// In fr, this message translates to:
  /// **'Déneigements illimités'**
  String get subscription_premiumFeature1;

  /// No description provided for @subscription_premiumFeature2.
  ///
  /// In fr, this message translates to:
  /// **'Priorité haute'**
  String get subscription_premiumFeature2;

  /// No description provided for @subscription_premiumFeature3.
  ///
  /// In fr, this message translates to:
  /// **'Support 24/7'**
  String get subscription_premiumFeature3;

  /// No description provided for @subscription_premiumFeature4.
  ///
  /// In fr, this message translates to:
  /// **'Notifications SMS'**
  String get subscription_premiumFeature4;

  /// No description provided for @subscription_priceLabel.
  ///
  /// In fr, this message translates to:
  /// **'{price}\$/{period}'**
  String subscription_priceLabel(String price, String period);

  /// No description provided for @subscription_recommended.
  ///
  /// In fr, this message translates to:
  /// **'RECOMMANDÉ'**
  String get subscription_recommended;

  /// No description provided for @subscription_saveWith.
  ///
  /// In fr, this message translates to:
  /// **'Économisez avec nos forfaits saisonniers'**
  String get subscription_saveWith;

  /// No description provided for @subscription_season.
  ///
  /// In fr, this message translates to:
  /// **'saison'**
  String get subscription_season;

  /// No description provided for @subscription_seasonal.
  ///
  /// In fr, this message translates to:
  /// **'Saisonnier'**
  String get subscription_seasonal;

  /// No description provided for @subscription_seasonalFeature1.
  ///
  /// In fr, this message translates to:
  /// **'Tout du Premium'**
  String get subscription_seasonalFeature1;

  /// No description provided for @subscription_seasonalFeature2.
  ///
  /// In fr, this message translates to:
  /// **'Plusieurs véhicules'**
  String get subscription_seasonalFeature2;

  /// No description provided for @subscription_seasonalFeature3.
  ///
  /// In fr, this message translates to:
  /// **'Gestionnaire dédié'**
  String get subscription_seasonalFeature3;

  /// No description provided for @subscription_seasonalFeature4.
  ///
  /// In fr, this message translates to:
  /// **'Rapports détaillés'**
  String get subscription_seasonalFeature4;

  /// No description provided for @subscription_seasonalFeature5.
  ///
  /// In fr, this message translates to:
  /// **'Garantie satisfaction'**
  String get subscription_seasonalFeature5;

  /// No description provided for @subscription_title.
  ///
  /// In fr, this message translates to:
  /// **'Abonnements'**
  String get subscription_title;

  /// No description provided for @legal_andThe.
  ///
  /// In fr, this message translates to:
  /// **' et la '**
  String get legal_andThe;

  /// No description provided for @legal_contactEmail.
  ///
  /// In fr, this message translates to:
  /// **'Contact: privacy@deneige-auto.com'**
  String get legal_contactEmail;

  /// No description provided for @legal_iAccept.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte les '**
  String get legal_iAccept;

  /// No description provided for @legal_lastUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour: {date}'**
  String legal_lastUpdated(String date);

  /// No description provided for @legal_privacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get legal_privacyPolicy;

  /// No description provided for @legal_privacyPolicySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment nous protégeons vos données'**
  String get legal_privacyPolicySubtitle;

  /// No description provided for @legal_rightsDescription.
  ///
  /// In fr, this message translates to:
  /// **'Conformément à la Loi 25 du Québec, vous pouvez demander l\'accès, la rectification ou la suppression de vos données personnelles.'**
  String get legal_rightsDescription;

  /// No description provided for @legal_termsOfService.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get legal_termsOfService;

  /// No description provided for @legal_yourRights.
  ///
  /// In fr, this message translates to:
  /// **'Vos droits'**
  String get legal_yourRights;

  /// No description provided for @ai_alert.
  ///
  /// In fr, this message translates to:
  /// **'Alerte'**
  String get ai_alert;

  /// No description provided for @ai_analysisInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Analyse IA en cours...'**
  String get ai_analysisInProgress;

  /// No description provided for @ai_analysisLabel.
  ///
  /// In fr, this message translates to:
  /// **'Analyse IA'**
  String get ai_analysisLabel;

  /// No description provided for @ai_analysisUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Analyse non disponible'**
  String get ai_analysisUnavailable;

  /// No description provided for @ai_analyzedOn.
  ///
  /// In fr, this message translates to:
  /// **'Analysé le {date}'**
  String ai_analyzedOn(String date);

  /// No description provided for @ai_basePrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix de base'**
  String get ai_basePrice;

  /// No description provided for @ai_completeness.
  ///
  /// In fr, this message translates to:
  /// **'Complétude'**
  String get ai_completeness;

  /// No description provided for @ai_criticalIssue.
  ///
  /// In fr, this message translates to:
  /// **'Problème critique détecté'**
  String get ai_criticalIssue;

  /// No description provided for @ai_estimatedDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée estimée'**
  String get ai_estimatedDuration;

  /// No description provided for @ai_estimatedSnow.
  ///
  /// In fr, this message translates to:
  /// **'Neige estimée'**
  String get ai_estimatedSnow;

  /// No description provided for @ai_estimation.
  ///
  /// In fr, this message translates to:
  /// **'Estimation IA'**
  String get ai_estimation;

  /// No description provided for @ai_improvementPoints.
  ///
  /// In fr, this message translates to:
  /// **'Points à améliorer'**
  String get ai_improvementPoints;

  /// No description provided for @ai_issuesDetected.
  ///
  /// In fr, this message translates to:
  /// **'Problèmes détectés'**
  String get ai_issuesDetected;

  /// No description provided for @ai_multiplier.
  ///
  /// In fr, this message translates to:
  /// **'Multiplicateur'**
  String get ai_multiplier;

  /// No description provided for @ai_notDetected.
  ///
  /// In fr, this message translates to:
  /// **'Non détecté'**
  String get ai_notDetected;

  /// No description provided for @ai_noVehicleDetected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun véhicule détecté sur la photo'**
  String get ai_noVehicleDetected;

  /// No description provided for @ai_noVehicleDetectedBullet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun véhicule détecté'**
  String get ai_noVehicleDetectedBullet;

  /// No description provided for @ai_perfect.
  ///
  /// In fr, this message translates to:
  /// **'Parfait!'**
  String get ai_perfect;

  /// No description provided for @ai_photoAlert.
  ///
  /// In fr, this message translates to:
  /// **'Alerte Photo'**
  String get ai_photoAlert;

  /// No description provided for @ai_photosAnalyzed.
  ///
  /// In fr, this message translates to:
  /// **'{count} photos analysées'**
  String ai_photosAnalyzed(int count);

  /// No description provided for @ai_priceRange.
  ///
  /// In fr, this message translates to:
  /// **'Fourchette'**
  String get ai_priceRange;

  /// No description provided for @ai_quality.
  ///
  /// In fr, this message translates to:
  /// **'Qualité'**
  String get ai_quality;

  /// No description provided for @ai_qualityVerification.
  ///
  /// In fr, this message translates to:
  /// **'Vérification de la qualité du travail'**
  String get ai_qualityVerification;

  /// No description provided for @ai_retakePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre photo'**
  String get ai_retakePhoto;

  /// No description provided for @ai_snowDepth.
  ///
  /// In fr, this message translates to:
  /// **'~{depth} cm neige'**
  String ai_snowDepth(String depth);

  /// No description provided for @ai_subtotal.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get ai_subtotal;

  /// No description provided for @ai_summary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé'**
  String get ai_summary;

  /// No description provided for @ai_surchargesApplied.
  ///
  /// In fr, this message translates to:
  /// **'Majorations appliquées'**
  String get ai_surchargesApplied;

  /// No description provided for @ai_suspiciousPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo suspecte détectée - Veuillez reprendre une photo authentique'**
  String get ai_suspiciousPhoto;

  /// No description provided for @ai_suspiciousPhotoFraud.
  ///
  /// In fr, this message translates to:
  /// **'Photo suspecte (possible fraude)'**
  String get ai_suspiciousPhotoFraud;

  /// No description provided for @ai_taxIncluded.
  ///
  /// In fr, this message translates to:
  /// **'taxes incluses'**
  String get ai_taxIncluded;

  /// No description provided for @ai_total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get ai_total;

  /// No description provided for @ai_tps.
  ///
  /// In fr, this message translates to:
  /// **'TPS (5%)'**
  String get ai_tps;

  /// No description provided for @ai_tvq.
  ///
  /// In fr, this message translates to:
  /// **'TVQ (9.975%)'**
  String get ai_tvq;

  /// No description provided for @ai_vehicle.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule'**
  String get ai_vehicle;

  /// No description provided for @ai_verificationLater.
  ///
  /// In fr, this message translates to:
  /// **'La vérification IA sera effectuée ultérieurement'**
  String get ai_verificationLater;

  /// No description provided for @chat_today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get chat_today;

  /// No description provided for @chat_yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get chat_yesterday;

  /// No description provided for @step1_freeLocationHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Devant le bâtiment A...'**
  String get step1_freeLocationHint;

  /// No description provided for @step1_spotNumberHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: P32, A-15, 205...'**
  String get step1_spotNumberHint;

  /// No description provided for @worker_greetingName.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, {name}'**
  String worker_greetingName(String name);

  /// No description provided for @worker_headerAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get worker_headerAvailable;

  /// No description provided for @worker_headerOffline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get worker_headerOffline;

  /// No description provided for @worker_statsCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminés'**
  String get worker_statsCompleted;

  /// No description provided for @worker_statsInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get worker_statsInProgress;

  /// No description provided for @worker_statsRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get worker_statsRevenue;

  /// No description provided for @worker_statsRating.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get worker_statsRating;

  /// No description provided for @worker_statsToday.
  ///
  /// In fr, this message translates to:
  /// **'aujourd\'hui'**
  String get worker_statsToday;

  /// No description provided for @worker_youAreOnline.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes en ligne'**
  String get worker_youAreOnline;

  /// No description provided for @worker_receivingSnowRequests.
  ///
  /// In fr, this message translates to:
  /// **'Vous recevez les demandes de déneigement'**
  String get worker_receivingSnowRequests;

  /// No description provided for @worker_activateToReceiveRequests.
  ///
  /// In fr, this message translates to:
  /// **'Activez pour recevoir des demandes'**
  String get worker_activateToReceiveRequests;

  /// No description provided for @worker_activeCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} actif{count, plural, =1{} other{s}}'**
  String worker_activeCount(int count);

  /// No description provided for @worker_jobCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} job{count, plural, =1{} other{s}}'**
  String worker_jobCount(int count);

  /// No description provided for @worker_statusAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get worker_statusAvailable;

  /// No description provided for @worker_statusAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Assigné'**
  String get worker_statusAssigned;

  /// No description provided for @worker_statusEnRoute.
  ///
  /// In fr, this message translates to:
  /// **'En route'**
  String get worker_statusEnRoute;

  /// No description provided for @worker_statusInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get worker_statusInProgress;

  /// No description provided for @worker_statusCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get worker_statusCompleted;

  /// No description provided for @worker_statusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get worker_statusCancelled;

  /// No description provided for @worker_serviceWindowScraping.
  ///
  /// In fr, this message translates to:
  /// **'Grattage vitres'**
  String get worker_serviceWindowScraping;

  /// No description provided for @worker_serviceDoorDeicing.
  ///
  /// In fr, this message translates to:
  /// **'Déglaçage portes'**
  String get worker_serviceDoorDeicing;

  /// No description provided for @worker_serviceWheelClearance.
  ///
  /// In fr, this message translates to:
  /// **'Dégagement roues'**
  String get worker_serviceWheelClearance;

  /// No description provided for @worker_serviceRoofClearing.
  ///
  /// In fr, this message translates to:
  /// **'Déneigement toit'**
  String get worker_serviceRoofClearing;

  /// No description provided for @worker_serviceSaltSpreading.
  ///
  /// In fr, this message translates to:
  /// **'Épandage sel'**
  String get worker_serviceSaltSpreading;

  /// No description provided for @worker_serviceLightsCleaning.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyage phares'**
  String get worker_serviceLightsCleaning;

  /// No description provided for @worker_servicePerimeterClearance.
  ///
  /// In fr, this message translates to:
  /// **'Dégagement périmètre'**
  String get worker_servicePerimeterClearance;

  /// No description provided for @worker_serviceExhaustCheck.
  ///
  /// In fr, this message translates to:
  /// **'Vérif. échappement'**
  String get worker_serviceExhaustCheck;

  /// No description provided for @worker_serviceWindows.
  ///
  /// In fr, this message translates to:
  /// **'Vitres'**
  String get worker_serviceWindows;

  /// No description provided for @worker_serviceDoors.
  ///
  /// In fr, this message translates to:
  /// **'Portes'**
  String get worker_serviceDoors;

  /// No description provided for @worker_serviceWheels.
  ///
  /// In fr, this message translates to:
  /// **'Roues'**
  String get worker_serviceWheels;

  /// No description provided for @worker_serviceRoof.
  ///
  /// In fr, this message translates to:
  /// **'Toit'**
  String get worker_serviceRoof;

  /// No description provided for @worker_serviceSalt.
  ///
  /// In fr, this message translates to:
  /// **'Sel'**
  String get worker_serviceSalt;

  /// No description provided for @worker_serviceLights.
  ///
  /// In fr, this message translates to:
  /// **'Phares'**
  String get worker_serviceLights;

  /// No description provided for @worker_servicePerimeter.
  ///
  /// In fr, this message translates to:
  /// **'Périmètre'**
  String get worker_servicePerimeter;

  /// No description provided for @worker_serviceExhaustShort.
  ///
  /// In fr, this message translates to:
  /// **'Échapp.'**
  String get worker_serviceExhaustShort;

  /// No description provided for @worker_acceptLabel.
  ///
  /// In fr, this message translates to:
  /// **'ACCEPTER'**
  String get worker_acceptLabel;

  /// No description provided for @worker_passLabel.
  ///
  /// In fr, this message translates to:
  /// **'PASSER'**
  String get worker_passLabel;

  /// No description provided for @worker_accepting.
  ///
  /// In fr, this message translates to:
  /// **'Acceptation...'**
  String get worker_accepting;

  /// No description provided for @worker_acceptThisJob.
  ///
  /// In fr, this message translates to:
  /// **'Accepter ce job'**
  String get worker_acceptThisJob;

  /// No description provided for @worker_swipeHint.
  ///
  /// In fr, this message translates to:
  /// **'Glisser → accepter  |  ← passer'**
  String get worker_swipeHint;

  /// No description provided for @worker_exceeded.
  ///
  /// In fr, this message translates to:
  /// **'DÉPASSÉ'**
  String get worker_exceeded;

  /// No description provided for @worker_urgent.
  ///
  /// In fr, this message translates to:
  /// **'URGENT'**
  String get worker_urgent;

  /// No description provided for @worker_equipmentCompatible.
  ///
  /// In fr, this message translates to:
  /// **'Équipement compatible'**
  String get worker_equipmentCompatible;

  /// No description provided for @worker_equipmentRequiredLabel.
  ///
  /// In fr, this message translates to:
  /// **'Équipement requis'**
  String get worker_equipmentRequiredLabel;

  /// No description provided for @worker_distanceAndTime.
  ///
  /// In fr, this message translates to:
  /// **'{km} km • ~{min} min'**
  String worker_distanceAndTime(String km, String min);

  /// No description provided for @worker_dateAtTime.
  ///
  /// In fr, this message translates to:
  /// **'{date} à {time}'**
  String worker_dateAtTime(String date, String time);

  /// No description provided for @worker_verificationOngoing.
  ///
  /// In fr, this message translates to:
  /// **'Verification en cours'**
  String get worker_verificationOngoing;

  /// No description provided for @worker_verificationOngoingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos documents sont en cours d\'analyse. Vous serez notifié une fois la vérification terminée.'**
  String get worker_verificationOngoingSubtitle;

  /// No description provided for @worker_verificationRejectedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos documents n\'ont pas été approuvés. Veuillez resoumettre des documents valides.'**
  String get worker_verificationRejectedSubtitle;

  /// No description provided for @worker_verificationExpiredSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre vérification a expiré. Veuillez resoumettre vos documents.'**
  String get worker_verificationExpiredSubtitle;

  /// No description provided for @worker_verificationRequiredSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre identité pour pouvoir accepter des jobs de déneigement.'**
  String get worker_verificationRequiredSubtitle;

  /// No description provided for @worker_verificationRequiredForJobs.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre identité pour accepter des jobs.'**
  String get worker_verificationRequiredForJobs;

  /// No description provided for @worker_retryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get worker_retryLabel;

  /// No description provided for @worker_notifUrgentJob.
  ///
  /// In fr, this message translates to:
  /// **'🚨 JOB URGENT!'**
  String get worker_notifUrgentJob;

  /// No description provided for @worker_notifNewJobAvailable.
  ///
  /// In fr, this message translates to:
  /// **'📍 Nouveau job disponible'**
  String get worker_notifNewJobAvailable;

  /// No description provided for @worker_notifNewJobBody.
  ///
  /// In fr, this message translates to:
  /// **'{address} - {price}\$ - {distance} km'**
  String worker_notifNewJobBody(String address, String price, String distance);

  /// No description provided for @worker_notifUrgentJobsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'🚨 Nouveaux jobs urgents!'**
  String get worker_notifUrgentJobsAvailable;

  /// No description provided for @worker_notifNewJobsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'📍 Nouveaux jobs disponibles'**
  String get worker_notifNewJobsAvailable;

  /// No description provided for @worker_notifNewJobsNearby.
  ///
  /// In fr, this message translates to:
  /// **'{count} nouveau{count, plural, =1{} other{x}} job{count, plural, =1{} other{s}} près de vous!'**
  String worker_notifNewJobsNearby(int count);

  /// No description provided for @worker_notifJobAccepted.
  ///
  /// In fr, this message translates to:
  /// **'✅ Job accepté!'**
  String get worker_notifJobAccepted;

  /// No description provided for @worker_notifGoTo.
  ///
  /// In fr, this message translates to:
  /// **'Rendez-vous à {address}'**
  String worker_notifGoTo(String address);

  /// No description provided for @worker_notifJobDone.
  ///
  /// In fr, this message translates to:
  /// **'🎉 Travail terminé!'**
  String get worker_notifJobDone;

  /// No description provided for @worker_notifEarned.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez gagné {amount}\$'**
  String worker_notifEarned(String amount);

  /// No description provided for @worker_notifChannelUrgent.
  ///
  /// In fr, this message translates to:
  /// **'Jobs Urgents'**
  String get worker_notifChannelUrgent;

  /// No description provided for @worker_notifChannelNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux Jobs'**
  String get worker_notifChannelNew;

  /// No description provided for @worker_notifChannelUrgentDesc.
  ///
  /// In fr, this message translates to:
  /// **'Notifications pour les jobs urgents'**
  String get worker_notifChannelUrgentDesc;

  /// No description provided for @worker_notifChannelNewDesc.
  ///
  /// In fr, this message translates to:
  /// **'Notifications pour les nouveaux jobs'**
  String get worker_notifChannelNewDesc;

  /// No description provided for @worker_businessNewJobsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} nouveaux jobs'**
  String worker_businessNewJobsCount(int count);

  /// No description provided for @worker_businessIncludingUrgent.
  ///
  /// In fr, this message translates to:
  /// **'Dont des jobs urgents!'**
  String get worker_businessIncludingUrgent;

  /// No description provided for @worker_businessNearYou.
  ///
  /// In fr, this message translates to:
  /// **'Disponibles près de vous'**
  String get worker_businessNearYou;

  /// No description provided for @worker_businessJobConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Job confirmé!'**
  String get worker_businessJobConfirmed;

  /// No description provided for @worker_businessJobCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Job annulé'**
  String get worker_businessJobCancelled;

  /// No description provided for @worker_businessJobCancelledBody.
  ///
  /// In fr, this message translates to:
  /// **'Le job à {address} a été annulé'**
  String worker_businessJobCancelledBody(String address);

  /// No description provided for @worker_businessJobCancelledReason.
  ///
  /// In fr, this message translates to:
  /// **'Le job à {address} a été annulé: {reason}'**
  String worker_businessJobCancelledReason(String address, String reason);

  /// No description provided for @worker_businessJobModified.
  ///
  /// In fr, this message translates to:
  /// **'Job modifié'**
  String get worker_businessJobModified;

  /// No description provided for @worker_businessPaymentReceived.
  ///
  /// In fr, this message translates to:
  /// **'Paiement reçu!'**
  String get worker_businessPaymentReceived;

  /// No description provided for @worker_businessPaymentAmount.
  ///
  /// In fr, this message translates to:
  /// **'{amount}\$ pour {description}'**
  String worker_businessPaymentAmount(String amount, String description);

  /// No description provided for @worker_businessBonusEarned.
  ///
  /// In fr, this message translates to:
  /// **'🎁 Bonus gagné!'**
  String get worker_businessBonusEarned;

  /// No description provided for @worker_businessBonusTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bonus gagné!'**
  String get worker_businessBonusTitle;

  /// No description provided for @worker_businessBonusBody.
  ///
  /// In fr, this message translates to:
  /// **'+{amount}\$ - {reason}'**
  String worker_businessBonusBody(String amount, String reason);

  /// No description provided for @worker_businessWeeklyPayout.
  ///
  /// In fr, this message translates to:
  /// **'💰 Paiement prêt!'**
  String get worker_businessWeeklyPayout;

  /// No description provided for @worker_businessWeeklyPayoutBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre paiement de {amount}\$ est disponible'**
  String worker_businessWeeklyPayoutBody(String amount);

  /// No description provided for @worker_businessPayoutAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Paiement disponible'**
  String get worker_businessPayoutAvailable;

  /// No description provided for @worker_businessNewRating.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle évaluation!'**
  String get worker_businessNewRating;

  /// No description provided for @worker_businessRatingReceived.
  ///
  /// In fr, this message translates to:
  /// **'Évaluation reçue'**
  String get worker_businessRatingReceived;

  /// No description provided for @worker_businessRatingStars.
  ///
  /// In fr, this message translates to:
  /// **'{rating} étoiles'**
  String worker_businessRatingStars(int rating);

  /// No description provided for @worker_businessPerformanceAlert.
  ///
  /// In fr, this message translates to:
  /// **'⚠️ Attention!'**
  String get worker_businessPerformanceAlert;

  /// No description provided for @worker_businessPerformanceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Alerte performance'**
  String get worker_businessPerformanceTitle;

  /// No description provided for @worker_businessMilestone.
  ///
  /// In fr, this message translates to:
  /// **'🏆 Félicitations!'**
  String get worker_businessMilestone;

  /// No description provided for @worker_businessKeepGoing.
  ///
  /// In fr, this message translates to:
  /// **'Continuez comme ça!'**
  String get worker_businessKeepGoing;

  /// No description provided for @worker_businessDocExpiring.
  ///
  /// In fr, this message translates to:
  /// **'📄 Document expirant'**
  String get worker_businessDocExpiring;

  /// No description provided for @worker_businessDocExpiringBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre {docType} expire dans {days} jours'**
  String worker_businessDocExpiringBody(String docType, int days);

  /// No description provided for @worker_businessDocExpiringTitle.
  ///
  /// In fr, this message translates to:
  /// **'Document expirant'**
  String get worker_businessDocExpiringTitle;

  /// No description provided for @worker_businessDocExpiringShort.
  ///
  /// In fr, this message translates to:
  /// **'{docType} - {days} jours'**
  String worker_businessDocExpiringShort(String docType, int days);

  /// No description provided for @worker_businessHighDemand.
  ///
  /// In fr, this message translates to:
  /// **'📈 Zone en demande!'**
  String get worker_businessHighDemand;

  /// No description provided for @worker_businessHighDemandBody.
  ///
  /// In fr, this message translates to:
  /// **'{zone} - {multiplier}x les gains!'**
  String worker_businessHighDemandBody(String zone, String multiplier);

  /// No description provided for @worker_businessHighDemandTitle.
  ///
  /// In fr, this message translates to:
  /// **'Zone en demande'**
  String get worker_businessHighDemandTitle;

  /// No description provided for @worker_businessHighDemandShort.
  ///
  /// In fr, this message translates to:
  /// **'{zone} - {multiplier}x'**
  String worker_businessHighDemandShort(String zone, String multiplier);

  /// No description provided for @worker_businessWeatherAlert.
  ///
  /// In fr, this message translates to:
  /// **'❄️ Tempête prévue!'**
  String get worker_businessWeatherAlert;

  /// No description provided for @worker_businessWeatherBody.
  ///
  /// In fr, this message translates to:
  /// **'{forecast} - Environ {count} jobs attendus'**
  String worker_businessWeatherBody(String forecast, int count);

  /// No description provided for @worker_businessWeatherTitle.
  ///
  /// In fr, this message translates to:
  /// **'Opportunité météo'**
  String get worker_businessWeatherTitle;

  /// No description provided for @worker_businessClientEnRoute.
  ///
  /// In fr, this message translates to:
  /// **'Déneigeur en route!'**
  String get worker_businessClientEnRoute;

  /// No description provided for @worker_businessClientEta.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée estimée dans {minutes} minutes'**
  String worker_businessClientEta(int minutes);

  /// No description provided for @worker_businessWorkStarted.
  ///
  /// In fr, this message translates to:
  /// **'Déneigement commencé'**
  String get worker_businessWorkStarted;

  /// No description provided for @worker_businessWorkStartedBody.
  ///
  /// In fr, this message translates to:
  /// **'Le déneigement de votre véhicule a commencé'**
  String get worker_businessWorkStartedBody;

  /// No description provided for @worker_businessWorkCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Déneigement terminé!'**
  String get worker_businessWorkCompleted;

  /// No description provided for @worker_businessWorkCompletedBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre véhicule est prêt'**
  String get worker_businessWorkCompletedBody;

  /// No description provided for @worker_businessWorkerMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message du déneigeur'**
  String get worker_businessWorkerMessage;

  /// No description provided for @privacy_introTitle.
  ///
  /// In fr, this message translates to:
  /// **'Introduction'**
  String get privacy_introTitle;

  /// No description provided for @privacy_introBody.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur Deneige Auto. Nous nous engageons à protéger votre vie privée et vos données personnelles. Cette politique explique comment nous collectons, utilisons et protégeons vos informations.'**
  String get privacy_introBody;

  /// No description provided for @privacy_dataCollectedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Données collectées'**
  String get privacy_dataCollectedTitle;

  /// No description provided for @privacy_dataCollectedBody.
  ///
  /// In fr, this message translates to:
  /// **'Nous collectons les données suivantes:\n• Informations d\'identification (nom, prénom, email, téléphone)\n• Informations de localisation pour le service de déneigement\n• Informations sur vos véhicules\n• Données de paiement (traitées de manière sécurisée par Stripe)\n• Historique de vos réservations'**
  String get privacy_dataCollectedBody;

  /// No description provided for @privacy_dataUsageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Utilisation des données'**
  String get privacy_dataUsageTitle;

  /// No description provided for @privacy_dataUsageBody.
  ///
  /// In fr, this message translates to:
  /// **'Vos données sont utilisées pour:\n• Fournir nos services de déneigement\n• Communiquer avec vous concernant vos réservations\n• Améliorer nos services\n• Traiter vos paiements de manière sécurisée\n• Vous envoyer des notifications pertinentes'**
  String get privacy_dataUsageBody;

  /// No description provided for @privacy_dataSharingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partage des données'**
  String get privacy_dataSharingTitle;

  /// No description provided for @privacy_dataSharingBody.
  ///
  /// In fr, this message translates to:
  /// **'Nous partageons vos données uniquement avec:\n• Les déneigeurs assignés à vos réservations (informations nécessaires au service)\n• Stripe pour le traitement des paiements\n• Les autorités si requis par la loi'**
  String get privacy_dataSharingBody;

  /// No description provided for @privacy_securityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get privacy_securityTitle;

  /// No description provided for @privacy_securityBody.
  ///
  /// In fr, this message translates to:
  /// **'Nous utilisons des mesures de sécurité conformes aux normes de l\'industrie pour protéger vos données, incluant le chiffrement des données sensibles et des connexions sécurisées (HTTPS).'**
  String get privacy_securityBody;

  /// No description provided for @privacy_retentionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conservation des données'**
  String get privacy_retentionTitle;

  /// No description provided for @privacy_retentionBody.
  ///
  /// In fr, this message translates to:
  /// **'Vos données sont conservées aussi longtemps que votre compte est actif. Après suppression de votre compte, vos données sont effacées dans un délai de 30 jours.'**
  String get privacy_retentionBody;

  /// No description provided for @privacy_rightsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos droits'**
  String get privacy_rightsTitle;

  /// No description provided for @privacy_rightsBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez le droit de:\n• Accéder à vos données personnelles\n• Corriger vos données inexactes\n• Supprimer votre compte et vos données\n• Exporter vos données\n• Retirer votre consentement à tout moment'**
  String get privacy_rightsBody;

  /// No description provided for @privacy_cookiesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cookies et technologies similaires'**
  String get privacy_cookiesTitle;

  /// No description provided for @privacy_cookiesBody.
  ///
  /// In fr, this message translates to:
  /// **'Notre application mobile n\'utilise pas de cookies. Nous utilisons des identifiants d\'appareil uniquement pour les notifications push.'**
  String get privacy_cookiesBody;

  /// No description provided for @privacy_contactTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get privacy_contactTitle;

  /// No description provided for @privacy_contactBody.
  ///
  /// In fr, this message translates to:
  /// **'Pour toute question concernant cette politique de confidentialité, contactez-nous via la section \"Aide et Support\" de l\'application ou par email à support@deneige-auto.ca'**
  String get privacy_contactBody;

  /// No description provided for @terms_section1Title.
  ///
  /// In fr, this message translates to:
  /// **'1. Acceptation des conditions'**
  String get terms_section1Title;

  /// No description provided for @terms_section1Body.
  ///
  /// In fr, this message translates to:
  /// **'En utilisant l\'application Deneige Auto, vous acceptez d\'être lié par les présentes conditions d\'utilisation. Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser l\'application.'**
  String get terms_section1Body;

  /// No description provided for @terms_section2Title.
  ///
  /// In fr, this message translates to:
  /// **'2. Description du service'**
  String get terms_section2Title;

  /// No description provided for @terms_section2Body.
  ///
  /// In fr, this message translates to:
  /// **'Deneige Auto est une plateforme mettant en relation des clients ayant besoin de services de déneigement avec des prestataires de services (déneigeurs) indépendants. Nous ne sommes pas l\'employeur des déneigeurs.'**
  String get terms_section2Body;

  /// No description provided for @terms_section3Title.
  ///
  /// In fr, this message translates to:
  /// **'3. Inscription et compte'**
  String get terms_section3Title;

  /// No description provided for @terms_section3Body.
  ///
  /// In fr, this message translates to:
  /// **'Pour utiliser nos services, vous devez:\n• Être âgé d\'au moins 18 ans\n• Fournir des informations exactes et à jour\n• Maintenir la confidentialité de vos identifiants\n• Nous informer de toute utilisation non autorisée de votre compte'**
  String get terms_section3Body;

  /// No description provided for @terms_section4Title.
  ///
  /// In fr, this message translates to:
  /// **'4. Réservations et paiements'**
  String get terms_section4Title;

  /// No description provided for @terms_section4Body.
  ///
  /// In fr, this message translates to:
  /// **'• Les prix affichés incluent les taxes applicables\n• Le paiement est effectué au moment de la réservation\n• Les annulations sont soumises à notre politique d\'annulation\n• Un remboursement peut être demandé selon les conditions applicables'**
  String get terms_section4Body;

  /// No description provided for @terms_section5Title.
  ///
  /// In fr, this message translates to:
  /// **'5. Politique d\'annulation'**
  String get terms_section5Title;

  /// No description provided for @terms_section5Body.
  ///
  /// In fr, this message translates to:
  /// **'• Annulation plus de 24h avant: remboursement complet\n• Annulation entre 12h et 24h avant: remboursement de 50%\n• Annulation moins de 12h avant: aucun remboursement\n• Annulation par le déneigeur: remboursement complet et priorité de réassignation'**
  String get terms_section5Body;

  /// No description provided for @terms_section6Title.
  ///
  /// In fr, this message translates to:
  /// **'6. Responsabilités de l\'utilisateur'**
  String get terms_section6Title;

  /// No description provided for @terms_section6Body.
  ///
  /// In fr, this message translates to:
  /// **'Vous vous engagez à:\n• Fournir un accès sécuritaire au véhicule\n• Décrire précisément l\'emplacement du véhicule\n• Être disponible pour toute communication urgente\n• Respecter les déneigeurs et leur travail'**
  String get terms_section6Body;

  /// No description provided for @terms_section7Title.
  ///
  /// In fr, this message translates to:
  /// **'7. Responsabilités des déneigeurs'**
  String get terms_section7Title;

  /// No description provided for @terms_section7Body.
  ///
  /// In fr, this message translates to:
  /// **'Les déneigeurs s\'engagent à:\n• Effectuer le service avec professionnalisme\n• Respecter les horaires convenus\n• Prendre soin des véhicules des clients\n• Signaler tout problème ou dommage'**
  String get terms_section7Body;

  /// No description provided for @terms_section8Title.
  ///
  /// In fr, this message translates to:
  /// **'8. Limitation de responsabilité'**
  String get terms_section8Title;

  /// No description provided for @terms_section8Body.
  ///
  /// In fr, this message translates to:
  /// **'Deneige Auto agit comme intermédiaire et ne peut être tenu responsable des dommages directs ou indirects résultant de l\'exécution des services par les déneigeurs. Tout litige doit être signalé dans les 24h suivant le service.'**
  String get terms_section8Body;

  /// No description provided for @terms_section9Title.
  ///
  /// In fr, this message translates to:
  /// **'9. Propriété intellectuelle'**
  String get terms_section9Title;

  /// No description provided for @terms_section9Body.
  ///
  /// In fr, this message translates to:
  /// **'Tous les contenus de l\'application (logos, textes, images, code) sont la propriété de Deneige Auto et sont protégés par les lois sur la propriété intellectuelle.'**
  String get terms_section9Body;

  /// No description provided for @terms_section10Title.
  ///
  /// In fr, this message translates to:
  /// **'10. Modification des conditions'**
  String get terms_section10Title;

  /// No description provided for @terms_section10Body.
  ///
  /// In fr, this message translates to:
  /// **'Nous nous réservons le droit de modifier ces conditions à tout moment. Les utilisateurs seront informés des changements significatifs par notification dans l\'application.'**
  String get terms_section10Body;

  /// No description provided for @terms_section11Title.
  ///
  /// In fr, this message translates to:
  /// **'11. Résiliation'**
  String get terms_section11Title;

  /// No description provided for @terms_section11Body.
  ///
  /// In fr, this message translates to:
  /// **'Nous pouvons suspendre ou résilier votre compte en cas de violation de ces conditions. Vous pouvez supprimer votre compte à tout moment depuis les paramètres de l\'application.'**
  String get terms_section11Body;

  /// No description provided for @terms_section12Title.
  ///
  /// In fr, this message translates to:
  /// **'12. Droit applicable'**
  String get terms_section12Title;

  /// No description provided for @terms_section12Body.
  ///
  /// In fr, this message translates to:
  /// **'Ces conditions sont régies par les lois de la province de Québec, Canada. Tout litige sera soumis aux tribunaux compétents de Montréal.'**
  String get terms_section12Body;

  /// No description provided for @terms_section13Title.
  ///
  /// In fr, this message translates to:
  /// **'13. Contact'**
  String get terms_section13Title;

  /// No description provided for @terms_section13Body.
  ///
  /// In fr, this message translates to:
  /// **'Pour toute question concernant ces conditions, contactez-nous via la section \"Aide et Support\" de l\'application.'**
  String get terms_section13Body;

  /// No description provided for @faq_catGeneral.
  ///
  /// In fr, this message translates to:
  /// **'Général'**
  String get faq_catGeneral;

  /// No description provided for @faq_catReservations.
  ///
  /// In fr, this message translates to:
  /// **'Réservations'**
  String get faq_catReservations;

  /// No description provided for @faq_catPayments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get faq_catPayments;

  /// No description provided for @faq_catDisputes.
  ///
  /// In fr, this message translates to:
  /// **'Litiges'**
  String get faq_catDisputes;

  /// No description provided for @faq_catAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get faq_catAccount;

  /// No description provided for @aiChat_suggestions.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions'**
  String get aiChat_suggestions;

  /// No description provided for @worker_navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get worker_navHome;

  /// No description provided for @worker_navEarnings.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get worker_navEarnings;

  /// No description provided for @worker_navPayments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get worker_navPayments;

  /// No description provided for @worker_navProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get worker_navProfile;

  /// No description provided for @earnings_myEarnings.
  ///
  /// In fr, this message translates to:
  /// **'Mes revenus'**
  String get earnings_myEarnings;

  /// No description provided for @earnings_day.
  ///
  /// In fr, this message translates to:
  /// **'Jour'**
  String get earnings_day;

  /// No description provided for @earnings_week.
  ///
  /// In fr, this message translates to:
  /// **'Semaine'**
  String get earnings_week;

  /// No description provided for @earnings_month.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get earnings_month;

  /// No description provided for @earnings_retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get earnings_retry;

  /// No description provided for @earnings_today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get earnings_today;

  /// No description provided for @earnings_thisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get earnings_thisWeek;

  /// No description provided for @earnings_thisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get earnings_thisMonth;

  /// No description provided for @earnings_jobs.
  ///
  /// In fr, this message translates to:
  /// **'Jobs'**
  String get earnings_jobs;

  /// No description provided for @earnings_tips.
  ///
  /// In fr, this message translates to:
  /// **'Pourboires'**
  String get earnings_tips;

  /// No description provided for @earnings_average.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne'**
  String get earnings_average;

  /// No description provided for @earnings_goalAmount.
  ///
  /// In fr, this message translates to:
  /// **'Objectif: {amount}\$'**
  String earnings_goalAmount(int amount);

  /// No description provided for @earnings_goalReached.
  ///
  /// In fr, this message translates to:
  /// **'Objectif atteint!'**
  String get earnings_goalReached;

  /// No description provided for @earnings_completed.
  ///
  /// In fr, this message translates to:
  /// **'Terminés'**
  String get earnings_completed;

  /// No description provided for @earnings_inProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get earnings_inProgress;

  /// No description provided for @earnings_assigned.
  ///
  /// In fr, this message translates to:
  /// **'Assignés'**
  String get earnings_assigned;

  /// No description provided for @earnings_earnings.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get earnings_earnings;

  /// No description provided for @earnings_tipsShort.
  ///
  /// In fr, this message translates to:
  /// **'Tips'**
  String get earnings_tipsShort;

  /// No description provided for @earnings_jobHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des jobs'**
  String get earnings_jobHistory;

  /// No description provided for @earnings_viewAllJobs.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous vos jobs terminés'**
  String get earnings_viewAllJobs;

  /// No description provided for @earnings_earningsPerDay.
  ///
  /// In fr, this message translates to:
  /// **'Revenus par jour'**
  String get earnings_earningsPerDay;

  /// No description provided for @earnings_dayMon.
  ///
  /// In fr, this message translates to:
  /// **'Lun'**
  String get earnings_dayMon;

  /// No description provided for @earnings_dayTue.
  ///
  /// In fr, this message translates to:
  /// **'Mar'**
  String get earnings_dayTue;

  /// No description provided for @earnings_dayWed.
  ///
  /// In fr, this message translates to:
  /// **'Mer'**
  String get earnings_dayWed;

  /// No description provided for @earnings_dayThu.
  ///
  /// In fr, this message translates to:
  /// **'Jeu'**
  String get earnings_dayThu;

  /// No description provided for @earnings_dayFri.
  ///
  /// In fr, this message translates to:
  /// **'Ven'**
  String get earnings_dayFri;

  /// No description provided for @earnings_daySat.
  ///
  /// In fr, this message translates to:
  /// **'Sam'**
  String get earnings_daySat;

  /// No description provided for @earnings_daySun.
  ///
  /// In fr, this message translates to:
  /// **'Dim'**
  String get earnings_daySun;

  /// No description provided for @earnings_overallStats.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques globales'**
  String get earnings_overallStats;

  /// No description provided for @earnings_totalJobs.
  ///
  /// In fr, this message translates to:
  /// **'Total jobs'**
  String get earnings_totalJobs;

  /// No description provided for @earnings_totalEarnings.
  ///
  /// In fr, this message translates to:
  /// **'Revenus totaux'**
  String get earnings_totalEarnings;

  /// No description provided for @earnings_totalTips.
  ///
  /// In fr, this message translates to:
  /// **'Pourboires totaux'**
  String get earnings_totalTips;

  /// No description provided for @earnings_averageRating.
  ///
  /// In fr, this message translates to:
  /// **'Note moyenne'**
  String get earnings_averageRating;

  /// No description provided for @workerFaq_q1.
  ///
  /// In fr, this message translates to:
  /// **'Comment devenir déneigeur sur Deneige Auto?'**
  String get workerFaq_q1;

  /// No description provided for @workerFaq_a1.
  ///
  /// In fr, this message translates to:
  /// **'Pour devenir déneigeur, vous devez créer un compte en tant que déneigeur, compléter votre profil avec vos informations personnelles, ajouter votre équipement disponible et configurer votre compte bancaire pour recevoir vos paiements.'**
  String get workerFaq_a1;

  /// No description provided for @workerFaq_q2.
  ///
  /// In fr, this message translates to:
  /// **'Quelles sont les conditions pour être déneigeur?'**
  String get workerFaq_q2;

  /// No description provided for @workerFaq_a2.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez avoir au moins 18 ans, posséder un équipement de déneigement de base (pelle, balai, grattoir), être disponible pendant les périodes de neige et avoir un compte bancaire canadien pour recevoir vos paiements.'**
  String get workerFaq_a2;

  /// No description provided for @workerFaq_q3.
  ///
  /// In fr, this message translates to:
  /// **'Puis-je choisir mes zones de travail?'**
  String get workerFaq_q3;

  /// No description provided for @workerFaq_a3.
  ///
  /// In fr, this message translates to:
  /// **'Oui! Dans vos paramètres, vous pouvez définir vos zones préférées. Vous recevrez des notifications prioritaires pour les jobs dans ces zones, mais vous pouvez aussi accepter des jobs ailleurs.'**
  String get workerFaq_a3;

  /// No description provided for @workerFaq_q4.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce que l\'Assistant IA?'**
  String get workerFaq_q4;

  /// No description provided for @workerFaq_a4.
  ///
  /// In fr, this message translates to:
  /// **'L\'Assistant IA est votre aide virtuel disponible 24/7 dans l\'application. Il peut répondre à vos questions sur les jobs, vous aider à résoudre des problèmes, donner des conseils pour améliorer votre service et vous informer sur les conditions météo pour planifier votre journée.'**
  String get workerFaq_a4;

  /// No description provided for @workerFaq_q5.
  ///
  /// In fr, this message translates to:
  /// **'Comment utiliser l\'Assistant IA?'**
  String get workerFaq_q5;

  /// No description provided for @workerFaq_a5.
  ///
  /// In fr, this message translates to:
  /// **'Accédez à l\'Assistant IA depuis le menu principal. Posez vos questions en langage naturel:\n- \"Quels jobs sont disponibles près de moi?\"\n- \"Comment répondre à un litige?\"\n- \"Quelle météo est prévue demain?\"\n- \"Comment améliorer mon score?\"\nL\'assistant vous répondra instantanément.'**
  String get workerFaq_a5;

  /// No description provided for @workerFaq_q6.
  ///
  /// In fr, this message translates to:
  /// **'L\'Assistant IA peut-il m\'aider avec la météo?'**
  String get workerFaq_q6;

  /// No description provided for @workerFaq_a6.
  ///
  /// In fr, this message translates to:
  /// **'Oui! L\'Assistant IA a accès aux prévisions météo en temps réel. Demandez-lui les conditions actuelles ou les prévisions pour planifier vos disponibilités. Vous pouvez ainsi anticiper les journées de forte demande lors des tempêtes de neige.'**
  String get workerFaq_a6;

  /// No description provided for @workerFaq_q7.
  ///
  /// In fr, this message translates to:
  /// **'Comment recevoir des jobs?'**
  String get workerFaq_q7;

  /// No description provided for @workerFaq_a7.
  ///
  /// In fr, this message translates to:
  /// **'Activez votre disponibilité dans l\'application. Vous recevrez des notifications push pour les nouveaux jobs disponibles dans votre zone. Vous pouvez alors accepter ou refuser chaque job.'**
  String get workerFaq_a7;

  /// No description provided for @workerFaq_q8.
  ///
  /// In fr, this message translates to:
  /// **'Puis-je accepter plusieurs jobs en même temps?'**
  String get workerFaq_q8;

  /// No description provided for @workerFaq_a8.
  ///
  /// In fr, this message translates to:
  /// **'Oui, vous pouvez gérer jusqu\'à 5 jobs simultanément. Dans vos paramètres, définissez le nombre maximum de jobs actifs que vous souhaitez avoir en même temps. Nous recommandons 2-3 jobs pour un service optimal.'**
  String get workerFaq_a8;

  /// No description provided for @workerFaq_q9.
  ///
  /// In fr, this message translates to:
  /// **'Comment annuler un job accepté?'**
  String get workerFaq_q9;

  /// No description provided for @workerFaq_a9.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez annuler un job avant de commencer le travail. Allez dans les détails du job et appuyez sur \"Annuler\". Attention: des annulations fréquentes peuvent affecter votre score et votre visibilité.'**
  String get workerFaq_a9;

  /// No description provided for @workerFaq_q10.
  ///
  /// In fr, this message translates to:
  /// **'Que faire si je ne trouve pas le véhicule?'**
  String get workerFaq_q10;

  /// No description provided for @workerFaq_a10.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez la messagerie intégrée pour contacter le client. Si le véhicule est introuvable après 15 minutes et sans réponse du client, vous pouvez signaler le problème et annuler le job sans pénalité.'**
  String get workerFaq_a10;

  /// No description provided for @workerFaq_q11.
  ///
  /// In fr, this message translates to:
  /// **'Comment signaler un problème avec un job?'**
  String get workerFaq_q11;

  /// No description provided for @workerFaq_a11.
  ///
  /// In fr, this message translates to:
  /// **'Dans les détails du job, appuyez sur \"Signaler un problème\". Décrivez la situation et ajoutez des photos si nécessaire. Notre équipe examinera votre signalement rapidement.'**
  String get workerFaq_a11;

  /// No description provided for @workerFaq_q12.
  ///
  /// In fr, this message translates to:
  /// **'Comment suis-je payé?'**
  String get workerFaq_q12;

  /// No description provided for @workerFaq_a12.
  ///
  /// In fr, this message translates to:
  /// **'Les paiements sont effectués automatiquement via Stripe Connect. Après chaque job complété, le montant est transféré sur votre compte bancaire dans un délai de 2-7 jours ouvrables.'**
  String get workerFaq_a12;

  /// No description provided for @workerFaq_q13.
  ///
  /// In fr, this message translates to:
  /// **'Comment configurer mon compte bancaire?'**
  String get workerFaq_q13;

  /// No description provided for @workerFaq_a13.
  ///
  /// In fr, this message translates to:
  /// **'Allez dans Paramètres > Mes paiements > Configuration Stripe. Suivez les étapes pour vérifier votre identité et ajouter vos coordonnées bancaires. Ce processus est sécurisé et obligatoire pour recevoir vos paiements.'**
  String get workerFaq_a13;

  /// No description provided for @workerFaq_q14.
  ///
  /// In fr, this message translates to:
  /// **'Comment sont calculés mes gains?'**
  String get workerFaq_q14;

  /// No description provided for @workerFaq_a14.
  ///
  /// In fr, this message translates to:
  /// **'Vos gains dépendent du type de service (déneigement standard, avec options), de la taille du véhicule et de la distance. Vous voyez le montant exact avant d\'accepter chaque job. Deneige Auto prélève une commission de 15%.'**
  String get workerFaq_a14;

  /// No description provided for @workerFaq_q15.
  ///
  /// In fr, this message translates to:
  /// **'Comment fonctionnent les pourboires?'**
  String get workerFaq_q15;

  /// No description provided for @workerFaq_a15.
  ///
  /// In fr, this message translates to:
  /// **'Les clients peuvent laisser un pourboire après le service. Les pourboires sont 100% pour vous, sans commission. Vous recevez une notification et le montant est ajouté à votre prochain paiement.'**
  String get workerFaq_a15;

  /// No description provided for @workerFaq_q16.
  ///
  /// In fr, this message translates to:
  /// **'Où voir mon historique de gains?'**
  String get workerFaq_q16;

  /// No description provided for @workerFaq_a16.
  ///
  /// In fr, this message translates to:
  /// **'Allez dans l\'onglet \"Gains\" pour voir vos revenus quotidiens, hebdomadaires et mensuels. Vous pouvez aussi voir le détail de chaque job et les pourboires reçus.'**
  String get workerFaq_a16;

  /// No description provided for @workerFaq_q17.
  ///
  /// In fr, this message translates to:
  /// **'Que se passe-t-il si un client me signale un no-show?'**
  String get workerFaq_q17;

  /// No description provided for @workerFaq_a17.
  ///
  /// In fr, this message translates to:
  /// **'Si un client signale que vous n\'êtes pas venu, vous recevrez une notification et aurez l\'opportunité de répondre. Si vous avez marqué \"En route\" dans l\'application, cela sera pris en compte. Les faux signalements de clients sont aussi sanctionnés.'**
  String get workerFaq_a17;

  /// No description provided for @workerFaq_q18.
  ///
  /// In fr, this message translates to:
  /// **'Comment répondre à un litige?'**
  String get workerFaq_q18;

  /// No description provided for @workerFaq_a18.
  ///
  /// In fr, this message translates to:
  /// **'Pour répondre à un litige:\n1. Allez dans Profil > Mes litiges\n2. Ouvrez le litige concerné\n3. Appuyez sur \"Répondre au litige\"\n4. Expliquez votre version des faits en détail\n5. Ajoutez des photos comme preuves (avant/après, captures d\'écran, etc.)\n6. Soumettez votre réponse\n\nVous avez généralement 48 heures pour répondre.'**
  String get workerFaq_a18;

  /// No description provided for @workerFaq_q19.
  ///
  /// In fr, this message translates to:
  /// **'Comment ajouter des preuves à ma défense?'**
  String get workerFaq_q19;

  /// No description provided for @workerFaq_a19.
  ///
  /// In fr, this message translates to:
  /// **'Les preuves sont essentielles pour défendre votre position. Dans les détails du litige, utilisez \"Ajouter des preuves\" pour:\n- Photos avant/après le déneigement\n- Captures d\'écran de communications\n- Photos horodatées sur le site\n- Tout document pertinent\n\nVous pouvez ajouter jusqu\'à 10 photos et une description détaillée.'**
  String get workerFaq_a19;

  /// No description provided for @workerFaq_q20.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce que l\'analyse IA des litiges?'**
  String get workerFaq_q20;

  /// No description provided for @workerFaq_a20.
  ///
  /// In fr, this message translates to:
  /// **'Notre système utilise l\'intelligence artificielle pour analyser objectivement chaque litige. L\'IA examine:\n- Les photos et preuves des deux parties\n- Les données GPS et timestamps\n- L\'historique du client et du déneigeur\n- La cohérence des déclarations\n\nCette analyse aide à prendre des décisions justes. Si l\'IA détecte un faux signalement, cela joue en votre faveur.'**
  String get workerFaq_a20;

  /// No description provided for @workerFaq_q21.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi prendre des photos avant/après est important?'**
  String get workerFaq_q21;

  /// No description provided for @workerFaq_a21.
  ///
  /// In fr, this message translates to:
  /// **'Les photos avant/après sont vos meilleures preuves:\n- Elles documentent l\'état initial et le travail accompli\n- L\'IA peut analyser la qualité du déneigement\n- En cas de litige, elles prouvent votre travail\n- Elles sont horodatées automatiquement\n\nPrenez l\'habitude de photographier chaque job!'**
  String get workerFaq_a21;

  /// No description provided for @workerFaq_q22.
  ///
  /// In fr, this message translates to:
  /// **'Quelles sont les conséquences d\'un litige contre moi?'**
  String get workerFaq_q22;

  /// No description provided for @workerFaq_a22.
  ///
  /// In fr, this message translates to:
  /// **'Les conséquences dépendent de la décision et de votre historique:\n- Premier avertissement: notification\n- Récidive: suspension temporaire (3-7 jours)\n- Problèmes répétés: suspension prolongée (30 jours)\n- Cas graves: exclusion permanente\n\nMaintenez un bon service pour éviter les litiges.'**
  String get workerFaq_a22;

  /// No description provided for @workerFaq_q23.
  ///
  /// In fr, this message translates to:
  /// **'Comment contester une décision défavorable?'**
  String get workerFaq_q23;

  /// No description provided for @workerFaq_a23.
  ///
  /// In fr, this message translates to:
  /// **'Si vous n\'êtes pas d\'accord avec la décision prise sur un litige, vous pouvez faire appel dans les 7 jours. Fournissez des preuves supplémentaires (photos, messages, etc.) pour appuyer votre contestation.'**
  String get workerFaq_a23;

  /// No description provided for @workerFaq_q24.
  ///
  /// In fr, this message translates to:
  /// **'Comment signaler un client problématique?'**
  String get workerFaq_q24;

  /// No description provided for @workerFaq_a24.
  ///
  /// In fr, this message translates to:
  /// **'Si un client est abusif, introuvable malgré vos efforts, ou fait de fausses réclamations, vous pouvez le signaler dans les détails du job. Notre équipe examinera la situation et pourra sanctionner le client si nécessaire.'**
  String get workerFaq_a24;

  /// No description provided for @workerFaq_q25.
  ///
  /// In fr, this message translates to:
  /// **'Mon paiement est-il affecté pendant un litige?'**
  String get workerFaq_q25;

  /// No description provided for @workerFaq_a25.
  ///
  /// In fr, this message translates to:
  /// **'Pendant l\'examen d\'un litige, le paiement correspondant peut être temporairement retenu. Une fois la décision prise:\n- Litige en votre faveur: paiement complet versé\n- Litige contre vous: remboursement au client (partiel ou total selon la décision)'**
  String get workerFaq_a25;

  /// No description provided for @workerFaq_q26.
  ///
  /// In fr, this message translates to:
  /// **'Comment protéger mon score de fiabilité?'**
  String get workerFaq_q26;

  /// No description provided for @workerFaq_a26.
  ///
  /// In fr, this message translates to:
  /// **'Pour maintenir un bon score:\n- Arrivez à l\'heure (marquez \"En route\" dans l\'app)\n- Prenez des photos avant/après chaque job\n- Communiquez avec le client en cas de problème\n- Complétez le travail selon les standards demandés\n- Évitez les annulations de dernière minute'**
  String get workerFaq_a26;

  /// No description provided for @workerFaq_q27.
  ///
  /// In fr, this message translates to:
  /// **'Comment modifier mon équipement disponible?'**
  String get workerFaq_q27;

  /// No description provided for @workerFaq_a27.
  ///
  /// In fr, this message translates to:
  /// **'Dans Paramètres ou dans votre Profil, vous pouvez cocher/décocher les équipements que vous possédez: pelle, balai, grattoir, épandeur de sel, souffleuse. Cela aide à vous assigner les jobs appropriés.'**
  String get workerFaq_a27;

  /// No description provided for @workerFaq_q28.
  ///
  /// In fr, this message translates to:
  /// **'Comment changer mes notifications?'**
  String get workerFaq_q28;

  /// No description provided for @workerFaq_a28.
  ///
  /// In fr, this message translates to:
  /// **'Dans Paramètres > Notifications, vous pouvez activer/désactiver les alertes pour: nouveaux jobs, jobs urgents et pourboires reçus.'**
  String get workerFaq_a28;

  /// No description provided for @workerFaq_q29.
  ///
  /// In fr, this message translates to:
  /// **'Comment améliorer mon score déneigeur?'**
  String get workerFaq_q29;

  /// No description provided for @workerFaq_a29.
  ///
  /// In fr, this message translates to:
  /// **'Votre score est basé sur: la qualité du service (évaluations clients), le taux d\'acceptation des jobs, la ponctualité et le taux de complétion. Offrez un service de qualité et soyez fiable pour améliorer votre score.'**
  String get workerFaq_a29;

  /// No description provided for @workerFaq_q30.
  ///
  /// In fr, this message translates to:
  /// **'Puis-je prendre une pause de l\'application?'**
  String get workerFaq_q30;

  /// No description provided for @workerFaq_a30.
  ///
  /// In fr, this message translates to:
  /// **'Oui! Désactivez simplement votre disponibilité dans l\'application. Vous ne recevrez plus de notifications de jobs. Réactivez quand vous êtes prêt à travailler.'**
  String get workerFaq_a30;

  /// No description provided for @worker_verified.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié'**
  String get worker_verified;
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
