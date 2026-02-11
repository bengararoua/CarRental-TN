// Import du package Material Design de Flutter pour utiliser ses widgets UI (boutons, champs texte, etc.)
import 'package:flutter/material.dart';
// Import du package pour gérer les entrées système comme le clavier, touches fléchées, etc.
import 'package:flutter/services.dart';
// Import du package Provider pour la gestion d'état (partage de données entre widgets)
import 'package:provider/provider.dart';
// Import du provider personnalisé des véhicules pour accéder aux données utilisateur (token, email, etc.)
import '../providers/vehicles_provider.dart';
// Import du service d'authentification pour effectuer les appels API de réservation
import '../services/auth_service.dart';

// Déclaration d'un widget StatefulWidget car l'écran a un état mutable (champs de formulaire, dates, etc.)
class BookingScreen extends StatefulWidget {
  // Propriété obligatoire : les données du véhicule sélectionné, stockées sous forme de map (clé-valeur)
  final Map<String, dynamic> vehicle;

  // Constructeur qui initialise le véhicule (requis grâce au mot-clé 'required')
  BookingScreen({required this.vehicle});

  // Méthode obligatoire pour créer l'état associé à ce widget (StatefulWidget)
  @override
  _BookingScreenState createState() => _BookingScreenState();
}

// Classe d'état qui contient la logique et les données variables de l'écran de réservation
class _BookingScreenState extends State<BookingScreen> {
  // Clé globale pour identifier et valider le formulaire (utilisée avec Form widget)
  final _formKey = GlobalKey<FormState>();
  // Contrôleur pour gérer le défilement de la page (scroll)
  final ScrollController _scrollController = ScrollController();
  // Nœud de focus pour capturer les événements clavier (touches fléchées)
  final FocusNode _focusNode = FocusNode();

  // Contrôleurs pour chaque champ de texte du formulaire (lisent/écrivent la valeur du champ)
  final _nameController = TextEditingController();    // Pour le nom complet
  final _phoneController = TextEditingController();   // Pour le numéro de téléphone
  final _emailController = TextEditingController();   // Pour l'adresse email
  final _addressController = TextEditingController(); // Pour l'adresse postale
  final _notesController = TextEditingController();   // Pour les notes optionnelles

  // Contrôleurs supplémentaires pour les champs de date (amélioration UX, pré-remplissage)
  final _pickupDateController = TextEditingController(); // Pour la date de début
  final _returnDateController = TextEditingController(); // Pour la date de fin

  // Variables pour stocker les dates sélectionnées (null par défaut)
  DateTime? _startDate;   // Date de début de location
  DateTime? _endDate;     // Date de fin de location
  // Variable pour stocker l'heure du rendez-vous (null par défaut)
  TimeOfDay? _meetingTime;

  // Variable pour stocker le lieu de rendez-vous sélectionné (valeur par défaut : 'Agence Tunis Centre')
  String _meetingLocation = 'Agence Tunis Centre';

  // Liste fixe des lieux de rendez-vous disponibles (affichés dans un menu déroulant)
  final List<String> _locations = [
    'Agence Tunis Centre',
    'Aéroport Tunis-Carthage',
    'Agence Sousse',
    'Agence Sfax',
  ];

  // Variables booléennes pour les options supplémentaires (initialement désactivées)
  bool _needsDriver = false;     // Option chauffeur
  bool _needsGPS = false;        // Option GPS
  bool _needsChildSeat = false;  // Option siège enfant

  // Variable pour afficher un indicateur de chargement lors de la soumission du formulaire
  bool _isLoading = false;

  // Variable pour basculer entre le mode location d'un jour et plusieurs jours (true = un jour)
  bool _singleDayMode = true;

  // Méthode appelée une seule fois lors de la création de l'état (initialisation)
  @override
  void initState() {
    super.initState(); // Appel de la méthode initState de la classe parent
    _fillUserInfo();   // Remplit automatiquement les champs avec les infos utilisateur
  }

