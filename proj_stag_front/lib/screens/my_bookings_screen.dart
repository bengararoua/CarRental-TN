// Importation de la bibliothèque principale Flutter pour la création d'interfaces utilisateur
import 'package:flutter/material.dart';

// Importation des services système comme le clavier pour la gestion des événements clavier
import 'package:flutter/services.dart';

// Importation du package Provider pour la gestion d'état dans l'application
import 'package:provider/provider.dart';

// Importation du service d'authentification qui contient les appels API pour les réservations
import '../services/auth_service.dart';

// Importation du provider des véhicules pour accéder au token d'authentification
import '../providers/vehicles_provider.dart';

// Définition de la classe MyBookingsScreen qui étend StatefulWidget
// StatefulWidget car cet écran doit gérer un état changeant (liste des réservations)
class MyBookingsScreen extends StatefulWidget {
  // Méthode createState qui crée l'instance de l'état associé à ce widget
  @override
  _MyBookingsScreenState createState() => _MyBookingsScreenState();
}

// Classe d'état qui gère la logique et l'affichage de l'écran Mes Réservations
class _MyBookingsScreenState extends State<MyBookingsScreen> {
  // Déclaration d'une Future qui contiendra le résultat asynchrone de la récupération des réservations
  late Future<List<dynamic>> _bookingsFuture;
  
  // Variable booléenne pour suivre l'état de chargement des données
  bool _isLoading = false;
  
  // Contrôleur pour gérer le défilement de la liste des réservations
  final ScrollController _scrollController = ScrollController();
  
  // Nœud de focus pour capturer les événements clavier (flèches haut/bas)
  final FocusNode _focusNode = FocusNode();

  // Méthode initState appelée une seule fois lors de la création de l'état du widget
  @override
  void initState() {
    // Appel de la méthode initState de la classe parente (State)
    super.initState();
    // Chargement initial des réservations
    _loadBookings();
  }
  
  // Méthode dispose appelée quand le widget est retiré de l'arbre des widgets
  @override
  void dispose() {
    // Libération des ressources du contrôleur de défilement
    _scrollController.dispose();
    // Libération des ressources du nœud de focus
    _focusNode.dispose();
    // Appel de la méthode dispose de la classe parente
    super.dispose();
  }

  // Méthode pour déplacer la vue de défilement vers le haut
  void _scrollUp() {
    // Vérification que le contrôleur est attaché à un widget
    if (_scrollController.hasClients) {
      // Animation du défilement pour un effet fluide
      _scrollController.animateTo(
        // Calcul de la nouvelle position (décalage actuel - 150 pixels)
        _scrollController.offset - 150,
        // Durée de l'animation : 200 millisecondes
        duration: Duration(milliseconds: 200),
        // Courbe d'animation pour un effet de ralenti en fin de mouvement
        curve: Curves.easeOut,
      );
    }
  }

  // Méthode pour déplacer la vue de défilement vers le bas
  void _scrollDown() {
    // Vérification que le contrôleur est attaché à un widget
    if (_scrollController.hasClients) {
      // Animation du défilement vers le bas
      _scrollController.animateTo(
        // Calcul de la nouvelle position (décalage actuel + 150 pixels)
        _scrollController.offset + 150,
        // Durée de l'animation : 200 millisecondes
        duration: Duration(milliseconds: 200),
        // Courbe d'animation pour un effet de ralenti
        curve: Curves.easeOut,
      );
    }
  }

  // Méthode pour charger les réservations depuis l'API
  void _loadBookings() {
    // Récupération du token d'authentification depuis le provider
    final token = Provider.of<VehiclesProvider>(context, listen: false).token;
    
    // Vérification que l'utilisateur est connecté (token non nul)
    if (token != null) {
      // Mise à jour de l'état pour activer l'indicateur de chargement
      setState(() {
        _isLoading = true;
      });
      
      // Appel asynchrone à l'API pour récupérer les réservations
      _bookingsFuture = AuthService.fetchMyBookings(token).then((bookings) {
        // Une fois les données récupérées, désactivation du chargement
        setState(() {
          _isLoading = false;
        });
        // Retour des réservations pour la Future
        return bookings;
      }).catchError((error) {
        // En cas d'erreur, désactivation du chargement et retour d'une liste vide
        setState(() {
          _isLoading = false;
        });
        return [];
      });
    } else {
      // Si aucun token, initialisation avec une Future contenant une liste vide
      _bookingsFuture = Future.value([]);
    }
  }

  // Méthode pour rafraîchir manuellement la liste des réservations
  Future<void> _refreshBookings() async {
    // Appel de la méthode de chargement des réservations
    _loadBookings();
  }

