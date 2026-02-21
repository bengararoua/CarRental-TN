// Importer le package Flutter pour utiliser les widgets et fonctionnalités de base de Flutter
import 'package:flutter/material.dart';
// Importer le service d'authentification pour gérer les appels API liés à l'authentification
import '../services/auth_service.dart';
// Importer le package HTTP pour effectuer des requêtes réseau
import 'package:http/http.dart' as http;

// Définir une classe qui gère l'état des véhicules et notifie les widgets lorsqu'il y a des changements
class VehiclesProvider with ChangeNotifier {
  // Getter pour récupérer l'email de l'utilisateur connecté depuis les données utilisateur
  String? get userEmail => _user?['email'];
  // Getter pour récupérer le nom d'utilisateur depuis les données utilisateur
  String? get username => _user?['username'];
  // Variable privée stockant la liste complète des véhicules 
  List<Map<String, dynamic>> _allVehicles = [];
  // Variable privée indiquant si une opération de chargement est en cours
  bool _isLoading = false;
  // Variable privée pour stocker les messages d'erreur (ex: échec API)
  String _errorMessage = '';
  // Variable privée pour stocker le token JWT de l'utilisateur connecté
  String? _token;
  // Variable privée pour stocker le rôle de l'utilisateur (admin, user, etc.)
  String? _userRole;
  // Variable privée pour stocker toutes les données de l'utilisateur connecté
  Map<String, dynamic>? _user;

  // Getter public permettant d'accéder à la liste des véhicules (lecture seule)
  List<Map<String, dynamic>> get allVehicles => _allVehicles;
  // Getter public pour savoir si un chargement est en cours
  bool get isLoading => _isLoading;
  // Getter public pour récupérer le message d'erreur actuel
  String get errorMessage => _errorMessage;
  // Getter public pour récupérer le token JWT (utile pour d'autres appels API)
  String? get token => _token;
  // Getter public pour récupérer le rôle de l'utilisateur connecté
  String? get userRole => _userRole;
  // Getter public pour récupérer les données complètes de l'utilisateur connecté
  Map<String, dynamic>? get user => _user;
  
  // Getter pour vérifier si l'utilisateur a le rôle admin 
  bool get isAdmin => _userRole?.toLowerCase() == 'admin';

  // Getter qui filtre et retourne uniquement les véhicules marqués comme favoris
  List<Map<String, dynamic>> get favorites =>
      _allVehicles.where((v) => v['isFavorite'] == true).toList();

  // Méthode qui vérifie si un véhicule spécifique (identifié par son ID) est dans les favoris
  bool isFavorite(int vehicleId) {
    // Utiliser un bloc try-catch pour éviter les erreurs si le véhicule n'est pas trouvé
    try {
      // Rechercher le véhicule dans la liste par son ID, retourner un Map vide si non trouvé
      final vehicle = _allVehicles.firstWhere(
        (v) => v['id'] == vehicleId,
        orElse: () => {},
      );
      // Vérifier si la clé 'isFavorite' existe et est true, sinon retourner false
      return vehicle['isFavorite'] == true;
    } catch (e) {
      // En cas d'erreur (ex: liste vide), retourner false
      return false;
    }
  }

  // Méthode pour définir le token et optionnellement le rôle de l'utilisateur
  void setToken(String token, {String? role}) {
    // Stocker le token JWT
    _token = token;
    // Stocker le rôle si fourni en paramètre
    _userRole = role;
    // Afficher un message de debug pour le développement
    print('🔑 Token défini avec rôle: $role');
    // Notifier tous les widgets écoutant ce provider qu'un changement a eu lieu
    notifyListeners();
  }

  // Méthode pour stocker les données utilisateur et le token après une connexion réussie
  void setUser(Map<String, dynamic> userData, String token) {
    // Stocker les données utilisateur
    _user = userData;
    // Stocker le token JWT
    _token = token;
    // Extraire le rôle des données utilisateur si la clé 'role' existe
    if (userData.containsKey('role')) {
      _userRole = userData['role'];
    }
    // Afficher un message de debug avec le rôle
    print('👤 Utilisateur connecté avec rôle: $_userRole');
    // Notifier les widgets d'un changement d'état
    notifyListeners();
  }

