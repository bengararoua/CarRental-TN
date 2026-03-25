// Importation du package Material Design de Flutter pour les widgets d'interface utilisateur
import 'package:flutter/material.dart';
// Importation du package Provider pour la gestion d'état partagé entre les widgets
import 'package:provider/provider.dart';
// Importation du service d'authentification pour gérer les appels API de connexion
import '../services/auth_service.dart';

import '../providers/vehicles_provider.dart';
// Importation de l'écran d'inscription pour la navigation
import 'register_screen.dart';
// Importation de l'écran de mot de passe oublié pour la navigation
import 'forgot_password_screen.dart';
// Importation de l'écran d'accueil pour la navigation après connexion réussie
import 'home_screen.dart';

// Définition d'un StatefulWidget pour l'écran de connexion (nécessaire car état mutable)
class LoginScreen extends StatefulWidget {
  // Redéfinition de la méthode createState pour créer l'état associé à ce widget
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

// Classe d'état qui gère les variables et la logique métier de l'écran de connexion
class _LoginScreenState extends State<LoginScreen> {
  // Clé globale pour identifier et valider le formulaire de connexion
  // GlobalKey : clé unique permettant d’identifier et d’accéder à un widget depuis l’extérieur
// <FormState> : précise que cette clé est utilisée pour manipuler l’état d’un formulaire 
  final _formKey = GlobalKey<FormState>();
  // Contrôleur pour gérer la saisie de l'email dans le champ texte
  final _emailController = TextEditingController();
  // Contrôleur pour gérer la saisie du mot de passe dans le champ texte
  final _passwordController = TextEditingController();
  // Variable booléenne pour suivre si le processus de connexion est en cours
  bool _isLoading = false;
  // Variable booléenne pour contrôler la visibilité du mot de passe (afficher/masquer)
  bool _showPassword = false;

