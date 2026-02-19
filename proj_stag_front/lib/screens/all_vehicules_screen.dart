// Importation des packages et fichiers nécessaires
import 'package:flutter/material.dart'; // Import du package Flutter pour l'UI
import 'package:flutter/services.dart'; // Import pour les services système (comme le clavier)
import 'package:provider/provider.dart'; // Import pour la gestion d'état avec Provider
import '../services/auth_service.dart'; // Import du service d'authentification personnalisé
import '../providers/vehicles_provider.dart'; // Import du fournisseur (provider) pour les véhicules
import 'booking_screen.dart'; // Import de l'écran de réservation
import 'add_vehicle_screen.dart'; // Import de l'écran d'ajout de véhicule

// Définition de l'écran principal qui affiche tous les véhicules
class AllVehiclesScreen extends StatefulWidget {
  const AllVehiclesScreen({super.key});

  // Widget avec état pour gérer les changements dynamiques
  @override
  _AllVehiclesScreenState createState() => _AllVehiclesScreenState(); // Crée l'état associé
}

class _AllVehiclesScreenState extends State<AllVehiclesScreen> {
  // Liste des véhicules après application des filtres
  List<Map<String, dynamic>> _filteredVehicles = [];
  
  // Contrôleur pour gérer le défilement de la liste
  final ScrollController _scrollController = ScrollController();
  
  // Nœud de focus pour gérer les entrées clavier
  final FocusNode _focusNode = FocusNode();
  
  // Contrôleur pour le champ de recherche texte
  final TextEditingController _searchController = TextEditingController();
  
  // Catégorie actuellement sélectionnée pour le filtrage
  String _selectedCategory = 'Tous';
  
  // Limite de prix actuelle pour le filtrage
  double _currentPriceLimit = 200.0;
  
  // Prix maximum trouvé parmi tous les véhicules (initialisé à 200)
  double _maxPriceFound = 200.0;
  
  // Booléen pour filtrer uniquement les véhicules disponibles
  bool _onlyAvailable = false;

  // Liste des catégories disponibles pour le filtrage
  final List<String> _categories = ['Tous', 'Économique', 'Citadine', 'Familiale', 'Compacte', 'SUV'];

  @override
  void initState() {
    super.initState(); // Appel de la méthode initState de la classe parente
    // Initialisation supplémentaire pourrait être ajoutée ici
  }

  @override
  void dispose() {
    // Nettoyage des contrôleurs et nœuds de focus pour éviter les fuites de mémoire
    _scrollController.dispose(); // Libère le contrôleur de défilement
    _focusNode.dispose(); // Libère le nœud de focus
    _searchController.dispose(); // Libère le contrôleur de recherche
    super.dispose(); // Appel de la méthode dispose de la classe parente
  }

  // Fonction pour appliquer les filtres de recherche, catégorie, prix et disponibilité
  void _applyFilters() {
    // Récupère le provider des véhicules sans écoute 
    final provider = Provider.of<VehiclesProvider>(context, listen: false);
    
    setState(() {
      // Filtre les véhicules selon les critères
      _filteredVehicles = provider.allVehicles.where((v) {
        // Vérifie si le nom du véhicule contient le texte de recherche (insensible à la casse)
        final matchesSearch = v['name'].toLowerCase().contains(_searchController.text.toLowerCase());
        
        // Vérifie si la catégorie correspond ou si "Tous" est sélectionné
        final matchesCategory = _selectedCategory == 'Tous' || v['category'] == _selectedCategory;
        
        // Vérifie si le prix est inférieur ou égal à la limite actuelle
        final matchesPrice = v['price'] <= _currentPriceLimit;
        
        // Vérifie la disponibilité si l'option est activée
        final matchesAvailability = !_onlyAvailable || v['isAvailable'] == true;
        
        // Retourne true seulement si tous les critères sont satisfaits
        return matchesSearch && matchesCategory && matchesPrice && matchesAvailability;
      }).toList(); // Convertit le résultat en liste
    });
  }

