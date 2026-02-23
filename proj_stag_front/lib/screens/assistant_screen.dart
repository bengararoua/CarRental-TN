// Import du package Material Design de Flutter pour les widgets UI
import 'package:flutter/material.dart';
// Import du package services pour gérer les événements clavier
import 'package:flutter/services.dart';
// Import du package Provider pour la gestion d'état
import 'package:provider/provider.dart';

// Import du provider des véhicules pour accéder aux données utilisateur
import '../providers/vehicles_provider.dart';
// Import du service d'authentification pour tous les appels API
import '../services/auth_service.dart';

// Définition de l'écran assistant (StatefulWidget pour gérer l'état)
class AssistantScreen extends StatefulWidget {
  // Constructeur de l'écran assistant avec clé optionnelle
  const AssistantScreen({Key? key}) : super(key: key);

  @override
  // Création de l'état associé à ce widget
  _AssistantScreenState createState() => _AssistantScreenState();
}

// Classe d'état pour gérer les variables et la logique de l'écran assistant
class _AssistantScreenState extends State<AssistantScreen> {
  // Contrôleur pour gérer le défilement de la liste des messages
  final ScrollController _scrollController = ScrollController();
  // Contrôleur pour gérer le champ de saisie du message
  final TextEditingController _messageController = TextEditingController();
  // Nœud de focus pour capturer les événements clavier
  final FocusNode _focusNode = FocusNode();
  // Liste pour stocker les messages de la conversation
  final List<Map<String, dynamic>> _messages = [];
  // Variable pour indiquer si l'assistant est en train de "réfléchir"
  bool _isTyping = false;
  // ID de conversation (nullable car peut ne pas être initialisé immédiatement)
  int? currentConversationId;