  // Méthode asynchrone pour gérer la logique de connexion de l'utilisateur
  Future<void> _login() async {
    // Vérifie la validité du formulaire, arrête l'exécution si invalide
    if (!_formKey.currentState!.validate()) return;

    // Active l'état de chargement et rafraîchit l'interface utilisateur
    // setState : met à jour l’état du widget et demande à Flutter de reconstruire l’interface avec les nouvelles données
    setState(() => _isLoading = true);

    // Bloc try-catch pour gérer les erreurs potentielles lors de la connexion
    try {
      // Appel du service d'authentification avec l'email et mot de passe saisis
      final result = await AuthService.login(
        // trim() : supprime les espaces (début et fin) d’une chaîne de caractères
        _emailController.text.trim(),
        // .text : permet de récupérer ou modifier le texte d’un champ de saisie (TextEditingController)
        _passwordController.text,
      );

      // Désactive l'état de chargement une fois la réponse reçue
      setState(() => _isLoading = false);

      // Vérifie si la connexion a réussi via le champ 'success' de la réponse
      if (result['success']) {
        // Récupère le token d'accès depuis les données de la réponse
        final token = result['data']['access_token'];
        // Récupère les informations utilisateur depuis les données de la réponse
        final user = result['data']['user'];
        // Extrait le nom d'utilisateur de l'objet utilisateur
        final username = user['username'];
        // Extrait le rôle de l'utilisateur de l'objet utilisateur
        final userRole = user['role'];

        // Affiche les informations de connexion dans la console pour débogage
        print('Utilisateur: $username');
        print('Rôle: $userRole');
        // substring(start, end) : extrait une partie d’une chaîne de caractères entre les indices start (inclus) et end (exclus)
        print('Token: ${token.substring(0, 20)}...');
        print('Date création: ${user['created_at']}');

        // Utilise le Provider pour enregistrer toutes les données utilisateur 
        // context : permet d'accéder à l'arbre des widgets et aux objets fournis par le Provider dans cet écran
        // listen: false : indique que ce widget ne doit pas se reconstruire automatiquement si les données du Provider changent
        Provider.of<VehiclesProvider>(context, listen: false).setUser(
          user,
          token,
        );

        // Détermine le message de bienvenue selon le rôle de l'utilisateur
        String welcomeMessage = userRole?.toLowerCase() == 'admin'
        //si admin
            ? 'Bienvenue Admin $username ! 🛡️'
            //sinon
            : 'Connexion réussie ! Bienvenue $username 👋';

        // Affiche un message snackbar pour confirmer la connexion réussie
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(welcomeMessage),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigation vers l'écran d'accueil avec remplacement (empêche le retour)
        // Navigator : permet de gérer la navigation entre les écrans
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userEmail: _emailController.text.trim(),
              username: username,
            ),
          ),
        );
      } else {
        // Affiche un message d'erreur si la connexion a échoué
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur de connexion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Gestion des erreurs réseau ou autres exceptions
      // mounted : vérifie que le widget est toujours présent dans l’arbre avant de mettre à jour son état 
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Une erreur est survenue lors de la connexion'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode build pour construire l'interface utilisateur de l'écran
  @override
  Widget build(BuildContext context) {
    // Retourne un Scaffold comme structure de base de l'écran
    return Scaffold(
      // Définit la couleur de fond de l'écran en noir
      backgroundColor: const Color(0xFF1A1A1A),
      // Utilise SafeArea pour éviter les zones système (encoches, barres)
      body: SafeArea(
        // Centre le contenu verticalement et horizontalement
        child: Center(
          // Permet le défilement si le contenu dépasse la taille de l'écran
          child: SingleChildScrollView(
            // Ajoute un padding uniforme autour du contenu
            padding: const EdgeInsets.all(24),
            // Formulaire pour regrouper et valider les champs de saisie
            child: Form(
              // Associe la clé globale au formulaire pour la validation
              key: _formKey,
              // Organise les widgets enfants en colonne verticale
              child: Column(
                // Centre les enfants verticalement dans l'espace disponible
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Conteneur pour l'icône/logo de l'application
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      // Fond bleu pour le cercle
                      color: Colors.blue,
                      // Forme circulaire pour le conteneur
                      shape: BoxShape.circle,
                    ),
                    // Icône de voiture à l'intérieur du cercle
                    child: const Icon(Icons.directions_car,
                        size: 60, color: Colors.white),
                  ),
                  // Espacement vertical entre les widgets
                  const SizedBox(height: 30),
                  
                  // Titre principal de l'application
                  const Text(
                    'CarRental Tunisia',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Petit espacement entre les lignes de texte
                  const SizedBox(height: 8),
                  // Sous-titre explicatif
                  const Text(
                    'Connectez-vous à votre compte',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  // Espacement plus grand avant les champs de formulaire
                  const SizedBox(height: 40),
                  
                  // Champ de saisie pour l'email
                  TextFormField(
                    // Associe le contrôleur pour lire/écrire la valeur
                    controller: _emailController,
                    // Style du texte saisi (couleur blanche)
                    style: const TextStyle(color: Colors.white),
                    // Type de clavier optimisé pour les adresses email
                    keyboardType: TextInputType.emailAddress,
                    // Configuration de l'apparence du champ
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white70),
                      // Icône à gauche du champ
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: Colors.white70),
                      // Active le remplissage de fond
                      filled: true,
                      // Couleur de fond gris foncé
                      fillColor: const Color(0xFF2A2A2A),
                      // Configuration de la bordure par défaut
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      // Configuration de la bordure quand le champ est activé
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.white24, width: 1),
                      ),
                    ),
                    // Validateur pour vérifier que l'email contient '@'
                    validator: (v) =>
                        (v != null && v.contains('@')) ? null : 'Email invalide',
                  ),
                  // Espacement entre les champs de formulaire
                  const SizedBox(height: 20),
                  
                  // Champ de saisie pour le mot de passe
                  TextFormField(
                    // Associe le contrôleur pour ce champ
                    controller: _passwordController,
                    // Style du texte saisi
                    style: const TextStyle(color: Colors.white),
                    // Masque le texte si _showPassword est false
                    obscureText: !_showPassword,
                    // Configuration de l'apparence du champ
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      labelStyle: const TextStyle(color: Colors.white70),
                      // Icône à gauche du champ
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: Colors.white70),
                      // Remplissage de fond activé
                      filled: true,
                      // Couleur de fond gris foncé
                      fillColor: const Color(0xFF2A2A2A),
                      // Icône à droite pour basculer la visibilité
                      suffixIcon: IconButton(
                        icon: Icon(
                          // Change l'icône selon l'état de visibilité
                          _showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        // Bascule l'état de visibilité au clic
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                      // Configuration de la bordure par défaut
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    // Validateur pour vérifier que le champ n'est pas vide
                    validator: (v) =>
                        (v != null && v.isNotEmpty) ? null : 'Champ requis',
                  ),
                  
                  // Lien pour réinitialiser le mot de passe
                  Align(
                    // Aligne le widget à droite de son conteneur
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      // Navigation vers l'écran de mot de passe oublié
                      onPressed: () => Navigator.push(
                        context,
                        // MaterialPageRoute : définit une route (écran) avec une animation de transition Material entre les pages
// builder : fonction qui construit l’écran à afficher (ForgotPasswordScreen ici)
                        MaterialPageRoute(
                            builder: (_) => ForgotPasswordScreen()),
                      ),
                      // Texte du lien
                      child: const Text('Mot de passe oublié?',
                          style: TextStyle(color: Colors.blue)),
                    ),
                  ),
                  // Espacement après le lien
                  const SizedBox(height: 20),
                  
                  // Bouton de connexion
                  SizedBox(
                    // Prend toute la largeur disponible
                    width: double.infinity,
                    // Hauteur fixe pour le bouton
                    height: 54,
                    child: ElevatedButton(
                      // Désactive le bouton pendant le chargement, sinon appelle _login
                      onPressed: _isLoading ? null : _login,
                      // Personnalisation du style du bouton
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      // Contenu du bouton (indicateur de chargement ou texte)
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text(
                              'Se connecter',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                    ),
                  ),
                  // Espacement après le bouton
                  const SizedBox(height: 24),
                  
                  // Ligne pour le lien vers l'inscription
                  Row(
                    // Centre les éléments horizontalement dans la ligne
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Texte statique
                      const Text("Vous n'avez pas de compte? ",
                          style: TextStyle(color: Colors.white70)),
                      // Bouton texte pour naviguer vers l'inscription
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RegisterScreen()),
                        ),
                        child: const Text(
                          "S'inscrire",
                          style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}