  // Méthode build principale qui construit l'interface utilisateur
  @override
  Widget build(BuildContext context) {
    // Utilisation de Consumer pour écouter les changements dans VehiclesProvider
    return Consumer<VehiclesProvider>(
      builder: (context, provider, child) {
        // Retour d'un Scaffold comme structure de base de l'écran
        return Scaffold(
          // Définition de la couleur de fond de l'écran
          backgroundColor: const Color(0xFF1A1A1A),
          // Configuration de la barre d'application en haut de l'écran
          appBar: AppBar(
            // Couleur de fond de la barre d'application
            backgroundColor: const Color(0xFF1A1A1A),
            // Suppression de l'ombre sous la barre
            elevation: 0,
            // Désactivation de la flèche de retour automatique
            automaticallyImplyLeading: false,
            // Configuration du titre de la barre d'application
            title: MouseRegion(
              // Changement du curseur en main lors du survol
              cursor: SystemMouseCursors.click,
              // Détection des clics sur le titre
              child: GestureDetector(
                // Action de retour à l'écran précédent lors du clic
                onTap: () => Navigator.pop(context),
                // Disposition en ligne des éléments (icône + texte)
                child: Row(
                  // Le Row ne prend que l'espace nécessaire
                  mainAxisSize: MainAxisSize.min,
                  // Liste des enfants du Row
                  children: const [
                    // Icône de retour stylisée
                    Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    // Espacement de 8 pixels entre l'icône et le texte
                    SizedBox(width: 8),
                    // Texte du titre de l'écran
                    Text(
                      'Mes Réservations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Boutons d'action supplémentaires dans la barre
            actions: [
              // Bouton d'icône pour rafraîchir les réservations
              IconButton(
                // Icône de rafraîchissement stylisée
                icon: Icon(Icons.refresh, color: Colors.blue, size: 22),
                // Action au clic : appel de la méthode de rafraîchissement
                onPressed: _refreshBookings,
                // Espacement interne du bouton
                padding: EdgeInsets.all(12),
              ),
            ],
          ),
          // Corps principal de l'écran
          body: RawKeyboardListener(
            // Attribution du nœud de focus pour la capture des événements clavier
            focusNode: _focusNode,
            // Donne automatiquement le focus à ce widget au chargement
            autofocus: true,
            // Callback appelé lorsqu'une touche du clavier est pressée
            onKey: (event) {
              // Vérification que c'est un événement d'appui (pas de relâchement)
              if (event is RawKeyDownEvent) {
                // Vérification si la touche est la flèche vers le haut
                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  // Appel de la méthode pour déplacer la vue vers le haut
                  _scrollUp();
                }
                // Vérification si la touche est la flèche vers le bas
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  // Appel de la méthode pour déplacer la vue vers le bas
                  _scrollDown();
                }
              }
            },
            // Enfant principal du RawKeyboardListener
            child: _isLoading
                // Si chargement en cours, affichage d'un indicateur de progression
                ? Center(child: CircularProgressIndicator(color: Colors.blue))
                // Sinon, affichage du contenu avec possibilité de rafraîchissement par glissement
                : RefreshIndicator(
                    // Méthode appelée lors du rafraîchissement par glissement
                    onRefresh: _refreshBookings,
                    // Widget qui gère les données asynchrones (Future)
                    child: FutureBuilder<List<dynamic>>(
                      // La Future qui contient les réservations
                      future: _bookingsFuture,
                      // Fonction de construction qui s'adapte à l'état de la Future
                      builder: (context, snapshot) {
                        // Vérification de l'état de connexion de la Future
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          // Pendant le chargement initial, affichage d'un indicateur
                          return Center(child: CircularProgressIndicator(color: Colors.blue));
                        } else if (snapshot.hasError) {
                          // En cas d'erreur, affichage d'un message d'erreur
                          return SingleChildScrollView(
                            // Attribution du contrôleur de défilement
                            controller: _scrollController,
                            // Activation permanente du défilement
                            physics: AlwaysScrollableScrollPhysics(),
                            // Centrage du contenu
                            child: Center(
                              child: Padding(
                                // Espacement interne
                                padding: const EdgeInsets.all(20.0),
                                // Disposition en colonne des éléments d'erreur
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Icône d'erreur
                                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                                    // Espacement vertical
                                    const SizedBox(height: 16),
                                    // Message d'erreur avec le détail de l'erreur
                                    Text(
                                      "Erreur : ${snapshot.error}",
                                      style: const TextStyle(color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                    // Espacement vertical
                                    const SizedBox(height: 16),
                                    // Bouton pour réessayer le chargement
                                    ElevatedButton(
                                      onPressed: _refreshBookings,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                      ),
                                      child: const Text("Réessayer", style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          // Si aucune donnée ou liste vide, affichage d'un message approprié
                          return SingleChildScrollView(
                            controller: _scrollController,
                            physics: AlwaysScrollableScrollPhysics(),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Espacement en haut
                                    SizedBox(height: 50),
                                    // Icône illustrative
                                    Icon(Icons.car_rental, color: Colors.grey, size: 80),
                                    // Espacement vertical
                                    SizedBox(height: 20),
                                    // Message informatif
                                    Text(
                                      "Vous n'avez pas encore de réservations.",
                                      style: TextStyle(color: Colors.white54, fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                    // Espacement vertical
                                    SizedBox(height: 20),
                                    // Bouton pour retourner à l'accueil
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        // Bouton avec largeur maximale et hauteur fixe
                                        minimumSize: Size(double.infinity, 50),
                                      ),
                                      child: Text("Retour à l'accueil", style: TextStyle(color: Colors.white)),
                                    ),
                                    // Espacement en bas
                                    SizedBox(height: 50),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        // Récupération des données de réservations
                        final bookings = snapshot.data!;

                        // Construction de la liste des réservations avec ListView.builder
                        return ListView.builder(
                          // Attribution du contrôleur de défilement
                          controller: _scrollController,
                          // Espacement interne de la liste
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          // Nombre d'éléments dans la liste
                          itemCount: bookings.length,
                          // Fonction de construction pour chaque élément de la liste
                          itemBuilder: (context, index) {
                            // Récupération de la réservation courante
                            final booking = bookings[index];
                            // Détermination du statut pour le style conditionnel
                            bool isConfirmed = booking['status'] == "Confirmée";
                            bool isCancelled = booking['status'] == "Annulée";

                            // Retour d'un conteneur pour chaque réservation
                            return Container(
                              // Marge en bas pour espacer les cartes
                              margin: const EdgeInsets.only(bottom: 15),
                              // Décoration de la carte (arrière-plan, bordures, coins arrondis)
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(15),
                                // Bordure dont la couleur dépend du statut
                                border: Border.all(
                                  color: isConfirmed
                                      ? Colors.green.withOpacity(0.5)
                                      : isCancelled
                                          ? Colors.red.withOpacity(0.5)
                                          : Colors.orange.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              // Contenu interne de la carte
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                // Disposition en colonne des informations
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Ligne avec le numéro de réservation et le badge de statut
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Texte du numéro de réservation avec ellipsis si trop long
                                        Flexible(
                                          child: Text(
                                            "Réservation #${booking['id']}",
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Badge coloré du statut
                                        _buildStatusBadge(booking['status']),
                                      ],
                                    ),
                                    // Espacement vertical
                                    SizedBox(height: 10),
                                    // Affichage conditionnel du nom du véhicule
                                    if (booking['car_name'] != null)
                                      Text(
                                        booking['car_name'],
                                        style: TextStyle(color: Colors.blue, fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    // Ligne de séparation
                                    const Divider(color: Colors.white12, height: 20),
                                    // Ligne pour les dates de réservation
                                    Row(
                                      children: [
                                        // Icône de calendrier
                                        const Icon(Icons.calendar_today, color: Colors.blue, size: 16),
                                        // Espacement horizontal
                                        const SizedBox(width: 8),
                                        // Dates de début et de fin
                                        Flexible(
                                          child: Text(
                                            "Du ${booking['pickup_date']} au ${booking['return_date']}",
                                            style: const TextStyle(color: Colors.white70),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Espacement vertical
                                    const SizedBox(height: 10),
                                    // Ligne pour le prix total
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Libellé "Prix Total"
                                        const Text("Prix Total:", style: TextStyle(color: Colors.white54)),
                                        // Prix total formaté
                                        Text(
                                          "${booking['total_price']} TND",
                                          style: const TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    // Affichage conditionnel de la date de création
                                    if (booking['created_at'] != null)
                                      ...[
                                        // Espacement vertical
                                        SizedBox(height: 10),
                                        // Ligne avec icône et date de création
                                        Row(
                                          children: [
                                            // Icône d'horloge
                                            Icon(Icons.access_time, color: Colors.grey, size: 14),
                                            // Petit espacement
                                            SizedBox(width: 5),
                                            // Date de création
                                            Text(
                                              "Créée le ${booking['created_at']}",
                                              style: TextStyle(color: Colors.grey, fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ],
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        );
      },
    );
  }

  // Méthode utilitaire pour créer un badge coloré selon le statut
  Widget _buildStatusBadge(String status) {
    // Déclaration des variables pour la couleur et l'icône
    Color statusColor;
    IconData statusIcon;
    
    // Logique de sélection basée sur la valeur du statut
    switch (status) {
      case "Confirmée":
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case "Annulée":
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        // Statut par défaut (probablement "En attente")
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top;
    }
    
    // Retour d'un conteneur stylisé pour le badge
    return Container(
      // Espacement interne du badge
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      // Décoration du badge (fond semi-transparent, coins arrondis)
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      // Disposition en ligne pour l'icône et le texte
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône correspondant au statut
          Icon(
            statusIcon,
            size: 14,
            color: statusColor,
          ),
          // Espacement entre l'icône et le texte
          const SizedBox(width: 5),
          // Texte du statut
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}