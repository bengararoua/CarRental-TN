// Importation pour manipuler les bytes (Uint8List) nécessaire à la prévisualisation web
import 'dart:typed_data';
// Importation des widgets Flutter de base
import 'package:flutter/material.dart';
// Importation pour les services système (clavier, raccourcis)
import 'package:flutter/services.dart';
// Importation du package Provider pour la gestion d'état
import 'package:provider/provider.dart';
// Importation du provider des véhicules (contient la liste et le token)
import '../providers/vehicles_provider.dart';
// Importation du service d'authentification (communication avec l'API)
import '../services/auth_service.dart';
// Importation du package image_picker pour sélectionner des images
import 'package:image_picker/image_picker.dart';

// ======================================================
// Définition du StatefulWidget
// ======================================================
class AddVehicleScreen extends StatefulWidget {
  @override
  _AddVehicleScreenState createState() => _AddVehicleScreenState();
}

// ======================================================
// Classe d'état associée à AddVehicleScreen
// ======================================================
class _AddVehicleScreenState extends State<AddVehicleScreen> {
  // Clé globale pour identifier le formulaire et le valider
  final _formKey = GlobalKey<FormState>();

  // Contrôleur de défilement pour permettre le défilement avec les touches du clavier
  final ScrollController _scrollController = ScrollController();
  // Nœud de focus pour écouter les événements clavier (flèches haut/bas)
  final FocusNode _focusNode = FocusNode();

  // Contrôleurs pour chaque champ de texte (liaison avec les inputs utilisateur)
  final _nameController = TextEditingController();         // Nom du véhicule
  final _imageController = TextEditingController();        // URL de l'image (après upload ou saisie manuelle)
  final _priceController = TextEditingController();        // Prix
  final _seatsController = TextEditingController();        // Nombre de sièges
  final _engineCapacityController = TextEditingController(); // Cylindrée / moteur
  final _yearController = TextEditingController();          // Année
  final _luggageCapacityController = TextEditingController(); // Capacité du coffre
  final _ratingController = TextEditingController();        // Note (optionnelle)
  final _popularityController = TextEditingController();    // Popularité (optionnelle)

  // Valeurs sélectionnées dans les menus déroulants
  String _selectedCategory = 'Économique';       // Catégorie par défaut
  String _selectedTransmission = 'Automatique';  // Transmission par défaut
  String _selectedFuel = 'Essence';               // Carburant par défaut

  // Booléens pour les options (interrupteurs)
  bool _isAvailable = true;           // Disponible
  bool _isNew = false;                // Nouveau véhicule ?
  bool _isBestChoice = false;         // Meilleur choix ?
  bool _hasAirConditioning = true;    // Climatisation ?
  bool _hasBluetooth = true;          // Bluetooth ?

  // État de chargement lors de l'ajout du véhicule
  bool _isLoading = false;

  // Gestion de l'image locale
  //Uint8List:une liste de nombres entiers non signés (entre 0 et 255) utilisée pour manipuler des données binaires (bytes)
  Uint8List? _selectedImageBytes;      // Bytes de l'image sélectionnée (utilisé pour la validation uniquement)
  bool _isUploadingImage = false;      // Indicateur de téléversement en cours
  final ImagePicker _imagePicker = ImagePicker(); // Instance du sélecteur d'images

  // Listes des options pour les menus déroulants
  final List<String> _categories = ['Économique', 'Citadine', 'Familiale', 'Compacte', 'SUV'];
  final List<String> _transmissions = ['Automatique', 'Manuelle'];
  final List<String> _fuels = ['Essence', 'Diesel', 'Électrique', 'Hybride'];

  // ========== MÉTHODES DE CYCLE DE VIE ==========

  @override
  void dispose() {
    // Libération des ressources pour éviter les fuites de mémoire
    _scrollController.dispose();
    _focusNode.dispose();
    _nameController.dispose();
    _imageController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    _engineCapacityController.dispose();
    _yearController.dispose();
    _luggageCapacityController.dispose();
    _ratingController.dispose();
    _popularityController.dispose();
    super.dispose();
  }

  // ========== FONCTIONS DE DÉFILEMENT (FLÈCHES CLAVIER) ==========

  /// Fait défiler la vue vers le haut de 150 pixels (ou jusqu'au début)
  void _scrollUp() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        (_scrollController.offset - 150).clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  /// Fait défiler la vue vers le bas de 150 pixels (ou jusqu'à la fin)
  void _scrollDown() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        (_scrollController.offset + 150).clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  // ========== FONCTION DE SÉLECTION ET UPLOAD D'IMAGE ==========

