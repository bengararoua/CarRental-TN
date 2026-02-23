// Import du package Material Design de Flutter pour les widgets UI
import 'package:flutter/material.dart';
// Import du package services pour accéder aux fonctionnalités système (clavier, etc.)
import 'package:flutter/services.dart';
// Import de l'écran affichant toutes les voitures
import 'all_vehicules_screen.dart';
// Import de l'écran de réservation
import 'booking_screen.dart';
// Import de l'écran des favoris
import 'favorites_screen.dart';
// Import de l'écran des réservations personnelles
import 'my_bookings_screen.dart';
// Import de l'écran d'administration des réservations
import 'admin_bookings_screen.dart';
// Import du package Provider pour la gestion d'état
import 'package:provider/provider.dart';
// Import du provider des véhicules
import '../providers/vehicles_provider.dart';
// Import de l'écran de profil
import 'profile_screen.dart';
// Import de l'écran assistant
import 'assistant_screen.dart';

// Définition de l'écran d'accueil (StatefulWidget car gestion d'état complexe)
class HomeScreen extends StatefulWidget {
  // Variable pour stocker l'email de l'utilisateur (passée depuis l'écran de connexion)
  final String userEmail;
  // Variable pour stocker le nom d'utilisateur (passée depuis l'écran de connexion)
  final String username;

  // Constructeur qui requiert les informations utilisateur
  HomeScreen({required this.userEmail, required this.username});

  @override
  // Crée l'état associé à ce widget
  _HomeScreenState createState() => _HomeScreenState();
}

// Classe d'état pour gérer les variables et la logique de l'écran d'accueil
class _HomeScreenState extends State<HomeScreen> {
  // Contrôleur pour gérer le défilement vertical de la page principale
  final ScrollController _verticalScrollController = ScrollController();
  // Contrôleur pour le défilement horizontal de la section "Nouveautés"
  final ScrollController _newVehiclesScrollController = ScrollController();
  // Contrôleur pour le défilement horizontal de la section "Plus demandées"
  final ScrollController _mostPopularScrollController = ScrollController();
  // Contrôleur pour le défilement horizontal de la section "Meilleurs choix"
  final ScrollController _bestChoicesScrollController = ScrollController();
  // Contrôleur pour le défilement horizontal de la section filtrée par catégorie
  final ScrollController _filteredVehiclesScrollController = ScrollController();
  // Nœud de focus pour capturer les événements clavier
  final FocusNode _focusNode = FocusNode();
  // Index de l'élément actuellement sélectionné dans la barre de navigation inférieure
  int _selectedIndex = 0;
  // Catégorie de véhicules sélectionnée pour filtrer (initialisée à "Tous")
  String _selectedCategory = 'Tous';
  // Liste des catégories disponibles pour le filtrage
  final List<String> _categories = ['Tous', 'Économique', 'Citadine', 'Familiale', 'Compacte', 'SUV'];

