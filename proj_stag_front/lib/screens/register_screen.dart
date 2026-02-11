// Import du package Material Design de Flutter pour utiliser les widgets d'interface utilisateur
import 'package:flutter/material.dart';
// Import du service d'authentification qui contient les méthodes pour appeler les API d'inscription
import '../services/auth_service.dart';

// Définition de la classe RegisterScreen qui hérite de StatefulWidget
// StatefulWidget car cet écran nécessite une gestion d'état (champs de texte, chargement, etc.)
class RegisterScreen extends StatefulWidget {
  @override
  // Méthode obligatoire qui crée l'état associé à ce widget
  // _RegisterScreenState contient la logique et les variables d'état
  _RegisterScreenState createState() => _RegisterScreenState();
}

// Classe d'état qui gère les données et la logique de l'écran d'inscription
// Étend State avec RegisterScreen comme type générique
class _RegisterScreenState extends State<RegisterScreen> {
  // Clé globale pour identifier et manipuler le formulaire dans l'arbre des widgets
  final _formKey = GlobalKey<FormState>();
  // Contrôleur pour le champ de texte du nom d'utilisateur
  // Permet de lire/écrire la valeur et de gérer le focus
  final _usernameController = TextEditingController();
  // Contrôleur pour le champ de texte de l'email
  final _emailController = TextEditingController();
  // Contrôleur pour le champ de texte du mot de passe
  final _passwordController = TextEditingController();
  // Contrôleur pour le champ de confirmation du mot de passe
  final _confirmController = TextEditingController();
  // Variable booléenne qui indique si l'inscription est en cours (pour afficher un indicateur de chargement)
  bool _isLoading = false;
  // Variable booléenne qui contrôle si le mot de passe doit être visible ou masqué
  bool _showPassword = false;
  // Variable booléenne qui contrôle si la confirmation du mot de passe doit être visible ou masqué
  bool _showConfirm = false;