  // Méthode pour pré-remplir les champs nom et email avec les données de l'utilisateur connecté
  void _fillUserInfo() {
    // Accède au provider des véhicules (sans écouter les changements : listen: false)
    final provider = Provider.of<VehiclesProvider>(context, listen: false);
    // Si le nom d'utilisateur est disponible dans le provider, le met dans le champ nom
    if (provider.username != null) {
      _nameController.text = provider.username!;
    }
    // Si l'email utilisateur est disponible, le met dans le champ email
    if (provider.userEmail != null) {
      _emailController.text = provider.userEmail!;
    }
  }

  // Méthode de nettoyage appelée quand le widget est retiré de l'arbre des widgets (évite les fuites mémoire)
  @override
  void dispose() {
    // Libère toutes les ressources des contrôleurs de texte
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _pickupDateController.dispose();
    _returnDateController.dispose();
    // Libère le contrôleur de défilement
    _scrollController.dispose();
    // Libère le nœud de focus
    _focusNode.dispose();
    super.dispose(); // Appelle la méthode dispose de la classe parent
  }

  // Fonction pour faire défiler la page vers le haut (appelée par la touche flèche haut)
  void _scrollUp() {
    // Vérifie si le contrôleur est attaché à un widget (évite les erreurs)
    if (_scrollController.hasClients) {
      // Anime le défilement vers le haut de 150 pixels
      _scrollController.animateTo(
        _scrollController.offset - 150,
        duration: Duration(milliseconds: 200), // Durée de l'animation : 200 ms
        curve: Curves.easeOut, // Courbe d'animation pour un effet fluide
      );
    }
  }

