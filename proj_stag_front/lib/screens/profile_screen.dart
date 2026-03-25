// Importation des bibliothèques Flutter de base pour l'interface utilisateur
import 'package:flutter/material.dart';
// Importation des services système pour gérer les interactions clavier
import 'package:flutter/services.dart';
// Importation de Provider pour la gestion d'état (pattern observateur)
import 'package:provider/provider.dart';

// Importation des providers personnalisés de l'application
import '../providers/vehicles_provider.dart';
// Importation du service d'authentification pour les appels API
import '../services/auth_service.dart';
// Importation des écrans de navigation
import 'login_screen.dart';
import 'my_bookings_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';

// Définition d'un widget avec état (StatefulWidget) pour l'écran de profil
// Ce widget accepte deux paramètres obligatoires : username et email
class ProfileScreen extends StatefulWidget {
  // Plus besoin de passer username/email en paramètre :
  // ProfileScreen lit directement depuis le Provider pour toujours avoir les données à jour
  ProfileScreen();

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

// Classe d'état qui gère la logique et l'interface de l'écran de profil
class _ProfileScreenState extends State<ProfileScreen> {
  // Variable booléenne pour gérer l'état de chargement
  bool _isLoading = false;
  
  // Contrôleurs pour les champs de texte modifiables
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  
  // Variables pour les statistiques utilisateur
  int _totalBookings = 0;     // Nombre total de réservations
  int _activeBookings = 0;    // Nombre de réservations actives/en cours
  int _totalFavorites = 0;    // Nombre de véhicules favoris
  
  // Variable pour stocker la date d'inscription formatée
  String _memberSince = '';
  
  // Contrôleurs pour gérer le défilement et le focus (hérités de HomeScreen)
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Méthode appelée une fois lors de la création de l'état
  @override
  void initState() {
    super.initState();
    // Date par défaut dynamique (mois/année actuel), sera écrasée par la vraie date du serveur
    _memberSince = _formatDateToMonthYear(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<VehiclesProvider>(context, listen: false);
      // Lecture toujours fraîche depuis le Provider
      _usernameController.text = provider.username ?? '';
      _emailController.text = provider.userEmail ?? '';
      _loadUserCreatedDate();
      _loadUserStats();
    });
  }
  
  // Méthode appelée lors de la destruction de l'état pour libérer les ressources
  @override
  void dispose() {
    // Libération des contrôleurs de défilement
    _scrollController.dispose();
    _focusNode.dispose();
    // Libération des contrôleurs de texte
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    // Appel de la méthode dispose de la classe parent
    super.dispose();
  }
  
  // Méthode pour charger la date de création depuis les données utilisateur
  void _loadUserCreatedDate() {
    // Récupération du provider sans écouter les changements (listen: false)
    final provider = Provider.of<VehiclesProvider>(context, listen: false);
    // Récupération des données utilisateur depuis le provider
    final userData = provider.user;
    
    // Vérification que les données existent et contiennent la date de création
    if (userData != null && userData.containsKey('created_at') && userData['created_at'] != null) {
      // Appel de la méthode pour parser et formater la date
      _parseAndSetCreatedDate(userData['created_at']);
    }
  }
  
  // Méthode pour parser différents formats de date et mettre à jour l'affichage
  void _parseAndSetCreatedDate(dynamic dateValue) {
    try {
      // Variable nullable pour stocker la date parsée
      DateTime? finalDate;
      
      // Si la valeur est une chaîne de caractères
      if (dateValue is String) {
        try {
          // Tentative de parsing au format 
          finalDate = DateTime.parse(dateValue);
        } catch (e) {
          try {
            // Tentative avec format alternatif (remplacement espace par T)
            //On remplace l’espace par un ‘T’ pour transformer la date en format ISO 8601, que DateTime.parse peut lire correctement
            finalDate = DateTime.parse(dateValue.replaceAll(' ', 'T'));
          } catch (e2) {
            // Log en cas d'échec des deux formats
            print('Format de date non reconnu: $dateValue');
            return;
          }
        }
      } else if (dateValue is DateTime) {
        // Si c'est déjà un objet DateTime, on l'utilise directement
        finalDate = dateValue;
      }
      
      // Si le parsing a réussi, mise à jour de l'interface
      if (finalDate != null) {
        setState(() {
          // Formatage de la date et mise à jour de la variable
          _memberSince = _formatDateToMonthYear(finalDate!);
        });
      }
    } catch (e) {
      // Log en cas d'erreur générale
      print('Erreur lors du parsing de la date: $e');
    }
  }
  
