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
  // FIX : on utilise un FocusNode dédié au scroll, séparé des TextFields
  final FocusNode _scrollFocusNode = FocusNode();

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
    // Libère le nœud de focus dédié au scroll
    _scrollFocusNode.dispose();
    super.dispose(); // Appelle la méthode dispose de la classe parent
  }

  // FIX 1 : _scrollUp avec clamp pour éviter une position négative
  // (important surtout avec BouncingScrollPhysics qui peut causer un rebond indésirable)
  void _scrollUp() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        (_scrollController.offset - 150).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  // FIX 1 : _scrollDown avec clamp pour ne pas dépasser la fin du contenu
  void _scrollDown() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        (_scrollController.offset + 150).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 200),
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
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
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
        _startDate = picked;
        _pickupDateController.text = _formatDateForApi(picked);

        if (_singleDayMode) {
          _endDate = picked.add(const Duration(days: 1));
          _returnDateController.text = _formatDateForApi(_endDate!);
        } else if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
          _returnDateController.text = '';
        }
      });
    }
  }

  // Ouvre un sélecteur de date pour choisir la date de fin de location
  Future<void> _selectEndDate(BuildContext context) async {
    if (_singleDayMode) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 1)),
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
        _endDate = picked;
        _returnDateController.text = _formatDateForApi(picked);
      });
    }
  }

  // Ouvre un sélecteur d'heure natif pour choisir l'heure du rendez-vous
  Future<void> _selectMeetingTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
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
        _meetingTime = picked;
      });
    }
  }

  // Méthode appelée quand l'utilisateur appuie sur le bouton "Confirmer la réservation"
  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_meetingTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner l\'heure du rendez-vous'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner la date de location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_singleDayMode && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner la date de fin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final token = Provider.of<VehiclesProvider>(context, listen: false).token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour effectuer une réservation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String pickupDate = _formatDateForApi(_startDate!);
      String returnDate = _formatDateForApi(_endDate!);

      final bookingData = {
        'car_id': widget.vehicle['id'],
        'full_name': _nameController.text.trim(),
        'pickup_date': pickupDate,
        'return_date': returnDate,
        'total_price': _calculateTotalPrice(),
      };

      print('📤 Envoi des données de réservation: $bookingData');

      final result = await AuthService.addBooking(bookingData, token);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Réservation envoyée ! En attente de confirmation."),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Erreur lors de la réservation"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Exception lors de la réservation: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur inattendue: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Méthode principale de construction de l'interface utilisateur (UI)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Réserver ${widget.vehicle['name']}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SafeArea(
        // FIX 2 : Utilisation de KeyboardListener (non déprécié) à la place de RawKeyboardListener.
        // On enveloppe avec un GestureDetector pour récupérer le focus scroll
        // uniquement quand l'utilisateur tape en dehors des TextFields,
        // évitant ainsi le conflit avec les touches fléchées dans les champs de saisie.
        child: GestureDetector(
          onTap: () {
            // Quand l'utilisateur tape en dehors d'un TextField :
            // - on ferme le clavier
            // - on redonne le focus au nœud de scroll pour que les flèches fonctionnent
            FocusScope.of(context).unfocus();
            _scrollFocusNode.requestFocus();
          },
          child: KeyboardListener(
            focusNode: _scrollFocusNode,
            // autofocus: false pour ne pas voler le focus des TextFields au démarrage
            autofocus: false,
            onKeyEvent: (KeyEvent event) {
              // FIX 2 : On n'intercepte les flèches QUE si aucun TextField n'a le focus,
              // c'est-à-dire uniquement quand _scrollFocusNode est le focus primaire.
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  _scrollUp();
                } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  _scrollDown();
                }
              }
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVehicleCard(),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Informations personnelles'),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _nameController,
                      label: 'Nom complet',
                      icon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _phoneController,
                      label: 'Téléphone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.length < 8 ? 'Numéro invalide' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v!.contains('@') ? null : 'Email invalide',
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _addressController,
                      label: 'Adresse',
                      icon: Icons.location_on_outlined,
                      validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Durée de location'),
                    const SizedBox(height: 12),

                    _buildCheckbox(
                      title: 'Location pour plusieurs jours',
                      value: !_singleDayMode,
                      onChanged: (v) {
                        setState(() {
                          _singleDayMode = !v!;
                          if (_singleDayMode && _startDate != null) {
                            _endDate = _startDate!.add(const Duration(days: 1));
                            _returnDateController.text = _formatDateForApi(_endDate!);
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildDateButton(
                      label: _singleDayMode ? 'Date de location' : 'Date de début',
                      date: _startDate,
                      onTap: () => _selectStartDate(context),
                    ),

                    const SizedBox(height: 12),

                    _buildDateButton(
                      label: 'Date de fin',
                      date: _endDate,
                      onTap: () => _selectEndDate(context),
                      isReturnDate: true,
                      singleDayMode: _singleDayMode,
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Durée totale:', style: TextStyle(color: Colors.white70)),
                          Text(
                            '${_calculateDays()} jour${_calculateDays() > 1 ? 's' : ''}',
                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Heure et lieu de prise du véhicule'),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: _buildTimePickerButton()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildLocationDropdown()),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Options supplémentaires'),
                    const SizedBox(height: 12),

                    _buildCheckbox(
                      title: 'Chauffeur (+50 TND/jour)',
                      value: _needsDriver,
                      onChanged: (v) => setState(() => _needsDriver = v!),
                    ),
                    _buildCheckbox(
                      title: 'GPS (+5 TND/jour)',
                      value: _needsGPS,
                      onChanged: (v) => setState(() => _needsGPS = v!),
                    ),
                    _buildCheckbox(
                      title: 'Siège enfant (+3 TND/jour)',
                      value: _needsChildSeat,
                      onChanged: (v) => setState(() => _needsChildSeat = v!),
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Notes (optionnel)'),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _notesController,
                      label: 'Remarques ou demandes spéciales',
                      icon: Icons.note_outlined,
                      maxLines: 3,
                      validator: null,
                    ),

                    const SizedBox(height: 24),

                    _buildPriceSummary(),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          disabledBackgroundColor: Colors.blue.withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Confirmer la réservation',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
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
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            child: Image.network(
              widget.vehicle['image'],
              width: 120,
              height: 100,
              fit: BoxFit.cover,
              cacheWidth: 240,
              cacheHeight: 200,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 120,
                  height: 100,
                  color: const Color(0xFF3A3A3A),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                width: 120,
                height: 100,
                color: const Color(0xFF3A3A3A),
                child: const Icon(Icons.car_repair, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.vehicle['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.vehicle['category'],
                    style: const TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
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
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      // FIX 2 : quand un TextField perd le focus, on le redonne au nœud de scroll
      // pour que les flèches reprennent le contrôle du scroll immédiatement après la saisie.
      onEditingComplete: () {
        FocusScope.of(context).unfocus();
        _scrollFocusNode.requestFocus();
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
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
                Icon(
                  Icons.calendar_today,
                  color: isReturnDate && singleDayMode ? Colors.grey : Colors.blue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  date == null
                      ? 'Sélectionner'
                      : isReturnDate && singleDayMode
                          ? 'Calculée automatiquement'
                          : '${date.day}/${date.month}/${date.year}',
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
                      : _meetingTime!.format(context),
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
        value: _meetingLocation,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF2A2A2A),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        style: const TextStyle(color: Colors.white, fontSize: 14),
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
          if (value != null) {
            setState(() {
              _meetingLocation = value;
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        value: value,
        activeColor: Colors.blue,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  // Méthode pour construire le récapitulatif du prix (détail et total)
  Widget _buildPriceSummary() {
    double basePrice = (widget.vehicle['price'] ?? 0).toDouble() * _calculateDays();
    double extras = 0;

    if (_needsDriver) extras += 50 * _calculateDays();
    if (_needsGPS) extras += 5 * _calculateDays();
    if (_needsChildSeat) extras += 3 * _calculateDays();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Location (${_calculateDays()} jour${_calculateDays() > 1 ? 's' : ''})',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                '${basePrice.toInt()} TND',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
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
          const Divider(color: Colors.white24, height: 24),
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