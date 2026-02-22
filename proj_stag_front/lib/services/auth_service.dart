// Importation de la bibliothèque 'dart:convert' pour encoder/décoder du JSON
import 'dart:convert';

// Importation du package 'http' pour effectuer des requêtes HTTP
import 'package:http/http.dart' as http;

// Importation du package 'image_picker' pour utiliser le type XFile (représentation d'un fichier image)
import 'package:image_picker/image_picker.dart'; // Ajout pour XFile

// Importation de 'http_parser' pour manipuler les types  (nécessaire pour l'upload)
import 'package:http_parser/http_parser.dart'; // Pour MediaType

// Définition de la classe AuthService qui contient toutes les méthodes d'appel à l'API backend
class AuthService {
  // URL de base de l'API 
  static const String baseUrl = 'http://localhost:8000'; 

  // ========== MÉTHODES D'AUTHENTIFICATION ==========

  // Méthode statique pour enregistrer un nouvel utilisateur
  static Future<Map> register(String username, String email, String password) async {
    // Bloc try-catch pour capturer les erreurs réseau ou d'exécution
    try {
      // Envoi d'une requête POST à l'endpoint '/register'
      final response = await http.post(
        Uri.parse('$baseUrl/register'), // Construction de l'URI complète
        headers: {'Content-Type': 'application/json'}, // En-tête indiquant du JSON
        body: jsonEncode({ // Corps de la requête encodé en JSON
          'username': username,
          'email': email,
          'password': password
        }),
      );
      // Retourne un Map contenant le succès de l'opération et les données de réponse
      return {
        'success': response.statusCode == 201, // Vérifie si le code HTTP est 201 (créé)
        'data': jsonDecode(response.body) // Décode le corps JSON de la réponse
      };
    } catch (e) { // En cas d'erreur (ex: pas de connexion)
      // Retourne un Map indiquant l'échec et le message d'erreur
      return {'success': false, 'message': 'Erreur connexion: $e'};
    }
  }

  // Méthode statique pour connecter un utilisateur
  static Future<Map> login(String email, String password) async {
    try {
      // Envoi d'une requête POST à l'endpoint '/login' avec des données x-www-form-urlencoded
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'}, // Type de contenu spécifique
        body: {'username': email, 'password': password}, // Corps sous forme de Map
      );
      // Retourne le résultat avec vérification du code 200 (OK)
      return {
        'success': response.statusCode == 200,
        'data': jsonDecode(response.body)
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur connexion: $e'};
    }
  }