  @override
  // Méthode appelée une fois lors de l'initialisation du widget
  void initState() {
    // Appel de la méthode initState de la classe parent
    super.initState();
    // Exécuter du code après que le widget a été rendu pour la première fois
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialiser la conversation après le premier rendu
      _initializeChat();
    });
  }

  // Initialiser la conversation 
  // Initialiser la conversation via AuthService (centralisé)
  Future<void> _initializeChat() async {
    try {
      // Récupérer le token d'authentification depuis le provider
      final token = Provider.of<VehiclesProvider>(context, listen: false).token;
      
      // Vérifier si l'utilisateur est connecté
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez vous connecter pour utiliser l\'assistant'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 1. Récupérer les conversations existantes via AuthService
      final conversations = await AuthService.getConversations(token);
      
      // Filtrer les conversations actives (is_active == true)
      final activeConversations = conversations.where((conv) => conv['is_active'] == true).toList();
      
      if (activeConversations.isNotEmpty) {
        // Utiliser la conversation la plus récente
        setState(() {
          currentConversationId = activeConversations.first['id'];
        });
      } else {
        // Créer une nouvelle conversation via AuthService
        final result = await AuthService.createConversation(
          'Conversation avec l\'assistant',
          token,
        );
        if (result['success'] == true) {
          setState(() {
            currentConversationId = result['data']['id'];
          });
        }
      }
      
      // Ajouter un message de bienvenue dans l'interface
      _addWelcomeMessage();
      
    } catch (e) {
      print("Erreur initialisation chat: $e");
      // En cas d'erreur, utiliser une conversation locale sans backend
      _addWelcomeMessage();
    }
  }

  @override
  // Méthode appelée lors de la destruction du widget (nettoyage)
  void dispose() {
    // Nettoyage des contrôleurs pour éviter les fuites de mémoire
    _scrollController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    // Appel de la méthode dispose de la classe parent
    super.dispose();
  }

  // Ajouter un message de bienvenue (méthode privée)
  void _addWelcomeMessage() {
    // Mettre à jour l'état du widget
    setState(() {
      // Ajouter un message d'accueil à la liste des messages
      _messages.add({
        'content': 'Bonjour ! 👋 Je suis votre assistant CarRental. Comment puis-je vous aider aujourd\'hui ?',
        'is_user': false, // Message de l'assistant (pas de l'utilisateur)
        'timestamp': DateTime.now(), // Date et heure actuelles
      });
    });
  }

  // Faire défiler automatiquement vers le bas de la liste
  void _scrollToBottom() {
    // Utiliser WidgetsBinding pour éviter l'erreur de "rebuild during build"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Vérifier que le contrôleur est attaché à un widget
      if (_scrollController.hasClients) {
        // Animer le défilement vers le bas
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent, // Position maximale
          duration: const Duration(milliseconds: 300), // Durée de l'animation
          curve: Curves.easeOut, // Courbe d'animation
        );
      }
    });
  }

  // Envoyer un message (méthode asynchrone)
  void _sendMessage(String text) async {
    // Ignorer si le message est vide ou ne contient que des espaces
    if (text.trim().isEmpty) return;

    // Vérifier si la conversation est initialisée
    if (currentConversationId == null) {
      // Afficher un message d'erreur si pas d'ID de conversation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La conversation n\'est pas initialisée'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Arrêter l'exécution
    }

    // Récupérer et nettoyer le message
    final message = text.trim();
    // Effacer le champ de saisie
    _messageController.clear();

    // 1. Mise à jour locale immédiate (UI) - Ajout du message utilisateur
    setState(() {
      // Ajouter le message de l'utilisateur à la liste
      _messages.add({
        'content': message,
        'is_user': true, // C'est un message de l'utilisateur
        'timestamp': DateTime.now(),
      });
      // Indiquer que l'assistant est en train de répondre
      _isTyping = true;
    });

    // Défiler vers le bas pour montrer le nouveau message
    _scrollToBottom();

    try {
      // 2. Récupération du token depuis le Provider
      final token = Provider.of<VehiclesProvider>(context, listen: false).token;

      // Vérifier si le token existe
      if (token == null) {
        throw Exception('Utilisateur non connecté. Veuillez vous connecter pour utiliser l\'assistant.');
      }

      // 3. Appel au service pour sauvegarder en base et obtenir la réponse
      final response = await AuthService.saveAndGetAssistantReply(
        conversationId: currentConversationId!, // ID de conversation (non null)
        content: message, // Contenu du message
        token: token, // Token d'authentification
      );

      // 4. Ajouter la réponse de l'assistant reçue de la base
      setState(() {
        // Ajouter la réponse de l'assistant à la liste
        _messages.add({
          'content': response['reply'], // Réponse de l'API
          'is_user': false, // C'est un message de l'assistant
          'timestamp': DateTime.now(),
        });
        // L'assistant a fini de "réfléchir"
        _isTyping = false;
      });
      
      // Défiler vers le bas pour montrer la réponse
      _scrollToBottom();
    } catch (e) {
      // En cas d'erreur, arrêter l'indicateur de frappe
      setState(() => _isTyping = false);
      // Afficher l'erreur dans la console
      print("Erreur assistant: $e");
      
      // Message d'erreur local en cas d'échec de l'API
      setState(() {
        // Ajouter un message d'erreur générique
        _messages.add({
          'content': 'Je rencontre des difficultés de connexion. Pourriez-vous reformuler votre question ou réessayer dans quelques instants ?',
          'is_user': false,
          'timestamp': DateTime.now(),
        });
      });
      
      // Afficher un snackbar avec le détail de l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur de connexion au serveur: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Construire les suggestions rapides (widget)
  Widget _buildQuickSuggestions() {
    // Liste des suggestions avec icônes et textes
    final suggestions = [
      {'icon': Icons.directions_car, 'text': 'Comment réserver ?'},
      {'icon': Icons.attach_money, 'text': 'Quels sont les tarifs ?'},
      {'icon': Icons.favorite_border, 'text': 'Ajouter aux favoris'},
      {'icon': Icons.category, 'text': 'Types de véhicules'},
      {'icon': Icons.support_agent, 'text': 'Contacter le support'},
      {'icon': Icons.car_rental, 'text': 'Véhicules disponibles'},
      {'icon': Icons.person, 'text': 'Modifier mon profil'},
    ];

    // Retourner un conteneur pour les suggestions
    return Container(
      height: 50, // Hauteur fixe
      margin: const EdgeInsets.only(bottom: 8), // Marge en bas
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal, // Défilement horizontal
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            // Convertir chaque suggestion en widget cliquable
            children: suggestions.map((suggestion) {
              return GestureDetector(
                // Envoyer le texte de suggestion au clic
                onTap: () => _sendMessage(suggestion['text'] as String),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4), // Marge horizontale
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Padding interne
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A), // Couleur de fond
                    borderRadius: BorderRadius.circular(20), // Bords arrondis
                    border: Border.all(color: Colors.blue.withOpacity(0.3)), // Bordure bleue
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Prendre le minimum d'espace
                    children: [
                      // Icône de la suggestion
                      Icon(
                        suggestion['icon'] as IconData,
                        color: Colors.blue,
                        size: 16,
                      ),
                      const SizedBox(width: 6), // Espacement entre icône et texte
                      // Texte de la suggestion
                      Text(
                        suggestion['text'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(), // Convertir en liste de widgets
          ),
        ),
      ),
    );
  }

  @override
  // Construire l'interface utilisateur
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Fond noir
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A), // Couleur de fond de l'app bar
        elevation: 0, // Pas d'ombre
        automaticallyImplyLeading: false, // Ne pas afficher la flèche retour automatique
        title: MouseRegion(
          cursor: SystemMouseCursors.click, // Curseur de souris en main
          child: GestureDetector(
            onTap: () => Navigator.pop(context), // Retour à l'écran précédent au clic
            child: Row(
              mainAxisSize: MainAxisSize.min, // Prendre le minimum d'espace
              children: const [
                // Icône de retour
                Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                SizedBox(width: 8), // Espacement
                // Icône de l'assistant
                Icon(Icons.support_agent, color: Colors.blue, size: 24),
                SizedBox(width: 8), // Espacement
                // Titre de l'écran
                Text(
                  'Assistant',
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
        actions: [
          // Bouton pour effacer la conversation
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70), // Icône de suppression
            onPressed: () {
              // Effacer tous les messages
              setState(() {
                _messages.clear();
                // Ajouter à nouveau le message de bienvenue
                _addWelcomeMessage();
              });
              // Afficher une confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conversation réinitialisée'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone des messages (prend tout l'espace disponible)
          Expanded(
            // Si pas de messages, afficher l'état vide, sinon la liste
            child: _messages.isEmpty
                ? _buildEmptyState() // État initial
                : ListView.builder(
                    controller: _scrollController, // Contrôleur de défilement
                    padding: const EdgeInsets.all(16), // Padding interne
                    itemCount: _messages.length + (_isTyping ? 1 : 0), // Nombre total d'items
                    itemBuilder: (context, index) {
                      // Si c'est le dernier item et que l'assistant tape
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator(); // Indicateur de frappe
                      }
                      // Sinon, construire une bulle de message normale
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Suggestions rapides (uniquement après le message de bienvenue)
          if (_messages.length == 1) // Seulement quand il n'y a que le message de bienvenue
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16), // Padding horizontal
              child: _buildQuickSuggestions(), // Widget des suggestions
            ),

          // Zone de saisie du message (toujours visible)
          _buildInputArea(),
        ],
      ),
    );
  }

  // État vide (pas encore de messages) - widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Centrer verticalement
        children: [
          // Cercle contenant l'icône de l'assistant
          Container(
            padding: const EdgeInsets.all(30), // Padding interne
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1), // Fond bleu très transparent
              shape: BoxShape.circle, // Forme circulaire
            ),
            child: const Icon(
              Icons.support_agent,
              size: 80,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 24), // Espacement vertical
          // Titre principal
          const Text(
            'Assistant CarRental',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8), // Espacement vertical
          // Sous-titre
          const Text(
            'Posez-moi vos questions !',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Bulle de message (widget)
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    // Déterminer si c'est un message de l'utilisateur ou de l'assistant
    final isUser = message['is_user'] as bool;
    // Contenu du message
    final content = message['content'] as String;

    // Retourner un widget Row pour aligner avatar et bulle
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // Marge en bas entre les messages
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start, // Alignement selon l'expéditeur
        crossAxisAlignment: CrossAxisAlignment.start, // Alignement en haut
        children: [
          // Si c'est l'assistant qui parle, afficher son avatar à gauche
          if (!isUser) ...[
            // Avatar de l'assistant
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.blue, // Fond bleu
                shape: BoxShape.circle, // Forme circulaire
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8), // Espacement entre avatar et bulle
          ],
          // Bulle de message (flexible pour s'adapter au contenu)
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Padding interne
              decoration: BoxDecoration(
                // Couleur différente selon l'expéditeur
                color: isUser
                    ? Colors.blue // Bleu pour l'utilisateur
                    : const Color(0xFF2A2A2A), // Gris foncé pour l'assistant
                // Bords arrondis avec des rayons différents selon la position
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16), // Arrondi en haut à gauche
                  topRight: const Radius.circular(16), // Arrondi en haut à droite
                  bottomLeft: Radius.circular(isUser ? 16 : 4), // Petit arrondi si assistant en bas à gauche
                  bottomRight: Radius.circular(isUser ? 4 : 16), // Petit arrondi si utilisateur en bas à droite
                ),
              ),
              // Contenu textuel du message
              child: Text(
                content,
                style: const TextStyle(
                  color: Colors.white, // Texte blanc
                  fontSize: 15,
                  height: 1.4, // Hauteur de ligne
                ),
              ),
            ),
          ),
          // Si c'est l'utilisateur qui parle, afficher son avatar à droite
          if (isUser) ...[
            const SizedBox(width: 8), // Espacement entre bulle et avatar
            // Avatar de l'utilisateur
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[800], // Gris foncé
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Indicateur de frappe (widget)
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // Marge en bas
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // Alignement à gauche
        crossAxisAlignment: CrossAxisAlignment.start, // Alignement en haut
        children: [
          // Avatar de l'assistant
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8), // Espacement entre avatar et bulle
          // Bulle contenant les points animés
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A), // Fond gris foncé
              borderRadius: BorderRadius.circular(16), // Bords arrondis
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Prendre le minimum d'espace
              children: [
                _buildDot(0), // Premier point animé
                const SizedBox(width: 4), // Espacement entre points
                _buildDot(1), // Deuxième point animé
                const SizedBox(width: 4), // Espacement entre points
                _buildDot(2), // Troisième point animé
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Point animé pour l'indicateur de frappe (widget)
  Widget _buildDot(int index) {
    // Animation qui varie de 0.0 à 1.0
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0), // Valeur animée
      duration: const Duration(milliseconds: 600), // Durée de l'animation
      builder: (context, value, child) {
        // Calcul du délai selon l'index du point
        final delay = index * 0.2;
        // Valeur d'animation ajustée avec le délai (limitée entre 0 et 1)
        //clamp:limite une valeur entre un minimum et un maximum.
        final animValue = (value - delay).clamp(0.0, 1.0);
        // Calcul de l'opacité (varie entre 0.3 et 1.0)
        final opacity = (animValue * 2).clamp(0.3, 1.0);

        // Point visuel
        return Container(
          width: 8, // Largeur fixe
          height: 8, // Hauteur fixe
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity), // Blanc avec opacité variable
            shape: BoxShape.circle, // Forme circulaire
          ),
        );
      },
      // Quand l'animation se termine, forcer un rebuild pour la relancer
      onEnd: () {
        if (mounted) { // Vérifier que le widget est toujours dans l'arbre
          setState(() {}); // Redémarrer l'animation
        }
      },
    );
  }

  // Zone de saisie du message (widget)
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16), // Padding interne
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A), // Fond gris foncé
        // Ombre portée en haut
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Couleur noire semi-transparente
            blurRadius: 10, // Flou
            offset: const Offset(0, -2), // Décalage vers le haut
          ),
        ],
      ),
      child: Row(
        children: [
          // Champ de saisie (prend tout l'espace disponible)
          Expanded(
            child: TextField(
              controller: _messageController, // Contrôleur pour le texte
              focusNode: _focusNode, // Nœud de focus
              style: const TextStyle(color: Colors.white), // Texte blanc
              maxLines: null, // Nombre illimité de lignes
              textInputAction: TextInputAction.send, // Action "Envoyer" sur le clavier
              onSubmitted: (text) => _sendMessage(text), // Envoyer au appui sur "Entrée"
              decoration: InputDecoration(
                hintText: 'Posez votre question...', // Texte indicatif
                hintStyle: const TextStyle(color: Colors.white38), // Style du texte indicatif
                filled: true, // Remplir le fond
                fillColor: const Color(0xFF1A1A1A), // Couleur de fond
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24), // Bords arrondis
                  borderSide: BorderSide.none, // Pas de bordure
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Colors.white12, // Bordure gris clair
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: Colors.blue, // Bordure bleue quand focus
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8), // Espacement entre champ et bouton
          // Bouton d'envoi
          Container(
            decoration: BoxDecoration(
              color: Colors.blue, // Fond bleu
              shape: BoxShape.circle, // Forme circulaire
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white), // Icône d'envoi
              onPressed: () => _sendMessage(_messageController.text), // Action au clic
            ),
          ),
        ],
      ),
    );
  }
}