  // Méthode pour réinitialiser toutes les données
  void clearUser() {
    // Réinitialiser le token
    _token = null;
    // Réinitialiser le rôle
    _userRole = null;
    // Réinitialiser les données utilisateur
    _user = null;
    // Vider la liste des véhicules
    _allVehicles = [];
    // Arrêter tout indicateur de chargement
    _isLoading = false;
    // Effacer les messages d'erreur
    _errorMessage = '';
    // Afficher un message de debug
    print('🔓 Utilisateur déconnecté, données nettoyées');
    // Notifier les widgets d'un changement d'état
    notifyListeners();
  }

  // Méthode asynchrone pour charger les véhicules depuis l'API
  Future<void> loadVehicles() async {
    // Définir l'état de chargement à true (début du chargement)
    _isLoading = true;
    // Réinitialiser les messages d'erreur précédents
    _errorMessage = '';
    // Notifier les widgets que l'état a changé (affichage d'un indicateur de chargement)
    notifyListeners();

    // Bloc try-catch pour gérer les erreurs potentielles lors des appels réseau
    try {
     

      // Appeler le service d'authentification pour récupérer la liste des véhicules
      // Passage du token pour authentification (peut être null)
      List<dynamic> vehiclesData = await AuthService.getVehicles(token: _token);

      // Transformer les données JSON brutes en une liste de Maps avec une structure claire
      _allVehicles = vehiclesData.map<Map<String, dynamic>>((vehicle) {
        return {
          'id': vehicle['id'],
          'name': vehicle['name'],
          'category': vehicle['category'],
          'price': vehicle['price'],
          'image': vehicle['image'],
          'transmission': vehicle['transmission'],
          'seats': vehicle['seats'],
          'engine': vehicle['engine'],
          'year': vehicle['year'],
          'fuel': vehicle['fuel'],
          'isAvailable': vehicle['isAvailable'],
          // Valeur par défaut false si 'isFavorite' n'existe pas
          'isFavorite': vehicle['isFavorite'] ?? false,
          'isNew': vehicle['isNew'] ?? false,
          'isBestChoice': vehicle['isBestChoice'] ?? false,
          // Convertir le rating en double (si null, mettre 0.0)
          'rating': vehicle['rating']?.toDouble() ?? 0.0,
          'popularity': vehicle['popularity'] ?? 0,
          'luggage': vehicle['luggage'] ?? 0,
          'airConditioning': vehicle['airConditioning'] ?? false,
          'bluetooth': vehicle['bluetooth'] ?? false,
        };
      }).toList(); // Convertir l'itérable en liste

      // Fin du chargement : définir l'état à false
      _isLoading = false;
      // Notifier les widgets que le chargement est terminé et les données sont prêtes
      notifyListeners();
    } catch (e) {
      // En cas d'erreur (ex: problème réseau, API hors service)
      _isLoading = false; // Arrêter l'indicateur de chargement
      _errorMessage = 'Erreur: $e'; // Stocker le message d'erreur
      // Notifier les widgets qu'une erreur est survenue (afficher un message d'erreur)
      notifyListeners();
    }
  }

  // Méthode asynchrone pour basculer l'état "favori" d'un véhicule
  Future<void> toggleFavorite(int vehicleId) async {
    // Si l'utilisateur n'est pas connecté (token null), ne rien faire
    if (_token == null) return;

    // Trouver l'index du véhicule dans la liste par son ID
    final index = _allVehicles.indexWhere((v) => v['id'] == vehicleId);
    // Si le véhicule n'existe pas (index -1), sortir de la méthode
    if (index == -1) return;

    // Sauvegarder l'état actuel du favori pour pouvoir le restaurer en cas d'erreur API
    final bool isCurrentlyFav = _allVehicles[index]['isFavorite'];

    try {
      // Mise à jour immédiate de l'interface utilisateur : inverser l'état local
      _allVehicles[index]['isFavorite'] = !isCurrentlyFav;
      // Notifier les widgets du changement (feedback visuel instantané)
      notifyListeners();

      // Appel API pour synchroniser avec le serveur
      if (isCurrentlyFav) {
        // Si le véhicule était déjà favori, le retirer des favoris côté serveur
        await AuthService.removeFavorite(vehicleId, _token!);
      } else {
        // Sinon, l'ajouter aux favoris côté serveur
        await AuthService.addFavorite(vehicleId, _token!);
      }
    } catch (e) {
      // En cas d'échec de l'appel API : restaurer l'état précédent localement
      _allVehicles[index]['isFavorite'] = isCurrentlyFav;
      // Notifier les widgets de la restauration (annuler le changement visuel)
      notifyListeners();
      // Afficher l'erreur dans la console pour le débogage
      print("Erreur toggleFavorite: $e");
    }
  }
}