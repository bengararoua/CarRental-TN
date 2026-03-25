// Import des bibliothèques Flutter nécessaires
import 'package:flutter/material.dart'; // Widgets de base de Flutter
import 'package:flutter/services.dart'; // Services système (clavier, etc.)
import 'package:provider/provider.dart'; // Gestion d'état avec Provider
import '../services/auth_service.dart'; // Service d'authentification et d'API
import '../providers/vehicles_provider.dart'; // Fournisseur de données des véhicules

// Écran d'administration des réservations (StatefulWidget pour état mutable)
class AdminBookingsScreen extends StatefulWidget {
  @override
  _AdminBookingsScreenState createState() => _AdminBookingsScreenState(); // Crée l'état associé
}

// État de l'écran d'administration des réservations
class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  late Future<List<dynamic>> _bookingsFuture; // Future pour charger les réservations
  bool _isLoading = false; // Indicateur de chargement
  String _filterStatus = 'Tous'; // Filtre de statut actif
  String _searchQuery = ''; // Requête de recherche
  
  // Contrôleurs pour le défilement fluide
  final ScrollController _verticalScrollController = ScrollController(); // Contrôleur de défilement vertical
  final FocusNode _focusNode = FocusNode(); // Nœud de focus pour les événements clavier
  final TextEditingController _searchController = TextEditingController(); // Contrôleur du champ de recherche

  @override
  void initState() {
    super.initState(); // Initialise l'état parent
    _loadBookings(); // Charge les réservations au démarrage
  }

  @override
  void dispose() {
    // Nettoie les contrôleurs pour éviter les fuites de mémoire
    _verticalScrollController.dispose(); // Libère le contrôleur de défilement
    _focusNode.dispose(); // Libère le nœud de focus
    _searchController.dispose(); // Libère le contrôleur de texte
    super.dispose(); // Appelle la méthode dispose parente
  }

  // Fonction pour défiler vers le haut de 150 pixels avec animation
  void _scrollUp() {
    if (_verticalScrollController.hasClients) { // Vérifie si le contrôleur est attaché
      _verticalScrollController.animateTo(
        _verticalScrollController.offset - 150, // Nouvelle position (vers le haut)
        duration: Duration(milliseconds: 200), // Durée de l'animation
        curve: Curves.easeOut, // Courbe d'animation
      );
    }
  }

  // Fonction pour défiler vers le bas de 150 pixels avec animation
  void _scrollDown() {
    if (_verticalScrollController.hasClients) { // Vérifie si le contrôleur est attaché
      _verticalScrollController.animateTo(
        _verticalScrollController.offset + 150, // Nouvelle position (vers le bas)
        duration: Duration(milliseconds: 200), // Durée de l'animation
        curve: Curves.easeOut, // Courbe d'animation
      );
    }
  }

  // Charge les réservations depuis l'API
  void _loadBookings() {
    // Récupère le token depuis le provider
    final token = Provider.of<VehiclesProvider>(context, listen: false).token;
    
    if (token != null) { // Vérifie si l'utilisateur est connecté
      setState(() {
        _isLoading = true; // Active l'indicateur de chargement
      });
      
      // Appelle le service pour récupérer toutes les réservations
      //.then():équivalent à utiliser "await" dans une fonction async
      _bookingsFuture = AuthService.fetchAllBookings(token).then((bookings) {
        setState(() {
          _isLoading = false; // Désactive le chargement après réussite
        });
        return bookings; // Retourne les réservations
      }).catchError((error) {
        setState(() {
          _isLoading = false; // Désactive le chargement en cas d'erreur
        });
        return []; // Retourne une liste vide en cas d'erreur
      });
    } else {
      _bookingsFuture = Future.value([]); // Pas de token : liste vide
    }
  }

  // Rafraîchit la liste des réservations (pour le RefreshIndicator)
  Future<void> _refreshBookings() async {
    _loadBookings(); // Recharge les réservations
  }

  // Met à jour le statut d'une réservation via l'API
  Future<void> _updateStatus(int bookingId, String newStatus) async {
    final token = Provider.of<VehiclesProvider>(context, listen: false).token;
    
    if (token == null) return; // Si pas de token, annule

    setState(() => _isLoading = true); // Active le chargement

    // Appelle le service de mise à jour
    final result = await AuthService.updateBookingStatus(bookingId, newStatus, token);

    setState(() => _isLoading = false); // Désactive le chargement

    if (result['success']) { // Si la requête a réussi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']), // Affiche le message de succès
          backgroundColor: Colors.green, // Couleur verte pour succès
        ),
      );
      _refreshBookings(); // Rafraîchit la liste
    } else { // En cas d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']), // Affiche le message d'erreur
          backgroundColor: Colors.red, // Couleur rouge pour erreur
        ),
      );
    }
  }

  // Supprime une réservation après confirmation
  Future<void> _deleteBooking(int bookingId) async {
    // Boîte de dialogue de confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2A2A2A), // Fond sombre
        title: Text('Confirmer la suppression', style: TextStyle(color: Colors.white)),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer cette réservation ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Annuler
            child: Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Confirmer
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return; // Si l'utilisateur annule, on s'arrête

    final token = Provider.of<VehiclesProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true); // Active le chargement

    final result = await AuthService.deleteBooking(bookingId, token); // Appel API

    setState(() => _isLoading = false); // Désactive le chargement

    if (result['success']) { // Succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      _refreshBookings(); // Rafraîchit
    } else { // Échec
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Affiche une boîte de dialogue pour changer le statut
  void _showStatusDialog(int bookingId, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2A2A2A), // Fond sombre
        title: Text('Changer le statut', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Colonne de taille minimale
          children: [
            _buildStatusOption('En attente', bookingId, currentStatus),
            _buildStatusOption('Confirmée', bookingId, currentStatus),
            _buildStatusOption('Annulée', bookingId, currentStatus),
            _buildStatusOption('Terminée', bookingId, currentStatus),
          ],
        ),
      ),
    );
  }

  // Construit un élément de liste pour un statut
  Widget _buildStatusOption(String status, int bookingId, String currentStatus) {
    bool isSelected = status == currentStatus; // Vérifie si c'est le statut actuel
    
    return ListTile(
      title: Text(status, style: TextStyle(color: isSelected ? Colors.blue : Colors.white)),
      leading: Icon(
        _getStatusIcon(status), // Icône correspondante
        color: _getStatusColor(status), // Couleur correspondante
      ),
      selected: isSelected, // Met en surbrillance si sélectionné
      onTap: () {
        Navigator.pop(context); // Ferme la boîte de dialogue
        _updateStatus(bookingId, status); // Met à jour le statut
      },
    );
  }

  // Retourne l'icône appropriée selon le statut
  IconData _getStatusIcon(String status) {
    switch (status) {
      case "Confirmée":
        return Icons.check_circle; // Icône de confirmation
      case "Annulée":
        return Icons.cancel; // Icône d'annulation
      case "Terminée":
        return Icons.done_all; // Icône de terminé
      default:
        return Icons.hourglass_top; // Icône par défaut (en attente)
    }
  }

  // Retourne la couleur appropriée selon le statut
  Color _getStatusColor(String status) {
    switch (status) {
      case "Confirmée":
        return Colors.green; // Vert pour confirmé
      case "Annulée":
        return Colors.red; // Rouge pour annulé
      case "Terminée":
        return Colors.blue; // Bleu pour terminé
      default:
        return Colors.orange; // Orange pour en attente
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Fond noir
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Bouton retour
          onPressed: () => Navigator.of(context).pop(), // Retour à l'écran précédent
        ),
        backgroundColor: const Color(0xFF1A1A1A), // Fond noir
        elevation: 0, // Pas d'ombre
      ),
      // Écoute les touches du clavier pour le défilement
      body: RawKeyboardListener(
        focusNode: _focusNode, // Nœud de focus
        autofocus: true, // Focus automatique
        onKey: (event) {
          if (event is RawKeyDownEvent) { // Si une touche est enfoncée
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _scrollUp(); // Défile vers le haut avec flèche du haut
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _scrollDown(); // Défile vers le bas avec flèche du bas
            }
          }
        },
        child: Column(
          children: [
            // En-tête avec sous-titre seulement
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Visualisez et gérez toutes les réservations du système',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 12),
                      // Badge "Administrateur"
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue, width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: Colors.blue, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Administrateur',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Barre de recherche
                  TextField(
                    controller: _searchController, // Contrôleur pour le texte
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase(); // Met à jour la requête
                      });
                    },
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une réservation...',
                      hintStyle: TextStyle(color: Colors.white54),
                      prefixIcon: Icon(Icons.search, color: Colors.white54), // Icône de recherche
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.white54), // Bouton effacer
                              onPressed: () {
                                _searchController.clear(); // Efface le texte
                                setState(() {
                                  _searchQuery = ''; // Réinitialise la requête
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Color(0xFF2A2A2A), // Fond gris foncé
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none, // Pas de bordure
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),

            // Filtres par statut (défilement horizontal)
            Container(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal, // Défilement horizontal
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildFilterChip('Tous'),
                  _buildFilterChip('En attente'),
                  _buildFilterChip('Confirmée'),
                  _buildFilterChip('Annulée'),
                  _buildFilterChip('Terminée'),
                ],
              ),
            ),

            // Statistiques rapides
            FutureBuilder<List<dynamic>>(
              future: _bookingsFuture, // Future des réservations
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SizedBox(); // Si pas de données, retourne un widget vide
                }
                
                final bookings = snapshot.data!; // Récupère les réservations
                final total = bookings.length; // Nombre total
                final pending = bookings.where((b) => b['status'] == 'En attente').length; // En attente
                final confirmed = bookings.where((b) => b['status'] == 'Confirmée').length; // Confirmées
                final cancelled = bookings.where((b) => b['status'] == 'Annulée').length; // Annulées
                
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A), // Fond gris foncé
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Total', total.toString(), Icons.list_alt, Colors.blue),
                      _buildStatCard('En attente', pending.toString(), Icons.hourglass_top, Colors.orange),
                      _buildStatCard('Confirmées', confirmed.toString(), Icons.check_circle, Colors.green),
                      _buildStatCard('Annulées', cancelled.toString(), Icons.cancel, Colors.red),
                    ],
                  ),
                );
              },
            ),

            // Liste des réservations
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.blue)) // Indicateur de chargement
                  : RefreshIndicator( // Permet de tirer pour rafraîchir
                      onRefresh: _refreshBookings,
                      color: Colors.blue,
                      child: FutureBuilder<List<dynamic>>(
                        future: _bookingsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator(color: Colors.blue)); // Chargement initial
                          } else if (snapshot.hasError) {
                            return Center( // Affichage d'erreur
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red, size: 50),
                                  SizedBox(height: 16),
                                  Text(
                                    "Erreur : ${snapshot.error}",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _refreshBookings, // Bouton pour réessayer
                                    child: Text("Réessayer"),
                                  ),
                                ],
                              ),
                            );
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center( // Aucune donnée
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox, color: Colors.grey, size: 80),
                                  SizedBox(height: 20),
                                  Text(
                                    "Aucune réservation trouvée.",
                                    style: TextStyle(color: Colors.white54, fontSize: 16),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Les réservations apparaîtront ici",
                                    style: TextStyle(color: Colors.white30, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }

                          var bookings = snapshot.data!; // Récupère les réservations
                          
                          // Appliquer les filtres
                          if (_filterStatus != 'Tous') {
                            bookings = bookings.where((b) => b['status'] == _filterStatus).toList(); // Filtre par statut
                          }
                          
                          // Appliquer la recherche
                          if (_searchQuery.isNotEmpty) {
                            bookings = bookings.where((b) {
                              final userName = b['user_name']?.toString().toLowerCase() ?? '';
                              final userEmail = b['user_email']?.toString().toLowerCase() ?? '';
                              final carName = b['car_name']?.toString().toLowerCase() ?? '';
                              final bookingId = b['id']?.toString().toLowerCase() ?? '';
                              
                              // Vérifie si la requête correspond à l'un de ces champs
                              return userName.contains(_searchQuery) ||
                                  userEmail.contains(_searchQuery) ||
                                  carName.contains(_searchQuery) ||
                                  bookingId.contains(_searchQuery);
                            }).toList();
                          }

                          if (bookings.isEmpty) {
                            return Center( // Aucun résultat après filtrage
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, color: Colors.grey, size: 60),
                                  SizedBox(height: 16),
                                  Text(
                                    "Aucune réservation correspondante",
                                    style: TextStyle(color: Colors.white54, fontSize: 16),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Essayez de modifier vos filtres ou votre recherche",
                                    style: TextStyle(color: Colors.white30, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Liste des réservations filtrées
                          return ListView.builder(
                            controller: _verticalScrollController, // Contrôleur de défilement
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: bookings.length,
                            itemBuilder: (context, index) {
                              final booking = bookings[index]; // Réservation courante
                              
                              return Container(
                                margin: EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Color(0xFF2A2A2A), // Fond gris foncé
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: _getStatusColor(booking['status']).withOpacity(0.3), // Bordure colorée selon statut
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: Offset(0, 3), // Ombre portée
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "RÉSERVATION #${booking['id']}", // ID de réservation
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      "Créée le ${booking['created_at']?.split('T')[0] ?? 'Date inconnue'}", // Date de création
                                                      style: TextStyle(
                                                        color: Colors.white54,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              _buildStatusBadge(booking['status']), // Badge du statut
                                            ],
                                          ),
                                          SizedBox(height: 12),
                                          
                                          // Informations client
                                          Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF1A1A1A), // Fond noir
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor: Colors.blue.withOpacity(0.2),
                                                  child: Icon(Icons.person, color: Colors.blue, size: 20), // Icône utilisateur
                                                ),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        booking['user_name'] ?? 'Client inconnu', // Nom du client
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      SizedBox(height: 2),
                                                      Text(
                                                        booking['user_email'] ?? 'Email non fourni', // Email du client
                                                        style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 12,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          
                                          // Véhicule réservé
                                          if (booking['car_name'] != null) // Si le nom du véhicule existe
                                            Container(
                                              padding: EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF1A1A1A), // Fond noir
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.car_rental, color: Colors.blue, size: 20), // Icône véhicule
                                                  SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      booking['car_name'], // Nom du véhicule
                                                      style: TextStyle(
                                                        color: Colors.blue,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  if (booking['car_price'] != null) // Si le prix existe
                                                    Text(
                                                      "${booking['car_price']} TND/jour", // Prix par jour
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          
                                          SizedBox(height: 12),
                                          
                                          // Dates de réservation
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding: EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFF1A1A1A), // Fond noir
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(Icons.calendar_today, color: Colors.green, size: 14), // Icône date début
                                                          SizedBox(width: 6),
                                                          Text(
                                                            'Début',
                                                            style: TextStyle(
                                                              color: Colors.white70,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        booking['pickup_date'] ?? 'Non spécifié', // Date de début
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Container(
                                                  padding: EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFF1A1A1A), // Fond noir
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(Icons.calendar_today, color: Colors.red, size: 14), // Icône date fin
                                                          SizedBox(width: 6),
                                                          Text(
                                                            'Fin',
                                                            style: TextStyle(
                                                              color: Colors.white70,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        booking['return_date'] ?? 'Non spécifié', // Date de fin
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          SizedBox(height: 12),
                                          
                                          // Prix total
                                          Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF1A1A1A), // Fond noir
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  "Prix Total:",
                                                  style: TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  "${booking['total_price'] ?? 0} TND", // Prix total
                                                  style: TextStyle(
                                                    color: Colors.blue,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Boutons d'action (modifier statut et supprimer)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xFF1A1A1A), // Fond noir
                                        borderRadius: BorderRadius.vertical(
                                          bottom: Radius.circular(15), // Arrondi uniquement en bas
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextButton.icon(
                                              onPressed: () => _showStatusDialog(
                                                booking['id'],
                                                booking['status'],
                                              ), // Ouvre la boîte de dialogue de modification
                                              icon: Icon(Icons.edit, color: Colors.blue, size: 18),
                                              label: Text(
                                                'Modifier statut',
                                                style: TextStyle(color: Colors.blue),
                                              ),
                                            ),
                                          ),
                                          Container(width: 1, height: 40, color: Colors.white12), // Séparateur vertical
                                          Expanded(
                                            child: TextButton.icon(
                                              onPressed: () => _deleteBooking(booking['id']), // Supprime la réservation
                                              icon: Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                              label: Text(
                                                'Supprimer',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Construit un filtre sous forme de chip (bouton à bascule)
  Widget _buildFilterChip(String label) {
    bool isSelected = _filterStatus == label; // Vérifie si ce filtre est actif
    
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterStatus = label; // Met à jour le filtre actif
          });
        },
        backgroundColor: Color(0xFF2A2A2A), // Fond gris foncé
        selectedColor: Colors.blue, // Fond bleu quand sélectionné
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // Construit un badge coloré pour le statut
  Widget _buildStatusBadge(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.15), // Fond semi-transparent
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.5), // Bordure colorée
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status), // Icône du statut
            size: 14,
            color: _getStatusColor(status), // Couleur de l'icône
          ),
          SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: _getStatusColor(status), // Couleur du texte
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Construit une carte de statistique (icône + nombre + label)
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), // Fond très transparent
            shape: BoxShape.circle, // Cercle
            border: Border.all(color: color.withOpacity(0.3), width: 1), // Bordure
          ),
          child: Center(
            child: Icon(icon, color: color, size: 22), // Icône au centre
          ),
        ),
        SizedBox(height: 8),
        Text(
          value, // Valeur numérique
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title, // Titre (ex: "Total")
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}