  /// Ouvre la galerie pour choisir une image, puis l'uploade sur le serveur
  Future<void> _pickImageFromGallery() async {
    try {
      // Utilise ImagePicker pour sélectionner une image dans la galerie
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,          // Compression (85% de qualité)
        maxWidth: 1200,            // Largeur maximale pour réduire la taille
      );

      // Si l'utilisateur annule, on ne fait rien
      if (pickedFile == null) return;

      // Lecture des bytes de l'image (pour validation et éventuelle prévisualisation future)
      final bytes = await pickedFile.readAsBytes();

      // Mise à jour de l'état : on stocke les bytes et on affiche le loader
      setState(() {
        _selectedImageBytes = bytes;          // Stockage des bytes pour la validation
        _isUploadingImage = true;             // Activation du loader (désactive l'icône)
        _imageController.text = '';           // Vide le champ URL pendant l'upload
      });

      // Récupération du token depuis le provider
      final token = Provider.of<VehiclesProvider>(context, listen: false).token;
      if (token == null) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous devez être connecté'), backgroundColor: Colors.red),
        );
        return;
      }

      // Appel du service d'upload avec l'objet XFile directement
      final result = await AuthService.uploadImage(pickedFile, token);

      if (result['success']) {
        // Succès : on stocke l'URL retournée par le serveur dans le champ image
        setState(() {
          _imageController.text = result['url'];
          _isUploadingImage = false;
          // On garde _selectedImageBytes pour indiquer qu'une image a été uploadée (validation)
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploadée avec succès '), backgroundColor: Colors.green),
        );
      } else {
        // Échec : on réinitialise les bytes et on désactive le loader
        setState(() {
          _selectedImageBytes = null;
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de l\'upload'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Gestion des exceptions (par exemple, permission refusée)
      setState(() {
        _selectedImageBytes = null;
        _isUploadingImage = false;
      });
      print(' Erreur pickImage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ========== FONCTION D'AJOUT DU VÉHICULE ==========

  /// Valide le formulaire et envoie les données au serveur
  Future<void> _addVehicle() async {
    // Vérifie la validité de tous les champs du formulaire
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Récupère le token d'authentification depuis le provider
    final token = Provider.of<VehiclesProvider>(context, listen: false).token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous devez être connecté'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Active l'indicateur de chargement
    setState(() => _isLoading = true);

    try {
      // Construction du dictionnaire des données du véhicule
      final vehicleData = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'price': double.parse(_priceController.text), // Conversion en double (accepte les décimales)
        'image': _imageController.text.trim(),
        'transmission': _selectedTransmission,
        'seats': int.parse(_seatsController.text),
        'engine': _engineCapacityController.text.trim(),
        'year': int.parse(_yearController.text),
        'fuel': _selectedFuel,
        'isAvailable': _isAvailable,
        'isNew': _isNew,
        'isBestChoice': _isBestChoice,
        'rating': double.parse(_ratingController.text.isEmpty ? '0.0' : _ratingController.text),
        'popularity': int.parse(_popularityController.text.isEmpty ? '0' : _popularityController.text),
        'luggage': int.parse(_luggageCapacityController.text),
        'airConditioning': _hasAirConditioning,
        'bluetooth': _hasBluetooth,
      };

      print(' Données du véhicule: $vehicleData'); // Log de débogage

      // Appel du service pour ajouter le véhicule
      final result = await AuthService.addVehicle(vehicleData, token);

      if (!result['success']) {
        throw Exception(result['message']);
      }

      // Désactive le chargement
      setState(() => _isLoading = false);

      // Affiche un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Véhicule ajouté avec succès !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Recharge la liste des véhicules dans le provider pour mettre à jour l'affichage
      await Provider.of<VehiclesProvider>(context, listen: false).loadVehicles();

      // Retourne à l'écran précédent
      Navigator.pop(context);

    } catch (e) {
      // En cas d'erreur, désactive le chargement et affiche l'erreur
      setState(() => _isLoading = false);
      print(' Erreur ajout véhicule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // ========== CONSTRUCTION DE L'INTERFACE ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Couleur de fond sombre
      backgroundColor: Color(0xFF1A1A1A),
      // Barre d'application personnalisée
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0, // Pas d'ombre
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context), // Retour à l'écran précédent
        ),
        title: Row(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.blue, size: 24),
            SizedBox(width: 8),
            Text(
              'Ajouter un véhicule',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        // Permet de fermer le clavier en tapant à l'extérieur des champs
        onTap: () {
          FocusScope.of(context).unfocus();
          _focusNode.requestFocus(); // Redonne le focus au nœud pour les touches clavier
        },
        child: KeyboardListener(
          focusNode: _focusNode,
          autofocus: false,
          onKeyEvent: (KeyEvent event) {
            // Gestion des flèches haut/bas pour défiler
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) _scrollUp();
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) _scrollDown();
            }
          },
          child: SingleChildScrollView(
            controller: _scrollController, // Permet le contrôle du défilement
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey, // Clé pour la validation
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bannière d'en-tête avec dégradé
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.blue.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.directions_car, color: Colors.white, size: 32),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nouveau véhicule',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Remplissez tous les champs ci-dessous',
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

                  SizedBox(height: 24),

                  // SECTION 1 : Informations principales
                  _buildSectionTitle('Informations principales', Icons.info_outline),
                  SizedBox(height: 12),

                  // Champ Nom du véhicule
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nom du véhicule',
                    icon: Icons.car_rental,
                    hint: 'Ex: Renault Clio',
                    validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                  ),
                  SizedBox(height: 16),

                  // SECTION IMAGE : champ URL avec icône de sélection d'image à droite
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _imageController,
                          label: 'URL de l\'image',
                          icon: Icons.link,
                          hint: 'https://exemple.com/image.jpg',
                          validator: (v) {
                            // Validation : soit une URL non vide, soit une image locale sélectionnée 
                            if ((v == null || v.isEmpty) && _selectedImageBytes == null) {
                              return 'Ajoutez une image (URL ou sélection)';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Conteneur arrondi pour l'icône de sélection d'image
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _isUploadingImage ? null : _pickImageFromGallery,
                          icon: Icon(
                            Icons.image,
                            color: _isUploadingImage ? Colors.grey : Colors.blue,
                          ),
                          tooltip: 'Choisir une image depuis la galerie',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Ligne Catégorie + Prix
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          value: _selectedCategory,
                          label: 'Catégorie',
                          icon: Icons.category,
                          items: _categories,
                          onChanged: (value) => setState(() => _selectedCategory = value!),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _priceController,
                          label: 'Prix (TND/jour)',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Requis' : null,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // SECTION 2 : Caractéristiques techniques
                  _buildSectionTitle('Caractéristiques techniques', Icons.build),
                  SizedBox(height: 12),

                  // Ligne Sièges + Année
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _seatsController,
                          label: 'Sièges',
                          icon: Icons.event_seat,
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Requis' : null,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
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

                  // Ligne Transmission + Carburant
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          value: _selectedTransmission,
                          label: 'Transmission',
                          icon: Icons.settings,
                          items: _transmissions,
                          onChanged: (value) => setState(() => _selectedTransmission = value!),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          value: _selectedFuel,
                          label: 'Carburant',
                          icon: Icons.local_gas_station,
                          items: _fuels,
                          //items:fournit un liste d'element a afficher
                          onChanged: (value) => setState(() => _selectedFuel = value!),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Ligne Moteur + Coffre
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _engineCapacityController,
                          label: 'Moteur (L)',
                          icon: Icons.engineering,
                          hint: 'Ex: 2.0L, 1.5L',
                          validator: (v) => v!.isEmpty ? 'Requis' : null,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
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

                  // Conteneur avec les interrupteurs
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          title: 'Climatisation',
                          icon: Icons.ac_unit,
                          value: _hasAirConditioning,
                          onChanged: (v) => setState(() => _hasAirConditioning = v),
                        ),
                        Divider(color: Colors.white12, height: 24),
                        _buildSwitchTile(
                          title: 'Bluetooth',
                          icon: Icons.bluetooth,
                          value: _hasBluetooth,
                          onChanged: (v) => setState(() => _hasBluetooth = v),
                        ),
                        Divider(color: Colors.white12, height: 24),
                        _buildSwitchTile(
                          title: 'Disponible',
                          icon: Icons.check_circle,
                          value: _isAvailable,
                          onChanged: (v) => setState(() => _isAvailable = v),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // SECTION 4 : Marketing et visibilité
                  _buildSectionTitle('Marketing et visibilité', Icons.star),
                  SizedBox(height: 12),

                  // Conteneur avec interrupteurs marketing
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          title: 'Nouveau véhicule',
                          subtitle: 'Apparaît dans "Nouveautés 2026"',
                          icon: Icons.fiber_new,
                          value: _isNew,
                          onChanged: (v) => setState(() => _isNew = v),
                        ),
                        Divider(color: Colors.white12, height: 24),
                        _buildSwitchTile(
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

                  // Ligne Note + Popularité (optionnels)
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _ratingController,
                          label: 'Note (0-5)',
                          icon: Icons.star_rate,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          hint: '4.5',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
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

                  // Boutons d'action : Annuler et Ajouter
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red, width: 2),
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
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addVehicle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
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
                              : Row(
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
      ),
    );
  }

  // ========== FONCTIONS DE CONSTRUCTION DE WIDGETS RÉUTILISABLES ==========

  /// Construit un titre de section avec une icône
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Construit un champ de texte stylisé
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white30),
        prefixIcon: Icon(icon, color: Colors.blue),
        filled: true,
        fillColor: Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white12, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
      ),
      validator: validator,
    );
  }

  /// Construit un menu déroulant (Dropdown) stylisé
  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16, top: 8),
            child: Text(
              label,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          DropdownButtonFormField<String>(
            value: value,
            dropdownColor: Color(0xFF2A2A2A),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.blue),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            style: TextStyle(color: Colors.white, fontSize: 16),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// Construit une ligne avec interrupteur (Switch) et icône
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
            color: value ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: value ? Colors.blue : Colors.grey,
            size: 24,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
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
        Switch(
          value: value,
          activeColor: Colors.blue,
          onChanged: onChanged,
        ),
      ],
    );
  }
}