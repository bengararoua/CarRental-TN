// Importation de la bibliothèque pour encoder/décoder du JSON
import 'dart:convert';

// Importation de la bibliothèque HTTP pour effectuer des requêtes réseau
import 'package:http/http.dart' as http;

// Classe de service d'authentification regroupant toutes les méthodes liées à l'API
class AuthService {
  
  // URL de base de l'API backend (serveur local sur le port 8000)

  static const String baseUrl = 'http://localhost:8000';


  // ========== MÉTHODES D'AUTHENTIFICATION ==========

  // Méthode statique pour l'inscription d'un nouvel utilisateur
  static Future<Map> register(String username, String email, String password) async {
    try {
      // Envoi d'une requête POST à l'endpoint /register avec les données utilisateur
      final response = await http.post(
        // Construction de l'URL complète pour l'inscription
        //tranforme chaine en url
        Uri.parse('$baseUrl/register'),
        // Définition du header pour indiquer que le corps est en JSON
        headers: {'Content-Type': 'application/json'},
        // Encodage des données utilisateur (nom, email, mot de passe) en JSON
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password
        }),
      );

      // Retourne un map indiquant le succès (statut 201) et les données de réponse décodées
      return {
        'success': response.statusCode == 201,
        'data': jsonDecode(response.body)
      };
    } catch (e) {
      // En cas d'erreur, retourne un map d'erreur avec le message d'exception
      return {'success': false, 'message': 'Erreur connexion: $e'};
    }
  }

  // Méthode statique pour la connexion d'un utilisateur existant
  static Future<Map> login(String email, String password) async {
    try {
      // Envoi d'une requête POST à l'endpoint /login
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        // Utilisation du format x-www-form-urlencoded pour les données de connexion
           // Ce format est requis par OAuth2 pour l'authentification
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        // Corps de la requête contenant l'email (utilisé comme username) et le mot de passe
        body: {
          'username': email,
          'password': password
        },
      );

      // Retourne un map indiquant le succès (statut 200) et les données de réponse
      return {
        'success': response.statusCode == 200,
        'data': jsonDecode(response.body)
      };
    } catch (e) {
      // En cas d'erreur, retourne un map d'erreur
      return {'success': false, 'message': 'Erreur connexion: $e'};
    }
  }

  // Méthode statique pour réinitialiser le mot de passe d'un utilisateur
  static Future<Map> resetPassword(String email, String newPassword) async {
    try {
      // Envoi d'une requête POST à l'endpoint /forgot-password/reset
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password/reset'),
        // Définition du header pour indiquer le format JSON
        headers: {'Content-Type': 'application/json'},
        // Encodage de l'email et du nouveau mot de passe en JSON
        body: jsonEncode({
          'email': email,
          'new_password': newPassword
        }),
      );

      // Retourne un map indiquant le succès (statut 200) et les données de réponse
      return {
        'success': response.statusCode == 200,
        'data': jsonDecode(response.body)
      };
    } catch (e) {
      // En cas d'erreur, retourne un map d'erreur
      return {'success': false, 'message': 'Erreur connexion: $e'};
    }
  }

  // ========== MÉTHODES POUR LES VÉHICULES ==========

  // Méthode statique pour récupérer la liste des véhicules
  static Future<List<dynamic>> getVehicles({String? token}) async {
    try {
      // Création d'un map pour les headers, initialement avec le type de contenu JSON
      final Map<String, String> headers = {'Content-Type': 'application/json'};
      // Si un token est fourni, on ajoute le header d'autorisation Bearer
      if (token != null) headers['Authorization'] = 'Bearer $token';

      // Envoi d'une requête GET à l'endpoint /vehicles
      final response = await http.get(Uri.parse('$baseUrl/vehicles'), headers: headers);

      // Si la réponse a un statut 200 (succès), on décode le corps de la réponse
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Vérifie que les données sont bien une liste, sinon retourne une liste vide
        return (data is List) ? data : [];
      }
      // En cas de statut différent de 200, retourne une liste vide
      return [];
    } catch (e) {
      // En cas d'erreur, affiche l'erreur dans la console et retourne une liste vide
      print('Erreur récupération véhicules: $e');
      return [];
    }
  }

  // Méthode statique pour ajouter un nouveau véhicule (admin uniquement)
  static Future<Map<String, dynamic>> addVehicle(Map<String, dynamic> vehicleData, String token) async {
    try {
      print('📤 Envoi du véhicule: $vehicleData');
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/vehicles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(vehicleData),
      );

      print('📊 Statut de la réponse: ${response.statusCode}');
      print('📊 Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData,
          'message': responseData['message'] ?? 'Véhicule ajouté avec succès'
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Erreur lors de l\'ajout'
        };
      }
    } catch (e) {
      print("❌ Erreur addVehicle: $e");
      return {
        'success': false,
        'message': 'Erreur de connexion: $e'
      };
    }
  }

  // ========== MÉTHODES POUR LES FAVORIS ==========

  // Méthode statique pour récupérer la liste des favoris de l'utilisateur
  static Future<List<dynamic>> getFavorites(String token) async {
    try {
      // Envoi d'une requête GET à l'endpoint /favorites avec le token d'autorisation
      final response = await http.get(
        Uri.parse('$baseUrl/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      // Si la réponse a un statut 200, on décode le corps de la réponse
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Vérifie que les données sont bien une liste, sinon retourne une liste vide
        return (data is List) ? data : [];
      }
      // En cas de statut différent de 200, retourne une liste vide
      return [];
    } catch (e) {
      // En cas d'erreur, affiche l'erreur dans la console et retourne une liste vide
      print('Erreur récupération favoris: $e');
      return [];
    }
  }

  // Méthode statique pour ajouter un véhicule aux favoris
  static Future<Map> addFavorite(int carId, String token) async {
    try {
      // Envoi d'une requête POST à l'endpoint /favorites/add
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        // Encodage de l'ID du véhicule en JSON
        body: jsonEncode({'car_id': carId}),
      );
      // Retourne un map indiquant le succès (statut 200) et les données de réponse
      return {'success': response.statusCode == 200, 'data': jsonDecode(response.body)};
    } catch (e) {
      // En cas d'erreur, retourne un map d'erreur
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Méthode statique pour retirer un véhicule des favoris
  static Future<Map> removeFavorite(int carId, String token) async {
    try {
      // Envoi d'une requête DELETE à l'endpoint /favorites/remove/{carId}
      final response = await http.delete(
        Uri.parse('$baseUrl/favorites/remove/$carId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      // Retourne un map indiquant le succès (statut 200) et les données de réponse
      return {'success': response.statusCode == 200, 'data': jsonDecode(response.body)};
    } catch (e) {
      // En cas d'erreur, retourne un map d'erreur
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // ========== MÉTHODES POUR LES RÉSERVATIONS ==========

  // Méthode statique pour ajouter une nouvelle réservation
  static Future<Map<String, dynamic>> addBooking(Map<String, dynamic> data, String token) async {
    try {
      // Affichage dans la console des données de réservation envoyées
      print('🔄 Envoi de la réservation: $data');
      
      // Envoi d'une requête POST à l'endpoint /bookings
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        // Encodage des données de réservation en JSON
        body: jsonEncode(data),
      );

      // Affichage du statut et du corps de la réponse pour le débogage
      print('📊 Statut de la réponse: ${response.statusCode}');
      print('📊 Corps de la réponse: ${response.body}');

      // Si la réponse a un statut 200 (succès)
      if (response.statusCode == 200) {
        // Décodage des données de réponse
        final responseData = jsonDecode(response.body);
        // Retourne un map de succès avec les données et un message
        return {
          'success': true,
          'data': responseData,
          'message': responseData['message'] ?? 'Réservation créée avec succès'
        };
      } else {
        // Si le statut est différent de 200, on décode les données d'erreur
        final errorData = jsonDecode(response.body);
        // Retourne un map d'échec avec le message d'erreur
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Erreur lors de la création de la réservation'
        };
      }
    } catch (e) {
      // En cas d'exception, affiche l'erreur dans la console
      print("❌ Erreur addBooking: $e");
      // Retourne un map d'échec avec le message d'erreur
      return {
        'success': false,
        'message': 'Erreur de connexion: $e'
      };
    }
  }

  // Méthode statique pour récupérer les réservations de l'utilisateur
  static Future<List<dynamic>> fetchMyBookings(String token) async {
    try {
      // Affichage dans la console du début de la récupération
      print('🔄 Récupération des réservations...');
      
      // Envoi d'une requête GET à l'endpoint /my-bookings
      final response = await http.get(
        Uri.parse('$baseUrl/my-bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Affichage du statut et du corps de la réponse pour le débogage
      print('📊 Statut de la réponse: ${response.statusCode}');
      print('📊 Corps de la réponse: ${response.body}');

      // Si la réponse a un statut 200 (succès)
      if (response.statusCode == 200) {
        // Décodage des données de réponse
        final decodedData = jsonDecode(response.body);
        // Vérifie que les données sont bien une liste, sinon retourne une liste vide
        return (decodedData is List) ? decodedData : [];
      } else {
        // Si le statut est différent de 200, affiche l'erreur serveur
        print("❌ Erreur serveur: ${response.statusCode} - ${response.body}");
        // Retourne une liste vide
        return [];
      }
    } catch (e) {
      // En cas d'exception, affiche l'erreur dans la console
      print("❌ Erreur fetchMyBookings: $e");
      // Retourne une liste vide
      return [];
    }
  }

  // ========== MÉTHODES ADMIN ==========

  // Récupère toutes les réservations (admin uniquement)
  static Future<List<dynamic>> fetchAllBookings(String token) async {
    try {
      print('📄 Récupération de toutes les réservations (admin)...');
      
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
        //statusCode == 403:accés interdit
      } else if (response.statusCode == 403) {
        print("❌ Accès refusé: droits administrateur requis");
        return [];
        //Erreur réponse du serveur
      } else {
        print("❌ Erreur serveur: ${response.statusCode} - ${response.body}");
        return [];
      }
      //catch (e) → Erreur technique / inattendue
    } catch (e) {
      print("❌ Erreur fetchAllBookings: $e");
      return [];
    }
  }

  // Met à jour le statut d'une réservation (admin uniquement)
  static Future<Map<String, dynamic>> updateBookingStatus(
    int bookingId, 
    String newStatus, 
    String token
  ) async {
    try {
      print('📝 Mise à jour du statut de la réservation #$bookingId vers "$newStatus"...');
      
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
      return {
        'success': false,
        'message': 'Erreur de connexion: $e'
      };
    }
  }

  // Supprime une réservation (admin uniquement)
  static Future<Map<String, dynamic>> deleteBooking(
    int bookingId, 
    String token
  ) async {
    try {
      print('🗑️ Suppression de la réservation #$bookingId...');
      
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
      return {
        'success': false,
        'message': 'Erreur de connexion: $e'
      };
    }
  }

  // ========== MÉTHODES POUR LE CHAT ==========

  // Méthode pour envoyer un message au chatbot
  static Future<Map<String, dynamic>> sendChatMessage(int convId, String text, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/assistant/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'conversation_id': convId,
        'content': text,
      }),
    );
    return jsonDecode(response.body);
  }

  // Méthode pour envoyer un message au chatbot et obtenir une réponse (avec gestion d'erreur améliorée)
  static Future<Map<String, dynamic>> saveAndGetAssistantReply({
    required int conversationId,
    required String content,
    required String token,
  }) async {
    try {
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
      rethrow;
    }
  }

  // Méthode pour créer une nouvelle conversation
  static Future<Map<String, dynamic>> createConversation(String token, String title) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/conversations/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
        }),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la création de la conversation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  // Méthode pour récupérer les conversations
  static Future<List<dynamic>> getUserConversations(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conversations/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data is List) ? data : [];
      }
      return [];
    } catch (e) {
      print('Erreur récupération conversations: $e');
      return [];
    }
  }

  // Méthode pour mettre à jour le profil utilisateur
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> userData, 
    String token
  ) async {
    try {
      print('📤 Envoi des données de mise à jour: $userData');
      
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

  // ========== MÉTHODES POUR LA GESTION DES VÉHICULES (ADMIN) ==========

  /// Supprime un véhicule (admin uniquement)
  static Future<Map<String, dynamic>> deleteVehicle(int vehicleId, String token) async {
    try {
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
      return {
        'success': false,
        'message': 'Erreur de connexion: $e'
      };
    }
  }

  /// Met à jour un véhicule (admin uniquement)
  static Future<Map<String, dynamic>> updateVehicle(
    int vehicleId, 
    Map<String, dynamic> vehicleData, 
    String token
  ) async {
    try {
      print('📤 Mise à jour du véhicule $vehicleId: $vehicleData');
      
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
      return {
        'success': false,
        'message': 'Erreur de connexion: $e'
      };
    }
  }
} 