  @override
  // Méthode appelée automatiquement lors de l'initialisation du widget
  void initState() {
    // Appelle la méthode initState de la classe parente (State)
    super.initState();
    // Utilise un callback pour charger les véhicules après le premier rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Charge les véhicules via le provider
      Provider.of<VehiclesProvider>(context, listen: false).loadVehicles();
    });
  }

  // Fonction pour basculer l'état "favori" d'un véhicule
  void _toggleFavorite(Map<String, dynamic> vehicle) {
    // Appelle la méthode toggleFavorite du provider
    Provider.of<VehiclesProvider>(context, listen: false).toggleFavorite(vehicle['id']);
    // Affiche un message snackbar pour confirmer l'action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // Contenu du message avec confirmation d'ajout ou retrait
        content: Text(
          vehicle['isFavorite']
              ? '${vehicle['name']} ajouté des favoris❤️' // Si déjà favori (retrait)
              : '${vehicle['name']} retiré aux favoris ' // Si pas favori (ajout)
        ),
        // Couleur de fond différente selon l'action
        backgroundColor: vehicle['isFavorite'] ? Colors.red : Colors.grey,
        // Durée d'affichage du message (1 seconde)
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Fonction pour défiler vers le haut (défilement vertical)
  void _scrollUp() {
    // Vérifie si le contrôleur est attaché à un widget
    if (_verticalScrollController.hasClients) {
      // Anime le défilement vers le haut de 150 pixels
      _verticalScrollController.animateTo(
        // Nouvelle position (position actuelle moins 150 pixels)
        _verticalScrollController.offset - 150,
        // Durée de l'animation (200 millisecondes)
        duration: Duration(milliseconds: 200),
        // Courbe d'animation pour un effet progressif
        curve: Curves.easeOut,
      );
    }
  }

  // Fonction pour défiler vers le bas (défilement vertical)
  void _scrollDown() {
    // Vérifie si le contrôleur est attaché à un widget
    if (_verticalScrollController.hasClients) {
      // Anime le défilement vers le bas de 150 pixels
      _verticalScrollController.animateTo(
        // Nouvelle position (position actuelle plus 150 pixels)
        _verticalScrollController.offset + 150,
        // Durée de l'animation (200 millisecondes)
        duration: Duration(milliseconds: 200),
        // Courbe d'animation pour un effet progressif
        curve: Curves.easeOut,
      );
    }
  }

  // Fonction pour défiler vers la gauche (défilement horizontal)
  void _scrollLeft(ScrollController controller) {
    // Vérifie si le contrôleur est attaché à un widget
    if (controller.hasClients) {
      // Anime le défilement vers la gauche de 300 pixels
      controller.animateTo(
        // Nouvelle position (position actuelle moins 300 pixels)
        controller.offset - 300,
        // Durée de l'animation (300 millisecondes)
        duration: Duration(milliseconds: 300),
        // Courbe d'animation pour un effet plus doux
        curve: Curves.easeInOut,
      );
    }
  }

  // Fonction pour défiler vers la droite (défilement horizontal)
  void _scrollRight(ScrollController controller) {
    // Vérifie si le contrôleur est attaché à un widget
    if (controller.hasClients) {
      // Anime le défilement vers la droite de 300 pixels
      controller.animateTo(
        // Nouvelle position (position actuelle plus 300 pixels)
        controller.offset + 300,
        // Durée de l'animation (300 millisecondes)
        duration: Duration(milliseconds: 300),
        // Courbe d'animation pour un effet plus doux
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  // Méthode appelée automatiquement lors de la destruction du widget
  void dispose() {
    // Nettoyage des contrôleurs pour éviter les fuites de mémoire
    _verticalScrollController.dispose();
    _newVehiclesScrollController.dispose();
    _mostPopularScrollController.dispose();
    _bestChoicesScrollController.dispose();
    _filteredVehiclesScrollController.dispose();
    _focusNode.dispose();
    // Appelle la méthode dispose de la classe parente (State)
    super.dispose();
  }

  @override
  // Méthode principale qui construit l'interface utilisateur
  Widget build(BuildContext context) {
    // Utilisation de Consumer pour écouter les changements du VehiclesProvider
    return Consumer<VehiclesProvider>(
      // Builder qui reconstruit le widget quand le provider change
      builder: (context, provider, child) {
        // Retourne un Scaffold (structure de base d'un écran)
        return Scaffold(
          // Définit la couleur de fond de l'écran (noir)
          backgroundColor: Color(0xFF1A1A1A),
          // Définit la barre d'application en haut de l'écran
          appBar: AppBar(
            // Définit la couleur de fond de la barre d'application (noir)
            backgroundColor: Color(0xFF1A1A1A),
            // Supprime l'ombre sous la barre d'application
            elevation: 0,
            // Contenu de la barre d'application (titre et actions)
            title: Row(
              // Aligne les éléments horizontalement
              children: [
                // Icône de voiture avec couleur bleue
                Icon(Icons.directions_car, color: Colors.blue, size: 28),
                // Espacement de 8 pixels entre l'icône et le texte
                SizedBox(width: 8),
                // Titre de l'application
                Text('CarRental TN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            // Actions à droite de la barre d'application (icônes)
            actions: [
              // ========== BOUTON ADMIN (VISIBLE UNIQUEMENT POUR LES ADMINS) ==========
              // Utilise Consumer pour accéder au provider dans le contexte
              Consumer<VehiclesProvider>(
                // Builder qui reconstruit le bouton admin selon le rôle utilisateur
                builder: (context, provider, child) {
                  // CONDITION STRICTE: affiche UNIQUEMENT si l'utilisateur est admin
                  if (provider.isAdmin) {
                    // Message de debug dans la console
                    print('✅ Utilisateur admin détecté, affichage du bouton');
                    // Retourne le bouton admin
                    return IconButton(
                      // Icône des paramètres admin avec couleur ambre
                      icon: Icon(Icons.admin_panel_settings, color: Colors.amber),
                      // Texte d'infobulle au survol
                      tooltip: 'Gestion des Réservations (Admin)',
                      // Action lors du clic sur le bouton
                      onPressed: () {
                        // Message de debug dans la console
                        print('🔧 Navigation vers AdminBookingsScreen');
                        // Navigation vers l'écran d'administration des réservations
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AdminBookingsScreen()),
                        );
                      },
                    );
                  } else {
                    // Si pas admin, ne rien afficher du tout
                    // Message de debug dans la console
                    print('❌ Utilisateur non-admin (rôle: ${provider.userRole}), bouton masqué');
                    // Retourne un widget invisible (qui ne prend pas de place)
                    //shrink() force le widget à se réduire à la taille minimale nécessaire, au lieu d’occuper tout l’espace disponible
                    return SizedBox.shrink();
                  }
                },
              ),
              
              // Bouton pour voir ses réservations personnelles (visible pour TOUS)
              IconButton(
                // Icône de liste des tâches avec couleur blanche
                icon: Icon(Icons.assignment, color: Colors.white),
                // Texte d'infobulle au survol
                tooltip: 'Mes Réservations',
                // Action lors du clic sur le bouton
                onPressed: () {
                  // Navigation vers l'écran des réservations personnelles
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyBookingsScreen()),
                  );
                },
              ),
              
              // Bouton favoris (visible pour TOUS)
              IconButton(
                // Icône de cœur avec couleur rouge
                icon: Icon(Icons.favorite, color: Colors.red),
                // Texte d'infobulle au survol
                tooltip: 'Voir mes favoris',
                // Action lors du clic sur le bouton
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Navigation vers l'écran des favoris
                    builder: (context) => FavoritesScreen(),
                  ),
                ),
              ),
              
              // Bouton assistant IA (visible pour TOUS)
              IconButton(
                // Icône de robot avec couleur bleue
                icon: Icon(Icons.smart_toy_outlined, color: Colors.blue),
                // Texte d'infobulle au survol
                tooltip: 'Assistant IA',
                // Action lors du clic sur le bouton
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Navigation vers l'écran de l'assistant IA
                    builder: (context) => AssistantScreen(),
                  ),
                ),
              ),
              
              // Bouton voir toutes les voitures (visible pour TOUS)
              IconButton(
                // Icône de voiture de location avec couleur bleue
                icon: Icon(Icons.car_rental, color: Colors.blue),
                // Texte d'infobulle au survol
                tooltip: 'Voir toutes les voitures',
                // Action lors du clic sur le bouton
                onPressed: () {
                  // Navigation vers l'écran de toutes les voitures
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllVehiclesScreen(),
                    ),
                  );
                },
              ),
              
              // Avatar de l'utilisateur (visible pour TOUS) 
              // Widget MouseRegion pour modifier le curseur au survol
              MouseRegion(
                // Définit le curseur en forme de main (cliquable)
                cursor: SystemMouseCursors.click,
                // Widget GestureDetector pour détecter les taps
                child: GestureDetector(
                  // Action lors du tap sur l'avatar
                  onTap: () {
                    // Navigation vers l'écran de profil
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // Passe le nom d'utilisateur et l'email au ProfileScreen
                        builder: (context) => ProfileScreen(),
                      ),
                    );
                  },
                  // Conteneur avec padding pour l'avatar
                  child: Padding(
                    // Padding uniquement à droite de 16 pixels
                    padding: EdgeInsets.only(right: 16),
                    // Avatar circulaire
                    child: CircleAvatar(
                      // Couleur de fond bleue
                      backgroundColor: Colors.blue,
                      // Texte à l'intérieur de l'avatar (première lettre du nom)
                      child: Text(
                        // Première lettre du nom en majuscule
                        (Provider.of<VehiclesProvider>(context).username ?? widget.username)[0].toUpperCase(),
                        // Style du texte (blanc et gras)
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Corps principal de l'écran
          body: RawKeyboardListener(
            // Nœud de focus pour capturer les touches du clavier
            focusNode: _focusNode,
            // Focus automatique au chargement de l'écran
            autofocus: true,
            // Gestionnaire d'événements clavier
            onKey: (event) {
              // Vérifie si l'événement est une touche enfoncée
              if (event is RawKeyDownEvent) {
                // Si la touche fléchée haut est pressée
                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  // Appelle la fonction pour défiler vers le haut
                  _scrollUp();
                }
                // Si la touche fléchée bas est pressée
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  // Appelle la fonction pour défiler vers le bas
                  _scrollDown();
                }
              }
            },
            // Contenu principal de l'écran
            child: _buildHomeContent(provider),
          ),
          // Barre de navigation inférieure
          bottomNavigationBar: Container(
            // Décoration de la barre de navigation
            decoration: BoxDecoration(
              // Couleur de fond noire
              color: Color(0xFF1A1A1A),
              // Bordure supérieure blanche transparente
              border: Border(top: BorderSide(color: Colors.white12, width: 1)),
              // Ombre portée
              boxShadow: [
                BoxShadow(
                  // Couleur noire semi-transparente
                  color: Colors.black.withOpacity(0.2),
                  // Rayon de flou de l'ombre
                  blurRadius: 8,
                  // Décalage de l'ombre (vers le haut)
                  offset: Offset(0, -2),
                ),
              ],
            ),
            // Widget pour arrondir les coins
            child: ClipRRect(
              // Barre de navigation Flutter standard
              child: BottomNavigationBar(
                // Fond transparent pour voir la décoration du parent
                backgroundColor: Colors.transparent,
                // Couleur de l'élément sélectionné (bleu)
                selectedItemColor: Colors.blue,
                // Couleur des éléments non sélectionnés (blanc transparent)
                unselectedItemColor: Colors.white54,
                // Index actuellement sélectionné
                currentIndex: _selectedIndex,
                // Type fixe (tous les éléments toujours visibles)
                type: BottomNavigationBarType.fixed,
                // Pas d'ombre (utilise l'ombre du conteneur parent)
                elevation: 0,
                // Gestionnaire de clic sur les éléments
                onTap: (index) {
                  // Si l'index 0 (Accueil) est cliqué
                  if (index == 0) {
                    // Met à jour l'état avec le nouvel index
                    setState(() {
                      _selectedIndex = 0;
                    });
                  } 
                  // Si l'index 1 (Voitures) est cliqué
                  else if (index == 1) {
                    // Met à jour l'état avec le nouvel index
                    setState(() {
                      _selectedIndex = 1;
                    });
                    // Navigation vers l'écran de toutes les voitures
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllVehiclesScreen(),
                      ),
                    ).then((_) {
                      // Après retour de la navigation, réinitialise l'index à 0 (Accueil)
                      setState(() {
                        _selectedIndex = 0;
                      });
                    });
                  } 
                  // Si l'index 2 (Réservations) est cliqué
                  else if (index == 2) {
                    // Met à jour l'état avec le nouvel index
                    setState(() {
                      _selectedIndex = 2;
                    });
                    // Navigation vers l'écran des réservations personnelles
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyBookingsScreen(),
                      ),
                    ).then((_) {
                      // Après retour de la navigation, réinitialise l'index à 0 (Accueil)
                      setState(() {
                        _selectedIndex = 0;
                      });
                    });
                  } 
                  // Si l'index 3 (Favoris) est cliqué
                  else if (index == 3) {
                    // Met à jour l'état avec le nouvel index
                    setState(() {
                      _selectedIndex = 3;
                    });
                    // Navigation vers l'écran des favoris
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FavoritesScreen(),
                      ),
                    ).then((_) {
                      // Après retour de la navigation, réinitialise l'index à 0 (Accueil)
                      setState(() {
                        _selectedIndex = 0;
                      });
                    });
                  } 
                  // Si l'index 4 (Profil) est cliqué
                  else if (index == 4) {
                    // Met à jour l'état avec le nouvel index
                    setState(() {
                      _selectedIndex = 4;
                    });
                    // Navigation vers l'écran de profil
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(),
                      ),
                    ).then((_) {
                      // Après retour de la navigation, réinitialise l'index à 0 (Accueil)
                      setState(() {
                        _selectedIndex = 0;
                      });
                    });
                  }
                },
                // Liste des éléments de la barre de navigation
                items: [
                  // Élément Accueil
                  BottomNavigationBarItem(
                    // Icône d'accueil non sélectionné (contour)
                    icon: Icon(Icons.home_outlined),
                    // Icône d'accueil sélectionné (plein)
                    activeIcon: Icon(Icons.home),
                    // Libellé de l'élément
                    label: 'Accueil',
                  ),
                  // Élément Voitures
                  BottomNavigationBarItem(
                    // Icône de voiture non sélectionné (contour)
                    icon: Icon(Icons.car_rental_outlined),
                    // Icône de voiture sélectionné (plein)
                    activeIcon: Icon(Icons.car_rental),
                    // Libellé de l'élément
                    label: 'Voitures',
                  ),
                  // Élément Réservations
                  BottomNavigationBarItem(
                    // Icône de calendrier non sélectionné (contour)
                    icon: Icon(Icons.calendar_today_outlined),
                    // Icône de calendrier sélectionné (plein)
                    activeIcon: Icon(Icons.calendar_today),
                    // Libellé de l'élément
                    label: 'Réservations',
                  ),
                  // Élément Favoris
                  BottomNavigationBarItem(
                    // Icône de cœur vide (contour)
                    icon: Icon(Icons.favorite_outline),
                    // Icône de cœur plein
                    activeIcon: Icon(Icons.favorite),
                    // Libellé de l'élément
                    label: 'Favoris',
                  ),
                  // Élément Profil
                  BottomNavigationBarItem(
                    // Icône de profil vide (contour)
                    icon: Icon(Icons.person_outline),
                    // Icône de profil plein
                    activeIcon: Icon(Icons.person),
                    // Libellé de l'élément
                    label: 'Profil',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Méthode pour construire le contenu principal de l'écran
  Widget _buildHomeContent(VehiclesProvider provider) {
    // Accède directement aux données du provider
    // Liste de tous les véhicules
    final vehicles = provider.allVehicles;
    // État de chargement (true si en cours de chargement)
    final isLoading = provider.isLoading;
    // Message d'erreur éventuel (vide si pas d'erreur)
    final errorMessage = provider.errorMessage;

    // Si les données sont en cours de chargement
    if (isLoading) {
      // Retourne un indicateur de chargement centré
      return Center(
        child: Column(
          // Centre verticalement les enfants
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indicateur de chargement circulaire bleu
            CircularProgressIndicator(color: Colors.blue),
            // Espacement de 16 pixels
            SizedBox(height: 16),
            // Message de chargement en blanc
            Text('Chargement des véhicules...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    // Si une erreur est survenue
    if (errorMessage.isNotEmpty) {
      // Retourne un message d'erreur centré avec bouton de réessai
      return Center(
        child: Column(
          // Centre verticalement les enfants
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône d'erreur rouge de taille 50
            Icon(Icons.error_outline, color: Colors.red, size: 50),
            // Espacement de 16 pixels
            SizedBox(height: 16),
            // Message d'erreur en blanc
            Text(errorMessage, style: TextStyle(color: Colors.white, fontSize: 16)),
            // Espacement de 16 pixels
            SizedBox(height: 16),
            // Bouton pour réessayer le chargement
            ElevatedButton(
              // Appelle la méthode loadVehicles du provider
              onPressed: () => provider.loadVehicles(),
              // Texte du bouton
              child: Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    // Si aucun véhicule n'est disponible
    if (vehicles.isEmpty) {
      // Retourne un message "aucun véhicule" centré
      return Center(
        child: Column(
          // Centre verticalement les enfants
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône de voiture grise de taille 60
            Icon(Icons.car_repair, color: Colors.grey, size: 60),
            // Espacement de 16 pixels
            SizedBox(height: 16),
            // Message principal en blanc
            Text('Aucun véhicule disponible', style: TextStyle(color: Colors.white, fontSize: 18)),
            // Espacement de 8 pixels
            SizedBox(height: 8),
            // Sous-message en gris
            Text('Veuillez ajouter des véhicules', style: TextStyle(color: Colors.grey)),
            // Espacement de 16 pixels
            SizedBox(height: 16),
            // Bouton pour rafraîchir la liste
            ElevatedButton(
              // Appelle la méthode loadVehicles du provider
              onPressed: () => provider.loadVehicles(),
              // Texte du bouton
              child: Text('Rafraîchir'),
            ),
          ],
        ),
      );
    }

    // Calculer les listes spéciales pour les différentes sections
    // Véhicules marqués comme nouveaux (isNew == true)
    final newVehicles = vehicles.where((v) => v['isNew'] == true).toList();
    // Véhicules marqués comme meilleurs choix (isBestChoice == true)
    final bestChoices = vehicles.where((v) => v['isBestChoice'] == true).toList();
    
    // Calculer les plus populaires (tri par popularité décroissante)
    // Liste vide par défaut
    List<Map<String, dynamic>> mostPopular = [];
    // Vérifie si la liste des véhicules n'est pas vide
    if (vehicles.isNotEmpty) {
      // Crée une copie de la liste pour ne pas modifier l'originale
      mostPopular = List.from(vehicles);
      // Trie la liste par popularité décroissante (popularité la plus haute d'abord)
      mostPopular.sort((a, b) => (b['popularity'] ?? 0).compareTo(a['popularity'] ?? 0));
      // Prend seulement les 5 premiers (les plus populaires)
      mostPopular = mostPopular.take(5).toList();
    }

    // Si tout est chargé, affiche le contenu normal avec défilement
    return SingleChildScrollView(
      // Contrôleur de défilement vertical pour gérer le défilement clavier
      controller: _verticalScrollController,
      // Colonne principale avec tous les éléments
      child: Column(
        // Aligne les enfants sur le côté gauche
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec message de bienvenue et barre de recherche
          Container(
            // Marge intérieure horizontale de 16px et verticale de 12px
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              // Aligne les enfants sur le côté gauche
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message de bienvenue personnalisé avec le nom de l'utilisateur
                Text(
                  // Utilise le nom d'utilisateur et un drapeau tunisien
                  'Marhba, ${Provider.of<VehiclesProvider>(context).username ?? widget.username}! 🇹🇳',
                  // Style du texte (blanc clair, taille 16)
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                // Espacement de 4 pixels entre les textes
                SizedBox(height: 4),
                // Slogan de l'application
                Text(
                  'Trouvez votre véhicule idéal',
                  // Style du texte (blanc, gras, taille 24)
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Section "Nouveautés 2026"
          // Appelle la méthode pour construire l'en-tête de section
          _buildSectionHeader(
            // Titre de la section
            title: 'Nouveautés 2026',
            // Icône de la section (icône "nouveau")
            icon: Icons.fiber_new,
            // Couleur de l'icône (orange)
            color: Colors.orange,
          ),
          // Section horizontale avec flèches de navigation pour les nouveautés
          _buildHorizontalSectionWithArrows(
            // Contrôleur de défilement spécifique à cette section
            controller: _newVehiclesScrollController,
            // Liste des véhicules nouveaux
            vehicles: newVehicles,
            // Indique que c'est la section "Nouveautés"
            isNew: true,
          ),

          // Espacement de 12 pixels entre les sections
          SizedBox(height: 12),

          // Section "Les Plus Demandées"
          _buildSectionHeader(
            // Titre de la section
            title: 'Les Plus Demandées',
            // Icône de tendance à la hausse
            icon: Icons.trending_up,
            // Couleur de l'icône (vert)
            color: Colors.green,
          ),
          // Section horizontale avec flèches de navigation pour les populaires
          _buildHorizontalSectionWithArrows(
            // Contrôleur de défilement spécifique à cette section
            controller: _mostPopularScrollController,
            // Liste des véhicules les plus populaires
            vehicles: mostPopular,
            // Indique que c'est la section "Populaires"
            isPopular: true,
          ),

          // Espacement de 12 pixels entre les sections
          SizedBox(height: 12),

          // Section "Nos Meilleurs Choix"
          _buildSectionHeader(
            // Titre de la section
            title: 'Nos Meilleurs Choix',
            // Icône d'étoile
            icon: Icons.star,
            // Couleur de l'icône (ambre/doré)
            color: Colors.amber,
          ),
          // Section horizontale avec flèches de navigation pour les meilleurs choix
          _buildHorizontalSectionWithArrows(
            // Contrôleur de défilement spécifique à cette section
            controller: _bestChoicesScrollController,
            // Liste des meilleurs choix
            vehicles: bestChoices,
            // Indique que c'est la section "Meilleurs choix"
            isBestChoice: true,
          ),

          // Espacement de 12 pixels entre les sections
          SizedBox(height: 12),

          // Section "Parcourir par catégorie"
          Padding(
            // Marge horizontale de 16 pixels
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              // Répartit l'espace entre le titre et le bouton
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Titre de la section
                Text(
                  'Parcourir par catégorie',
                  // Style du texte (blanc, gras, taille 20)
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Bouton "Voir toutes" pour naviguer vers toutes les voitures
                // Widget GestureDetector pour rendre le texte cliquable
                GestureDetector(
                  // Action lors du clic sur le bouton
                  onTap: () {
                    // Navigation vers l'écran de toutes les voitures
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllVehiclesScreen()
                      ),
                    );
                  },
                  // Conteneur stylisé pour le bouton
                  child: Container(
                    // Marge intérieure horizontale de 12px et verticale de 6px
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    // Décoration du bouton
                    decoration: BoxDecoration(
                      // Fond bleu
                      color: Colors.blue,
                      // Coins arrondis de 8 pixels
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // Texte du bouton
                    child: Text(
                      'Voir toutes',
                      // Style du texte (blanc, gras, taille 14)
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Espacement de 10 pixels entre le titre et les catégories
          SizedBox(height: 10),

          // Liste horizontale des catégories (filtres)
          Container(
            // Hauteur fixe de 50 pixels pour la liste des catégories
            height: 50,
            // Liste horizontale des catégories
            child: ListView.builder(
              // Défilement horizontal
              scrollDirection: Axis.horizontal,
              // Marge horizontale de 16 pixels
              padding: EdgeInsets.symmetric(horizontal: 16),
              // Nombre d'éléments = nombre de catégories
              itemCount: _categories.length,
              // Fonction de construction de chaque élément
              itemBuilder: (context, index) {
                // Récupère la catégorie à l'index courant
                String category = _categories[index];
                // Vérifie si cette catégorie est actuellement sélectionnée
                bool isSelected = _selectedCategory == category;

                // Retourne un widget GestureDetector pour rendre la catégorie cliquable
                return GestureDetector(
                  // Action lors du clic sur une catégorie
                  onTap: () {
                    // Met à jour l'état avec la nouvelle catégorie sélectionnée
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  // Conteneur pour chaque catégorie
                  child: Container(
                    // Marge à droite de 12 pixels entre les catégories
                    margin: EdgeInsets.only(right: 12),
                    // Marge intérieure horizontale de 20px et verticale de 10px
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    // Décoration de la catégorie
                    decoration: BoxDecoration(
                      // Fond bleu si sélectionnée, gris foncé sinon
                      color: isSelected ? Colors.blue : Color(0xFF2A2A2A),
                      // Coins très arrondis (25 pixels pour un effet "pill")
                      borderRadius: BorderRadius.circular(25),
                      // Bordure si non sélectionnée (pas de bordure si sélectionnée)
                      border: isSelected ? null : Border.all(color: Colors.white24, width: 1),
                    ),
                    // Contenu centré dans le conteneur
                    child: Center(
                      // Texte de la catégorie
                      child: Text(
                        category,
                        // Style du texte (blanc, gras si sélectionnée, taille 14)
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Espacement de 14 pixels entre les catégories et la section filtrée
          SizedBox(height: 14),

          // Section des véhicules filtrés par catégorie (avec flèches de navigation)
          // Appelle la méthode qui construit cette section
          _buildFilteredVehiclesSectionWithArrows(vehicles),

          // Espacement final de 40 pixels en bas de la page
          // Pour éviter que le contenu ne soit collé au bord inférieur
          SizedBox(height: 40),
        ],
      ),
    );
  }

  // Méthode pour construire une section horizontale avec des flèches de navigation
  Widget _buildHorizontalSectionWithArrows({
    // Paramètre requis: contrôleur de défilement pour cette section
    required ScrollController controller,
    // Paramètre requis: liste des véhicules à afficher
    required List<Map<String, dynamic>> vehicles,
    // Paramètres optionnels pour identifier le type de section
    bool isNew = false,      // Section "Nouveautés"
    bool isBestChoice = false, // Section "Meilleurs choix"
    bool isPopular = false,  // Section "Populaires"
  }) {
    // Si aucun véhicule dans cette catégorie, affiche un message
    if (vehicles.isEmpty) {
      // Retourne un conteneur avec un message centré
      return Container(
        // Hauteur fixe de 370 pixels pour maintenir la mise en page cohérente
        height: 370,
        // Marge horizontale de 16 pixels
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          // Message indiquant qu'aucun véhicule n'est disponible
          child: Text(
            'Aucun véhicule dans cette catégorie',
            // Style du texte (blanc semi-transparent, taille 16)
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      );
    }

    // Construit la section avec flèches de navigation
    return Container(
      // Hauteur fixe de 370 pixels pour la section
      height: 370,
      // Stack permet de superposer des widgets (flèches sur la liste)
      child: Stack(
        children: [
          // Liste horizontale des véhicules (widget de base)
          ListView.builder(
            // Contrôleur de défilement pour cette liste
            controller: controller,
            // Défilement horizontal
            scrollDirection: Axis.horizontal,
            // Marge horizontale de 16 pixels
            padding: EdgeInsets.symmetric(horizontal: 16),
            // Nombre d'éléments = nombre de véhicules
            itemCount: vehicles.length,
            // Fonction de construction de chaque carte de véhicule
            itemBuilder: (context, index) {
              // Appelle la méthode pour construire une carte horizontale détaillée
              return _buildHorizontalVehicleCard(
                // Passe le véhicule à l'index courant
                vehicles[index],
                // Transmet les paramètres de type de section
                isNew: isNew,
                isBestChoice: isBestChoice,
                isPopular: isPopular,
              );
            },
          ),

          // Flèche de navigation gauche (superposée à la liste)
          Positioned(
            // Positionnée tout à gauche
            left: 0,
            // Positionnée tout en haut
            top: 0,
            // Positionnée tout en bas (s'étend sur toute la hauteur)
            bottom: 0,
            child: MouseRegion(
              // Change le curseur en main au survol
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                // Action lors du clic: défile vers la gauche
                onTap: () => _scrollLeft(controller),
                // Zone cliquable transparente
                child: Container(
                  // Largeur de 40 pixels pour la zone cliquable
                  width: 40,
                  // Fond transparent pour ne pas cacher le contenu
                  color: Colors.transparent,
                  // Centre l'icône dans la zone
                  child: Center(
                    // Icône de flèche gauche
                    child: Icon(
                      Icons.arrow_back_ios,
                      // Couleur blanche semi-transparente
                      color: Colors.white.withOpacity(0.7),
                      // Taille de 24 pixels
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Flèche de navigation droite (superposée à la liste)
          Positioned(
            // Positionnée tout à droite
            right: 0,
            // Positionnée tout en haut
            top: 0,
            // Positionnée tout en bas (s'étend sur toute la hauteur)
            bottom: 0,
            child: MouseRegion(
              // Change le curseur en main au survol
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                // Action lors du clic: défile vers la droite
                onTap: () => _scrollRight(controller),
                // Zone cliquable transparente
                child: Container(
                  // Largeur de 40 pixels pour la zone cliquable
                  width: 40,
                  // Fond transparent pour ne pas cacher le contenu
                  color: Colors.transparent,
                  // Centre l'icône dans la zone
                  child: Center(
                    // Icône de flèche droite
                    child: Icon(
                      Icons.arrow_forward_ios,
                      // Couleur blanche semi-transparente
                      color: Colors.white.withOpacity(0.7),
                      // Taille de 24 pixels
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour construire la section des véhicules filtrés par catégorie
  Widget _buildFilteredVehiclesSectionWithArrows(List<Map<String, dynamic>> vehicles) {
    // Filtre les véhicules selon la catégorie sélectionnée
    var filteredVehicles = _selectedCategory == 'Tous'
        // Si "Tous" est sélectionné, prend tous les véhicules
        ? vehicles
        // Sinon, filtre les véhicules dont la catégorie correspond
        : vehicles.where((v) => v['category'] == _selectedCategory).toList();

    // Si aucun véhicule dans la catégorie sélectionnée
    if (filteredVehicles.isEmpty) {
      // Retourne un message centré
      return Padding(
        // Marge de 16 pixels sur tous les côtés
        padding: EdgeInsets.all(16),
        child: Center(
          // Message indiquant l'absence de véhicules
          child: Text(
            'Aucun véhicule disponible dans cette catégorie',
            // Style du texte (blanc semi-transparent, taille 16)
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      );
    }

    // Calcule le nombre de lignes nécessaires (2 véhicules par colonne)
    // Utilise ceil() pour arrondir à l'entier supérieur
    int rows = (filteredVehicles.length / 2).ceil();

    // Retourne un conteneur avec flèches de navigation
    return Container(
      // Hauteur fixe de 360 pixels
      height: 360,
      // Stack pour superposer les flèches sur la liste
      child: Stack(
        children: [
          // Liste horizontale organisée en colonnes de 2 véhicules
          ListView.builder(
            // Contrôleur de défilement pour cette section
            controller: _filteredVehiclesScrollController,
            // Défilement horizontal
            scrollDirection: Axis.horizontal,
            // Marge horizontale de 16 pixels
            padding: EdgeInsets.symmetric(horizontal: 16),
            // Nombre d'éléments = nombre de colonnes
            itemCount: rows,
            // Fonction de construction de chaque colonne
            itemBuilder: (context, columnIndex) {
              // Calcule les indices des véhicules pour cette colonne
              // Premier véhicule de la colonne
              int firstIndex = columnIndex * 2;
              // Deuxième véhicule de la colonne
              int secondIndex = firstIndex + 1;

              // Retourne une colonne avec 2 véhicules
              return Container(
                // Largeur fixe de 200 pixels pour chaque colonne
                width: 200,
                // Marge à droite de 12 pixels entre les colonnes
                margin: EdgeInsets.only(right: 12),
                // Colonne verticale pour les 2 véhicules
                child: Column(
                  children: [
                    // Premier véhicule de la colonne
                    SizedBox(
                      // Hauteur fixe de 164 pixels pour la carte
                      height: 164,
                      // Appelle la méthode pour construire une carte compacte
                      child: _buildCompactVehicleCard(filteredVehicles[firstIndex]),
                    ),
                    // Deuxième véhicule de la colonne (s'il existe)
                    // Utilise une condition if avec l'opérateur spread (...)
                    if (secondIndex < filteredVehicles.length) ...[
                      // Espacement de 12 pixels entre les deux véhicules
                      SizedBox(height: 12),
                      // Deuxième véhicule
                      SizedBox(
                        // Hauteur fixe de 164 pixels pour la carte
                        height: 164,
                        // Appelle la méthode pour construire une carte compacte
                        child: _buildCompactVehicleCard(filteredVehicles[secondIndex]),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          // Flèche de navigation gauche (identique aux autres sections)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _scrollLeft(_filteredVehiclesScrollController),
                child: Container(
                  width: 40,
                  color: Colors.transparent,
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white.withOpacity(0.7),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Flèche de navigation droite (identique aux autres sections)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _scrollRight(_filteredVehiclesScrollController),
                child: Container(
                  width: 40,
                  color: Colors.transparent,
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.7),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour construire une carte compacte pour un véhicule
  Widget _buildCompactVehicleCard(Map<String, dynamic> vehicle) {
    // Retourne un GestureDetector pour rendre toute la carte cliquable
    return GestureDetector(
      // Action lors du clic sur la carte
      onTap: () {
        // Navigation vers l'écran de réservation
        Navigator.push(
          context,
          MaterialPageRoute(
            // Passe le véhicule sélectionné à l'écran de réservation
            builder: (context) => BookingScreen(vehicle: vehicle),
          ),
        );
      },
      // Conteneur principal de la carte
      child: Container(
        // Décoration de la carte
        decoration: BoxDecoration(
          // Couleur de fond gris foncé
          color: Color(0xFF2A2A2A),
          // Coins arrondis de 12 pixels
          borderRadius: BorderRadius.circular(12),
          // Ombre portée pour donner de la profondeur
          boxShadow: [
            BoxShadow(
              // Couleur noire semi-transparente
              color: Colors.black26,
              // Rayon de flou de 6 pixels
              blurRadius: 6,
              // Décalage de l'ombre (3 pixels vers le bas)
              offset: Offset(0, 3),
            ),
          ],
        ),
        // Colonne verticale pour organiser le contenu de la carte
        child: Column(
          // Aligne les enfants sur le côté gauche
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stack pour superposer des éléments sur l'image
            Stack(
              children: [
                // Image du véhicule avec coins arrondis en haut
                ClipRRect(
                  // Arrondit seulement les coins supérieurs
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  // Vérifie si l'image existe et n'est pas vide
                  child: vehicle['image'] != null && vehicle['image'].isNotEmpty
                      // Si oui, affiche l'image depuis l'URL
                      ? Image.network(
                          // URL de l'image
                          vehicle['image'],
                          // Hauteur fixe de 80 pixels
                          height: 80,
                          // Largeur totale du parent
                          width: double.infinity,
                          // Remplit l'espace disponible en conservant les proportions
                          fit: BoxFit.cover,
                          // Builder pour gérer le chargement de l'image
                          loadingBuilder: (context, child, loadingProgress) {
                            // Si le chargement est terminé, retourne l'image
                            if (loadingProgress == null) return child;
                            // Sinon, affiche un indicateur de chargement
                            return Container(
                              height: 80,
                              // Fond gris pendant le chargement
                              color: Color(0xFF3A3A3A),
                              child: Center(
                                // Indicateur de chargement circulaire bleu
                                child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 2),
                              ),
                            );
                          },
                          // Builder pour gérer les erreurs de chargement
                          errorBuilder: (context, error, stackTrace) {
                            // En cas d'erreur, affiche une icône de remplacement
                            return Container(
                              height: 80,
                              // Fond gris pour l'icône de remplacement
                              color: Color(0xFF3A3A3A),
                              child: Center(
                                // Icône de voiture blanche
                                child: Icon(Icons.car_repair, color: Colors.white, size: 30),
                              ),
                            );
                          },
                        )
                      // Si pas d'image, affiche une icône de remplacement
                      : Container(
                          height: 80,
                          // Fond gris pour l'icône de remplacement
                          color: Color(0xFF3A3A3A),
                          child: Center(
                            // Icône de voiture blanche
                            child: Icon(Icons.car_repair, color: Colors.white, size: 30),
                          ),
                        ),
                ),
                // Badge de disponibilité (cercle vert/rouge en haut à droite)
                Positioned(
                  // Positionné à 6 pixels du haut
                  top: 6,
                  // Positionné à 6 pixels de la droite
                  right: 6,
                  child: Container(
                    // Taille fixe de 18x18 pixels
                    width: 18,
                    height: 18,
                    // Décoration du badge circulaire
                    decoration: BoxDecoration(
                      // Vert si disponible, rouge sinon
                      color: vehicle['isAvailable'] ? Colors.green : Colors.red,
                      // Forme circulaire
                      shape: BoxShape.circle,
                    ),
                    // Centre une icône dans le badge
                    child: Center(
                      // Icône de check (vérification) si disponible, croix sinon
                      child: Icon(
                        vehicle['isAvailable'] ? Icons.check : Icons.close,
                        // Couleur blanche pour l'icône
                        color: Colors.white,
                        // Taille très petite (10 pixels)
                        size: 10,
                      ),
                    ),
                  ),
                ),
                // Bouton favori (cœur en haut à gauche)
                Positioned(
                  // Positionné à 6 pixels du haut
                  top: 6,
                  // Positionné à 6 pixels de la gauche
                  left: 6,
                  child: GestureDetector(
                    // Action lors du clic: bascule l'état favori
                    onTap: () => _toggleFavorite(vehicle),
                    // Conteneur circulaire pour le bouton
                    child: Container(
                      // Taille fixe de 22x22 pixels
                      width: 22,
                      height: 22,
                      // Décoration du bouton
                      decoration: BoxDecoration(
                        // Fond noir semi-transparent
                        color: Colors.black54,
                        // Forme circulaire
                        shape: BoxShape.circle,
                      ),
                      // Centre une icône dans le bouton
                      child: Center(
                        // Icône de cœur plein si favori, cœur vide sinon
                        child: Icon(
                          vehicle['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                          // Rouge si favori, blanc sinon
                          color: vehicle['isFavorite'] ? Colors.red : Colors.white,
                          // Taille de 12 pixels
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Partie inférieure de la carte (informations textuelles)
            Expanded(
              // Utilise Expanded pour prendre tout l'espace vertical restant
              child: Padding(
                // Marge intérieure de 8 pixels sur tous les côtés
                padding: EdgeInsets.all(8),
                // Colonne pour organiser les informations textuelles
                child: Column(
                  // Aligne les enfants sur le côté gauche
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // Prend le minimum d'espace vertical nécessaire
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nom du véhicule
                    Text(
                      // Utilise le nom du véhicule ou une valeur par défaut
                      vehicle['name'] ?? 'Véhicule',
                      // Style du texte (blanc, gras, taille 12)
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      // Limite à une ligne
                      maxLines: 1,
                      // Ajoute des points de suspension si le texte est trop long
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Espacement de 2 pixels entre le nom et la catégorie
                    SizedBox(height: 2),
                    // Ligne pour la catégorie et la note
                    Row(
                      children: [
                        // Catégorie du véhicule (prend tout l'espace disponible)
                        Expanded(
                          child: Text(
                            // Utilise la catégorie du véhicule ou une valeur par défaut
                            vehicle['category'] ?? 'Catégorie',
                            // Style du texte (bleu, taille 9)
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 9,
                            ),
                            // Limite à une ligne
                            maxLines: 1,
                            // Ajoute des points de suspension si le texte est trop long
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Note du véhicule (étoiles)
                        Row(
                          children: [
                            // Icône d'étoile ambre
                            Icon(Icons.star, color: Colors.amber, size: 10),
                            // Espacement de 2 pixels entre l'icône et le texte
                            SizedBox(width: 2),
                            // Texte de la note
                            Text(
                              // Utilise la note du véhicule ou 0.0 par défaut
                              '${vehicle['rating'] ?? 0.0}',
                              // Style du texte (blanc semi-transparent, taille 9)
                              style: TextStyle(color: Colors.white70, fontSize: 9),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Espacement de 3 pixels entre la note et les caractéristiques
                    SizedBox(height: 3),
                    // Ligne pour les caractéristiques (sièges et carburant)
                    Row(
                      children: [
                        // Icône de personnes (sièges)
                        Icon(Icons.people, size: 9, color: Colors.white54),
                        // Espacement de 2 pixels entre l'icône et le texte
                        SizedBox(width: 2),
                        // Nombre de sièges
                        Text(
                          // Utilise le nombre de sièges ou 0 par défaut
                          '${vehicle['seats'] ?? 0}',
                          // Style du texte (blanc semi-transparent, taille 9)
                          style: TextStyle(color: Colors.white70, fontSize: 9),
                        ),
                        // Espacement de 4 pixels entre les deux caractéristiques
                        SizedBox(width: 4),
                        // Icône de station-service (carburant)
                        Icon(Icons.local_gas_station, size: 9, color: Colors.white54),
                        // Espacement de 2 pixels entre l'icône et le texte
                        SizedBox(width: 2),
                        // Type de carburant (prend tout l'espace restant)
                        Expanded(
                          child: Text(
                            // Utilise le type de carburant ou "Essence" par défaut
                            vehicle['fuel'] ?? 'Essence',
                            // Style du texte (blanc semi-transparent, très petite taille)
                            style: TextStyle(color: Colors.white70, fontSize: 8),
                            // Limite à une ligne
                            maxLines: 1,
                            // Ajoute des points de suspension si le texte est trop long
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Spacer pousse les éléments suivants vers le bas
                    Spacer(),
                    // Ligne pour le prix et le bouton de réservation
                    Row(
                      // Répartit l'espace entre le prix et le bouton
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      // Aligne les éléments en bas de la ligne
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Prix du véhicule
                        Expanded(
                          child: Text(
                            // Format: "XXX TND" (prix par jour)
                            '${vehicle['price'] ?? 0} TND',
                            // Style du texte (blanc, gras, taille 13)
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            // Limite à une ligne
                            maxLines: 1,
                            // Ajoute des points de suspension si le texte est trop long
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Espacement de 4 pixels entre le prix et le bouton
                        SizedBox(width: 4),
                        // Bouton de réservation
                        ElevatedButton(
                          // Active le bouton seulement si le véhicule est disponible
                          onPressed: vehicle['isAvailable'] == true
                              ? () {
                                  // Navigation vers l'écran de réservation
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookingScreen(vehicle: vehicle),
                                    ),
                                  );
                                }
                              : null, // Désactive le bouton si non disponible
                          // Style personnalisé du bouton
                          style: ElevatedButton.styleFrom(
                            // Couleur de fond bleue
                            backgroundColor: Colors.blue,
                            // Taille minimale (0 pour la largeur, 28 pixels pour la hauteur)
                            minimumSize: Size(0, 28),
                            // Marge intérieure réduite
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            // Réduit la zone de clic à la taille du contenu
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          // Texte du bouton
                          child: Text(
                            'Réserver',
                            // Très petite taille de police
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour construire l'en-tête d'une section avec icône
  Widget _buildSectionHeader({
    // Paramètre requis: titre de la section
    required String title,
    // Paramètre requis: icône de la section
    required IconData icon,
    // Paramètre requis: couleur de l'icône
    required Color color,
  }) {
    // Retourne un Padding pour ajouter de l'espace autour de l'en-tête
    return Padding(
      // Marge: 16 pixels à gauche, 8 pixels en haut, 12 pixels en bas
      padding: EdgeInsets.only(left: 16, top: 8, bottom: 12),
      // Ligne horizontale pour l'icône et le titre
      child: Row(
        children: [
          // Icône de la section
          Icon(icon, color: color, size: 24),
          // Espacement de 8 pixels entre l'icône et le texte
          SizedBox(width: 8),
          // Titre de la section
          Text(
            title,
            // Style du texte (blanc, gras, taille 20)
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour construire une carte horizontale détaillée pour un véhicule
  Widget _buildHorizontalVehicleCard(
    // Paramètre requis: données du véhicule
    Map<String, dynamic> vehicle, {
    // Paramètres optionnels pour identifier le type de section
    bool isNew = false,      // Section "Nouveautés"
    bool isBestChoice = false, // Section "Meilleurs choix"
    bool isPopular = false,  // Section "Populaires"
  }) {
    // Variables pour le badge (couleur et texte)
    Color badgeColor = Colors.blue; // Couleur par défaut
    String badgeText = ''; // Texte vide par défaut (pas de badge)

    // Détermine la couleur et le texte du badge selon la section
    if (isNew) {
      // Pour la section "Nouveautés"
      badgeColor = Colors.orange;
      badgeText = 'NOUVEAU';
    } else if (isBestChoice) {
      // Pour la section "Meilleurs choix"
      badgeColor = Colors.amber;
      badgeText = 'TOP';
    } else if (isPopular) {
      // Pour la section "Populaires"
      badgeColor = Colors.green;
      badgeText = 'POPULAIRE';
    }

    // Retourne le conteneur principal de la carte
    return Container(
      // Largeur fixe de 280 pixels pour la carte
      width: 280,
      // Marge à droite de 16 pixels entre les cartes
      margin: EdgeInsets.only(right: 16),
      // Décoration de la carte
      decoration: BoxDecoration(
        // Couleur de fond gris foncé
        color: Color(0xFF2A2A2A),
        // Coins arrondis de 16 pixels
        borderRadius: BorderRadius.circular(16),
        // Ombre portée pour donner de la profondeur
        boxShadow: [
          BoxShadow(
            // Couleur noire semi-transparente
            color: Colors.black26,
            // Rayon de flou de 8 pixels
            blurRadius: 8,
            // Décalage de l'ombre (4 pixels vers le bas)
            offset: Offset(0, 4),
          ),
        ],
      ),
      // Colonne verticale pour organiser le contenu de la carte
      child: Column(
        // Aligne les enfants sur le côté gauche
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stack pour superposer des éléments sur l'image
          Stack(
            children: [
              // Image du véhicule avec coins arrondis en haut
              ClipRRect(
                // Arrondit seulement les coins supérieurs
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                // Vérifie si l'image existe et n'est pas vide
                child: vehicle['image'] != null && vehicle['image'].isNotEmpty
                    // Si oui, affiche l'image depuis l'URL
                    ? Image.network(
                        // URL de l'image
                        vehicle['image'],
                        // Hauteur fixe de 160 pixels
                        height: 160,
                        // Largeur fixe de 280 pixels (même que la carte)
                        width: 280,
                        // Remplit l'espace disponible en conservant les proportions
                        fit: BoxFit.cover,
                        // Builder pour gérer le chargement de l'image
                        loadingBuilder: (context, child, loadingProgress) {
                          // Si le chargement est terminé, retourne l'image
                          if (loadingProgress == null) return child;
                          // Sinon, affiche un indicateur de chargement
                          return Container(
                            height: 160,
                            // Fond gris pendant le chargement
                            color: Color(0xFF3A3A3A),
                            child: Center(
                              // Indicateur de chargement circulaire bleu
                              child: CircularProgressIndicator(color: Colors.blue),
                            ),
                          );
                        },
                        // Builder pour gérer les erreurs de chargement
                        errorBuilder: (context, error, stackTrace) {
                          // En cas d'erreur, affiche une icône de remplacement
                          return Container(
                            height: 160,
                            // Fond gris pour l'icône de remplacement
                            color: Color(0xFF3A3A3A),
                            child: Center(
                              // Icône de voiture blanche
                              child: Icon(Icons.car_repair, color: Colors.white, size: 50),
                            ),
                          );
                        },
                      )
                    // Si pas d'image, affiche une icône de remplacement
                    : Container(
                        height: 160,
                        // Fond gris pour l'icône de remplacement
                        color: Color(0xFF3A3A3A),
                        child: Center(
                          // Icône de voiture blanche
                          child: Icon(Icons.car_repair, color: Colors.white, size: 50),
                        ),
                      ),
              ),
              // Badge (Nouveau, Top, Populaire) - seulement si badgeText n'est pas vide
              if (badgeText.isNotEmpty)
                Positioned(
                  // Positionné à 12 pixels du haut
                  top: 12,
                  // Positionné à 12 pixels de la droite
                  right: 12,
                  child: Container(
                    // Marge intérieure horizontale de 10px et verticale de 5px
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    // Décoration du badge
                    decoration: BoxDecoration(
                      // Couleur déterminée par la section
                      color: badgeColor,
                      // Coins arrondis de 10 pixels
                      borderRadius: BorderRadius.circular(10),
                    ),
                    // Texte du badge
                    child: Text(
                      badgeText,
                      // Style du texte (blanc, gras, très petite taille)
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // Bouton favori (cœur en haut à gauche)
              Positioned(
                // Positionné à 12 pixels du haut
                top: 12,
                // Positionné à 12 pixels de la gauche
                left: 12,
                child: GestureDetector(
                  // Action lors du clic: bascule l'état favori
                  onTap: () => _toggleFavorite(vehicle),
                  // Conteneur circulaire pour le bouton
                  child: Container(
                    // Taille fixe de 34x34 pixels
                    width: 34,
                    height: 34,
                    // Décoration du bouton
                    decoration: BoxDecoration(
                      // Fond noir semi-transparent
                      color: Colors.black54,
                      // Forme circulaire
                      shape: BoxShape.circle,
                    ),
                    // Centre une icône dans le bouton
                    child: Center(
                      // Icône de cœur plein si favori, cœur vide sinon
                      child: Icon(
                        vehicle['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                        // Rouge si favori, blanc sinon
                        color: vehicle['isFavorite'] ? Colors.red : Colors.white,
                        // Taille de 18 pixels
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Partie inférieure de la carte (informations textuelles)
          Expanded(
            // Utilise Expanded pour prendre tout l'espace vertical restant
            child: Padding(
              // Marge intérieure de 12 pixels sur tous les côtés
              padding: EdgeInsets.all(12),
              // Colonne pour organiser les informations textuelles
              child: Column(
                // Aligne les enfants sur le côté gauche
                crossAxisAlignment: CrossAxisAlignment.start,
                // Prend le minimum d'espace vertical nécessaire
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ligne pour le nom et la note du véhicule
                  Row(
                    // Répartit l'espace entre le nom et la note
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Nom du véhicule (prend tout l'espace disponible)
                      Expanded(
                        child: Text(
                          // Utilise le nom du véhicule ou une valeur par défaut
                          vehicle['name'] ?? 'Véhicule',
                          // Style du texte (blanc, gras, taille 15)
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          // Limite à une ligne
                          maxLines: 1,
                          // Ajoute des points de suspension si le texte est trop long
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Note du véhicule (étoiles)
                      Row(
                        children: [
                          // Icône d'étoile ambre
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          // Espacement de 3 pixels entre l'icône et le texte
                          SizedBox(width: 3),
                          // Texte de la note
                          Text(
                            // Utilise la note du véhicule ou 0.0 par défaut
                            '${vehicle['rating'] ?? 0.0}',
                            // Style du texte (blanc semi-transparent, taille 13)
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Espacement de 3 pixels entre le nom et la catégorie
                  SizedBox(height: 3),
                  // Catégorie du véhicule
                  Text(
                    // Utilise la catégorie du véhicule ou une valeur par défaut
                    vehicle['category'] ?? 'Catégorie',
                    // Style du texte (bleu, taille 11)
                    style: TextStyle(color: Colors.blue, fontSize: 11),
                    // Limite à une ligne
                    maxLines: 1,
                    // Ajoute des points de suspension si le texte est trop long
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Espacement de 6 pixels entre la catégorie et les caractéristiques
                  SizedBox(height: 6),
                  // Première ligne de caractéristiques (4 éléments)
                  Row(
                    // Répartit l'espace également entre les 4 éléments
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Nombre de sièges
                      _buildVehicleFeature(
                        // Utilise le nombre de sièges ou 0 par défaut
                        '${vehicle['seats'] ?? 0}',
                        // Icône de personnes
                        Icons.people,
                      ),
                      // Transmission (Manuelle/Automatique)
                      _buildVehicleFeature(
                        // "Man." si manuelle, "Auto." sinon
                        (vehicle['transmission'] ?? 'Automatique') == 'Manuelle' ? 'Man.' : 'Auto.',
                        // Icône d'engrenage
                        Icons.settings,
                      ),
                      // Type de carburant
                      _buildVehicleFeature(
                        // Utilise le type de carburant ou "Essence" par défaut
                        vehicle['fuel'] ?? 'Essence',
                        // Icône de station-service
                        Icons.local_gas_station,
                      ),
                      // Moteur (cylindrée)
                      _buildVehicleFeature(
                        // Utilise la cylindrée ou "1.6L" par défaut
                        vehicle['engine'] ?? '1.6L',
                        // Icône d'ingénierie
                        Icons.engineering,
                      ),
                    ],
                  ),
                  // Espacement de 6 pixels entre les deux lignes de caractéristiques
                  SizedBox(height: 6),
                  // Deuxième ligne de caractéristiques (4 éléments)
                  Row(
                    // Répartit l'espace également entre les 4 éléments
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Capacité du coffre
                      _buildVehicleFeature(
                        // Utilise la capacité ou 0 par défaut
                        '${vehicle['luggage'] ?? 0}',
                        // Icône de valise
                        Icons.business_center,
                      ),
                      // Climatisation
                      _buildVehicleFeature(
                        // "AC" si présente, "Non" sinon
                        (vehicle['airConditioning'] ?? true) ? 'AC' : 'Non',
                        // Icône de climatisation
                        Icons.ac_unit,
                      ),
                      // Bluetooth
                      _buildVehicleFeature(
                        // "BT" si présent, "Non" sinon
                        (vehicle['bluetooth'] ?? true) ? 'BT' : 'Non',
                        // Icône Bluetooth
                        Icons.bluetooth,
                      ),
                      // Année du véhicule
                      _buildVehicleFeature(
                        // Utilise l'année ou 2023 par défaut
                        '${vehicle['year'] ?? 2023}',
                        // Icône de calendrier
                        Icons.calendar_today,
                      ),
                    ],
                  ),
                  // Spacer pousse les éléments suivants vers le bas
                  Spacer(),
                  // Ligne pour le prix et le bouton de réservation
                  Row(
                    // Répartit l'espace entre le prix et le bouton
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Colonne pour le prix (avec libellé "par jour")
                      Column(
                        // Aligne les enfants sur le côté gauche
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Prix du véhicule
                          Text(
                            // Format: "XXX TND"
                            '${vehicle['price'] ?? 0} TND',
                            // Style du texte (blanc, gras, taille 18)
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Libellé "par jour"
                          Text(
                            'par jour',
                            // Style du texte (blanc semi-transparent, très petite taille)
                            style: TextStyle(color: Colors.white54, fontSize: 9),
                          ),
                        ],
                      ),
                      // Bouton de réservation
                      ElevatedButton(
                        // Active le bouton seulement si le véhicule est disponible
                        onPressed: vehicle['isAvailable'] == true
                            ? () {
                                // Navigation vers l'écran de réservation
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookingScreen(vehicle: vehicle),
                                  ),
                                );
                              }
                            : null, // Désactive le bouton si non disponible
                        // Style personnalisé du bouton
                        style: ElevatedButton.styleFrom(
                          // Couleur de fond bleue
                          backgroundColor: Colors.blue,
                          // Forme avec coins arrondis
                          shape: RoundedRectangleBorder(
                            // Coins arrondis de 8 pixels
                            borderRadius: BorderRadius.circular(8),
                          ),
                          // Marge intérieure
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        // Texte du bouton
                        child: Text(
                          'Réserver',
                          // Taille de police 12
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour construire un widget d'une caractéristique du véhicule (icône + texte)
  Widget _buildVehicleFeature(String text, IconData icon) {
    // Retourne une colonne verticale pour l'icône et le texte
    return Column(
      children: [
        // Icône de la caractéristique
        Icon(
          icon,
          // Couleur blanche semi-transparente
          color: Colors.white54,
          // Taille de 14 pixels
          size: 14,
        ),
        // Espacement de 3 pixels entre l'icône et le texte
        SizedBox(height: 3),
        // Texte de la caractéristique
        Text(
          // Tronque le texte à 6 caractères s'il est trop long
          text.length > 6 ? '${text.substring(0, 6)}' : text,
          // Style du texte (blanc semi-transparent, très petite taille)
          style: TextStyle(color: Colors.white54, fontSize: 9),
          // Limite à une ligne
          maxLines: 1,
          // Ajoute des points de suspension si le texte est trop long
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}