  // Méthode asynchrone qui gère le processus d'inscription
  // async indique que la méthode contient des opérations asynchrones
  Future<void> _register() async {
    // Vérifie la validité de tous les champs du formulaire
    // Si un champ est invalide, la méthode s'arrête ici
    if (!_formKey.currentState!.validate()) return;
    
    // Vérification manuelle que les deux mots de passe saisis sont identiques
    if (_passwordController.text != _confirmController.text) {
      // Affiche un message d'erreur sous forme de snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Texte du message d'erreur
          content: Text('Les mots de passe ne correspondent pas'),
          // Couleur de fond rouge pour indiquer une erreur
          backgroundColor: Colors.red,
        ),
      );
      // Arrête l'exécution de la méthode car les mots de passe ne correspondent pas
      return;
    }
    
    // Active l'indicateur de chargement en mettant à jour l'état du widget
    setState(() => _isLoading = true);
    
    // Appelle la méthode register du AuthService avec les données saisies
    // Attend la réponse de l'API (await)
    final result = await AuthService.register(
      // Valeur du champ nom d'utilisateur
      _usernameController.text,
      // Valeur du champ email
      _emailController.text,
      // Valeur du champ mot de passe
      _passwordController.text,
    );
    
    // Désactive l'indicateur de chargement une fois l'appel terminé
    setState(() => _isLoading = false);
    
    // Traite le résultat retourné par l'API
    if (result['success']) {
      // Si l'inscription réussit, affiche un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Texte du message de succès
          content: Text('Inscription réussie! Vous pouvez vous connecter.'),
          // Couleur de fond verte pour indiquer le succès
          backgroundColor: Colors.green,
        ),
      );
      // Retourne à l'écran précédent (généralement l'écran de connexion)
      Navigator.pop(context);
    } else {
      // Si l'inscription échoue, affiche un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Texte d'erreur détaillé, utilise 'detail' ou 'message' de la réponse
          content: Text('Erreur: ${result['data']['detail'] ?? result['message']}'),
          // Couleur de fond rouge pour indiquer une erreur
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  // Méthode build qui construit l'interface utilisateur
  // Appelée à chaque fois que l'état change (setState)
  Widget build(BuildContext context) {
    // Retourne un Scaffold qui fournit la structure de base d'un écran Material Design
    return Scaffold(
      // Définit la couleur de fond de l'écran en noir
      backgroundColor: Color(0xFF1A1A1A),
      // Barre d'application en haut de l'écran
      appBar: AppBar(
        // Définit la couleur de fond de la barre d'application
        backgroundColor: Color(0xFF1A1A1A),
        // Supprime l'ombre sous la barre pour un look plat
        elevation: 0,
        // Bouton de retour sur le côté gauche de la barre
        leading: IconButton(
          // Icône de flèche retour
          icon: Icon(Icons.arrow_back, color: Colors.white),
          // Action lors du clic : retourne à l'écran précédent
          onPressed: () => Navigator.pop(context),
        ),
        // Titre de la barre d'application
        title: Text('Inscription', style: TextStyle(color: Colors.white)),
      ),
      // Corps principal de l'écran
      body: SafeArea(
        // SafeArea évite que le contenu soit masqué par les encoches ou barres système
        child: SingleChildScrollView(
          // Permet le défilement vertical si le contenu dépasse la hauteur de l'écran
          padding: EdgeInsets.all(24),
          // Enfant unique : le formulaire d'inscription
          child: Form(
            // Associe la clé globale au formulaire pour la validation
            key: _formKey,
            // Contenu du formulaire organisé en colonne
            child: Column(
              // Liste des widgets enfants dans la colonne
              children: [
                // Container pour le logo/icône d'inscription
                Container(
                  // Espacement interne autour de l'icône
                  padding: EdgeInsets.all(20),
                  // Décoration visuelle du container
                  decoration: BoxDecoration(
                    // Couleur de fond bleue
                    color: Colors.blue,
                    // Forme circulaire
                    shape: BoxShape.circle,
                  ),
                  // Icône d'ajout d'utilisateur
                  child: Icon(Icons.person_add, size: 50, color: Colors.white),
                ),
                // Espacement vertical entre le logo et le titre
                SizedBox(height: 24),
                
                // Titre principal de l'écran
                Text(
                  'Créer un compte',
                  style: TextStyle(
                    // Couleur du texte en blanc
                    color: Colors.white,
                    // Taille de police
                    fontSize: 24,
                    // Police en gras
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Petit espacement vertical
                SizedBox(height: 8),
                // Sous-titre
                Text(
                  'Rejoignez CarRental Tunisia',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                // Espacement vertical plus important avant les champs de saisie
                SizedBox(height: 30),
                
                // Champ de saisie pour le nom d'utilisateur
                TextFormField(
                  // Associe le contrôleur à ce champ
                  controller: _usernameController,
                  // Style du texte saisi par l'utilisateur
                  style: TextStyle(color: Colors.white),
                  // Configuration de l'apparence du champ
                  decoration: InputDecoration(
                    // Texte du label (au-dessus du champ quand il est vide)
                    labelText: "Nom d'utilisateur",
                    // Style du label
                    labelStyle: TextStyle(color: Colors.white70),
                    // Icône à gauche du champ
                    prefixIcon: Icon(Icons.person_outline, color: Colors.white70),
                    // Active le remplissage de fond
                    filled: true,
                    // Couleur de fond du champ
                    fillColor: Color(0xFF2A2A2A),
                    // Configuration de la bordure par défaut
                    border: OutlineInputBorder(
                      // Coins arrondis
                      borderRadius: BorderRadius.circular(12),
                      // Pas de bordure visible par défaut
                      borderSide: BorderSide.none,
                    ),
                    // Bordure quand le champ est activé mais non sélectionné
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      // Bordure gris clair fine
                      borderSide: BorderSide(color: Colors.white24, width: 1),
                    ),
                    // Bordure quand le champ est sélectionné (focus)
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      // Bordure bleue épaisse pour indiquer le focus
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  // Fonction de validation qui s'exécute quand on soumet le formulaire
                  validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                ),
                // Espacement vertical entre les champs
                SizedBox(height: 16),
                
                // Champ de saisie pour l'email
                TextFormField(
                  // Contrôleur pour ce champ
                  controller: _emailController,
                  // Style du texte saisi
                  style: TextStyle(color: Colors.white),
                  // Configuration de l'apparence
                  decoration: InputDecoration(
                    // Label du champ
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white70),
                    // Icône d'email
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.white70),
                    // Remplissage de fond
                    filled: true,
                    // Couleur de fond
                    fillColor: Color(0xFF2A2A2A),
                    // Bordure par défaut
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    // Bordure activée
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white24, width: 1),
                    ),
                    // Bordure en focus
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  // Validation basique : vérifie la présence de '@'
                  validator: (v) => v!.contains('@') ? null : 'Email invalide',
                ),
                // Espacement vertical
                SizedBox(height: 16),
                
                // Champ de saisie pour le mot de passe
                TextFormField(
                  // Contrôleur
                  controller: _passwordController,
                  // Style
                  style: TextStyle(color: Colors.white),
                  // Décoration
                  decoration: InputDecoration(
                    // Label
                    labelText: 'Mot de passe',
                    labelStyle: TextStyle(color: Colors.white70),
                    // Icône de cadenas
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.white70),
                    // Fond
                    filled: true,
                    fillColor: Color(0xFF2A2A2A),
                    // Bordures
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white24, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                    // Bouton à droite pour basculer la visibilité
                    suffixIcon: IconButton(
                      // Change d'icône selon l'état
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      // Action : inverse l'état de visibilité
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  // Masque le texte si _showPassword est false
                  obscureText: !_showPassword,
                  // Validation : minimum 6 caractères
                  validator: (v) => v!.length < 6 ? 'Minimum 6 caractères' : null,
                ),
                // Espacement vertical
                SizedBox(height: 16),
                
                // Champ de confirmation du mot de passe
                TextFormField(
                  // Contrôleur
                  controller: _confirmController,
                  // Style
                  style: TextStyle(color: Colors.white),
                  // Décoration
                  decoration: InputDecoration(
                    // Label
                    labelText: 'Confirmer le mot de passe',
                    labelStyle: TextStyle(color: Colors.white70),
                    // Icône
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.white70),
                    // Fond
                    filled: true,
                    fillColor: Color(0xFF2A2A2A),
                    // Bordures
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white24, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                    // Bouton de visibilité
                    suffixIcon: IconButton(
                      // Icône conditionnelle
                      icon: Icon(
                        _showConfirm ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      // Action
                      onPressed: () => setState(() => _showConfirm = !_showConfirm),
                    ),
                  ),
                  // Masquage conditionnel
                  obscureText: !_showConfirm,
                  // Validation simple
                  validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                ),
                // Espacement vertical avant le bouton
                SizedBox(height: 30),
                
                // Bouton d'inscription
                SizedBox(
                  // Prend toute la largeur disponible
                  width: double.infinity,
                  // Hauteur fixe
                  height: 54,
                  // Bouton élévé (Material Design)
                  child: ElevatedButton(
                    // Désactivé pendant le chargement, sinon appelle _register
                    onPressed: _isLoading ? null : _register,
                    // Style personnalisé
                    style: ElevatedButton.styleFrom(
                      // Couleur de fond bleue
                      backgroundColor: Colors.blue,
                      // Forme avec coins arrondis
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      // Pas d'ombre
                      elevation: 0,
                    ),
                    // Contenu du bouton
                    child: _isLoading
                        // Si chargement en cours, affiche un indicateur circulaire
                        ? CircularProgressIndicator(color: Colors.white)
                        // Sinon affiche le texte normal
                        : Text(
                            "S'inscrire",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                // Espacement après le bouton
                SizedBox(height: 20),
                
                // Ligne pour le lien vers la connexion
                Row(
                  // Centre les éléments horizontalement
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Texte informatif
                    Text(
                      'Vous avez déjà un compte? ',
                      style: TextStyle(color: Colors.white70),
                    ),
                    // Bouton texte pour aller à la connexion
                    TextButton(
                      // Retourne à l'écran précédent (connexion)
                      onPressed: () => Navigator.pop(context),
                      // Texte du bouton
                      child: Text(
                        'Se connecter',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}