  // Fonction pour faire défiler la page vers le bas (appelée par la touche flèche bas)
  void _scrollDown() {
    if (_scrollController.hasClients) {
      // Anime le défilement vers le bas de 150 pixels
      _scrollController.animateTo(
        _scrollController.offset + 150,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  // Fonction utilitaire pour formater une date au format YYYY-MM-DD (requis par l'API)
  String _formatDateForApi(DateTime date) {
    // Format : année-mois-jour avec mois et jour sur 2 chiffres (ex: 2024-05-01)
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Calcule le nombre de jours de location en fonction des dates sélectionnées
  int _calculateDays() {
    // En mode 1 jour, retourne toujours 1 
    if (_singleDayMode) return 1;

    // Si les deux dates sont sélectionnées, calcule la différence en jours
    if (_startDate != null && _endDate != null) {
      return _endDate!.difference(_startDate!).inDays;
    }
    // Valeur par défaut si les dates ne sont pas renseignées
    return 1;
  }

  // Calcule le prix total de la réservation (prix de base + options)
  double _calculateTotalPrice() {
    // Prix de base = prix du véhicule par jour × nombre de jours
    double basePrice = (widget.vehicle['price'] ?? 0).toDouble() * _calculateDays();
    double extras = 0; // Initialise le total des extras à 0

    // Ajoute le coût de chaque option si elle est sélectionnée (prix par jour × nombre de jours)
    if (_needsDriver) extras += 50 * _calculateDays(); // Chauffeur : 50 TND/jour
    if (_needsGPS) extras += 5 * _calculateDays();     // GPS : 5 TND/jour
    if (_needsChildSeat) extras += 3 * _calculateDays(); // Siège enfant : 3 TND/jour

    // Retourne la somme du prix de base et des extras
    return basePrice + extras;
  }

  // Ouvre un sélecteur de date natif pour choisir la date de début de location
  Future<void> _selectStartDate(BuildContext context) async {
    // Affiche le sélecteur de date avec showDatePicker
    final DateTime? picked = await showDatePicker(
      context: context, // Contexte de l'interface (pour afficher le dialogue)
      // Date initiale : aujourd'hui si aucune date n'est encore sélectionnée
      initialDate: _startDate ?? DateTime.now(),
      // Première date sélectionnable : aujourd'hui (on ne peut pas réserver dans le passé)
      firstDate: DateTime.now(),
      // Dernière date sélectionnable : dans 365 jours (1 an)
      lastDate: DateTime.now().add(const Duration(days: 365)),
      // Personnalisation du thème du sélecteur (sombre pour s'accorder avec l'app)
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,   // Couleur principale (boutons, sélection)
              surface: Color(0xFF2A2A2A), // Couleur de fond du sélecteur
            ),
          ),
          child: child!, // Passe le widget du sélecteur à Theme
        );
      },
    );

    // Si l'utilisateur a sélectionné une date 
    if (picked != null) {
      // Met à jour l'état du widget (rafraîchit l'interface)
      setState(() {
        _startDate = picked; // Stocke la date sélectionnée
        _pickupDateController.text = _formatDateForApi(picked); // Met à jour le champ texte

        // Si on est en mode 1 jour, la date de fin = date de début + 1 jour
        if (_singleDayMode) {
          _endDate = picked.add(const Duration(days: 1));
          _returnDateController.text = _formatDateForApi(_endDate!);
        }
        // Sinon (mode plusieurs jours), si la date de fin est avant la nouvelle date de début, on la réinitialise
        else if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
          _returnDateController.text = '';
        }
      });
    }
  }

  // Ouvre un sélecteur de date pour choisir la date de fin de location
  Future<void> _selectEndDate(BuildContext context) async {
    // En mode 1 jour, on ne permet pas de sélectionner la date de fin (elle est calculée automatiquement)
    if (_singleDayMode) return;

    // Affiche le sélecteur de date
    final DateTime? picked = await showDatePicker(
      context: context,
      // Date initiale : date de fin existante, ou date de début + 1 jour, ou aujourd'hui + 1 jour
      initialDate: _endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 1)),
      // Première date sélectionnable : la date de début (ou aujourd'hui si pas de date de début)
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              surface: Color(0xFF2A2A2A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked; // Stocke la date de fin sélectionnée
        _returnDateController.text = _formatDateForApi(picked); // Met à jour le champ texte
      });
    }
  }

  // Ouvre un sélecteur d'heure natif pour choisir l'heure du rendez-vous
  Future<void> _selectMeetingTime(BuildContext context) async {
    // Affiche le sélecteur d'heure avec showTimePicker
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      // Heure initiale : 9h00 (valeur par défaut)
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              surface: Color(0xFF2A2A2A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _meetingTime = picked; // Stocke l'heure sélectionnée
      });
    }
  }

  // Méthode appelée quand l'utilisateur appuie sur le bouton "Confirmer la réservation"
  Future<void> _submitBooking() async {
    // Étape 1 : Validation du formulaire (vérifie que tous les champs obligatoires sont valides)
    if (!_formKey.currentState!.validate()) {
      // Affiche un message d'erreur en bas de l'écran (snackbar)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red, // Couleur rouge pour l'erreur
        ),
      );
      return; // Arrête l'exécution de la méthode
    }

    // Étape 2 : Validation de l'heure du rendez-vous (doit être sélectionnée)
    if (_meetingTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner l\'heure du rendez-vous'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Étape 3 : Validation de la date de début (obligatoire)
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner la date de location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Étape 4 : En mode plusieurs jours, validation de la date de fin (obligatoire)
    if (!_singleDayMode && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner la date de fin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Étape 5 : Récupération du token d'authentification depuis le provider
    final token = Provider.of<VehiclesProvider>(context, listen: false).token;

    // Si l'utilisateur n'est pas connecté (token null), affiche une erreur
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour effectuer une réservation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Étape 6 : Active l'indicateur de chargement
    setState(() => _isLoading = true);

    try {
      // Prépare les dates au format API
      String pickupDate = _formatDateForApi(_startDate!);
      // Note : en mode 1 jour, _endDate est déjà défini comme _startDate + 1 jour
      String returnDate = _formatDateForApi(_endDate!);

      // Construit l'objet de données à envoyer à l'API
      final bookingData = {
        'car_id': widget.vehicle['id'],      // ID du véhicule à réserver
        'full_name': _nameController.text.trim(), // Nom complet de l'utilisateur
        'pickup_date': pickupDate,           // Date de début formatée
        'return_date': returnDate,           // Date de fin formatée
        'total_price': _calculateTotalPrice(), // Prix total calculé
      };

      // Log de débogage (visible dans la console)
      print('📤 Envoi des données de réservation: $bookingData');

      // Appel à l'API via AuthService pour créer la réservation
      final result = await AuthService.addBooking(bookingData, token);

      // Vérifie que le widget est toujours monté (pour éviter d'appeler setState sur un widget détruit)
      if (!mounted) return;

      // Si l'API a répondu avec success: true
      if (result['success']) {
        // Affiche un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Réservation envoyée ! En attente de confirmation."),
            backgroundColor: Colors.green, // Couleur verte pour le succès
            duration: const Duration(seconds: 3), // Durée d'affichage : 3 secondes
          ),
        );

        // Retourne à l'écran précédent (détail du véhicule ou liste)
        Navigator.pop(context);
      } else {
        // Si l'API a répondu avec une erreur, affiche le message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Erreur lors de la réservation"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Capture toute exception (erreur réseau, format de données, etc.)
      print('❌ Exception lors de la réservation: $e');
      if (!mounted) return;

      // Affiche l'erreur dans une snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur inattendue: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      // Désactive l'indicateur de chargement dans tous les cas (succès ou erreur)
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Méthode principale de construction de l'interface utilisateur (UI)
  @override
  Widget build(BuildContext context) {
    // Scaffold est la structure de base d'un écran Material Design (AppBar, Body, etc.)
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Fond noir (thème sombre)
      // Barre d'application en haut de l'écran
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A), // Même fond que le body
        elevation: 0, // Pas d'ombre sous la barre
        // Bouton de retour à gauche (flèche)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context), // Retourne à l'écran précédent
        ),
        // Titre de la barre : "Réserver [nom du véhicule]"
        title: Text(
          'Réserver ${widget.vehicle['name']}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      // Corps de l'écran (contenu principal)
      body: SafeArea(
        // SafeArea évite que le contenu soit masqué par la encoche ou les barres système
        child: RawKeyboardListener(
          // Écoute les événements clavier (touches fléchées pour le défilement)
          focusNode: _focusNode,
          autofocus: true, // Donne automatiquement le focus à ce widget
          onKey: (event) {
            // Quand une touche est enfoncée
            if (event is RawKeyDownEvent) {
              // Flèche haut : défile vers le haut
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                _scrollUp();
              }
              // Flèche bas : défile vers le bas
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _scrollDown();
              }
            }
          },
          child: SingleChildScrollView(
            // Permet de faire défiler tout le contenu verticalement
            controller: _scrollController, // Contrôleur pour le défilement programmatique
            physics: const BouncingScrollPhysics(), // Effet de rebond à la fin du scroll
            padding: const EdgeInsets.all(16), // Marge intérieure de 16 pixels sur tous les côtés
            child: Form(
              // Widget Form qui regroupe tous les champs et permet la validation
              key: _formKey, // Clé globale pour accéder à l'état du formulaire
              child: Column(
                // Colonne principale qui empile tous les widgets enfants verticalement
                crossAxisAlignment: CrossAxisAlignment.start, // Aligne les enfants à gauche
                children: [
                  // Carte qui affiche les informations du véhicule (image, nom, prix)
                  _buildVehicleCard(),

                  const SizedBox(height: 24), // Espacement vertical de 24 pixels

                  // Titre de section "Informations personnelles"
                  _buildSectionTitle('Informations personnelles'),
                  const SizedBox(height: 12),

                  // Champ de texte pour le nom complet
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nom complet',
                    icon: Icons.person_outline,
                    validator: (v) => v!.isEmpty ? 'Champ requis' : null, // Validation : ne doit pas être vide
                  ),
                  const SizedBox(height: 16),

                  // Champ de texte pour le téléphone
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Téléphone',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone, // Ouvre le clavier numérique
                    validator: (v) => v!.length < 8 ? 'Numéro invalide' : null, // Validation : au moins 8 caractères
                  ),
                  const SizedBox(height: 16),

                  // Champ de texte pour l'email
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress, // Clavier avec @
                    validator: (v) => v!.contains('@') ? null : 'Email invalide', // Validation : doit contenir @
                  ),
                  const SizedBox(height: 16),

                  // Champ de texte pour l'adresse
                  _buildTextField(
                    controller: _addressController,
                    label: 'Adresse',
                    icon: Icons.location_on_outlined,
                    validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                  ),

                  const SizedBox(height: 24),

                  // Titre de section "Durée de location"
                  _buildSectionTitle('Durée de location'),
                  const SizedBox(height: 12),

                  // Case à cocher pour basculer entre mode 1 jour / plusieurs jours
                  _buildCheckbox(
                    title: 'Location pour plusieurs jours',
                    // La valeur est l'inverse de _singleDayMode (car checkbox cochée = plusieurs jours)
                    value: !_singleDayMode,
                    onChanged: (v) {
                      setState(() {
                        _singleDayMode = !v!; // Inverse la valeur actuelle
                        // Si on repasse en mode 1 jour et qu'une date de début est sélectionnée
                        if (_singleDayMode && _startDate != null) {
                          // Calcule automatiquement la date de fin (début + 1 jour)
                          _endDate = _startDate!.add(const Duration(days: 1));
                          _returnDateController.text = _formatDateForApi(_endDate!);
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Bouton pour sélectionner la date de début (ou date de location en mode 1 jour)
                  _buildDateButton(
                    label: _singleDayMode ? 'Date de location' : 'Date de début',
                    date: _startDate,
                    onTap: () => _selectStartDate(context),
                  ),

                  const SizedBox(height: 12),
                  // Bouton pour sélectionner la date de fin (désactivé en mode 1 jour)
                  _buildDateButton(
                    label: 'Date de fin',
                    date: _endDate,
                    onTap: () => _selectEndDate(context),
                    isReturnDate: true, // Indique que c'est la date de retour (affichage différent)
                    singleDayMode: _singleDayMode, // Passe le mode pour désactiver le bouton si nécessaire
                  ),

                  const SizedBox(height: 12),

                  // Affichage de la durée totale calculée (nombre de jours)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A), // Fond gris foncé
                      borderRadius: BorderRadius.circular(8), // Coins arrondis
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Éspace les éléments au maximum
                      children: [
                        const Text('Durée totale:', style: TextStyle(color: Colors.white70)),
                        Text(
                          '${_calculateDays()} jour${_calculateDays() > 1 ? 's' : ''}', // Ajoute un 's' au pluriel
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Titre de section "Heure et lieu de prise du véhicule"
                  _buildSectionTitle('Heure et lieu de prise du véhicule'),
                  const SizedBox(height: 12),

                  // Ligne qui contient le sélecteur d'heure et le menu déroulant pour le lieu
                  Row(
                    children: [
                      // Sélecteur d'heure (première moitié de la ligne)
                      Expanded(
                        child: _buildTimePickerButton(), // Version compacte du bouton d'heure
                      ),
                      const SizedBox(width: 12), // Espacement horizontal de 12 pixels
                      // Menu déroulant pour le lieu (seconde moitié de la ligne)
                      Expanded(
                        child: _buildLocationDropdown(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Titre de section "Options supplémentaires"
                  _buildSectionTitle('Options supplémentaires'),
                  const SizedBox(height: 12),

                  // Case à cocher pour l'option chauffeur
                  _buildCheckbox(
                    title: 'Chauffeur (+50 TND/jour)',
                    value: _needsDriver,
                    onChanged: (v) => setState(() => _needsDriver = v!), // Met à jour l'état et rafraîchit l'UI
                  ),

                  // Case à cocher pour l'option GPS
                  _buildCheckbox(
                    title: 'GPS (+5 TND/jour)',
                    value: _needsGPS,
                    onChanged: (v) => setState(() => _needsGPS = v!),
                  ),

                  // Case à cocher pour l'option siège enfant
                  _buildCheckbox(
                    title: 'Siège enfant (+3 TND/jour)',
                    value: _needsChildSeat,
                    onChanged: (v) => setState(() => _needsChildSeat = v!),
                  ),

                  const SizedBox(height: 24),

                  // Titre de section "Notes (optionnel)"
                  _buildSectionTitle('Notes (optionnel)'),
                  const SizedBox(height: 12),

                  // Champ de texte multiligne pour les notes
                  _buildTextField(
                    controller: _notesController,
                    label: 'Remarques ou demandes spéciales',
                    icon: Icons.note_outlined,
                    maxLines: 3, // Permet d'écrire sur plusieurs lignes
                    validator: null, // Pas de validation car optionnel
                  ),

                  const SizedBox(height: 24),

                  // Récapitulatif du prix (détail du calcul)
                  _buildPriceSummary(),

                  const SizedBox(height: 24),

                  // Bouton de confirmation de réservation (largeur maximale)
                  SizedBox(
                    width: double.infinity, // Prend toute la largeur disponible
                    height: 54, // Hauteur fixe
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitBooking, // Désactivé pendant le chargement
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Couleur de fond bleue
                        disabledBackgroundColor: Colors.blue.withOpacity(0.5), // Bleu semi-transparent si désactivé
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white) // Spinner de chargement
                          : const Text(
                              'Confirmer la réservation',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24), // Espacement final en bas de la page
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Méthode qui construit la carte affichant les informations du véhicule (image, nom, prix)
  Widget _buildVehicleCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A), // Fond gris foncé
        borderRadius: BorderRadius.circular(12), // Coins arrondis
      ),
      child: Row(
        children: [
          // Image du véhicule (à gauche)
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)), // Coins arrondis à gauche seulement
            child: Image.network(
              widget.vehicle['image'], // URL de l'image (depuis les données du véhicule)
              width: 120, // Largeur fixe
              height: 100, // Hauteur fixe
              fit: BoxFit.cover, // Remplit le cadre sans déformer l'image
              cacheWidth: 240, // Optimisation : cache l'image en double résolution pour les écrans HD
              cacheHeight: 200,
              // Builder pour afficher un indicateur de chargement pendant le téléchargement
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child; // Si chargé, affiche l'image
                // Sinon, affiche un container gris avec un spinner de progression
                return Container(
                  width: 120,
                  height: 100,
                  color: const Color(0xFF3A3A3A),
                  child: Center(
                    child: CircularProgressIndicator(
                      // Calcule la progression si le poids total est connu
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              // Builder en cas d'erreur de chargement de l'image
              errorBuilder: (context, error, stackTrace) => Container(
                width: 120,
                height: 100,
                color: const Color(0xFF3A3A3A),
                child: const Icon(Icons.car_repair, color: Colors.white), // Icône de remplacement
              ),
            ),
          ),
          // Partie texte de la carte (à droite de l'image)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12), // Marge intérieure de 12 pixels
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Alignement du texte à gauche
                children: [
                  // Nom du véhicule
                  Text(
                    widget.vehicle['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Catégorie du véhicule (ex: SUV, Berline)
                  Text(
                    widget.vehicle['category'],
                    style: const TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  // Prix par jour
                  Text(
                    '${widget.vehicle['price']} TND / jour',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode qui construit un titre de section (texte en gras blanc)
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Méthode générique pour construire un champ de texte du formulaire
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller, // Lie le contrôleur au champ
      keyboardType: keyboardType, // Type de clavier (ex: numérique, email)
      maxLines: maxLines, // Nombre de lignes (1 par défaut, >1 pour zone de texte)
      style: const TextStyle(color: Colors.white), // Couleur du texte saisi
      decoration: InputDecoration(
        labelText: label, // Texte du label (au-dessus quand en focus)
        labelStyle: const TextStyle(color: Colors.white70), // Couleur du label
        prefixIcon: Icon(icon, color: Colors.white70), // Icône à gauche du champ
        filled: true, // Remplit le fond du champ
        fillColor: const Color(0xFF2A2A2A), // Couleur de fond gris foncé
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // Coins arrondis
          borderSide: BorderSide.none, // Pas de bordure visible
        ),
      ),
      validator: validator, // Fonction de validation (peut retourner un message d'erreur)
    );
  }

  // Méthode pour construire un bouton de sélection de date
  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    bool isReturnDate = false,
    bool singleDayMode = false,
  }) {
    return GestureDetector(
      // Désactive le clic si c'est la date de retour en mode 1 jour
      onTap: isReturnDate && singleDayMode ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label (texte plus petit et gris)
            Text(
              label,
              style: TextStyle(
                color: isReturnDate && singleDayMode ? Colors.grey : Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Icône calendrier (grisée si désactivée)
                Icon(
                  Icons.calendar_today,
                  color: isReturnDate && singleDayMode ? Colors.grey : Colors.blue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                // Texte affichant la date ou "Sélectionner"
                Text(
                  date == null
                      ? 'Sélectionner'
                      : isReturnDate && singleDayMode
                          ? 'Calculée automatiquement' // Texte spécial pour date de retour en mode 1 jour
                          : '${date.day}/${date.month}/${date.year}', // Format jour/mois/année
                  style: TextStyle(
                    color: isReturnDate && singleDayMode ? Colors.grey : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour construire le bouton de sélection d'heure
  Widget _buildTimePickerButton() {
    return GestureDetector(
      onTap: () => _selectMeetingTime(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Heure de prise',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.blue, size: 18),
                const SizedBox(width: 8),
                Text(
                  _meetingTime == null
                      ? 'Sélectionner'
                      : _meetingTime!.format(context), // Formate l'heure selon les paramètres régionaux
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour construire le menu déroulant de sélection du lieu
  Widget _buildLocationDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _meetingLocation, // Lieu actuellement sélectionné
        isExpanded: true, // Prend toute la largeur disponible
        underline: const SizedBox(), // Supprime le trait de soulignement par défaut
        dropdownColor: const Color(0xFF2A2A2A), // Fond du menu déroulant (gris foncé)
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white), // Icône de flèche
        style: const TextStyle(color: Colors.white, fontSize: 14), // Style du texte des options
        // Construit la liste des options à partir de la liste _locations
        items: _locations.map((location) {
          return DropdownMenuItem(
            value: location,
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(location),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          // Quand l'utilisateur sélectionne une nouvelle option
          if (value != null) {
            setState(() {
              _meetingLocation = value; // Met à jour le lieu sélectionné
            });
          }
        },
      ),
    );
  }

  // Méthode pour construire une case à cocher (checkbox) avec un titre
  Widget _buildCheckbox({
    required String title,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Marge en bas entre les options
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        value: value, // État actuel (coché ou non)
        activeColor: Colors.blue, // Couleur de la case quand cochée
        onChanged: onChanged, // Fonction appelée quand l'état change
        controlAffinity: ListTileControlAffinity.leading, // Place la case à gauche du texte
      ),
    );
  }

  // Méthode pour construire le récapitulatif du prix (détail et total)
  Widget _buildPriceSummary() {
    // Calcule le prix de base (véhicule × nombre de jours)
    double basePrice = (widget.vehicle['price'] ?? 0).toDouble() * _calculateDays();
    double extras = 0; // Initialise le total des extras

    // Ajoute le coût de chaque option si elle est sélectionnée
    if (_needsDriver) extras += 50 * _calculateDays();
    if (_needsGPS) extras += 5 * _calculateDays();
    if (_needsChildSeat) extras += 3 * _calculateDays();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 1), // Bordure bleue pour mettre en évidence
      ),
      child: Column(
        children: [
          // Ligne pour le prix de la location (base)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Libellé avec le nombre de jours (pluriel si >1)
              Text(
                'Location (${_calculateDays()} jour${_calculateDays() > 1 ? 's' : ''})',
                style: const TextStyle(color: Colors.white70),
              ),
              // Montant de la location
              Text(
                '${basePrice.toInt()} TND',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          // Section des extras (affichée seulement si au moins une option est sélectionnée)
          if (extras > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Options', style: TextStyle(color: Colors.white70)),
                Text('${extras.toInt()} TND', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ],
          // Ligne de séparation entre le détail et le total
          const Divider(color: Colors.white24, height: 24),
          // Ligne pour le prix total (en plus gros et en bleu)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_calculateTotalPrice().toInt()} TND',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}