  // Méthode pour formater un DateTime en "Mois Année" en français
  String _formatDateToMonthYear(DateTime date) {
    // Tableau des noms de mois en français
    final monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    // Retourne le mois (index -1 car les mois commencent à 1) et l'année
    return '${monthNames[date.month - 1]} ${date.year}';
  }
  
  // Méthode pour défilement vers le haut (utilisée avec les touches clavier)
  void _scrollUp() {
    // Vérifie que le contrôleur est attaché à un widget
    if (_scrollController.hasClients) {
      // Animation de défilement
      _scrollController.animateTo(
        // Déplacement de 150 pixels vers le haut
        _scrollController.offset - 150,
        // Durée de l'animation
        duration: Duration(milliseconds: 200),
        // Courbe d'animation pour un effet fluide
        curve: Curves.easeOut,
      );
    }
  }

  // Méthode pour défilement vers le bas (utilisée avec les touches clavier)
  void _scrollDown() {
    // Vérifie que le contrôleur est attaché à un widget
    if (_scrollController.hasClients) {
      // Animation de défilement
      _scrollController.animateTo(
        // Déplacement de 150 pixels vers le bas
        _scrollController.offset + 150,
        // Durée de l'animation
        duration: Duration(milliseconds: 200),
        // Courbe d'animation pour un effet fluide
        curve: Curves.easeOut,
      );
    }
  }

  // Méthode asynchrone pour charger les statistiques utilisateur
  Future<void> _loadUserStats() async {
    // Récupération du token depuis le provider
    final token = Provider.of<VehiclesProvider>(context, listen: false).token;
    // Si pas de token, on arrête l'exécution
    if (token == null) return;

    // Activation de l'indicateur de chargement
    setState(() => _isLoading = true);

    try {
      // Appels API parallèles pour récupérer les réservations et favoris
      final bookings = await AuthService.fetchMyBookings(token);
      final favorites = await AuthService.getFavorites(token);
      
      // Mise à jour de l'état avec les nouvelles données
      setState(() {
        // Nombre total de réservations
        _totalBookings = bookings.length;
        // Compte les réservations avec statut actif
        _activeBookings = bookings.where((b) => 
          b['status'] == 'En attente' || b['status'] == 'Confirmée'
        ).length;
        // Nombre total de favoris
        _totalFavorites = favorites.length;
        // Désactivation de l'indicateur de chargement
        _isLoading = false;
      });
    } catch (e) {
      // En cas d'erreur, on désactive le chargement et on log l'erreur
      setState(() => _isLoading = false);
      print('Erreur chargement stats: $e');
    }
  }