  // Fonction pour ajouter ou retirer un véhicule des favoris
  void _toggleFavorite(int vehicleId, String vehicleName, bool isCurrentlyFavorite) {
    // Appelle la méthode du provider pour basculer l'état favori
    Provider.of<VehiclesProvider>(context, listen: false).toggleFavorite(vehicleId);
    
    // Affiche un message snackbar pour confirmer l'action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          // Message différent selon l'état actuel
          isCurrentlyFavorite
              ? '$vehicleName retiré des favoris'
              : '$vehicleName ajouté aux favoris ❤️'
        ),
        // Couleur différente selon l'action
        backgroundColor: isCurrentlyFavorite ? Colors.grey : Colors.red,
        duration: Duration(seconds: 1), // Durée d'affichage courte
      ),
    );
  }

  // Supprimer un véhicule
  Future<void> _deleteVehicle(int vehicleId, String vehicleName) async {
    // Affiche une boîte de dialogue de confirmation avant suppression
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2A2A2A), // Fond sombre pour le thème
        title: Text('Confirmer la suppression', style: TextStyle(color: Colors.white)),
        content: Text(
          'Voulez-vous vraiment supprimer "$vehicleName" ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          // Bouton Annuler
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Retourne false
            child: Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          // Bouton Supprimer
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Retourne true
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // Si l'utilisateur annule, on quitte la fonction
    if (confirm != true) return;

    // Récupère le provider et le token d'authentification
    final provider = Provider.of<VehiclesProvider>(context, listen: false);
    final token = provider.token;

    // Vérifie si l'utilisateur est connecté (token non nul)
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: Vous devez être connecté'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Arrête l'exécution si non connecté
    }

    // Affiche un indicateur de chargement pendant la suppression
    showDialog(
      context: context,
      barrierDismissible: false, // Empêche la fermeture en cliquant à l'extérieur
      builder: (context) => Center(child: CircularProgressIndicator()), // Indicateur circulaire
    );

    // Appelle le service pour supprimer le véhicule via l'API
    final result = await AuthService.deleteVehicle(vehicleId, token);

    // Ferme l'indicateur de chargement
    Navigator.pop(context);

    // Traite le résultat de la suppression
    if (result['success']) {
      // Affiche un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Véhicule supprimé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      // Recharge la liste des véhicules et réapplique les filtres
      await provider.loadVehicles();
      _applyFilters();
    } else {
      // Affiche un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur lors de la suppression'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

 // Modifier un véhicule
  Future<void> _editVehicle(Map<String, dynamic> vehicle) async {
    // Navigue vers l'écran d'édition en passant les données du véhicule
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVehicleScreen(vehicle: vehicle),
      ),
    );

    // Si la modification a réussi (retourne true), recharge les données
    if (result == true) {
      final provider = Provider.of<VehiclesProvider>(context, listen: false);
      await provider.loadVehicles();
      _applyFilters(); // Réapplique les filtres pour mettre à jour l'affichage
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utilise Consumer pour écouter les changements du VehiclesProvider
    //Consumer écoute le provider et reconstruit automatiquement l’UI quand les données changent
    return Consumer<VehiclesProvider>(
      builder: (context, provider, child) {
        // Calcule le prix maximum parmi les véhicules une seule fois
        if (provider.allVehicles.isNotEmpty && _maxPriceFound == 200.0) {
          //ddPostFrameCallback exécute un code après que le widget soit affiché
          // Utilise addPostFrameCallback pour éviter les erreurs de contexte
          //WidgetsBinding.instance donne accès au moteur Flutter pour exécuter du code
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Trouve le prix maximum dans la liste des véhicules
            //reduce prend une liste et combine tous ses éléments deux par deux pour produire une seule valeur finale
            double maxPrice = provider.allVehicles.map((v) => v['price'] as num).reduce((a, b) => a > b ? a : b).toDouble();
            setState(() {
              _maxPriceFound = maxPrice; // Met à jour la valeur max
              _currentPriceLimit = maxPrice; // Définit la limite actuelle au max
            });
          });
        }

        // Si aucun filtre n'est appliqué et la liste filtrée est vide
     if (_filteredVehicles.isEmpty &&
    _searchController.text.isEmpty &&
    _selectedCategory == 'Tous' &&
    _currentPriceLimit == _maxPriceFound &&
    !_onlyAvailable) {
  _filteredVehicles = provider.allVehicles;
}

        // Retourne la structure principale de l'écran
        return Scaffold(
          backgroundColor: Color(0xFF1A1A1A), // Fond sombre
          appBar: AppBar(
            backgroundColor: Color(0xFF1A1A1A), // Couleur de l'appBar
            elevation: 0, // Pas d'ombre
            automaticallyImplyLeading: false, // Désactive le bouton retour automatique
            title: MouseRegion(
              cursor: SystemMouseCursors.click, // Change le curseur au survol
              child: GestureDetector(
                onTap: () => Navigator.pop(context), // Retour à l'écran précédent
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), // Icône retour
                    SizedBox(width: 8), // Espacement
                    Text('Nos Voitures', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), // Titre
                  ],
                ),
              ),
            ),
          ),
          // RawKeyboardListener pour gérer les touches fléchées du clavier
          body: RawKeyboardListener(
            focusNode: _focusNode,
            autofocus: true, // Prend le focus automatiquement
            onKey: (event) {
              // Détecte les touches pressées
              if (event is RawKeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  // Défile vers le haut
                  _scrollController.animateTo(
                    _scrollController.offset - 150,
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  // Défile vers le bas
                  _scrollController.animateTo(
                    _scrollController.offset + 150,
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
              }
            },
            child: Column(
              children: [
                _buildFilters(), // Affiche la section des filtres
                Expanded(
                  child: provider.isLoading
                      ? Center(child: CircularProgressIndicator()) // Indicateur de chargement
                      : _filteredVehicles.isEmpty
                          ? Center(
                              // Message si aucun véhicule trouvé
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 80, color: Colors.grey), // Icône
                                  SizedBox(height: 16), // Espacement
                                  Text('Aucun véhicule trouvé', style: TextStyle(color: Colors.white70, fontSize: 18)), // Texte
                                ],
                              ),
                            )
                          : GridView.builder(
                              // Grille des véhicules filtrés
                              controller: _scrollController, // Contrôleur de défilement
                              padding: EdgeInsets.all(16), // Marge interne
                              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 400, // Largeur max par élément
                                mainAxisExtent: 380, // Hauteur fixe par élément
                                crossAxisSpacing: 16, // Espacement horizontal
                                mainAxisSpacing: 16, // Espacement vertical
                              ),
                              itemCount: _filteredVehicles.length, // Nombre d'éléments
                              itemBuilder: (context, index) =>
                                  _buildVehicleCard(_filteredVehicles[index], provider), // Construit chaque carte
                            ),
                ),
              ],
            ),
          ),
          // Bouton flottant pour ajouter un véhicule (visible seulement pour l'admin)
          floatingActionButton: provider.isAdmin
              ? FloatingActionButton(
                  onPressed: () {
                    // Navigue vers l'écran d'ajout de véhicule
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddVehicleScreen(),
                      ),
                    ).then((_) async {
                      // Après retour, recharge les véhicules et réapplique les filtres
                      await provider.loadVehicles();
                      _applyFilters();
                    });
                  },
                  backgroundColor: Colors.blue, // Couleur bleue
                  child: Icon(Icons.add, color: Colors.white, size: 30), // Icône d'ajout
                )
              : null, // Pas de bouton si non admin
        );
      },
    );
  }

  // Construit la section des filtres (recherche, catégorie, prix, disponibilité)
  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(16), // Marge interne
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A), // Fond sombre
        border: Border(bottom: BorderSide(color: Colors.white12)), // Bordure inférieure subtile
      ),
      child: Column(
        children: [
          // Champ de recherche
          TextField(
            controller: _searchController, // Contrôleur pour le texte
            style: TextStyle(color: Colors.white), // Couleur du texte saisi
            decoration: InputDecoration(
              hintText: 'Rechercher un véhicule...', // Texte d'indication
              hintStyle: TextStyle(color: Colors.white54), // Couleur du texte d'indication
              prefixIcon: Icon(Icons.search, color: Colors.white70), // Icône de recherche
              filled: true, // Remplir le fond
              fillColor: Color(0xFF2A2A2A), // Couleur de fond
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), // Bord arrondi
            ),
            onChanged: (_) => _applyFilters(), // Applique les filtres à chaque frappe
          ),
          SizedBox(height: 12), // Espacement
          Row(
            children: [
              // Dropdown pour la catégorie
              Expanded(child: _buildDropdown(_selectedCategory, _categories, (val) {
                setState(() => _selectedCategory = val!); // Met à jour la catégorie sélectionnée
                _applyFilters(); // Applique les filtres
              })),
              SizedBox(width: 12), // Espacement
              // Slider pour le prix maximum
              Expanded(
                flex: 2, // Prend plus d'espace
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prix max: ${_currentPriceLimit.toInt()} TND', style: TextStyle(color: Colors.white70, fontSize: 12)), // Affichage de la valeur
                    Slider(
                      value: _currentPriceLimit, // Valeur actuelle
                      min: 0, // Valeur minimale
                      max: _maxPriceFound, // Valeur maximale (dynamique)
                      //Si le prix maximum est positif, on divise le slider en autant de pas que ce prix ; sinon, on met au moins 1 pas
                      divisions: (_maxPriceFound > 0) ? _maxPriceFound.toInt() : 1, // Nombre de divisions
                      activeColor: Colors.blue, // Couleur de la partie active
                      inactiveColor: Colors.white24, // Couleur de la partie inactive
                      onChanged: (val) {
                        setState(() => _currentPriceLimit = val); // Met à jour la limite de prix
                        _applyFilters(); // Applique les filtres
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 15), // Espacement
              Text("Dispo", style: TextStyle(color: Colors.white, fontSize: 12)), // Libellé du switch
              // Switch pour filtrer par disponibilité
              Switch(
                value: _onlyAvailable,
                activeThumbColor: Colors.blue, // Couleur quand activé
                onChanged: (val) {
                  setState(() => _onlyAvailable = val); // Met à jour la valeur
                  _applyFilters(); // Applique les filtres
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Construit un menu déroulant (Dropdown) personnalisé
  Widget _buildDropdown(String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10), // Marge interne horizontale
      decoration: BoxDecoration(color: Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(12)), // Fond et bord arrondi
      child: DropdownButton<String>(
        value: value, // Valeur sélectionnée
        dropdownColor: Color(0xFF2A2A2A), // Couleur du menu déroulant
        underline: SizedBox(), // Supprime la ligne par défaut
        style: TextStyle(color: Colors.white, fontSize: 13), // Style du texte
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), // Crée les options
        onChanged: onChanged, // Callback quand une option est sélectionnée
      ),
    );
  }

  // Avec boutons admin (modifier et supprimer)
  Widget _buildVehicleCard(Map<String, dynamic> v, VehiclesProvider provider) {
    // Détermine si le véhicule est en favori
    bool isFavorite = v['isFavorite'] ?? false;
    // Vérifie si l'utilisateur est administrateur
    bool isAdmin = provider.isAdmin;

    return Container(
      decoration: BoxDecoration(color: Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(16)), // Carte avec fond sombre et coins arrondis
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
        children: [
          Stack(
            children: [
              // Image du véhicule
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)), // Arrondi uniquement en haut
                child: Image.network(
                  v['image'], // URL de l'image
                  fit: BoxFit.cover, // Remplir l'espace
                  width: double.infinity, // Largeur totale
                  height: 160, // Hauteur fixe
                  errorBuilder: (_, __, ___) => Container(
                    // Si l'image ne charge pas, affiche une icône de remplacement
                    height: 160,
                    color: Color(0xFF3A3A3A),
                    child: Center(child: Icon(Icons.car_repair, color: Colors.white, size: 40)),
                  ),
                ),
              ),
              // Bouton favori (en haut à droite)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _toggleFavorite(v['id'], v['name'], isFavorite), // Appelle la fonction pour basculer le favori
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4), // Fond semi-transparent
                      shape: BoxShape.circle, // Forme circulaire
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border, // Icône pleine ou vide selon l'état
                      color: isFavorite ? Colors.red : Colors.white, // Couleur rouge si favori, blanche sinon
                      size: 20,
                    ),
                  ),
                ),
              ),
              //  BOUTONS ADMIN (en haut à gauche) - Visibles seulement pour l'admin
              if (isAdmin)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    children: [
                      // Bouton Modifier
                      GestureDetector(
                        onTap: () => _editVehicle(v), // Appelle la fonction d'édition
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.8), // Fond bleu semi-transparent
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.edit, color: Colors.white, size: 18), // Icône d'édition
                        ),
                      ),
                      SizedBox(width: 8), // Espacement entre les boutons
                      // Bouton Supprimer
                      GestureDetector(
                        onTap: () => _deleteVehicle(v['id'], v['name']), // Appelle la fonction de suppression
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8), // Fond rouge semi-transparent
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.delete, color: Colors.white, size: 18), // Icône de suppression
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Contenu textuel de la carte
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12), // Marge interne
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du véhicule
                  Text(v['name'], style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  // Catégorie du véhicule
                  Text(v['category'], style: TextStyle(color: Colors.blue, fontSize: 11)),
                  SizedBox(height: 4), // Espacement
                  // Description détaillée du véhicule (défilable)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        "Cette voiture (${v['year']}) avec moteur ${v['engine']} "
                        "offre ${v['seats']} places et une boîte ${v['transmission']}. "
                        "Carburant: ${v['fuel']}. Coffre: ${v['luggage']} bagages. "
                        "${v['airConditioning'] ? 'Climatisée.' : 'Non climatisée.'}",
                        style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3), // Texte gris clair
                      ),
                    ),
                  ),
                  SizedBox(height: 4), // Espacement
                  // Ligne avec le prix et le bouton de réservation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Prix du véhicule
                      Text("${v['price'].toInt()} TND", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      // Bouton de réservation
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: v['isAvailable'] ? Colors.white : Colors.grey[800], // Blanc si disponible, gris sinon
                          foregroundColor: v['isAvailable'] ? Colors.black : Colors.white38, // Texte noir si disponible, gris clair sinon
                          shape: StadiumBorder(), // Forme arrondie
                          padding: EdgeInsets.symmetric(horizontal: 12), // Marge interne horizontale
                        ),
                        onPressed: v['isAvailable'] 
                            ? () {
                                // Navigue vers l'écran de réservation si disponible
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookingScreen(vehicle: v),
                                  ),
                                );
                              } 
                            : null, // Désactivé si non disponible
                        child: Text(v['isAvailable'] ? "Réserver" : "Occupé", style: TextStyle(fontSize: 11)), // Texte du bouton
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ÉCRAN - Modifier un véhicule
class EditVehicleScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle; // Données du véhicule à modifier

  const EditVehicleScreen({super.key, required this.vehicle}); // Constructeur

  @override
  _EditVehicleScreenState createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>(); // Clé pour gérer le formulaire
  final ScrollController _scrollController = ScrollController(); // Contrôleur de défilement
  
  // Contrôleurs pour les champs de texte
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _seatsController;
  late TextEditingController _engineController;
  late TextEditingController _yearController;
  late TextEditingController _luggageController;
  late TextEditingController _ratingController;
  late TextEditingController _popularityController;
  
  // Variables pour les sélections et états
  late String _selectedCategory;
  late String _selectedTransmission;
  late String _selectedFuel;
  late bool _isAvailable;
  late bool _isNew;
  late bool _isBestChoice;
  late bool _hasAirConditioning;
  late bool _hasBluetooth;
  bool _isLoading = false; // Indicateur de chargement pendant la mise à jour

  // Listes d'options pour les menus déroulants
  final List<String> _categories = ['Économique', 'Citadine', 'Familiale', 'Compacte', 'SUV', 'Berline'];
  final List<String> _transmissions = ['Automatique', 'Manuelle', 'Hybride'];
  final List<String> _fuels = ['Essence', 'Diesel', 'Électrique', 'Hybride'];

  @override
  void initState() {
    super.initState();
    // Initialise les contrôleurs avec les valeurs existantes du véhicule
    _nameController = TextEditingController(text: widget.vehicle['name']);
    _priceController = TextEditingController(text: widget.vehicle['price'].toString());
    _seatsController = TextEditingController(text: widget.vehicle['seats']?.toString() ?? '');
    _engineController = TextEditingController(text: widget.vehicle['engine'] ?? '');
    _yearController = TextEditingController(text: widget.vehicle['year']?.toString() ?? '');
    _luggageController = TextEditingController(text: widget.vehicle['luggage'] ?? '');
    _ratingController = TextEditingController(text: widget.vehicle['rating']?.toString() ?? '0.0');
    _popularityController = TextEditingController(text: widget.vehicle['popularity'] ?? '');
    
    // Initialise les sélections avec les valeurs existantes
    _selectedCategory = widget.vehicle['category'] ?? 'Économique';
    _selectedTransmission = widget.vehicle['transmission'] ?? 'Automatique';
    _selectedFuel = widget.vehicle['fuel'] ?? 'Essence';
    _isAvailable = widget.vehicle['isAvailable'] ?? true;
    _isNew = widget.vehicle['isNew'] ?? false;
    _isBestChoice = widget.vehicle['isBestChoice'] ?? false;
    _hasAirConditioning = widget.vehicle['airConditioning'] ?? true;
    _hasBluetooth = widget.vehicle['bluetooth'] ?? true;
  }

  @override
  void dispose() {
    // Nettoie tous les contrôleurs
    _scrollController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    _engineController.dispose();
    _yearController.dispose();
    _luggageController.dispose();
    _ratingController.dispose();
    _popularityController.dispose();
    super.dispose();
  }

  // Fonction pour mettre à jour le véhicule via l'API
  Future<void> _updateVehicle() async {
    // Valide le formulaire
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Arrête si validation échoue
    }

    // Récupère le provider et le token
    final provider = Provider.of<VehiclesProvider>(context, listen: false);
    final token = provider.token;
    
    // Vérifie la connexion
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: Vous devez être connecté'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true); // Active l'indicateur de chargement

    // Prépare les données à envoyer
    final vehicleData = {
      'name': _nameController.text.trim(),
      'category': _selectedCategory,
      'price': double.parse(_priceController.text),
      'image': widget.vehicle['image'], // Garde l'image existante (pas de modification d'image ici)
      'transmission': _selectedTransmission,
      'seats': int.parse(_seatsController.text),
      'engine': _engineController.text.trim(),
      'year': int.parse(_yearController.text),
      'fuel': _selectedFuel,
      'isAvailable': _isAvailable,
      'isNew': _isNew,
      'isBestChoice': _isBestChoice,
      'rating': double.parse(_ratingController.text),
      'popularity': _popularityController.text.trim(),
      'luggage': _luggageController.text.trim(),
      'airConditioning': _hasAirConditioning,
      'bluetooth': _hasBluetooth,
    };

    // Appelle le service pour mettre à jour le véhicule
    final result = await AuthService.updateVehicle(
      widget.vehicle['id'], // ID du véhicule à modifier
      vehicleData,
      token,
    );

    setState(() => _isLoading = false); // Désactive l'indicateur de chargement

    // Traite le résultat
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Véhicule modifié avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Retourne true pour indiquer le succès
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur lors de la modification'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A), // Fond sombre
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        title: Text('Modifier le véhicule', style: TextStyle(color: Colors.white)), // Titre
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Bouton retour
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Gestion du clavier pour le défilement avec flèches
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              // Défile vers le haut
              _scrollController.animateTo(
                _scrollController.offset - 100,
                duration: Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              // Défile vers le bas
              _scrollController.animateTo(
                _scrollController.offset + 100,
                duration: Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          }
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(16), // Marge interne
          child: Form(
            key: _formKey, // Associe la clé du formulaire
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Étire les enfants en largeur
              children: [
                // Champs de formulaire avec des méthodes helper
                _buildTextField('Nom du véhicule', _nameController, Icons.directions_car),
                SizedBox(height: 16),
                _buildTextField('Prix (TND)', _priceController, Icons.attach_money, isNumber: true),
                SizedBox(height: 16),
                _buildDropdownField('Catégorie', _selectedCategory, _categories, (val) {
                  setState(() => _selectedCategory = val!); // Met à jour la catégorie
                }),
                SizedBox(height: 16),
                _buildTextField('Nombre de sièges', _seatsController, Icons.event_seat, isNumber: true),
                SizedBox(height: 16),
                _buildTextField('Moteur (ex: 1.5L)', _engineController, Icons.engineering),
                SizedBox(height: 16),
                _buildTextField('Année', _yearController, Icons.calendar_today, isNumber: true),
                SizedBox(height: 16),
                _buildDropdownField('Transmission', _selectedTransmission, _transmissions, (val) {
                  setState(() => _selectedTransmission = val!); // Met à jour la transmission
                }),
                SizedBox(height: 16),
                _buildDropdownField('Carburant', _selectedFuel, _fuels, (val) {
                  setState(() => _selectedFuel = val!); // Met à jour le carburant
                }),
                SizedBox(height: 16),
                _buildTextField('Capacité coffre (ex: 380L)', _luggageController, Icons.luggage),
                SizedBox(height: 16),
                _buildTextField('Note (0.0 - 5.0)', _ratingController, Icons.star, isNumber: true),
                SizedBox(height: 16),
                _buildTextField('Popularité', _popularityController, Icons.trending_up),
                SizedBox(height: 20),
                // Switches pour les options booléennes
                _buildSwitchRow('Disponible', _isAvailable, (val) => setState(() => _isAvailable = val)),
                _buildSwitchRow('Nouveau', _isNew, (val) => setState(() => _isNew = val)),
                _buildSwitchRow('Meilleur choix', _isBestChoice, (val) => setState(() => _isBestChoice = val)),
                _buildSwitchRow('Climatisation', _hasAirConditioning, (val) => setState(() => _hasAirConditioning = val)),
                _buildSwitchRow('Bluetooth', _hasBluetooth, (val) => setState(() => _hasBluetooth = val)),
                SizedBox(height: 30),
                // Bouton de mise à jour
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateVehicle, // Désactivé pendant le chargement
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Couleur bleue
                    padding: EdgeInsets.symmetric(vertical: 16), // Marge interne verticale
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Coins arrondis
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white) // Indicateur de chargement
                      : Text('Mettre à jour', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper pour construire un champ de texte
  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text, // Clavier numérique si besoin
      style: TextStyle(color: Colors.white), // Couleur du texte
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70), // Couleur du label
        prefixIcon: Icon(icon, color: Colors.white70), // Icône
        filled: true,
        fillColor: Color(0xFF2A2A2A), // Fond sombre
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // Pas de bordure
        ),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null, // Validation requise
    );
  }

  // Helper pour construire un menu déroulant
  Widget _buildDropdownField(String label, String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A), // Fond sombre
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        dropdownColor: Color(0xFF2A2A2A), // Couleur du menu déroulant
        style: TextStyle(color: Colors.white), // Couleur du texte
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none, // Pas de bordure
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), // Crée les options
        onChanged: onChanged, // Callback de changement
      ),
    );
  }

  // Helper pour construire une ligne avec un switch
  Widget _buildSwitchRow(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white, fontSize: 16)), // Label
        Switch(
          value: value,
          activeThumbColor: Colors.blue, // Couleur quand activé
          onChanged: onChanged, // Callback de changement
        ),
      ],
    );
  }
}