  // Méthode statique pour réinitialiser le mot de passe
  static Future<Map> resetPassword(String email, String newPassword) async {
    try {
      // Requête POST à '/forgot-password/reset' avec le nouveau mot de passe en JSON
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'new_password': newPassword}),
      );
      return {
        'success': response.statusCode == 200,
        'data': jsonDecode(response.body)
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur connexion: $e'};
    }
  }

  // ========== MÉTHODES POUR LES VÉHICULES ==========

  // Méthode statique pour récupérer la liste des véhicules
  static Future<List<dynamic>> getVehicles({String? token}) async {
    try {
      // Préparation des en-têtes HTTP
      final Map<String, String> headers = {'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token'; // Ajout du token si fourni

      // Requête GET à l'endpoint '/vehicles'
      final response = await http.get(Uri.parse('$baseUrl/vehicles'), headers: headers);
      if (response.statusCode == 200) { // Si la requête réussit
        final data = jsonDecode(response.body); // Décode la réponse
        return (data is List) ? data : []; // Retourne une liste si c'en est une, sinon liste vide
      }
      return []; // Retourne une liste vide en cas d'échec
    } catch (e) {
      print('Erreur récupération véhicules: $e'); // Affiche l'erreur dans la console
      return [];
    }
  }

  // Méthode statique pour ajouter un véhicule (réservé à l'admin)
  static Future<Map<String, dynamic>> addVehicle(Map<String, dynamic> vehicleData, String token) async {
    try {
      print('📤 Envoi du véhicule: $vehicleData'); // Log de débogage
      // Requête POST à '/admin/vehicles' avec authentification Bearer
      final response = await http.post(
        Uri.parse('$baseUrl/admin/vehicles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(vehicleData), // Encodage des données du véhicule en JSON
      );
      print('📊 Statut de la réponse: ${response.statusCode}'); // Log du statut
      print('📊 Corps de la réponse: ${response.body}'); // Log du corps

      if (response.statusCode == 200) { // Succès
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData,
          'message': responseData['message'] ?? 'Véhicule ajouté avec succès'
        };
      } else { // Erreur côté serveur
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Erreur lors de l\'ajout'
        };
      }
    } catch (e) { // Erreur réseau ou autre exception
      print("❌ Erreur addVehicle: $e");
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  // ========== MÉTHODES POUR LES FAVORIS ==========

  // Méthode statique pour récupérer les favoris de l'utilisateur connecté
  static Future<List<dynamic>> getFavorites(String token) async {
    try {
      // Requête GET à '/favorites' avec authentification
      final response = await http.get(
        Uri.parse('$baseUrl/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data is List) ? data : []; // Retourne une liste de favoris
      }
      return [];
    } catch (e) {
      print('Erreur récupération favoris: $e');
      return [];
    }
  }

  // Méthode statique pour ajouter un véhicule aux favoris
  static Future<Map> addFavorite(int carId, String token) async {
    try {
      // Requête POST à '/favorites/add' avec l'identifiant du véhicule
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'car_id': carId}),
      );
      return {'success': response.statusCode == 200, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Méthode statique pour retirer un véhicule des favoris
  static Future<Map> removeFavorite(int carId, String token) async {
    try {
      // Requête DELETE à '/favorites/remove/$carId'
      final response = await http.delete(
        Uri.parse('$baseUrl/favorites/remove/$carId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return {'success': response.statusCode == 200, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // ========== MÉTHODES POUR LES RÉSERVATIONS ==========

  // Méthode statique pour créer une nouvelle réservation
  static Future<Map<String, dynamic>> addBooking(Map<String, dynamic> data, String token) async {
    try {
      print('🔄 Envoi de la réservation: $data');
      // Requête POST à '/bookings'
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      print('📊 Statut de la réponse: ${response.statusCode}');
      print('📊 Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
          'message': responseData['message'] ?? 'Réservation créée avec succès'
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Erreur lors de la création de la réservation'
        };
      }
    } catch (e) {
      print("❌ Erreur addBooking: $e");
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  // Méthode statique pour récupérer les réservations de l'utilisateur connecté
  static Future<List<dynamic>> fetchMyBookings(String token) async {
    try {
      print('🔄 Récupération des réservations...');
      // Requête GET à '/my-bookings'
      final response = await http.get(
        Uri.parse('$baseUrl/my-bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('📊 Statut de la réponse: ${response.statusCode}');
      print('📊 Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        return (decodedData is List) ? decodedData : []; // Retourne la liste des réservations
      } else {
        print("❌ Erreur serveur: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ Erreur fetchMyBookings: $e");
      return [];
    }
  }

  // ========== MÉTHODES ADMIN ==========

  // Méthode statique pour récupérer toutes les réservations (admin uniquement)
  static Future<List<dynamic>> fetchAllBookings(String token) async {
    try {
      print('📄 Récupération de toutes les réservations (admin)...');
      // Requête GET à '/admin/bookings'
      final response = await http.get(
        Uri.parse('$baseUrl/admin/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('📊 Statut de la réponse: ${response.statusCode}');
      print('📊 Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        return (decodedData is List) ? decodedData : [];
      } else if (response.statusCode == 403) {
        print("❌ Accès refusé: droits administrateur requis");
        return [];
      } else {
        print("❌ Erreur serveur: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ Erreur fetchAllBookings: $e");
      return [];
    }
  }

  // Méthode statique pour mettre à jour le statut d'une réservation (admin)
  static Future<Map<String, dynamic>> updateBookingStatus(
    int bookingId,
    String newStatus,
    String token
  ) async {
    try {
      print('📝 Mise à jour du statut de la réservation #$bookingId vers "$newStatus"...');
      // Requête PATCH à '/admin/bookings/$bookingId/status?status=$newStatus'
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/bookings/$bookingId/status?status=$newStatus'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('📊 Statut de la réponse: ${response.statusCode}');
      print('📊 Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
          'message': responseData['message'] ?? 'Statut mis à jour avec succès'
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Erreur lors de la mise à jour'
        };
      }
    } catch (e) {
      print("❌ Erreur updateBookingStatus: $e");
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  // Méthode statique pour supprimer une réservation (admin)
  static Future<Map<String, dynamic>> deleteBooking(int bookingId, String token) async {
    try {
      print('🗑️ Suppression de la réservation #$bookingId...');
      // Requête DELETE à '/admin/bookings/$bookingId'
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/bookings/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('📊 Statut de la réponse: ${response.statusCode}');
      print('📊 Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
          'message': responseData['message'] ?? 'Réservation supprimée avec succès'
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Erreur lors de la suppression'
        };
      }
    } catch (e) {
      print("❌ Erreur deleteBooking: $e");
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  // ========== MÉTHODES POUR LE CHAT ==========

  // Méthode statique pour enregistrer un message et obtenir la réponse de l'assistant
  static Future<Map<String, dynamic>> saveAndGetAssistantReply({
    required int conversationId,
    required String content,
    required String token,
  }) async {
    try {
      // Même requête POST que sendChatMessage
      final response = await http.post(
        Uri.parse('$baseUrl/assistant/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'conversation_id': conversationId,
          'content': content,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Erreur saveAndGetAssistantReply: $e");
      rethrow; // Relance l'exception pour la gestion par l'appelant
    }
  }

  // Méthode statique pour mettre à jour le profil de l'utilisateur
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> userData,
    String token
  ) async {
    try {
      print('📤 Envoi des données de mise à jour: $userData');
      // Requête PUT à '/update-profile/'
      final response = await http.put(
        Uri.parse('$baseUrl/update-profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(userData),
      );
      print('📥 Réponse API (${response.statusCode}): ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        print('✅ Profil mis à jour avec succès: $responseData');
        return responseData;
      } else {
        print('❌ Erreur API: ${response.statusCode} - ${response.body}');
        throw Exception(responseData['message'] ?? 'Erreur lors de la mise à jour du profil');
      }
    } catch (e) {
      print('❌ Exception lors de la mise à jour: $e');
      throw Exception('Erreur réseau: $e');
    }
  }

  // ========== MÉTHODE UPLOAD D'IMAGE  ==========
  static Future<Map<String, dynamic>> uploadImage(XFile imageFile, String token) async {
    try {
      // Création d'une requête multipart (pour envoyer un fichier)
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-image/'),
      );
      request.headers['Authorization'] = 'Bearer $token'; // Ajout du token

      // Lecture des bytes de l'image
      final bytes = await imageFile.readAsBytes();
      // Récupère le type MIME (ex: 'image/png') ; fallback si null
      final mimeType = imageFile.mimeType ?? 'image/png'; // fallback si null
      // Ajout du fichier à la requête multipart
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', // Nom du champ attendu par le serveur
          bytes,
          filename: imageFile.name, // Nom du fichier
          contentType: MediaType.parse(mimeType), // Important pour le bon type MIME
        ),
      );

      print('📤 Upload de l\'image: ${imageFile.name} (type: $mimeType)');

      // Envoi de la requête et récupération de la réponse
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Réponse upload (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'url': data['url']}; // Retourne l'URL de l'image
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Erreur lors de l\'upload',
        };
      }
    } catch (e) {
      print('❌ Erreur uploadImage: $e');
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  // ========== MÉTHODES POUR LA GESTION DES VÉHICULES (ADMIN) ==========

  // Méthode statique pour supprimer un véhicule (admin)
  static Future<Map<String, dynamic>> deleteVehicle(int vehicleId, String token) async {
    try {
      // Requête DELETE à '/admin/vehicles/$vehicleId'
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/vehicles/$vehicleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'message': 'Véhicule supprimé avec succès'
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Erreur lors de la suppression'
        };
      }
    } catch (e) {
      print("❌ Erreur deleteVehicle: $e");
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  // Méthode statique pour mettre à jour un véhicule (admin)
  static Future<Map<String, dynamic>> updateVehicle(
    int vehicleId,
    Map<String, dynamic> vehicleData,
    String token
  ) async {
    try {
      print('📤 Mise à jour du véhicule $vehicleId: $vehicleData');
      // Requête PUT à '/admin/vehicles/$vehicleId'
      final response = await http.put(
        Uri.parse('$baseUrl/admin/vehicles/$vehicleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(vehicleData),
      );
      print('📥 Réponse API (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'message': 'Véhicule mis à jour avec succès'
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Erreur lors de la mise à jour'
        };
      }
    } catch (e) {
      print("❌ Erreur updateVehicle: $e");
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }
}