// Importation des bibliothèques Flutter nécessaires
import 'package:flutter/material.dart'; // Widgets Material Design
import 'package:flutter/services.dart'; // Services système comme le clavier
import 'package:provider/provider.dart'; // Gestion d'état avec Provider
import '../providers/vehicles_provider.dart'; // Provider personnalisé pour les véhicules
import '../services/auth_service.dart'; // Service d'authentification

// Écran pour ajouter un véhicule 
class AddVehicleScreen extends StatefulWidget {
  @override
  _AddVehicleScreenState createState() => _AddVehicleScreenState(); // Crée l'état associé
}

// Classe d'état pour AddVehicleScreen
class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>(); // Clé pour valider le formulaire
  final ScrollController _scrollController = ScrollController(); // Contrôleur pour le défilement
  final FocusNode _focusNode = FocusNode(); // Nœud de focus pour écouter les touches clavier
  
  // Contrôleurs pour les champs de texte (gèrent la saisie utilisateur)
  final _nameController = TextEditingController(); // Contrôleur pour le nom
  final _imageController = TextEditingController(); // Contrôleur pour l'URL de l'image
  final _priceController = TextEditingController(); // Contrôleur pour le prix
  final _seatsController = TextEditingController(); // Contrôleur pour le nombre de sièges
  final _engineCapacityController = TextEditingController(); // Contrôleur pour la capacité moteur
  final _yearController = TextEditingController(); // Contrôleur pour l'année
  final _luggageCapacityController = TextEditingController(); // Contrôleur pour la capacité du coffre
  final _ratingController = TextEditingController(); // Contrôleur pour la note
  final _popularityController = TextEditingController(); // Contrôleur pour la popularité
  
  // Variables pour les sélections avec valeurs par défaut
  String _selectedCategory = 'Économique'; // Catégorie sélectionnée
  String _selectedTransmission = 'Automatique'; // Transmission sélectionnée
  String _selectedFuel = 'Essence'; // Carburant sélectionné
  bool _isAvailable = true; // Disponibilité du véhicule
  bool _isNew = false; // Si le véhicule est nouveau
  bool _isBestChoice = false; // Si c'est le meilleur choix
  bool _hasAirConditioning = true; // Si le véhicule a la climatisation
  bool _hasBluetooth = true; // Si le véhicule a le Bluetooth
  bool _isLoading = false; // État de chargement lors de l'ajout

  // Listes de choix pour les menus déroulants
  final List<String> _categories = ['Économique', 'Citadine', 'Familiale', 'Compacte', 'SUV']; // Catégories
  final List<String> _transmissions = ['Automatique', 'Manuelle']; // Types de transmission
  final List<String> _fuels = ['Essence', 'Diesel', 'Électrique', 'Hybride']; // Types de carburant

  @override
  void dispose() {
    // Nettoie tous les contrôleurs et objets pour éviter les fuites de mémoire
    _scrollController.dispose(); // Libère le contrôleur de défilement
    _focusNode.dispose(); // Libère le nœud de focus
    _nameController.dispose(); // Libère le contrôleur du nom
    _imageController.dispose(); // Libère le contrôleur de l'image
    _priceController.dispose(); // Libère le contrôleur du prix
    _seatsController.dispose(); // Libère le contrôleur des sièges
    _engineCapacityController.dispose(); // Libère le contrôleur du moteur
    _yearController.dispose(); // Libère le contrôleur de l'année
    _luggageCapacityController.dispose(); // Libère le contrôleur du coffre
    _ratingController.dispose(); // Libère le contrôleur de la note
    _popularityController.dispose(); // Libère le contrôleur de la popularité
    super.dispose(); // Appelle la méthode dispose de la classe parente
  }

  // Fonction pour faire défiler vers le haut
  void _scrollUp() {
    if (_scrollController.hasClients) { // Vérifie si le contrôleur est attaché à un widget
      _scrollController.animateTo( // Anime le défilement
        _scrollController.offset - 150, // Réduit l'offset de 150 pixels
        duration: Duration(milliseconds: 200), // Durée de l'animation
        curve: Curves.easeOut, // Courbe d'animation
      );
    }
  }

  // Fonction pour faire défiler vers le bas
  void _scrollDown() {
    if (_scrollController.hasClients) { // Vérifie si le contrôleur est attaché
      _scrollController.animateTo(
        _scrollController.offset + 150, // Augmente l'offset de 150 pixels
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  // Fonction asynchrone pour ajouter un véhicule
  Future<void> _addVehicle() async {
    if (!_formKey.currentState!.validate()) { // Valide le formulaire
      // Affiche un message d'erreur si le formulaire n'est pas valide
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Arrête l'exécution
    }

    // Récupère le token d'authentification depuis le provider
    //listen: false → Le widget ne se met PAS à jour, il lit juste la valeur une fois.
    final token = Provider.of<VehiclesProvider>(context, listen: false).token;
    
    if (token == null) { // Vérifie si l'utilisateur est connecté
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous devez être connecté'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true); // Active l'indicateur de chargement

    try {
      // Prépare les données du véhicule à envoyer
      final vehicleData = {
        'name': _nameController.text.trim(), // Nom du véhicule (sans espaces superflus)
        'category': _selectedCategory, // Catégorie sélectionnée
        'price': int.parse(_priceController.text), // Prix converti en entier
        'image': _imageController.text.trim(), // URL de l'image
        'transmission': _selectedTransmission, // Transmission sélectionnée
        'seats': int.parse(_seatsController.text), // Nombre de sièges
        'engine': _engineCapacityController.text.trim(), // Capacité moteur
        'year': int.parse(_yearController.text), // Année
        'fuel': _selectedFuel, // Carburant
        'isAvailable': _isAvailable, // Disponibilité
        'isNew': _isNew, // Nouveau véhicule
        'isBestChoice': _isBestChoice, // Meilleur choix
        'rating': double.parse(_ratingController.text.isEmpty ? '0.0' : _ratingController.text), // Note (défaut 0.0)
        'popularity': int.parse(_popularityController.text.isEmpty ? '0' : _popularityController.text), // Popularité (défaut 0)
        'luggage': int.parse(_luggageCapacityController.text), // Capacité du coffre
        'airConditioning': _hasAirConditioning, // Climatisation
        'bluetooth': _hasBluetooth, // Bluetooth
      };

      print('📤 Données du véhicule: $vehicleData'); // Affiche les données dans la console

      // Appelle le service d'ajout de véhicule
      final result = await AuthService.addVehicle(vehicleData, token);

      if (!result['success']) { // Vérifie si l'ajout a échoué
        throw Exception(result['message']); // Lance une exception avec le message d'erreur
      }
      
      setState(() => _isLoading = false); // Désactive le chargement

      // Affiche un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Véhicule ajouté avec succès !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Recharge la liste des véhicules dans le provider
      await Provider.of<VehiclesProvider>(context, listen: false).loadVehicles();

      Navigator.pop(context); // Retourne à l'écran précédent

    } catch (e) { // Gère les erreurs
      setState(() => _isLoading = false); // Désactive le chargement
      print('❌ Erreur ajout véhicule: $e'); // Affiche l'erreur dans la console
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'), // Affiche l'erreur à l'utilisateur
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A), // Fond noir
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A), // Fond noir
        elevation: 0, // Pas d'ombre
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), // Icône de retour
          onPressed: () => Navigator.pop(context), // Retourne à l'écran précédent
        ),
        title: Row(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.blue, size: 24), // Icône d'ajout
            SizedBox(width: 8), // Espacement
            Text(
              'Ajouter un véhicule', // Titre de l'app bar
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: RawKeyboardListener( // Écoute les touches du clavier
        focusNode: _focusNode, // Nœud de focus
        autofocus: true, // Focus automatique
        onKey: (event) {
          if (event is RawKeyDownEvent) { // Vérifie si une touche est enfoncée
          //// Vérifie si la touche du clavier pressée est la flèche vers le haut (Arrow Up)
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) { 
              _scrollUp(); // Défile vers le haut
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) { // Flèche bas
              _scrollDown(); // Défile vers le bas
            }
          }
        },
        child: SingleChildScrollView( // Permet le défilement
          controller: _scrollController, // Contrôleur de défilement
          padding: EdgeInsets.all(16), // Marge intérieure
          child: Form( // Formulaire
            key: _formKey, // Clé du formulaire
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
              children: [
                Container( // Bannière d'en-tête
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient( // Dégradé de bleu
                      colors: [Colors.blue, Colors.blue.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12), // Bords arrondis
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2), // Fond blanc translucide
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.directions_car, color: Colors.white, size: 32), // Icône de voiture
                      ),
                      SizedBox(width: 16), // Espacement
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nouveau véhicule', // Titre
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4), // Espacement
                            Text(
                              'Remplissez tous les champs ci-dessous', // Sous-titre
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24), // Espacement

                // SECTION 1 : Informations principales
                _buildSectionTitle('Informations principales', Icons.info_outline), // Titre de section
                SizedBox(height: 12), // Espacement

                _buildTextField( // Champ pour le nom du véhicule
                  controller: _nameController,
                  label: 'Nom du véhicule',
                  icon: Icons.car_rental,
                  hint: 'Ex: Renault Clio',
                  validator: (v) => v!.isEmpty ? 'Champ requis' : null, // Validation obligatoire
                ),
                SizedBox(height: 16), // Espacement

                _buildTextField( // Champ pour l'URL de l'image
                  controller: _imageController,
                  label: 'URL de l\'image',
                  icon: Icons.image,
                  hint: 'https://exemple.com/image.jpg',
                  validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                ),
                SizedBox(height: 16), // Espacement

                Row( // Ligne avec deux champs côte à côte
                  children: [
                    Expanded(
                      child: _buildDropdown( // Menu déroulant pour la catégorie
                        value: _selectedCategory,
                        label: 'Catégorie',
                        icon: Icons.category,
                        items: _categories,
                        onChanged: (value) => setState(() => _selectedCategory = value!), // Met à jour l'état
                      ),
                    ),
                    SizedBox(width: 12), // Espacement
                    Expanded(
                      child: _buildTextField( // Champ pour le prix
                        controller: _priceController,
                        label: 'Prix (TND/jour)',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number, // Clavier numérique
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24), // Espacement

                // SECTION 2 : Caractéristiques techniques
                _buildSectionTitle('Caractéristiques techniques', Icons.build),
                SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField( // Champ pour le nombre de sièges
                        controller: _seatsController,
                        label: 'Sièges',
                        icon: Icons.event_seat,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField( // Champ pour l'année
                        controller: _yearController,
                        label: 'Année',
                        icon: Icons.calendar_today,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown( // Menu déroulant pour la transmission
                        value: _selectedTransmission,
                        label: 'Transmission',
                        icon: Icons.settings,
                        items: _transmissions,
                        onChanged: (value) => setState(() => _selectedTransmission = value!),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown( // Menu déroulant pour le carburant
                        value: _selectedFuel,
                        label: 'Carburant',
                        icon: Icons.local_gas_station,
                        items: _fuels,
                        onChanged: (value) => setState(() => _selectedFuel = value!),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField( // Champ pour la capacité moteur
                        controller: _engineCapacityController,
                        label: 'Moteur (L)',
                        icon: Icons.engineering,
                        hint: 'Ex: 2.0L, 1.5L',
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField( // Champ pour la capacité du coffre
                        controller: _luggageCapacityController,
                        label: 'Coffre (L)',
                        icon: Icons.luggage,
                        hint: 'Ex: 380L, 497L',
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // SECTION 3 : Options et équipements
                _buildSectionTitle('Options et équipements', Icons.checklist),
                SizedBox(height: 12),

                Container( // Conteneur pour les options
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A), // Fond gris foncé
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildSwitchTile( // Interrupteur pour la climatisation
                        title: 'Climatisation',
                        icon: Icons.ac_unit,
                        value: _hasAirConditioning,
                        onChanged: (v) => setState(() => _hasAirConditioning = v),
                      ),
                      Divider(color: Colors.white12, height: 24), // Séparateur
                      _buildSwitchTile( // Interrupteur pour le Bluetooth
                        title: 'Bluetooth',
                        icon: Icons.bluetooth,
                        value: _hasBluetooth,
                        onChanged: (v) => setState(() => _hasBluetooth = v),
                      ),
                      Divider(color: Colors.white12, height: 24),
                      _buildSwitchTile( // Interrupteur pour la disponibilité
                        title: 'Disponible',
                        icon: Icons.check_circle,
                        value: _isAvailable,
                        onChanged: (v) => setState(() => _isAvailable = v),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // SECTION 4 : Marketing
                _buildSectionTitle('Marketing et visibilité', Icons.star),
                SizedBox(height: 12),

                Container( // Conteneur pour les options marketing
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildSwitchTile( // Interrupteur pour "Nouveau véhicule"
                        title: 'Nouveau véhicule',
                        subtitle: 'Apparaît dans "Nouveautés 2026"',
                        icon: Icons.fiber_new,
                        value: _isNew,
                        onChanged: (v) => setState(() => _isNew = v),
                      ),
                      Divider(color: Colors.white12, height: 24),
                      _buildSwitchTile( // Interrupteur pour "Meilleur choix"
                        title: 'Meilleur choix',
                        subtitle: 'Apparaît dans "Nos Meilleurs Choix"',
                        icon: Icons.star,
                        value: _isBestChoice,
                        onChanged: (v) => setState(() => _isBestChoice = v),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField( // Champ pour la note
                        controller: _ratingController,
                        label: 'Note (0-5)',
                        icon: Icons.star_rate,
                        keyboardType: TextInputType.numberWithOptions(decimal: true), // Clavier numérique avec décimales
                        hint: '4.5',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField( // Champ pour la popularité
                        controller: _popularityController,
                        label: 'Popularité',
                        icon: Icons.trending_up,
                        keyboardType: TextInputType.number,
                        hint: '0',
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 32),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton( // Bouton "Annuler"
                        onPressed: _isLoading ? null : () => Navigator.pop(context), // Désactivé pendant le chargement
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red, width: 2), // Bordure rouge
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Annuler',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 2, // Prend plus d'espace que le bouton Annuler
                      child: ElevatedButton( // Bouton "Ajouter le véhicule"
                        onPressed: _isLoading ? null : _addVehicle, // Appelle _addVehicle si non en chargement
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // Fond bleu
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? SizedBox( // Indicateur de chargement
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row( // Contenu du bouton (icône + texte)
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ajouter le véhicule',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 40), // Espacement final
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Méthode pour construire un titre de section avec icône
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1), // Fond bleu très transparent
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue, size: 20), // Icône
        ),
        SizedBox(width: 12), // Espacement
        Text(
          title, // Texte du titre
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Méthode pour construire un champ de texte
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller, // Contrôleur pour le champ
      keyboardType: keyboardType, // Type de clavier (ex: numérique)
      style: TextStyle(color: Colors.white), // Style du texte saisi
      decoration: InputDecoration(
        labelText: label, // Étiquette du champ
        hintText: hint, // Texte indicatif
        labelStyle: TextStyle(color: Colors.white70), // Style de l'étiquette
        hintStyle: TextStyle(color: Colors.white30), // Style du texte indicatif
        prefixIcon: Icon(icon, color: Colors.blue), // Icône à gauche
        filled: true, // Remplir le fond
        fillColor: Color(0xFF2A2A2A), // Couleur de fond
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // Pas de bordure par défaut
        ),
        enabledBorder: OutlineInputBorder( // Bordure quand le champ est activé
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white12, width: 1),
        ),
        focusedBorder: OutlineInputBorder( // Bordure quand le champ est focus
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder( // Bordure en cas d'erreur
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
      ),
      validator: validator, // Fonction de validation
    );
  }

  // Méthode pour construire un menu déroulant
  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A), // Fond gris foncé
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1), // Bordure légère
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16, top: 8),
            child: Text(
              label, // Étiquette du menu
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          DropdownButtonFormField<String>( // Menu déroulant
            value: value, // Valeur sélectionnée
            dropdownColor: Color(0xFF2A2A2A), // Fond des options
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.blue), // Icône
              border: InputBorder.none, // Pas de bordure interne
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            style: TextStyle(color: Colors.white, fontSize: 16), // Style du texte
            items: items.map((item) { // Crée les options
              return DropdownMenuItem(
                value: item,
                child: Text(item), // Texte de l'option
              );
            }).toList(),
            onChanged: onChanged, // Callback quand la valeur change
          ),
        ],
      ),
    );
  }

  // Méthode pour construire une ligne avec interrupteur
  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1), // Fond conditionnel
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: value ? Colors.blue : Colors.grey, // Couleur conditionnelle
            size: 24,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, // Titre principal
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              //Le ...[ ] permet d’ajouter plusieurs widgets seulement si la condition est vraie.
              if (subtitle != null) ...[ // Sous-titre optionnel
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        Switch( // Interrupteur
          value: value,
          activeColor: Colors.blue, // Couleur quand activé
          onChanged: onChanged,
        ),
      ],
    );
  }
}