  // Méthode asynchrone pour mettre à jour le profil utilisateur
  Future<void> _updateProfile() async {
    // Récupération du token depuis le provider
    final token = Provider.of<VehiclesProvider>(context, listen: false).token;
    // Vérification que l'utilisateur est connecté
    if (token == null) {
      // Affichage d'un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous devez être connecté'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation : nom d'utilisateur non vide
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Le nom d\'utilisateur est requis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation : email non vide et contenant un @
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email invalide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation : si nouveau mot de passe saisi, l'actuel doit l'être aussi
    if (_newPasswordController.text.isNotEmpty && _currentPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez entrer votre mot de passe actuel pour changer le mot de passe'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Activation de l'indicateur de chargement
    setState(() => _isLoading = true);

    try {
      // Préparation des données à envoyer à l'API
      final Map<String, dynamic> updateData = {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
      };

      // Ajout du mot de passe actuel si fourni
      if (_currentPasswordController.text.isNotEmpty) {
        updateData['current_password'] = _currentPasswordController.text;
      }
      
      // Ajout du nouveau mot de passe si fourni
      if (_newPasswordController.text.isNotEmpty) {
        updateData['new_password'] = _newPasswordController.text;
      }

      // Log des données envoyées pour débogage
      print('Données envoyées: $updateData');

      // Appel API pour mettre à jour le profil
      final result = await AuthService.updateProfile(updateData, token);

      // Log de la réponse pour débogage
      print(' Résultat API: $result');

      // Si la mise à jour a réussi
      if (result['success'] == true && result['user'] != null) {
        // Récupération du nouveau token (crucial si l'email a changé)
        final String updatedToken = result['new_token'] ?? token;
        // Mise à jour des données ET du token dans le provider
        Provider.of<VehiclesProvider>(context, listen: false).setUser(result['user'], updatedToken);
        
        // Mise à jour de la date de création si présente dans la réponse
        if (result['user'].containsKey('created_at') && result['user']['created_at'] != null) {
          _parseAndSetCreatedDate(result['user']['created_at']);
        }
      }

      // Mise à jour de l'état : désactivation chargement et nettoyage champs mot de passe
      setState(() {
        _isLoading = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
      });

      // Affichage d'un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Rechargement des statistiques pour refléter les éventuels changements
      await _loadUserStats();
      
    } catch (e) {
      // En cas d'erreur, désactivation du chargement et affichage d'erreur
      setState(() => _isLoading = false);
      print(' Erreur mise à jour profil: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Méthode asynchrone pour déconnecter l'utilisateur
  Future<void> _logout() async {
    // Affichage d'une boîte de dialogue de confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2A2A2A),
        title: Text('Déconnexion', style: TextStyle(color: Colors.white)),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          // Bouton Annuler
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          // Bouton Déconnexion
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // Si l'utilisateur a confirmé la déconnexion
    if (confirm == true) {
      // Effacement des données utilisateur dans le provider
      Provider.of<VehiclesProvider>(context, listen: false).clearUser();
      
      // Navigation vers l'écran de connexion et suppression de l'historique
      //pushAndRemoveUntil:ouvrir une nouvelle page ET supprimer les anciennes pages de la pile
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
      
      // Affichage d'un message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Déconnexion réussie'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Méthode build principale qui construit l'interface utilisateur
  @override
  Widget build(BuildContext context) {
    // Récupération du provider et vérification du statut admin
    final provider = Provider.of<VehiclesProvider>(context);
    final isAdmin = provider.isAdmin;

    // Construction du Scaffold (structure de base de l'écran)
    return Scaffold(
      // Couleur de fond noir
      backgroundColor: Color(0xFF1A1A1A),
      // Configuration de l'AppBar (barre d'en-tête)
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        title: Text('Mon Profil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Corps de l'écran : soit un indicateur de chargement, soit le contenu
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blue))
          : RawKeyboardListener(
              focusNode: _focusNode,
              autofocus: true,
              // Gestion des événements clavier pour le défilement
              onKey: (event) {
                if (event is RawKeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    _scrollUp();
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    _scrollDown();
                  }
                }
              },
              // Zone défilable principale
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // En-tête du profil avec avatar
                    _buildProfileHeader(isAdmin),
                    
                    SizedBox(height: 24),
                    
                    // Section des statistiques
                    _buildStatsSection(),
                    
                    SizedBox(height: 24),
                    
                    // Section des informations personnelles
                    _buildSectionTitle('Mes informations'),
                    SizedBox(height: 12),
                    _buildInfoCard(),
                    
                    SizedBox(height: 24),
                    
                    // Section de modification du compte
                    _buildSectionTitle('Modifier mon compte'),
                    SizedBox(height: 12),
                    _buildEditProfileSection(),
                    
                    SizedBox(height: 24),
                    
                    // Section des accès rapides
                    _buildSectionTitle('Accès rapides'),
                    SizedBox(height: 12),
                    _buildQuickAccessSection(),
                    
                    SizedBox(height: 24),
                    
                    // Section À propos
                    _buildSectionTitle('À propos et informations'),
                    SizedBox(height: 12),
                    _buildAboutInfoSection(),
                    
                    SizedBox(height: 24),
                    
                    // Bouton de déconnexion
                    _buildLogoutButton(),
                    
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // Méthode pour construire l'en-tête du profil
  Widget _buildProfileHeader(bool isAdmin) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Stack pour superposer l'avatar et le badge admin
          Stack(
            children: [
              // Avatar circulaire
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Text(
                  _usernameController.text.isNotEmpty 
                      ? _usernameController.text[0].toUpperCase() 
                      : 'U',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              // Badge admin conditionnel
              if (isAdmin)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(Icons.verified, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Nom d'utilisateur
          Text(
            _usernameController.text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: 4),
          
          // Email
          Text(
            _emailController.text,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          
          SizedBox(height: 8),
          
          // Badge de statut (Admin ou Membre)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isAdmin ? Colors.amber : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.person,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  isAdmin ? 'Administrateur' : 'Membre',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour construire la section des statistiques
  Widget _buildStatsSection() {
    return Row(
      children: [
        // Carte des réservations totales
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today,
            value: _totalBookings.toString(),
            label: 'Réservations',
            color: Colors.blue,
          ),
        ),
        SizedBox(width: 12),
        // Carte des réservations en cours
        Expanded(
          child: _buildStatCard(
            icon: Icons.pending_actions,
            value: _activeBookings.toString(),
            label: 'En cours',
            color: Colors.orange,
          ),
        ),
        SizedBox(width: 12),
        // Carte des favoris
        Expanded(
          child: _buildStatCard(
            icon: Icons.favorite,
            value: _totalFavorites.toString(),
            label: 'Favoris',
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  // Méthode pour construire une carte de statistique individuelle
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          // Icône de la statistique
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          // Valeur numérique
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          // Libellé descriptif
          Text(
            label,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Méthode pour construire un titre de section aligné à gauche
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Méthode pour construire la carte d'informations personnelles
  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.person_outline, 'Nom d\'utilisateur', _usernameController.text),
          Divider(color: Colors.white12, height: 24),
          _buildInfoRow(Icons.email_outlined, 'Adresse email', _emailController.text),
          Divider(color: Colors.white12, height: 24),
          _buildInfoRow(Icons.verified_user_outlined, 'Statut du compte', 'Actif', 
            valueColor: Colors.green),
          Divider(color: Colors.white12, height: 24),
          _buildInfoRow(Icons.cake_outlined, 'Membre depuis', _memberSince),
        ],
      ),
    );
  }

  // Méthode pour construire une ligne d'information
  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Container(
      child: Row(
        children: [
          // Icône de la ligne
          Icon(icon, color: Colors.blue, size: 20),
          SizedBox(width: 12),
          // Colonne pour le label et la valeur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label en petit texte gris
                Text(
                  label,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                SizedBox(height: 4),
                // Valeur en texte blanc (ou couleur spécifique)
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour construire la section d'édition du profil
  Widget _buildEditProfileSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Champ de texte pour le nom d'utilisateur
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Nom d\'utilisateur',
              labelStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.person_outline, color: Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            style: TextStyle(color: Colors.white),
          ),
          
          SizedBox(height: 16),
          
          // Champ de texte pour l'email
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Adresse email',
              labelStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.email_outlined, color: Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            style: TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
          ),
          
          SizedBox(height: 16),
          
          // Champ de texte pour le mot de passe actuel
          TextField(
            controller: _currentPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Mot de passe actuel (pour changement)',
              labelStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.lock_outline, color: Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            style: TextStyle(color: Colors.white),
          ),
          
          SizedBox(height: 16),
          
          // Champ de texte pour le nouveau mot de passe
          TextField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Nouveau mot de passe (optionnel)',
              labelStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.lock_reset, color: Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            style: TextStyle(color: Colors.white),
          ),
          
          SizedBox(height: 24),
          
          // Bouton d'enregistrement des modifications
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Enregistrer les modifications',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          // Avertissement concernant le changement d'email
          Text(
            '⚠️ Après modification de l\'email, utilisez le nouvel email pour vous reconnecter',
            style: TextStyle(color: Colors.orange, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Méthode pour construire la section des accès rapides
  Widget _buildQuickAccessSection() {
    return Column(
      children: [
        // Bouton pour les réservations
        _buildQuickAccessButton(
          icon: Icons.calendar_today,
          title: 'Mes Réservations',
          subtitle: 'Voir l\'historique complet',
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyBookingsScreen()),
            );
          },
        ),
        SizedBox(height: 12),
        // Bouton pour les favoris
        _buildQuickAccessButton(
          icon: Icons.favorite,
          title: 'Mes Favoris',
          subtitle: 'Voitures sauvegardées',
          color: Colors.red,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FavoritesScreen()),
            );
          },
        ),
        SizedBox(height: 12),
        // Bouton pour l'accueil
        _buildQuickAccessButton(
          icon: Icons.home,
          title: 'Accueil',
          subtitle: 'Réserver une voiture',
          color: Colors.green,
          onTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ],
    );
  }

  // Méthode pour construire un bouton d'accès rapide
  Widget _buildQuickAccessButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icône dans un conteneur arrondi
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            // Titre et sous-titre
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Icône flèche indicatrice
            Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
          ],
        ),
      ),
    );
  }

  // Méthode pour construire la section "À propos et informations"
  Widget _buildAboutInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Version de l'application
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Version de l\'application',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(left: 34),
                  child: Text(
                    '1.0.0',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Divider(color: Colors.white12, height: 20),
          
          // Site web
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.language, color: Colors.blue, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Site web',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(left: 34),
                  child: Text(
                    'www.carrental-tn.com',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Divider(color: Colors.white12, height: 20),
          
          // Contact téléphonique
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.phone, color: Colors.blue, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Contact',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(left: 34),
                  child: Text(
                    '(+216) 71 234 567',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Divider(color: Colors.white12, height: 20),
          
          // Email de contact
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.email, color: Colors.blue, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Email de contact',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(left: 34),
                  child: Text(
                    'contact@carrental-tn.com',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour construire le bouton de déconnexion
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(Icons.logout, color: Colors.white),
        label: Text(
          'Se déconnecter',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}