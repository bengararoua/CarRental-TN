// Importation du package Flutter pour utiliser les widgets Material Design
import 'package:flutter/material.dart';

// Importation du service d'authentification pour utiliser la fonction de réinitialisation de mot de passe
import '../services/auth_service.dart';

// Définition d'un widget avec état pour l'écran de réinitialisation de mot de passe
class ForgotPasswordScreen extends StatefulWidget {
  // Méthode qui crée l'état associé à ce widget, requise par tous les StatefulWidget
  @override
  
  // Création et retour de l'instance de la classe d'état correspondante
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

// Classe d'état qui gère les données et la logique de l'écran de réinitialisation
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Clé globale permettant d'identifier et de valider le formulaire
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleur pour gérer la saisie de l'adresse email
  final _emailController = TextEditingController();
  
  // Contrôleur pour gérer la saisie du nouveau mot de passe
  final _passwordController = TextEditingController();
  
  // Contrôleur pour gérer la confirmation du nouveau mot de passe
  final _confirmPasswordController = TextEditingController();

  // Variable booléenne indiquant si une opération de réinitialisation est en cours
  bool _isLoading = false;
  
  // Variable booléenne contrôlant la visibilité du mot de passe dans les champs
  bool _isPasswordVisible = false;

  // Méthode asynchrone pour traiter la réinitialisation du mot de passe
  Future<void> _handleReset() async {
    // Validation du formulaire : si invalide, on arrête l'exécution
    if (!_formKey.currentState!.validate()) return;

    // Activation de l'indicateur de chargement pour informer l'utilisateur
    setState(() => _isLoading = true);

    // Appel du service d'authentification pour réinitialiser le mot de passe
    final result = await AuthService.resetPassword(
      // Nettoyage de l'email en supprimant les espaces inutiles
      _emailController.text.trim(),
      // Récupération du nouveau mot de passe saisi
      _passwordController.text,
    );

    // Désactivation de l'indicateur de chargement une fois l'opération terminée
    setState(() => _isLoading = false);

    // Traitement du résultat de la réinitialisation
    if (result['success']) {
      // Affichage d'un message de succès à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          // Contenu textuel du message de succès
          content: Text('Mot de passe mis à jour avec succès !'),
          // Couleur de fond verte pour indiquer le succès
          backgroundColor: Colors.green,
        ),
      );
      // Retour à l'écran précédent après réussite
      Navigator.pop(context);
    } else {
      // Affichage d'un message d'erreur en cas d'échec
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Contenu textuel du message d'erreur (personnalisé ou générique)
          content: Text(result['message'] ?? 'Erreur lors de la réinitialisation'),
          // Couleur de fond rouge pour indiquer l'erreur
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode pour créer une décoration uniforme pour tous les champs de saisie
  InputDecoration _buildInputDecoration(String label, IconData icon, {bool isPasswordField = false}) {
    return InputDecoration(
      // Texte du label affiché au-dessus du champ
      labelText: label,
      // Style appliqué au label (couleur gris clair)
      labelStyle: const TextStyle(color: Colors.white70),
      // Icône affichée à gauche du champ
      prefixIcon: Icon(icon, color: Colors.white70),
      // Icône optionnelle à droite pour les champs mot de passe
      suffixIcon: isPasswordField 
        ? IconButton(
            // Icône qui change selon l'état de visibilité
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.white70,
            ),
            // Action qui inverse l'état de visibilité au clic
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          )
        : null, // Pas d'icône suffixe pour les champs non mot de passe
      // Active le remplissage de fond du champ
      filled: true,
      // Couleur de fond du champ (gris foncé)
      fillColor: const Color(0xFF2A2A2A),
      // Configuration de la bordure du champ
      border: OutlineInputBorder(
        // Coins arrondis de la bordure
        borderRadius: BorderRadius.circular(12),
        // Suppression de la ligne de bordure visible
        borderSide: BorderSide.none,
      ),
    );
  }

  // Méthode appelée automatiquement lors de la destruction du widget
  @override
  void dispose() {
    // Nettoyage du contrôleur email pour éviter les fuites de mémoire
    _emailController.dispose();
    // Nettoyage du contrôleur mot de passe
    _passwordController.dispose();
    // Nettoyage du contrôleur confirmation mot de passe
    _confirmPasswordController.dispose();
    // Appel de la méthode dispose de la classe parente
    super.dispose();
  }

  // Méthode principale de construction de l'interface utilisateur
  @override
  Widget build(BuildContext context) {
    // Retourne un Scaffold qui fournit la structure de base de l'écran
    return Scaffold(
      // Définition de la couleur de fond de l'écran (noir profond)
      backgroundColor: const Color(0xFF1A1A1A),
      // Configuration de la barre d'application en haut de l'écran
      appBar: AppBar(
        // Couleur de fond de la barre d'application 
        backgroundColor: const Color(0xFF1A1A1A),
        // Suppression de l'ombre sous la barre pour un look plat
        elevation: 0,
        // Configuration du bouton de retour à gauche
        leading: IconButton(
          // Icône de flèche vers la gauche pour le retour
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          // Action qui renvoie à l'écran précédent
          onPressed: () => Navigator.pop(context),
        ),
        // Titre centré dans la barre d'application
        title: const Text('Réinitialisation', style: TextStyle(color: Colors.white)),
      ),
      // Corps principal de l'écran
      body: SafeArea(
        // SafeArea évite que le contenu soit masqué par les encoches/barres système
        child: SingleChildScrollView(
          // Permet le défilement vertical si le contenu dépasse l'écran
          padding: const EdgeInsets.all(24),
          // Conteneur principal avec formulaire
          child: Form(
            // Association de la clé globale au formulaire pour la validation
            key: _formKey,
            // Colonne pour organiser les éléments verticalement
            child: Column(
              // Liste des widgets enfants disposés verticalement
              children: [
                // Conteneur pour l'icône principale de réinitialisation
                Container(
                  // Espacement interne autour de l'icône
                  padding: const EdgeInsets.all(20),
                  // Décoration visuelle du conteneur
                  decoration: const BoxDecoration(
                    // Couleur de fond bleue
                    color: Colors.blue,
                    // Forme circulaire
                    shape: BoxShape.circle,
                  ),
                  // Icône de cadenas avec réinitialisation
                  child: const Icon(Icons.lock_reset, size: 50, color: Colors.white),
                ),
                // Espace vertical de séparation
                const SizedBox(height: 24),
                // Titre principal de l'écran
                const Text(
                  'Nouveau mot de passe',
                  // Style du texte : blanc, taille 22, gras
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                // Espace vertical plus important avant les champs
                const SizedBox(height: 30),

                // Premier champ : adresse email
                TextFormField(
                  // Association du contrôleur pour lier le champ aux données
                  controller: _emailController,
                  // Style du texte saisi par l'utilisateur (blanc)
                  style: const TextStyle(color: Colors.white),
                  // Application de la décoration personnalisée avec icône email
                  decoration: _buildInputDecoration('Email', Icons.email_outlined),
                  // Validation : vérifie la présence du caractère '@' pour un email valide
                  validator: (v) => v!.contains('@') ? null : 'Email invalide',
                ),
                // Espace vertical entre les champs
                const SizedBox(height: 20),

                // Deuxième champ : nouveau mot de passe
                TextFormField(
                  // Association du contrôleur pour le mot de passe
                  controller: _passwordController,
                  // Masquage du texte si la visibilité est désactivée
                  obscureText: !_isPasswordVisible,
                  // Style du texte saisi (blanc)
                  style: const TextStyle(color: Colors.white),
                  // Décoration personnalisée avec icône de clé et gestion de visibilité
                  decoration: _buildInputDecoration(
                    'Nouveau mot de passe', 
                    Icons.vpn_key_outlined, 
                    isPasswordField: true
                  ),
                  // Validation : longueur minimale de 6 caractères
                  validator: (v) => v!.length < 6 ? 'Minimum 6 caractères' : null,
                ),
                // Espace vertical entre les champs
                const SizedBox(height: 20),

                // Troisième champ : confirmation du mot de passe
                TextFormField(
                  // Association du contrôleur pour la confirmation
                  controller: _confirmPasswordController,
                  // Masquage du texte (même état que le champ précédent)
                  obscureText: !_isPasswordVisible,
                  // Style du texte saisi (blanc)
                  style: const TextStyle(color: Colors.white),
                  // Décoration personnalisée avec icône de validation
                  decoration: _buildInputDecoration(
                    'Confirmer le mot de passe', 
                    Icons.check_circle_outline,
                    isPasswordField: true
                  ),
                  // Validation : vérifie que les deux mots de passe saisis sont identiques
                  validator: (v) {
                    if (v != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),

                // Espace vertical avant le bouton d'action
                const SizedBox(height: 30),

                // Bouton de validation de la réinitialisation
                SizedBox(
                  // Largeur maximale disponible (prend toute la largeur de l'écran)
                  width: double.infinity,
                  // Hauteur fixe pour un bouton de taille standard
                  height: 54,
                  // Bouton élévé avec style personnalisé
                  child: ElevatedButton(
                    // Désactivation du bouton pendant le chargement, sinon appel de la fonction
                    onPressed: _isLoading ? null : _handleReset,
                    // Style visuel personnalisé du bouton
                    style: ElevatedButton.styleFrom(
                      // Couleur de fond bleue
                      backgroundColor: Colors.blue,
                      // Coins arrondis pour un design moderne
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    // Contenu du bouton : indicateur de chargement ou texte
                    child: _isLoading
                        // Indicateur circulaire de chargement quand l'opération est en cours
                        ? const CircularProgressIndicator(color: Colors.white)
                        // Texte du bouton quand aucune opération n'est en cours
                        : const Text(
                            'Mettre à jour',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}